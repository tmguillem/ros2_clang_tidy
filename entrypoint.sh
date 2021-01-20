#!/bin/bash

set -e
env

project_name=$(basename `git rev-parse --show-toplevel`)


mkdir -p $GITHUB_WORKSPACE/ws/src/$project_name
cd $GITHUB_WORKSPACE

# Move all files inside ws/src
rsync -aq --remove-source-files . ws/src/$project_name --exclude ws

cd ws

# Compile and source workspace packages
source "/opt/ros/$ROS_DISTRO/setup.bash"
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DBUILD_TESTING=OFF

cd src/$project_name

# Get list of all cpp files to analize
for file in $(find . \( ! -path "*.github*" -a ! -path "*.git*" -a ! -path "*build*" \) -regex '.*\(cpp\)$')
do 
	echo $file
	clang-tidy -p ../../build -fix $file
done

if [[ `git status --porcelain --untracked-files=no` ]]; then
    echo "Fixes in files required. Exiting"
    exit 1
else
    echo "Clang-tidy did not detect any problem"
fi