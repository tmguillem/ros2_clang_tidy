#!/bin/bash

set -e
env

project_name=$(basename `git rev-parse --show-toplevel`)


mkdir -p $GITHUB_WORKSPACE/ws/src/$project_name
cd $GITHUB_WORKSPACE

# Move all files inside ws/src
rsync -aq --remove-source-files . ws/src/$project_name --exclude ws

cd ws

# Set GUI_FLAG to False to be able to run the simulator in the container. TODO: pass this as an argument?
sed -i 's/GUI_FLAG = True/GUI_FLAG = False/' src/$project_name/simulator/bullet_simulation/bullet_simulation/full_simulator.py

# Compile and source workspace packages
source "/opt/ros/$ROS_DISTRO/setup.bash"
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cd src/$project_name
git status