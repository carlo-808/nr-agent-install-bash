#!/bin/bash

# exit on first failure
set -e

maxNodeVersion=14
minNodeVersion=10

error_msg="Quitting Nodejs agent installation."

NODE_NEW_RELIC_CMD="node -r newrelic "

check_yarn=0

# check for node
type -P node || { echo "Nodejs not found. $error_msg" ; exit 1; }

# check for npm
type -P npm || { echo "npm not found. Checking for yarn."; check_yarn=1; }

# check for yarn
if [ $check_yarn -eq 1 ]; then
  type -P yarn || { echo "yarn not found. $error_msg"; exit 1; }
fi


NODE_VERSION=$(node -v)

# get node major version
[[ $NODE_VERSION =~ ^v([0-9]+)\.[0-9]+\.[0-9]+ ]] && major_version=${BASH_REMATCH[1]}

if [[ "$major_version" -lt $minNodeVersion || "$major_version" -gt $maxNodeVersion ]]; then
  echo "$NODE_VERSION is not supported by the New Relic Nodejs Agent."
  echo "$error_msg"

  exit 1
fi

# initialize pid array
pid_array=()

# get all node pids
for x in $(sudo ps aux | grep "node\s." | awk '{print $2}')
do
  pid_array+=($x)
done

# attempt to instrument each application
for t in ${pid_array[@]}
do
  # get the command used to start the nodejs application
  orig_cmd=$(ps -p "$t" -o args | grep node)

  # get the location of the application
  app_loc=$(lsof -p "$t" | awk '{print $NF}' | head -n 2 | tail -1)

  # go to directory
  cd "${app_loc}"

  # extract application name from package.json
  app_name=$(node -p "require('./package.json').name")

  if [ -z $app_name ]; then
    echo "No name found in package.json at ${app_loc}. Skipping instrumentation."
    continue
  fi

  # stop the application
  kill "$t"

  echo "Installing New Relic Nodejs Agent for $app_name"

  # install the agent
  if [ $check_yarn -eq 1 ]; then
    yarn add newrelic
  else
    npm install newrelic
  fi

  # create new start command which loads agent
  new_cmd="${orig_cmd//node /$NODE_NEW_RELIC_CMD}"

  export NEW_RELIC_APP_NAME=$app_name

  echo "Starting application. Executing: $new_cmd"

  $($new_cmd) &

done

exit 0
