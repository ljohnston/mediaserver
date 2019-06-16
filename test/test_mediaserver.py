#!/usr/bin/env python3

import glob
import os
import shutil
import subprocess
import tempfile
import unittest

# TODO:

class TestMediaserver(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()

    # def tearDown(self):
        # shutil.rmtree(self.test_dir)

    def create_itunes_test_data(self, libraries):
        itunes_dir = os.path.join(self.test_dir, 'itunes')
        os.mkdir(itunes_dir)

        for library, artists in libraries.items():
            library_dir = os.path.join(itunes_dir, library)
            os.mkdir(library_dir)

            music_dir = os.path.join(library_dir, 'iTunes Media', 'Music')
            os.makedirs(music_dir, exist_ok=True)

            for artist, albums in artists.items():
                artist_dir = os.path.join(music_dir, artist)
                os.mkdir(artist_dir)

                for album in albums:
                    album_dir = os.path.join(artist_dir, album[0])
                    os.mkdir(album_dir)

    def test_sync_itunes(self):
        libraries = {
            "Lance's iTunes": {
                'The Beatles': [ ('Rubber Soul', 14) ],
                'Pink Floyd': [ ('The Final Cut', 12) ]},
            "Alison's iTunes": {
                'The Beatles': [ ('Rubber Soul', 14) ],
                'Johnny Cash': [ ('American IV', 15) ]},
        }

        self.create_itunes_test_data(libraries)

if __name__ == '__main__':
    unittest.main()
