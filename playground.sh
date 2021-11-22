#!/usr/bin/env bash

source logr.sh

echo "PROCESS $$ ($BASHPID) started: $# -> $*"

foo() {
  echo "foo: called"
  sleep 2
  echo "foo: calling bar"
  bar
  echo "foo: bar completed"
  sleep 2
  echo "foo: calling baz"
  baz
  echo "foo: baz completed"
  sleep 2
  echo "foo: terminating"
}

bar() {
  echo "bar: called"
  logr task -- eval "sleep 2; return 42"
  echo "bar: bar completed"
  logr task -- sleep 2
  echo "bar: terminating"
}

baz() {
  echo "baz: called"
  sleep 2
  echo "baz: baz completed"
  sleep 2
  echo "baz: terminating"
}

if [ "$#" -eq 0 ]; then
  declare -A pids=()
  declare max=2 pid
  for ((i = 0; i < max; i++)); do
    echo "PROCESS $$ ($BASHPID): Starting sub-process"
    "$0" "parent: $$" &
    pid=$!
    echo "PROCESS $$ ($BASHPID): Started sub-process $pid"
    pids[$pid]=''
    echo "CURRENTLY RUNNING SUB-PROCESSES: ${!pids[*]}"
    sleep 0.5
  done
  echo "PROCESS $$ ($BASHPID): WAITING FOR ${!pids[*]}"
  all_set() {
    while (($#)); do
      [ "${1-}" ] || return 1
      shift
    done
  }
  while ! all_set "${pids[@]}"; do
    declare result=''
    if wait -n -p process; then
      result=$?
      echo "$process succeeded with $result"
    else
      result=$?
      echo "$process failed with $result"
    fi
    pids[$process]=$result
    echo "RESULTS ${pids[*]}"
  done
else
  foo
fi
