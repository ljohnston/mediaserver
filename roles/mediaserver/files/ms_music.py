#!/usr/bin/env python3

import glob
import os

from os import path

itunes_library = '/storage/media/itunes/Lance\'s iTunes'
target_library = '/storage/media/music'

for pathname in glob.iglob(itunes_library + '/Music/**/*', recursive=True):

    if path.isfile(pathname):
        symlink = target_library + '/' + path.relpath(pathname, itunes_library + '/Music')
        symlink_directory = path.dirname(symlink)

        if not path.exists(symlink_directory):
            os.makedirs(symlink_directory)

        if not path.exists(symlink):
            os.symlink(path.relpath(pathname, path.dirname(symlink)), symlink)


