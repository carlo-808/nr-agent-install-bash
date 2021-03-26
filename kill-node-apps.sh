#!/bin/bash

for x in $(sudo ps aux | grep "node\s." | awk '{print $2}')
do
	app_loc=$(lsof -p "$x" | awk '{print $NF}' | head -n 2 | tail -1)

  kill "$x"

	cd "$app_loc"

	rm newrelic_agent.log

	npm uninstall newrelic

done