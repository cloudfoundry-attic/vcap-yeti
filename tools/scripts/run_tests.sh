#!/bin/bash

only_run_tests ()
{
  echo -e "http://api.cf54.dev.las01.vcsops.com" | bundle exec rake tests
}

create_users_and_run_tests ()
{
  echo -e "http://api.cf54.dev.las01.vcsops.com\nzhangcheng@rbcon.com\nzhangcheng" | bundle exec rake tests
}

file="~/.bvt/config.yml"
eval file="$file"

if [ -e "$file" ]
then
  only_run_tests
else
	create_users_and_run_tests
fi