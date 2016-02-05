# turbot-runner

## Getting started

    git submodule update --init
    cd schema && git checkout master && cd ..

## Updating the schema

    cd schema && git pull --rebase && cd ..
    git commit schema -m 'Pull in new schema'

## Releasing a new version

Bump the version in `lib/turbot_runner/version.rb` according to the [Semantic Versioning](http://semver.org/) convention, then:

    git commit lib/turbot_runner/version.rb -m 'Release new version'
    rake release # requires Rubygems credentials

Finally, [rebuild the Docker image](https://github.com/openc/morph-docker-ruby#readme).

## Rough outline of how it works

TurbotRunner is responsible for running a scraper, transforming its data, and
then validating and processing any output.

Work is coordinated by an instance of `Runner`.  Most of the interesting work
is done in `Runner#run_script`, which constructs a command like:

    python transformer.py >transformer.out 2>transformer.err <scraper.out

This command is then passed to an instance of `ScriptRunner` which runs the
command via `system` in a new thread.  The main thread then monitors the output
file, and processes each complete line of output.

A line is processed by an instance of `Processor`, which checks that the line
is valid JSON, and then passes it on to the instance of a subclass of
`BaseHandler` that was passed to the `Runner` when it was created.

The subclass of `BaseHandler` can implement any of the following methods:

 * `handle_valid_record`
 * `handle_invalid_record`
 * `handle_invalid_json`
 * `handle_snapshot_ended`

If the `Processor` finds an invalid record, it interrupts the `ScriptRunner`,
and marks the run as having failed.

The `Processor` will catch an `InterruptRun` that's raised by
`handler.handle_valid_record`, which will interrupt the `ScriptRunner`, but
will not mark the run as having failed.

When the `ScriptRunner` is interrupted, it will kill the running process, by
sending SIGINT to all the processes in the current process group.  The current
process is set up (via `trap('INT') {}` to ignore this.

If the `ScriptRunner` reads no output from the command within a timeout (by
default, 24 hours) it interrupts itself, and marks the run as having failed.

## Running the tests

Tests are run with rspec:

`./bin/rspec`

The first two specs to run require some manual input.
