#!/bin/bash

set -e
env

project_name=$(basename "git rev-parse --show-toplevel")


mkdir -p "$GITHUB_WORKSPACE"/ws/src/"$project_name"
cd "$GITHUB_WORKSPACE"

# Move all files inside ws/src
rsync -aq --remove-source-files . ws/src/"$project_name" --exclude ws

cd ws

# Compile and source workspace packages
source "/opt/ros/$ROS_DISTRO/setup.bash"
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DBUILD_TESTING=OFF

cd src/"$project_name"
mv /run-clang-tidy.py .

# Read list of ignored directories
ignored_paths=()
readarray -t ignored_paths < ws/src/project_ace/.clang-tidy-ignore
echo "These directories will be ignored:"
for path in "${ignored_paths[@]}"; do echo "$path"; done

all_passed=true

echo "Running script"
time python3 run-clang-tidy.py -p ../../build \
                               -directory "$GITHUB_WORKSPACE"/ws/src/"$project_name" \
                               -ignored_paths "${ignored_paths[@]}" \
                               -clang-tidy-binary clang-tidy-12 \
                               -clang-apply-replacements-binary clang-apply-replacements-12

retval=$?
if [ $retval -ne 0 ]; then
    all_passed=false
fi

if [ "$all_passed" = false ]; then
    echo "Fixes in files required. Exiting"
    exit 1
else
    echo "Clang-tidy did not detect any problem"
    git diff --exit-code
fi