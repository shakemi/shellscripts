#!/bin/bash

BASEDIR=$(dirname $0)
CONFIG_FILE=${0//.sh/.conf}
PID_FILE=${0//.sh/.pid}

JOBS=1

COOKIE=$BASEDIR/cookie_$$.txt
HEADER_DUMP=$BASEDIR/header_$$.dump
CURL_OPTS="-s -k"

clear_files() {
  if [ $JOBS -gt 1 ]; then
    for PID in `cat $PID_FILE`
    do
      kill $PID
    done
  fi

  for FILE in $COOKIE $HEADER_DUMP $PID_FILE
  do
    if [ -f $FILE ]; then
      rm $FILE
    fi
  done
  echo "===== pid: $$ end ====="
  exit
}

get_token() {
  TOKEN=`curl $CURL_OPTS -c $COOKIE https://$HOST$LOGIN | \
    grep 'input name="authenticity_token"' | \
    sed 's/.* value="\(.*\)" .*/\1/g'`
}

login() {
  echo "===== pid $$ login ====="

  get_token

  curl $CURL_OPTS -b $COOKIE -c $COOKIE -o /dev/null \
    -d "utf8=%E2%9C%93" \
    -d "authenticity_token=$TOKEN" \
    -d "user%5Bpersonal_number%5D=$USERID" \
    -d "user%5Bpassword%5D=$PASSWORD" \
    -d "commit=%E3%83%AD%E3%82%B0%E3%82%A4%E3%83%B3" https://$HOST$LOGIN
}

trap clear_files SIGINT SIGTERM

if [ -f $CONFIG_FILE ]; then
  . $CONFIG_FILE
else
  echo "config file: $CONFIG_FILE not found!"
  exit
fi

while getopts j: OPT
do
  case $OPT in
    j) JOBS=$OPTARG
      ;;
  esac
done

if [ $JOBS -gt 1 ]; then
  for i in $(seq 1 $JOBS)
  do
    $0 &
  done
  wait
else
  echo $$ >> $PID_FILE

  login

  while :
  do
    NUM=$(($RANDOM % ${#URL[*]}))
    TIME=`{ time -p \
      curl $CURL_OPTS -D $HEADER_DUMP -b $COOKIE -o /dev/null \
      https://$HOST${URL[$NUM]}; } 2>&1 | awk '/real/ {print $2}'`
    RET="${URL[$NUM]}, $TIME"

    if [ `awk '/Status:/ {print $2}' $HEADER_DUMP | \
        tr -d '\r|\n'` == "302" ]; then
      login
    else
      echo $RET
    fi
  done
fi
