#!/usr/bin/env bats

setup() {
  echo "Starting check-mail-delay setup at `date`" >> /tmp/break
  export OLD_RUBY_HOME=$RUBY_HOME
  export OLD_GEM_HOME=$GEM_HOME
  export OLD_GEM_PATH=$GEM_PATH
  echo "Unsetting old variables, `date`" >> /tmp/break
  unset GEM_HOME
  unset GEM_PATH
  echo "Sourcing /etc/profile, `date`" >> /tmp/break
  time source /etc/profile >> /tmp/break 2>&1
  export PATH="$PATH:/home/travis/.rvm/bin"
  source /home/travis/.rvm/scripts/rvm
  export RUBY_HOME=${MY_RUBY_HOME:-/opt/sensu/embedded}
  echo "Shelling out to Ruby, `date`" >> /tmp/break
  INNER_GEM_HOME=$($RUBY_HOME/bin/ruby -e 'print ENV["GEM_HOME"]')
  echo "Setting new environment variables, `date`" >> /tmp/break
  [ -n "$INNER_GEM_HOME" ] && GEM_BIN=$INNER_GEM_HOME/bin || GEM_BIN=$RUBY_HOME/bin
  export CHECK="$RUBY_HOME/bin/ruby $GEM_BIN/check-mail-delay.rb"

  echo "Completed check-mail-delay setup at `date`" >> /tmp/break
}

teardown() {
  echo "Starting check-mail-delay teardown at `date`" >> /tmp/break
  clear_queue
  unset_connect_timeout
  postfix reload

  export RUBY_HOME=$OLD_RUBY_HOME
  export GEM_HOME=$OLD_GEM_HOME
  export GEM_PATH=$OLD_GEM_PATH
  echo "Completed check-mail-delay teardown at `date`" >> /tmp/break
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
  echo "Start Check default (all) queue, ok, `date`" >> /tmp/break
  populate_hold_queue 2
  populate_queue 3
  run $CHECK -w 10 -c 20
  [ $status = 0 ]
  [ "$output" = "PostfixMailDelay OK: 0 messages in the postfix mail queue older than 3600 seconds" ]
  echo "Complete Check default (all) queue, ok, `date`" >> /tmp/break
}

@test "Check default (all) queue, warning" {
  echo "Start Check default (all) queue, warning, `date`" >> /tmp/break
  populate_hold_queue 3
  populate_queue 2
  sleep 2
  run $CHECK -d 1 -w 4 -c 20
  [ $status = 1 ]
  [ "$output" = "PostfixMailDelay WARNING: 5 messages in the postfix mail queue older than 1 seconds" ]
  echo "Complete Check default (all) queue, warning, `date`" >> /tmp/break
}

@test "Check default (all) queue, critical" {
  echo "Start Check default (all) queue, critical, `date`" >> /tmp/break
  populate_hold_queue 1
  populate_queue 4
  sleep 2
  run $CHECK -d 1 -w 4 -c 5
  [ $status = 2 ]
  [ "$output" = "PostfixMailDelay CRITICAL: 5 messages in the postfix mail queue older than 1 seconds" ]
  echo "Complete Check default (all) queue, critical, `date`" >> /tmp/break
}
