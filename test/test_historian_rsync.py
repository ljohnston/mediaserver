#!/usr/bin/env python3

import glob
import os
import shutil
import subprocess
import tempfile
import unittest

# TODO:
#   - Test for quiet period exceeded? Would be tricky as it would have to be
#   multi-threaded to we could keep touching a file while in the quiet period.

class TestHistorianRsync(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()

        self.export_dir = os.path.join(self.test_dir, 'historian_export')
        self.dest_dir = os.path.join(self.test_dir, 'source_photos', 'historian')

        os.makedirs(self.export_dir)
        os.makedirs(self.dest_dir)

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def create_test_data(self, file_counts):
        months = [ '01-January', '02-February' ]

        year_dir = os.path.join(self.export_dir, '2019')
        os.mkdir(year_dir)

        for month_index in range(len(months)):
            month_dir = os.path.join(year_dir, months[month_index])
            os.mkdir(month_dir)

            for file_index in range(1, file_counts[month_index] + 1):
                filename = 'photo_{}(rev {}).jpg'.format(file_index, file_index % 2)
                fq_filename = os.path.join(month_dir, filename)
                with open(fq_filename, 'w') as f:
                    f.write('{}_{}'.format(months[month_index], filename))

        # Untouch all the files so we don't have to wait for
        # the quietperiod to expire.
        self.untouch(self.export_dir)

    def untouch(self, path):
        os.utime(path, (0,0))
        for pathname in glob.iglob(os.path.join(path, '**/*'), recursive=True):
            os.utime(pathname, (0,0))

    def test_rsync_no_args(self):
        self.create_test_data([10,10])
        args = ['historian_rsync']
        response = subprocess.run(args, shell=False)
        self.assertEqual(response.returncode, 2)

    def test_rsync(self):
        self.create_test_data([10,10])
        args = ['historian_rsync', '-s', self.export_dir, '-d', self.dest_dir]
        response = subprocess.run(args, shell=False)

        synced_files = glob.glob(os.path.join(self.dest_dir, '**/*'), recursive=True)

        self.assertEqual(len(synced_files), 23)
        self.assertEqual(response.returncode, 0)

    def test_rsync_delete(self):
        self.create_test_data([10,10])
        args = ['historian_rsync', '-s', self.export_dir, '-d', self.dest_dir]
        response = subprocess.run(args, shell=False)

        self.create_test_data([10,9])
        args = ['historian_rsync', '-s', self.export_dir, '-d', self.dest_dir]
        response = subprocess.run(args, shell=False)

        synced_files = glob.glob(os.path.join(self.dest_dir, '**/*'), recursive=True)

        self.assertEqual(len(synced_files), 22)
        self.assertEqual(response.returncode, 0)

    def test_rsync_reductionlimit(self):
        self.create_test_data([10,10])
        args = ['historian_rsync', '-s', self.export_dir, '-d', self.dest_dir]
        response = subprocess.run(args, shell=False)

        self.create_test_data([10,0])
        args = ['historian_rsync', '-s', self.export_dir, '-d', self.dest_dir]
        response = subprocess.run(args, shell=False)

        synced_files = glob.glob(os.path.join(self.dest_dir, '**/*'), recursive=True)

        self.assertEqual(len(synced_files), 23)
        self.assertEqual(response.returncode, 5)

if __name__ == '__main__':
    unittest.main()
