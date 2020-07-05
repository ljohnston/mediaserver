#!/usr/bin/env python3

import glob
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

# TODO:

#
# To facilitate test/script development, pass the path to script location (i.e.
# the location of the script this test will be calling for tests) an as
# argument on command line. For example:
#
#   $ /test/test_mediaserver_photosyncapp_sync.py /vagrant/roles/mediaserver/files/
#
script_path = ''

class TestMediaserverPhotosyncSync(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()

        self.source_photos_dir = os.path.join(self.test_dir, 'source_photos')
        self.dest_photos_dir = os.path.join(self.test_dir, 'photos')

        os.makedirs(self.source_photos_dir)
        os.makedirs(self.dest_photos_dir)


    def tearDown(self):
        print(self.test_dir)
        # shutil.rmtree(self.test_dir)


    def create_test_data(self, data_defs):
        # Filenames
        # Usually: YYYY-MM-DD_HH-MM-SS_IMG_<randomname>.<ext>
        # Can be:  YYYY-MM-DD_HH-MM-SS_<randomname>.<ext>

        for data_def in data_defs:
            path = os.path.join(self.source_photos_dir, data_def['source_subdir'])
            for d in data_def['files_date'].split('-'):
                path = os.path.join(path, d)

            if not os.path.exists(path):
                os.makedirs(path)

            for i in range(data_def['files_start'], data_def['files_end'] + 1):
                filename = '{}_01-23-45_IMG_{:04d}.JPG'.format(data_def['files_date'], i)
                fq_filename = os.path.join(path, filename)
                with open(fq_filename, 'w') as f:
                    content = data_def.get('content', filename)
                    f.write(content)


    def delete_directory_contents(self, dir):
        for root, dirs, files in os.walk(dir, topdown=False):
            if not '.mediaserver' in root:
                for f in files:
                    os.unlink(os.path.join(root, f))
                for d in dirs:
                    path = os.path.join(root, d)
                    if len(os.listdir(path)) == 0:
                        os.rmdir(path)


    def test_sync_photos(self):

        # Note duplicate content.
        data_defs = [
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-02',
                'files_start': 1,
                'files_end': 10},
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-03',
                'files_start': 1,
                'files_end': 10},
            ]
        self.create_test_data(data_defs)

        source_dirs = set()

        for data_def in data_defs:
            source_dirs.add(os.path.join(self.source_photos_dir, data_def['source_subdir']))

        args = [os.path.join(script_path, 'sync_photos'),
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', self.dest_photos_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if os.path.isdir(f) and not os.path.basename(f).startswith('.mediaserver_')]

        self.assertEqual(len(synced_files), 20)
        self.assertEqual(len(destination_dirs), 4)
        self.assertEqual(response.returncode, 0)


    def test_sync_photos_with_dup(self):

        # Note duplicate content.
        data_defs = [
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-02',
                'files_start': 1,
                'files_end': 10},
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-02',
                'files_start': 11,
                'files_end': 11,
                'content': 'foo'},
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-03',
                'files_start': 1,
                'files_end': 10},
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-03',
                'files_start': 11,
                'files_end': 11,
                'content': 'foo'},
            ]
        self.create_test_data(data_defs)

        source_dirs = set()

        for data_def in data_defs:
            source_dirs.add(os.path.join(self.source_photos_dir, data_def['source_subdir']))

        args = [os.path.join(script_path, 'sync_photos'),
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', self.dest_photos_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if os.path.isdir(f) and not os.path.basename(f).startswith('.mediaserver_')]

        self.assertEqual(len(synced_files), 21)
        self.assertEqual(len(destination_dirs), 4)
        self.assertEqual(response.returncode, 0)


    def test_sync_photos_with_deleted_photo(self):

        data_defs = [
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-02',
                'files_start': 1,
                'files_end': 10},
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-03',
                'files_start': 1,
                'files_end': 10},
            ]
        self.create_test_data(data_defs)

        source_dirs = set()

        for data_def in data_defs:
            source_dirs.add(os.path.join(self.source_photos_dir, data_def['source_subdir']))

        args = [os.path.join(script_path, 'sync_photos'),
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', self.dest_photos_dir]
        response = subprocess.run(args, shell=False)

        # We'll simulate a delete by removing the sources and recreating with
        # one less song.

        self.delete_directory_contents(self.source_photos_dir)

        data_defs = [
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-02',
                'files_start': 1,
                'files_end': 10},
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-03',
                'files_start': 1,
                'files_end': 9},
            ]
        self.create_test_data(data_defs)

        args = [os.path.join(script_path, 'sync_photos'),
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', self.dest_photos_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if os.path.isdir(f) and not os.path.basename(f).startswith('.mediaserver_')]

        self.assertEqual(len(synced_files), 19)
        self.assertEqual(len(destination_dirs), 4)
        self.assertEqual(response.returncode, 0)


    def test_sync_photos_with_deleted_date(self):

        data_defs = [
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-02',
                'files_start': 1,
                'files_end': 10},
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-03',
                'files_start': 1,
                'files_end': 10},
            ]
        self.create_test_data(data_defs)

        source_dirs = set()

        for data_def in data_defs:
            source_dirs.add(os.path.join(self.source_photos_dir, data_def['source_subdir']))

        args = [os.path.join(script_path, 'sync_photos'),
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', self.dest_photos_dir]
        response = subprocess.run(args, shell=False)

        # We'll simulate a delete by removing the sources and recreating with
        # one less song.

        self.delete_directory_contents(self.source_photos_dir)

        data_defs = [
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-02',
                'files_start': 1,
                'files_end': 10},
            ]
        self.create_test_data(data_defs)

        source_dirs = set()

        for data_def in data_defs:
            source_dirs.add(os.path.join(self.source_photos_dir, data_def['source_subdir']))

        args = [os.path.join(script_path, 'sync_photos'),
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', self.dest_photos_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if os.path.isdir(f) and not os.path.basename(f).startswith('.mediaserver_')]

        self.assertEqual(len(synced_files), 10)
        self.assertEqual(len(destination_dirs), 3)
        self.assertEqual(response.returncode, 0)


    def test_sync_photos_previously_synced(self):

        data_defs = [
            {
                'source_subdir': "lance_photosync",
                'files_date': '2019-01-02',
                'files_start': 1,
                'files_end': 10},
            ]
        self.create_test_data(data_defs)

        source_dirs = set()

        for data_def in data_defs:
            source_dirs.add(os.path.join(self.source_photos_dir, data_def['source_subdir']))

        args = [os.path.join(script_path, 'sync_photos'),
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', self.dest_photos_dir]
        response = subprocess.run(args, shell=False)

        # Remove destination photos dir. Another sync should put nothing back,
        # since everything has previously been synced there.

        self.delete_directory_contents(self.dest_photos_dir)

        args = [os.path.join(script_path, 'sync_photos'),
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', self.dest_photos_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if os.path.isdir(f) and not os.path.basename(f).startswith('.mediaserver_')]

        self.assertEqual(len(synced_files), 0)
        self.assertEqual(len(destination_dirs), 0)
        self.assertEqual(response.returncode, 0)


if __name__ == '__main__':
    if len(sys.argv) == 2:
        script_path = sys.argv.pop()
    unittest.main()
