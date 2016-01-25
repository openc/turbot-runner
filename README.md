# turbot-runner

## Getting started

    git submodule update --init
    cd schema && git checkout master && cd ..

## Updating the schema

    cd schema && git pull --rebase && cd ..
    git commit schema -m 'Pull in new schema'

## Releasing a new version

Bump the version in `lib/turbot_runner/version.rb`, then:

    git commit lib/turbot_runner/version.rb -m 'Release new version'
    rake release # requires Rubygems credentials