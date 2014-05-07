#!/bin/bash

BASEDIR=$(dirname $0)
CONFIG_FILE=${0//sh/conf}

COOKIE=$BASEDIR/cookie_$$.txt
CURL_OPTS="-s -k -L -o /dev/null"

trap "rm $COOKIE; exit" 2

if [ -f $CONFIG_FILE ]; then
  . $CONFIG_FILE
else
  echo "config file: $CONFIG_FILE not found!"
  exit
fi

echo -n "/login, "
{ time -p curl $CURL_OPTS -c $COOKIE -d "userId=$USERID" -d "password=$PASSWORD" https://$HOST/login ; } 2>&1 | awk '/real/ {print $2}'

while :
do
  NUM=$(($RANDOM % ${#URL[*]}))
  echo -n "${URL[$NUM]}, "

  { time -p curl $CURL_OPTS -b $COOKIE https://$HOST${URL[$NUM]} ; } 2>&1 | awk '/real/ {print $2}'
done
