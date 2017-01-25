#!/usr/bin/env bash

shared_setup() {
  if [ -z "$READY" ]; then
    unset GEM_HOME
    unset GEM_PATH
    [ -e /etc/profile.d/rvm.sh ] && source /etc/profile.d/rvm.sh

    export RUBY_HOME=${MY_RUBY_HOME:-/opt/sensu/embedded}

    INNER_GEM_HOME=$($RUBY_HOME/bin/ruby -e 'print ENV["GEM_HOME"]')
    [ -n "$INNER_GEM_HOME" ] && GEM_BIN=$INNER_GEM_HOME/bin || GEM_BIN=$RUBY_HOME/bin

    echo "Finished setup, `date`" >> /tmp/break
    export READY=true
  fi
}
