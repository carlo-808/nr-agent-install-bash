#!/bin/bash

# exit on first failure
set -e

# prob don't need
start_dir=`pwd`

NODE_VERSION=$(node -v)

NPM_VERSION=$(npm -v)

echo $NODE_VERSION
echo $NPM_VERSION

# exit 111

# get the process id of something like node server.js
processid=$(ps -aef | grep "node\s." | awk '{print $2}')

# get the actual args to run node ie node server.js
# look into grabbing both off of first thing
NODE_CMD=$(ps -p "$processid" -o args | grep node)

# get node location (do we need to check for lsof?)
NODE_APP_LOC=$(lsof -p "$processid" | awk '{print $NF}' | head -n 2 | tail -1)

kill "$processid"

cd "${NODE_APP_LOC}"

NODE_APP_NAME=$(node -p "require('./package.json').name")

echo $NODE_APP_NAME

npm install newrelic

NODE_NEW_RELIC_CMD="node -r newrelic "

NODE_CMD="${NODE_CMD//node /$NODE_NEW_RELIC_CMD}"

export NEW_RELIC_APP_NAME=$NODE_APP_NAME

echo "Executing cmd: $NODE_CMD"

$($NODE_CMD)
