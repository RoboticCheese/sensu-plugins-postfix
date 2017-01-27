#!/usr/bin/env bash

shared_setup() {
  echo "which Ruby?" >> /tmp/break
  which -a ruby >> /tmp/break
  unset GEM_HOME
  unset GEM_PATH
  # echo "Sourcing rvm.sh, `date`" >> /tmp/break
  # [ -e /etc/profile.d/rvm.sh ] && source /etc/profile.d/rvm.sh
  # echo "Done sourcing rvm.sh, `date`" >> /tmp/break
  export RUBY_HOME=${MY_RUBY_HOME:-/opt/sensu/embedded}
  INNER_GEM_HOME=$($RUBY_HOME/bin/ruby -e 'print ENV["GEM_HOME"]')
  [ -n "$INNER_GEM_HOME" ] && export GEM_BIN=$INNER_GEM_HOME/bin || export GEM_BIN=$RUBY_HOME/bin

  # echo "=====" >> /tmp/break
  echo "ENV inside test_helper:" >> /tmp/break
  $RUBY_HOME/bin/ruby -e 'ENV.to_h.each { |k, v| puts "ENV #{k} => #{v}" }' >> /tmp/break

  echo "Finished setup, `date`" >> /tmp/break
}
