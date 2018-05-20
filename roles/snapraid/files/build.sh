#!/bin/bash

docker_image_tag="snapraid-from-source"
build_path="/tmp/snapraid-build/"

cd $build_path
docker build -t $docker_image_tag .

id=$(docker create --name snapraid-tmp $docker_image_tag)
docker cp $id:/artifact/ .

docker rm -v $id
docker rmi $docker_image_tag

