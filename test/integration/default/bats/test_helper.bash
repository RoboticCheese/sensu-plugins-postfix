#!/usr/bin/env bash

shared_setup() {
  if [ -z "$READY" ]; then
    unset GEM_HOME
    unset GEM_PATH
    echo "Sourcing rvm.sh, `date`" >> /tmp/break
    [ -e /etc/profile.d/rvm.sh ] && source /etc/profile.d/rvm.sh
    echo "Done sourcing rvm.sh, `date`" >> /tmp/break

    export RUBY_HOME=${MY_RUBY_HOME:-/opt/sensu/embedded}

    INNER_GEM_HOME=$($RUBY_HOME/bin/ruby -e 'print ENV["GEM_HOME"]')
    [ -n "$INNER_GEM_HOME" ] && GEM_BIN=$INNER_GEM_HOME/bin || GEM_BIN=$RUBY_HOME/bin

    echo "Finished setup, `date`" >> /tmp/break
    export READY=true
  fi
}
