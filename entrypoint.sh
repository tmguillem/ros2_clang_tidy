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

# To fix or not to fix
if [ "$INPUT_FIX" = true ]; then
    echo "Errors will be fixed whenever possible"
    fix="-fix"
else
    echo "Errors will not be fixed"
    fix=""
fi
echo "fix: $fix"

# Get list of all cpp files to analize
if [ "$INPUT_FILES" = 'all' ]; then
    for file in $(find . \( ! -path "*.github*" -a ! -path "*.git*" -a ! -path "*build*" \) -regex '.*\(cpp\)$')
    do 
        echo "Analyzing $file"
        clang-tidy -p ../../build $fix $file
    done
else
    for file in $INPUT_FILES
    do
        echo "Analyzing $file"
        clang-tidy -p ../../build $fix $file
    done
fi


if [[ `git status --porcelain --untracked-files=no` ]]; then
    echo "Fixes in files required. Exiting"
    exit 1
else
    echo "Clang-tidy did not detect any problem"
fi