#!/usr/bin/env python3

import glob
import os

from os import path

photo_library = '/storage/media/iphotos/Photos Library.photoslibrary/Masters'
target_library = '/storage/media/foo'


for pathname in glob.iglob(photo_library + '/**/*', recursive=True):

    if path.isfile(pathname):
        target_directory_name = '-'.join(pathname.split('/')[-5:-2])
        target_directory = target_library + '/' + target_directory_name

        if not path.exists(target_directory):
            os.mkdir(target_directory)

        filename = path.basename(pathname)
        symlink = target_directory + '/' + filename

        if not path.exists(symlink):
            os.symlink(path.relpath(pathname, path.dirname(symlink)), symlink)






