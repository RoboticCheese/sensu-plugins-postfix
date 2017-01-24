#!/usr/bin/env bats

setup() {
  echo "Starting check-mailq setup at `data`" >> /tmp/break
  export OLD_RUBY_HOME=$RUBY_HOME
  export OLD_GEM_HOME=$GEM_HOME
  export OLD_GEM_PATH=$GEM_PATH

  unset GEM_HOME
  unset GEM_PATH
  source /etc/profile
  export RUBY_HOME=${MY_RUBY_HOME:-/opt/sensu/embedded}

  INNER_GEM_HOME=$($RUBY_HOME/bin/ruby -e 'print ENV["GEM_HOME"]')
  [ -n "$INNER_GEM_HOME" ] && GEM_BIN=$INNER_GEM_HOME/bin || GEM_BIN=$RUBY_HOME/bin
  export CHECK="$RUBY_HOME/bin/ruby $GEM_BIN/check-mailq.rb"
  echo "Completed check-mailq setup at `date`" >> /tmp/break

}

teardown() {
  echo "Starting check-mailq teardown at `data`" >> /tmp/break

  clear_queue
  unset_connect_timeout
  postfix reload

  export RUBY_HOME=$OLD_RUBY_HOME
  export GEM_HOME=$OLD_GEM_HOME
  export GEM_PATH=$OLD_GEM_PATH
  echo "Completed check-mailq teardown at `date`" >> /tmp/break

}

clear_queue() {
  postsuper -d ALL
}

set_connect_timeout() {
  echo "smtp_connect_timeout = $1" >> /etc/postfix/main.cf
  postfix reload
}

unset_connect_timeout() {
  sed -i '/^smtp_connect_timeout/d' /etc/postfix/main.cf
  postfix reload
}

populate_queue() {
  for n in `seq 1 $1`; do
    echo pants | mail user$n@example.com
  done
}

populate_hold_queue() {
  populate_queue $1
  postsuper -h ALL
}

populate_deferred_queue() {
  set_connect_timeout 1
  populate_queue $1
  sleep 4
  unset_connect_timeout
}

@test "Check default (all) queue, ok" {
  populate_hold_queue 2
  populate_queue 3
  run $CHECK -w 10 -c 20
  [ $status = 0 ]
  [ "$output" = "PostfixMailq OK: 5 messages in the postfix mail queue" ]
}

@test "Check default (all) queue, warning" {
  populate_hold_queue 3
  populate_queue 2
  run $CHECK -w 4 -c 20
  [ $status = 1 ]
  [ "$output" = "PostfixMailq WARNING: 5 messages in the postfix mail queue" ]
}

@test "Check default (all) queue, critical" {
  populate_hold_queue 1
  populate_queue 4
  run $CHECK -w 4 -c 5
  [ $status = 2 ]
  [ "$output" = "PostfixMailq CRITICAL: 5 messages in the postfix mail queue" ]
}
