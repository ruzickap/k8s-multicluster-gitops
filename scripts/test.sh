#!/usr/bin/env bash

: "${my_local_secret:?Error: my_local_secret environment variable is not set!}"
: "${my_global_secret:?Error: my_global_secret environment variable is not set!}"

kind --version
echo "${my_local_secret}"
echo "${my_global_secret}"
