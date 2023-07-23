#!/bin/bash

read -p "This will check your internet connection by pinging Google's DNS servers. Proceed? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
  echo "Internet connection is up"
else
  echo "Internet connection is down"
fi
