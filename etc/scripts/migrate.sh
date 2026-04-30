#!/bin/bash
# migrate.sh

#
# One-time migration of UIDs/GIDs and mediausers group prior to updating
# ansible config to assign UIDs and GIDs. This to prepare for an Ubuntu OS
# upgrade on prd mediaserver. I wanted to do the OS upgrade by simply
# installing a brand new OS version from scratch on the boot disk. To do so
# meant I had to have EVERYTHING properly configured in ansible so that I could
# just do the upgrade and then run the ansible config against prd and all
# UIDs/GIDs and current file ownership would work without problem.
#
# A couple of upgrade notes:
#   - When I install the OS, I need to create an admin user that won't
#     conflict with any of my ansible configured users (e.g. ljohnston).
#     This is different than when I did the original OS install and
#     created my ljohnston user at install time.
#   - Prior to running this script in prd, the /docker-compose.yml file
#     needs to be edited to set the UID/GID for the plex container
#     to 2002/2002.
#
# To summarize the prd OS upgrade process:
#   - Copy this script to prd mediaserver 'ljohnston' user's home dir.
#   - Edit /docker-compose.yml to set plex container UID/GID to 2002/2002.
#   - Run the script via 'sudo bash migrate.sh prd', which will run in DRY_RUN
#     mode. Ensure nothing ugly happens.
#   - Re-run the script via 'sudo bash migrate.sh prd false'.
#   - Do the OS upgrade on the server, creating an 'ubuntu' admin user.
#   - Run the ansible playbook against prd. Will need to modify things to
#     get the playbook to run as the new 'ubuntu' user.
#
# Post prd migration notes:
#   - I had to create a new user on the box with sudo privileges to run the
#     script because logging in and running as my ljohnston user would fail
#     usermod due to systemd process was using that user.
#   - Due to the above failure, rerunning the script would fail for groupmod
#     and usermod issues since the groups/users had already been modified. I
#     simply went in and commented out the sections of the script that didn't
#     need to be rerun.
#   - In retrospect, the script could have been a little more robust, but it
#     should be a onetime only thing.
#
#

set -euo pipefail

# ---------------------------
# ARGUMENTS
# ---------------------------
if [ $# -lt 1 ]; then
    echo "Usage: $0 <dev|prd> [dry-run=true|false]"
    exit 1
fi

ENV="$1"
DRY_RUN="${2:-true}"

if [[ "$ENV" != "dev" && "$ENV" != "prd" ]]; then
    echo "First argument must be 'dev' or 'prd'"
    exit 1
fi

if [[ "$DRY_RUN" != "true" && "$DRY_RUN" != "false" ]]; then
    echo "Second argument must be 'true' or 'false'"
    exit 1
fi

echo "Running in ENV=$ENV DRY_RUN=$DRY_RUN"

# ---------------------------
# CONFIG: set old -> new IDs
# ---------------------------

#
# IMPORTANT!!! These maps differ between dev and prd!!!
#

# dev - ljohnston = 1003:1004, alison = 1002:1003, plexuser = 1004:1005
#       mediausers GID = 1002
# prd - ljohnston = 1000:1000, alison = 1001:1002, plexuser = 1002:1003
#       mediausers GID = 1001

# New on both dev and prd:
# ljohnston = 2000:2000
# alison = 2001:2001
# plexuser = 2002:2002

if [[ "$ENV" == "dev" ]]; then
  declare -A UID_MAP=( [1003]=2000 [1002]=2001 [1004]=2002 )
  declare -A GID_MAP=( [1004]=2000 [1003]=2001 [1005]=2002 )
  OLD_MEDIA_GID=1002
elif [[ "$ENV" == "prd" ]]; then
  declare -A UID_MAP=( [1000]=2000 [1001]=2001 [1002]=2002 )
  declare -A GID_MAP=( [1000]=2000 [1002]=2001 [1003]=2002 )
  OLD_MEDIA_GID=1001
fi

if grep 'P[GU]ID=100' /docker-compose.yml; then
  echo "docker-compose.yml needs UID/GID update for 2002/2002. Aborting..."
  exit 1
fi

# mediausers group
MEDIA_GROUP="mediausers"
NEW_MEDIA_GID=3000
MEDIA_USERS=(ljohnston alison plexuser)

# Add any host paths used by Docker containers or apps for your managed users
declare -A USER_EXTRA_PATHS=(
    [plexuser]="/var/lib/plexmediaserver"
    # Add more paths per user as needed
    # [user2]="/var/lib/foo /var/lib/bar ..."
)


# Directories
DATA_DIRS=(/mnt/data /mnt/snapraid/data/*)
HOME_DIRS=(/home/ljohnston /home/plexuser)
ROOT_SCAN=true

# ---------------------------
# FUNCTIONS
# ---------------------------
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

# ---------------------------
# Stop services
# ---------------------------
echo "Stop services writing to disks..."

# dev/prd on different docker versions.
if which docker-compose &>/dev/null; then
  DOCKER_COMPOSE_CMD="docker-compose"
else
  DOCKER_COMPOSE_CMD="docker compose"
fi

run_cmd "sudo $DOCKER_COMPOSE_CMD -f /docker-compose.yml down"
run_cmd "sudo systemctl stop docker.socket docker.service smbd"

# ---------------------------
# Update groups
# ---------------------------
echo "Ensuring group $MEDIA_GROUP exists with GID $NEW_MEDIA_GID..."
run_cmd "sudo groupmod -g $NEW_MEDIA_GID $MEDIA_GROUP 2>/dev/null || sudo groupadd -g $NEW_MEDIA_GID $MEDIA_GROUP"


echo "Updating other groups..."
for old_gid in "${!GID_MAP[@]}"; do
    new_gid=${GID_MAP[$old_gid]}
    group_name=$(getent group "$old_gid" | cut -d: -f1 || true)
    if [ -n "$group_name" ]; then
        run_cmd "sudo groupmod -g $new_gid $group_name"
    fi
done


# ---------------------------
# Update users
# ---------------------------
echo "Updating users UIDs/GIDs..."
for old_uid in "${!UID_MAP[@]}"; do
    new_uid=${UID_MAP[$old_uid]}
    username=$(getent passwd "$old_uid" | cut -d: -f1 || true)
    if [ -n "$username" ]; then
        # Update UID and primary GID
        run_cmd "sudo usermod -u $new_uid -g $new_uid $username"
    fi
done

echo "Adding users to $MEDIA_GROUP..."
for u in "${MEDIA_USERS[@]}"; do
    run_cmd "sudo usermod -aG $MEDIA_GROUP $u"
done


# ---------------------------
# Update file ownership
# ---------------------------

for disk in "${DATA_DIRS[@]}"; do
    echo "Updating files with old mediausers GID ($OLD_MEDIA_GID) to new GID ($NEW_MEDIA_GID)..."
    run_cmd "sudo find \"$disk\" -gid $OLD_MEDIA_GID -print0 | sudo xargs -0 --no-run-if-empty chgrp -h $NEW_MEDIA_GID"

    echo "Processing data disks for UIDs/GIDs..."
    echo "Disk: $disk"
    for old_uid in "${!UID_MAP[@]}"; do
        new_uid=${UID_MAP[$old_uid]}
        run_cmd "sudo find \"$disk\" -uid $old_uid -print0 | sudo xargs -0 --no-run-if-empty chown -h $new_uid"
    done
    for old_gid in "${!GID_MAP[@]}"; do
        new_gid=${GID_MAP[$old_gid]}
        run_cmd "sudo find \"$disk\" -gid $old_gid -print0 | sudo xargs -0 --no-run-if-empty chgrp -h $new_gid"
    done
done

echo "Processing home directories..."
for home in "${HOME_DIRS[@]}"; do
    echo "  Directory: $home"
    run_cmd "sudo chown -R $(basename "$home"):$(basename "$home") $home"
done

if [ "$ROOT_SCAN" = true ]; then
    run_cmd "sudo find / -xdev -gid $OLD_MEDIA_GID -print0 | sudo xargs -0 --no-run-if-empty chgrp $NEW_MEDIA_GID"
fi

# ---------------------------
# Update home directories
# ---------------------------
echo "Processing home directories..."
for home in "${HOME_DIRS[@]}"; do
    run_cmd "sudo chown -R $(basename "$home"):$(basename "$home") $home"
done

# ---------------------------
# Fix ownership for extra paths
# ---------------------------
echo "Fixing ownership in application directories..."
for u in "${!USER_EXTRA_PATHS[@]}"; do
    new_uid=${UID_MAP[$(id -u "$u" 2>/dev/null)]:-$u} # get new UID from map
    new_gid=${GID_MAP[$(id -g "$u" 2>/dev/null)]:-$u} # get new GID from map
    for path in ${USER_EXTRA_PATHS[$u]}; do
        if [ -d "$path" ]; then
	    echo "Updating $path for $u:$u..."
            run_cmd "sudo find $path -uid $old_uid -print0 | sudo xargs -0 -r chown -h $new_uid"
            run_cmd "sudo find $path -gid $old_gid -print0 | sudo xargs -0 -r chgrp -h $new_gid"
        fi
    done
done

# ---------------------------
# Optional: scan root filesystem
# ---------------------------
if [ "$ROOT_SCAN" = true ]; then
    echo "Scanning / for old UIDs/GIDs..."
    for old_uid in "${!UID_MAP[@]}"; do
        new_uid=${UID_MAP[$old_uid]}
        run_cmd "sudo find / -xdev -uid $old_uid -print0 | sudo xargs -0 --no-run-if-empty chown -h $new_uid || true"
    done
    for old_gid in "${!GID_MAP[@]}"; do
        new_gid=${GID_MAP[$old_gid]}
        run_cmd "sudo find / -xdev -gid $old_gid -print0 | sudo xargs -0 --no-run-if-empty chgrp -h $new_gid || true"
    done
fi

# ---------------------------
# Verification
# ---------------------------
echo "Verifying data disks..."
for disk in "${DATA_DIRS[@]}"; do
    echo "Disk: $disk"
    for old_uid in "${!UID_MAP[@]}"; do
        echo "  Files still with UID $old_uid:"
        find "$disk" -uid "$old_uid"
    done
    for old_gid in "${!GID_MAP[@]}"; do
        echo "  Files still with GID $old_gid:"
        find "$disk" -gid "$old_gid"
    done
    # Mediausers GID
    echo "  Files still with old mediausers GID $OLD_MEDIA_GID:"
    find "$disk" -gid "$OLD_MEDIA_GID"
done

if [ "$ROOT_SCAN" = true ]; then
    echo "Verifying / for orphaned files..."
    sudo find / -xdev -nouser -o -nogroup
fi

# ---------------------------
# Restart services
# ---------------------------
echo "Restart services..."
# Example, edit as needed:
# run_cmd "sudo systemctl start docker plexmediaserver sonarr radarr"

run_cmd "sudo systemctl start docker smbd"
run_cmd "sudo $DOCKER_COMPOSE_CMD -f /docker-compose.yml up -d"

echo "UID/GID and mediausers migration complete."
