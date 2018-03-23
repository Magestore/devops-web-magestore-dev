#!/bin/bash

## add to crontab
## * * * * * root /bin/bash /absolute_path_to/script/auto_pull.sh staging 2>&1  >/dev/null &

branch=${1:-master} #default branch is master

cd data/www

git checkout $branch

git pull

echo "Pull successfuly"
