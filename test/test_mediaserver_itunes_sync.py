#!/usr/bin/env python3

import glob
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

# TODO:

# To facilitate test/script development. Pass path to script location (i.e. the
# location of the script this test will be calling for tests) as argument on
# command line.
script_path = ''

class TestMediaserverItunesSync(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()

        self.source_music_dir = os.path.join(self.test_dir, 'source_music')
        self.dest_music_dir = os.path.join(self.test_dir, 'music')

        os.makedirs(self.source_music_dir)
        os.makedirs(self.dest_music_dir)

    def tearDown(self):
        # print(self.test_dir)
        shutil.rmtree(self.test_dir)

    def create_itunes_test_data(self, libraries):

        for library, artists in libraries.items():
            library_dir = os.path.join(self.source_music_dir, library)
            os.mkdir(library_dir)

            music_dir = os.path.join(library_dir, 'iTunes Media', 'Music')
            os.makedirs(music_dir, exist_ok=True)

            for artist, albums in artists.items():
                artist_dir = os.path.join(music_dir, artist)
                os.mkdir(artist_dir)

                for album in albums:
                    album_dir = os.path.join(artist_dir, album[0])
                    os.mkdir(album_dir)

                    for i in range(1, album[1] + 1):
                        filename = 'song_{}.m4a'.format(i)
                        fq_filename = os.path.join(album_dir, filename)
                        with open(fq_filename, 'w') as f:
                            f.write('{}_{}_{}'.format(artist, album[0], filename))


    def delete_directory_contents(self, dir):
        for root, dirs, files in os.walk(dir):
            for f in files:
                os.unlink(os.path.join(root, f))
            for d in dirs:
                shutil.rmtree(os.path.join(root, d))


    def test_sync_itunes(self):
        libraries = {
            "Lance's iTunes": {
                'The Beatles': [ ('Rubber Soul', 10) ],
                'Pink Floyd': [ ('The Final Cut', 10) ]},
            "Alison's iTunes": {
                'The Beatles': [ ('Rubber Soul', 10) ],
                'Johnny Cash': [ ('American IV', 10) ]},
        }

        itunes_libraries = [os.path.join(self.source_music_dir, "Lance's iTunes"),
                            os.path.join(self.source_music_dir, "Alison's iTunes")]

        self.create_itunes_test_data(libraries)
        args = [os.path.join(script_path, 'sync_music'),
                '-t', 'itunes',
                '-s', ','.join(itunes_libraries),
                '-d', self.dest_music_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_music_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [
                f for f in glob.glob(os.path.join(self.dest_music_dir, '**/*'), recursive=True) \
                if os.path.isdir(f)]

        self.assertEqual(len(synced_files), 30)
        self.assertEqual(len(destination_dirs), 6)
        self.assertEqual(response.returncode, 0)


    def test_sync_itunes_with_deleted_song(self):
        libraries = {
            "Lance's iTunes": {
                'The Beatles': [ ('Rubber Soul', 10) ],
                'Pink Floyd': [ ('The Final Cut', 10) ]},
            "Alison's iTunes": {
                'The Beatles': [ ('Rubber Soul', 10) ],
                'Johnny Cash': [ ('American IV', 10) ]},
        }

        itunes_libraries = [os.path.join(self.source_music_dir, "Lance's iTunes"),
                            os.path.join(self.source_music_dir, "Alison's iTunes")]

        self.create_itunes_test_data(libraries)
        args = [os.path.join(script_path, 'sync_music'),
                '-t', 'itunes',
                '-s', ','.join(itunes_libraries),
                '-d', self.dest_music_dir]
        response = subprocess.run(args, shell=False)

        # We'll simulate a delete by removing the sources and recreating with
        # one less song.

        self.delete_directory_contents(self.source_music_dir)

        libraries = {
            "Lance's iTunes": {
                'The Beatles': [ ('Rubber Soul', 10) ],
                'Pink Floyd': [ ('The Final Cut', 10) ]},
            "Alison's iTunes": {
                'The Beatles': [ ('Rubber Soul', 10) ],
                'Johnny Cash': [ ('American IV', 9) ]},
        }

        self.create_itunes_test_data(libraries)
        args = [os.path.join(script_path, 'sync_music'),
                '-t', 'itunes',
                '-s', ','.join(itunes_libraries),
                '-d', self.dest_music_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_music_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [
                f for f in glob.glob(os.path.join(self.dest_music_dir, '**/*'), recursive=True) \
                if os.path.isdir(f)]

        self.assertEqual(len(synced_files), 29)
        self.assertEqual(len(destination_dirs), 6)
        self.assertEqual(response.returncode, 0)


    def test_sync_itunes_with_deleted_album(self):
        libraries = {
            "Lance's iTunes": {
                'The Beatles': [ ('Rubber Soul', 10) ],
                'Pink Floyd': [ ('The Final Cut', 10) ]},
            "Alison's iTunes": {
                'The Beatles': [ ('Rubber Soul', 10) ],
                'Johnny Cash': [ ('American IV', 10) ]},
        }

        itunes_libraries = [os.path.join(self.source_music_dir, "Lance's iTunes"),
                            os.path.join(self.source_music_dir, "Alison's iTunes")]

        self.create_itunes_test_data(libraries)
        args = [os.path.join(script_path, 'sync_music'),
                '-t', 'itunes',
                '-s', ','.join(itunes_libraries),
                '-d', self.dest_music_dir]
        response = subprocess.run(args, shell=False)

        # We'll simulate a delete by removing the sources and recreating with
        # one less album.

        self.delete_directory_contents(self.source_music_dir)

        libraries = {
            "Lance's iTunes": {
                'Pink Floyd': [ ('The Final Cut', 10) ]},
            "Alison's iTunes": {
                'Johnny Cash': [ ('American IV', 10) ]},
        }

        self.create_itunes_test_data(libraries)
        args = [os.path.join(script_path, 'sync_music'),
                '-t', 'itunes',
                '-s', ','.join(itunes_libraries),
                '-d', self.dest_music_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_music_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [
                f for f in glob.glob(os.path.join(self.dest_music_dir, '**/*'), recursive=True) \
                if os.path.isdir(f)]

        self.assertEqual(len(synced_files), 20)
        self.assertEqual(len(destination_dirs), 4)
        self.assertEqual(response.returncode, 0)


if __name__ == '__main__':
    if len(sys.argv) == 2:
        script_path = sys.argv.pop()
    unittest.main()
