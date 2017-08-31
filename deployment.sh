#!/usr/bin/env bash
BRANCH=staging
CUR_DIR=$( pwd )

## backup local.xml file
if [ -f ${CUR_DIR}/data/www/app/etc/local.xml ];then
  cp ${CUR_DIR}/data/www/app/etc/local.xml ${CUR_DIR}/data/local.xml.backup
fi

## clear data/www/
echo "cleaning data/www/*"
rm -rf data/www
mkdir -p data/www
echo "Pull source code from git source, enter github username & password:"
if [ ! -d "data/.www/.git" ]; then
  echo "Cloning source from branch ${BRANCH}:"
  rm -rf data/.www
  git clone -b ${BRANCH} https://github.com/Magestore/Magestore-1.9.3.2.git data/.www
  check_branch=$( cd ${CUR_DIR}/data/.www && git branch -r | grep ${BRANCH} | wc -l )
  if [ ${check_branch} -lt 1 ]; then
    echo "No branch choose ${BRANCH}"
    exit 0
  fi
else
  echo "Load source from branch ${BRANCH}"
  cd ${CUR_DIR}/data/.www && git reset --hard HEAD
  cd ${CUR_DIR}/data/.www && git fetch
  check_branch=$( cd ${CUR_DIR}/data/.www && git branch -r | grep ${BRANCH} | wc -l )
  if [ ${check_branch} -lt 1 ]; then
    echo "No branch choose ${BRANCH}"
    exit 0
  fi
  cd ${CUR_DIR}/data/.www && git checkout ${BRANCH}
  cd ${CUR_DIR}/data/.www && git pull
fi

cd $CUR_DIR
echo "copy source to www:"
cp -Rf ${CUR_DIR}/data/.www/* ${CUR_DIR}/data/www/
cp -f ${CUR_DIR}/data/.www/.htaccess ${CUR_DIR}/data/www/
rm -rf data/www/.git # remove git info

## restore local.xml file
if [ -f ${CUR_DIR}/data/local.xml.backup ];then
  echo "Restore local.xml file"
  mv ${CUR_DIR}/data/local.xml.backup ${CUR_DIR}/data/www/app/etc/local.xml
fi

echo "chown data/www:"
chown -R www-data:www-data data/www

echo "create media dir:"
mkdir -p data/www/media
chown -R www-data:www-data data/www/media

echo "clear var/"
rm -rf data/www/var/*

## get varnish container ID and IP
container_id_varnish=$( docker ps -q --filter=ancestor=thinlt/varnish:5.1 ) # get container id
container_ip_varnish=$( docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${container_id_varnish} )

## add require ip to secure/.htaccess
if [ ! -z ${container_ip_varnish} ]; then
sed "0,/Require ip/s//Require ip ${container_ip_varnish}\n&/ " data/www/secure/.htaccess > /tmp/secure_htaccess \
  && cat /tmp/secure_htaccess > data/www/secure/.htaccess
fi
