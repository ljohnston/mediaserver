#!/usr/bin/env python3

#
# Our test data will look like this:
#
#   manifest.vaultx
#   Items/
#     00/
#       container1.containerx
#       pic01(rev 0).jpg
#       pic01(rev 1).jpg  <-- this will be the "Act"ive revision.
#       pic02(rev 0).jpg
#     01/
#       container2.containerx
#       movie01.mpg
#       pic03(rev 0).jpg
#       pic04(rev 0).jpg  <-- this will not appear in manifest.vaultx
#       pic05(rev 0).jpg
#
# Items/00/container1.containerx will look like this:
#
#   <Container Name="Mom's Birthday" Category="Events/Birthdays/Mom">
#     <Item Id="pic01" />
#     <Item Id="pic05" />
#   </Container>
#
# Items/01/container2.containerx will look like this:
#
#   <Container Name="Dad's Birthday" Category="Events/Birthdays/Dad">
#     <Item Id="pic02" />
#     <Item Id="movie01" />
#   </Container>
#
# manifest.vaultx will look like this:
#
#   <Manifest>
#     <Items>
#       <Image ID="pic01" OrgDate="G2020-01-01-17-51-46-000">
#         <Rev Act="False" Fil="pic01(rev 0).jpg"/>
#         <Rev Act="True" Fil="pic01(rev 1).jpg"/>
#       </Image>
#       <Image ID="pic02" OrgDate="G2020-02-02-17-51-46-000">
#         <Rev Act="True" Fil="pic02(rev 0).jpg"/>
#       </Image>
#       <Image ID="pic03" OrgDate="G2021-02-02-17-51-46-000">
#         <Rev Act="True" Fil="pic03(rev 0).jpg"/>
#       </Image>
#       <Image ID="pic05" OrgDate="G2022-03-03-17-51-46-000">
#         <Rev Act="True" Fil="pic05(rev 0).jpg"/>
#       </Image>
#       <Video ID="movie01" OrgDate="G2020-02-02-17-51-46-000" Fil="movie01.mpg">
#       </Video>
#     </Items>
#   </Manifest>
#
# This should result in the following in the destination (all files are
# symbolic links):
#
# 2020/
#   01/
#     pic01(rev 1).jpg
#   02/
#     pic02(rev 0).jpg
#     movie01.mpg
# 2021/
#   02/
#     pic03(rev 0).jpg
# 2022/
#   03/
#     pic05(rev 0).jpg
#

items = {'images': [
            {'Id': 'pic01',
             'OrgDate': 'G2020-01-01-17-51-46-000',
             'Revs': [{'Act': 'False', 'Fil': 'pic01(rev 0).jpg'},
                      {'Act': 'True', 'Fil': 'pic01(rev 1).jpg'}]},
            {'Id': 'pic02',
             'OrgDate': 'G2020-02-02-17-51-46-000',
             'Revs': [{'Act': 'True', 'Fil': 'pic02(rev 0).jpg'}]},
            {'Id': 'pic03',
             'OrgDate': 'G2020-02-02-17-51-46-000',
             'Revs': [{'Act': 'True', 'Fil': 'pic03(rev 0).jpg'}]},
            {'Id': 'pic05',
             'OrgDate': 'G2022-03-03-17-51-46-000',
             'Revs': [{'Act': 'True', 'Fil': 'pic05(rev 0).jpg'}]}],
         'movies': [
            {'Id': 'movie1', 'OrgDate': 'G2020-02-02-17-51-46-000', 'Fil': 'movie1.mpg'}]
}

import glob
import os
import shutil
import subprocess
import subprocess
import sys
import tempfile
import unittest

import xml.etree.ElementTree as ET

#
# To facilitate test/script development, pass the path to script location (i.e.
# the location of the script this test will be calling for tests) as an
# argument on command line. For example:
#
#   $ /test/test_historian_sync.py /vagrant/roles/mediaserver/files/
#
script_path = ''

# ElementTree in Python 3.9 has an indent method.
# Maybe at some point we can get rid of this.
def indent(elem, level=0):
    indent_size = "  "
    i = "\n" + level * indent_size
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + indent_size
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level + 1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i


class Container:
    def __init__(self, filename, name, category, items):
        self.filename = filename
        self.name = name
        self.category = category
        self.items = items

    def get_content(self):
        container = ET.Element('Container')
        container.set('Name', self.name)
        container.set('Category', self.category)

        for item in self.items:
            container_item = ET.SubElement(container, 'Item')
            container_item.set('Id', item)

        indent(container)
        return ET.tostring(container)


class TestHistorianSync(unittest.TestCase):


    def setUp(self):
        self.test_dir = tempfile.mkdtemp()

        self.vault_dir = os.path.join(self.test_dir, 'historian', 'Johnston Soup (Shadow copy)')
        self.photos_dir = os.path.join(self.test_dir, 'photos')

        print(f'vault_dir: {self.vault_dir}')
        print(f'photos_dir: {self.photos_dir}')

        os.makedirs(self.vault_dir)
        os.makedirs(self.photos_dir)


    # def tearDown(self):
    #     shutil.rmtree(self.test_dir)


    def create_manifest(self):
        manifest = ET.Element('Manifest')
        items = ET.SubElement(manifest, 'Items')

        image1 = ET.SubElement(items, 'Image')
        image1.set('ID', 'pic01')
        image1.set('OrgDate', 'G2020-01-01-17-51-46-000')
        image1_rev1 = ET.SubElement(image1, 'Rev')
        image1_rev1.set('Act', 'False')
        image1_rev1.set('Fil', 'pic01(rev 0).jpg')
        image1_rev2 = ET.SubElement(image1, 'Rev')
        image1_rev2.set('Act', 'True')
        image1_rev2.set('Fil', 'pic01(rev 1).jpg')

        image2 = ET.SubElement(items, 'Image')
        image2.set('ID', 'pic02')
        image2.set('OrgDate', 'G2020-02-02-17-51-46-000')
        image2_rev1 = ET.SubElement(image2, 'Rev')
        image2_rev1.set('Act', 'True')
        image2_rev1.set('Fil', 'pic02(rev 0).jpg')

        image3 = ET.SubElement(items, 'Image')
        image3.set('ID', 'pic03')
        image3.set('OrgDate', 'G2021-02-02-17-51-46-000')
        image3_rev1 = ET.SubElement(image3, 'Rev')
        image3_rev1.set('Act', 'True')
        image3_rev1.set('Fil', 'pic03(rev 0).jpg')

        image4 = ET.SubElement(items, 'Image')
        image4.set('ID', 'pic05')
        image4.set('OrgDate', 'G2022-03-03-17-51-46-000')
        image4_rev1 = ET.SubElement(image4, 'Rev')
        image4_rev1.set('Act', 'True')
        image4_rev1.set('Fil', 'pic05(rev 0).jpg')

        video1 = ET.SubElement(items, 'Video')
        video1.set('ID', 'movie01')
        video1.set('OrgDate', 'G2020-02-02-17-51-46-000')
        video1.set('Fil', 'movie01.mpg')

        indent(manifest)

        with open(os.path.join(self.vault_dir, 'manifest.vaultx'), 'wb') as f:
            f.write(ET.tostring(manifest))


    def create_items(self):
        container1 = Container(
                'container1.containerx',
                "Mom's Birthday",
                'Events/Birthdays/Mom',
                ['pic01','pic05'])
        container2 = Container(
                'container2.containerx',
                "Dad's Birthday",
                'Events/Birthdays/Dad',
                ['pic02','movie01'])

        files = {
            'Items': {
                '00': [
                    container1,
                    'pic01(rev 0).jpg',
                    'pic01(rev 1).jpg',
                    'pic02(rev 0).jpg'
                ],
                '01': [
                    container2,
                    'movie01.mpg',
                    'pic03(rev 0).jpg',
                    'pic04(rev 1).jpg',
                    'pic05(rev 0).jpg'
                ]
            }
        }

        for key, val in files.items():
            if isinstance(val, dict):
                for inner_key, inner_val in val.items():
                    path = os.path.join(self.vault_dir, key, inner_key)
                    os.makedirs(path, exist_ok=True)

                    for entry in inner_val:
                        if isinstance(entry, Container):
                            with open(os.path.join(path, entry.filename), 'wb') as f:
                                f.write(entry.get_content())
                        else:
                            with open(os.path.join(path, entry), 'w') as f:
                                f.write(entry)


    def create_test_data(self):
        self.create_manifest()
        self.create_items()


    def test_historian_sync(self):
        self.create_test_data()

        args = [os.path.join(script_path, 'historian_sync'),
                '-s', self.vault_dir,
                '-d', self.photos_dir]
        response = subprocess.run(args, shell=False)

        synced_files = [
                f for f in glob.glob(os.path.join(self.photos_dir, '**/*'), recursive=True) \
                if not os.path.isdir(f)]
        synced_dirs = [
                f for f in glob.glob(os.path.join(self.photos_dir, '**/*'), recursive=True) \
                if os.path.isdir(f)]

        self.assertEqual(len(synced_files), 5)
        self.assertEqual(len(synced_dirs), 7)
        self.assertEqual(response.returncode, 0)


if __name__ == '__main__':
    if len(sys.argv) == 2:
        script_path = sys.argv.pop()
    unittest.main()


