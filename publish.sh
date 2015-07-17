#!/bin/bash

branch=$(git rev-parse --abbrev-ref HEAD)

if [[ $branch != "master" ]]; then
	echo "Must be run from master!"
	exit 1
fi

gem build turbot-runner.gemspec
gem push $(ls *gem|tail -1)

function clean {
 rm *gem
}
trap clean EXIT
