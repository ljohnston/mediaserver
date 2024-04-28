
import hashlib
import json
import os

from abc import ABC, abstractmethod

#
# Database classes to manage photos. Typically, photos are synced to the
# 'source_photos' directory via some process (e.g. photosync). These photos get
# symlinked to different plex library directories via custom python scripts.
# These database classes are used to keep track of what's been synced where, so
# that  we don't duplicate files, have a sync history, etc.
#
# An example use case:
#
#   Sending source photos to historian_import.
#
#   Alison will have to import these then delete them all when she's done. So
#   we'll only run the sync in the middle of the night.
#
#   Sync:
#     /storage/media/source_photos/alison_photosync AND
#     /storage/media/source_photos/lance_photosync
#     to /storage/media/historian_import
#
#     Only if:
#       - photo has never been synced to historian_import
#       - photo doesn't exist in historian_import
#
#     Idealy, we'd also inlude a check to make sure the photo doesn't exist in
#     the historian shadow copy maintained at /mnt/data/historian. I expect,
#     however, that historian would modify the photo during import (e.g. add
#     some tags). TODO: I could test this.
#

#
# Ideally, plex photo libraries (i.e. our sync targets) will have the following
# diretory structure when possible:
#
#   <root>
#     <year>
#       <month>
#         <day>
#           ...
#

class MediaserverDB(ABC):

    def __init__(self, database_dir, db):
        self.db_path = os.path.join(database_dir, db)
        if not os.path.exists(self.db_path):
            os.makedirs(self.db_path)

    @abstractmethod
    def get_key(self, photo):
        pass

    @abstractmethod
    def to_dict(self, photo):
        pass

    @abstractmethod
    def from_dict(self, data):
        pass

    # TODO: We need a select method (really just select all), so that we can
    # remove DB records for files that may have been deleted.
    def select_all(self):
        pass

    def read_record(self, photo):
        rec = self.__get_record_path(photo)

        if not os.path.isfile(rec):
            return None

        # TODO: Error handling. Deserializing may fail due to corrupt or
        # incomplete file. In that case we should delete it and return None.
        with open(rec, 'r') as f:
            data = json.load(f)

        return self.from_dict(data)

    def write_record(self, photo):
        rec = self.__get_record_path(photo)

        rec_dir = os.path.dirname(rec)
        if not os.path.exists(rec_dir):
            os.makedirs(rec_dir)

        with open(rec, 'w') as f:
            json.dump(self.to_dict(photo), f)

    def delete_record(self, photo):
        rec = self.__get_record_path(photo)

        # TODO: Delete empty path elements up the tree.

        if os.path.isfile(rec):
            os.remove(rec)

    #
    # "Private" methods.
    #

    def __get_record_path(self, photo):
        hash = self.get_key(photo)
        return os.path.join(self.db_path, hash[-1], hash[-3:-1], hash[:-3])

    def __to_json_str(self, photo, destination_dir):
        return json.dumps(self.to_dict(photo, destination_dir), sort_keys=True)


#
# A PhotoDB is a database of photos in the current directory tree.
#
#   - type: the type of photo application where the image originated (e.g.
#     photosync or historian).
#   - source_file: the location of the originating file
#   - digest: MD5 of the source file
#

class PhotoDB(MediaserverDB):

    def __init__(self, database_dir):
        MediaserverDB.__init__(self, database_dir, '.mediaserver_photoDB')

    def get_key(self, photo):
        return photo.digest()

    def to_dict(self, photo):
        data = {}
        data['type'] = photo.type
        data['source_file'] = photo.file
        data['digest'] = photo.digest()
        return data

    def from_dict(self, data):
        return PhotoRecord(
            data['type'],
            data['source_file'],
            data['digest'])


class PhotoRecord:

    def __init__(self, type, source_file, digest):
        self.type = type
        self.source_file = source_file
        self.digest = digest


#
# A SyncDB is a record of photos in the current directory tree that have been
# synced to some external location.
#
#   - type: the type of photo application where the image originated (e.g.
#     photosync or historian).
#   - source_file: the location of the originating file
#   - destination_file: the location of the "synced" file
#   - digest: MD5 of the source file
#

class SyncDB(MediaserverDB):

    def __init__(self, database_dir, destination_dir):
        # TODO: syncDB name should include destination
        MediaserverDB.__init__(self, database_dir, '.mediaserver_syncDB')
        self.destination_dir = destination_dir

    def get_key(self, photo):
        return hashlib.md5((photo.digest() + self.destination_dir).encode()).hexdigest()

    def to_dict(self, photo):
        data = {}
        data['type'] = photo.type
        data['source_file'] = photo.file
        data['destination_dir'] = self.destination_dir
        data['digest'] = photo.digest()
        return data

    def from_dict(self, data):
        return SyncRecord(
            data['type'],
            data['source_file'],
            data['destination_dir'],
            data['digest'])


class SyncRecord:

    def __init__(self, type, source_file, destination_dir, digest):
        self.type = type
        self.source_file = source_file
        self.destination_dir = destination_dir
        self.digest = digest
