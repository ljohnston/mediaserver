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

class TestMediaserverPhotosyncSync(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        print(self.test_dir)

        self.source_photos_dir = os.path.join(self.test_dir, 'source_photos')
        self.dest_photos_dir = os.path.join(self.test_dir, 'photos')
        self.database_dir = os.path.join(self.test_dir, 'photosdb')

        os.makedirs(self.source_photos_dir)
        os.makedirs(self.dest_photos_dir)


    # def tearDown(self):
    #     shutil.rmtree(self.test_dir)

    def create_test_data(self, data_defs):
        # Filenames: YYYY-MM-DD_HH-MM-SS_IMG_<randomname>.<ext>

        for data_def in data_defs:
            path = os.path.join(self.source_photos_dir, data_def['source_subdir'])

            if not os.path.exists(path):
                os.makedirs(path)

            for i in range(data_def['files_start'], data_def['files_end'] + 1):
                filename = '{}_01-23-45_IMG_{:04d}.JPG'.format(data_def['files_prefix'], i)
                fq_filename = os.path.join(path, filename)
                with open(fq_filename, 'w') as f:
                    f.write(filename)


    def test_sync_photos(self):
        data_defs = [
            {
                'source_subdir': "Lance Johnston's iPhone",
                'files_prefix': '2019-01-02',
                'files_start': 1,
                'files_end': 10},
            {
                'source_subdir': "Lance Johnston's iPhone",
                'files_prefix': '2019-01-03',
                'files_start': 1,
                'files_end': 10}
            ]
        self.create_test_data(data_defs)

        source_dirs = set()

        for data_def in data_defs:
            source_dirs.add(os.path.join(self.source_photos_dir, data_def['source_subdir']))

        args = [os.path.join(script_path, 'mediaserver'), 'sync-photos',
                '-t', 'photosync-app',
                '-s', ','.join(source_dirs),
                '-d', ','.join([self.dest_photos_dir]),
                '--database-dir', self.database_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.dest_photos_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        destination_dirs = [f for f in os.listdir(self.dest_photos_dir)]

        self.assertEqual(len(synced_files), 20)
        self.assertEqual(len(destination_dirs), 2)
        self.assertEqual(response.returncode, 0)


if __name__ == '__main__':
    if len(sys.argv) == 2:
        script_path = sys.argv.pop()
    unittest.main()
