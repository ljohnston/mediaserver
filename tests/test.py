import pytest

@pytest.mark.parametrize("pkg", ['docker-ce', 'mergerfs', 'samba', 'snapraid'])
def test_packages(host, pkg):
    assert host.package(pkg).is_installed

def test_docker_running_and_enabled(host):
    docker = host.service("docker")
    assert docker.is_running
    assert docker.is_enabled

@pytest.mark.parametrize("container", ["plex", "mysql", "nextcloud"])
def test_docker_containers_running(host, container):
    assert host.docker(container).is_running

def test_mediausers_group_exists(host):
    mediausers_group = host.group("mediausers")
    assert mediausers_group.exists

@pytest.mark.parametrize("user", ["alison", "ljohnston"])
def test_users_exist(host, user):
    user = host.user(user)
    assert user.exists
    assert "mediausers" in user.groups

def test_mediaserver_scripts_run(host):
    with host.sudo("plexuser"):
        assert host.run("sync_music --help").rc == 0
        assert host.run("sync_photos --help").rc == 0

def test_test_scripts(host):
    with host.sudo("plexuser"):
        assert host.run("~/test/test_mediaserver_itunes_sync.py").rc == 0
        assert host.run("~/test/test_mediaserver_photosyncapp_sync.py").rc == 0
