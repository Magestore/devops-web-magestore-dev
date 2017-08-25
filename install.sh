#!/bin/bash

## Define vars
### Clone from Cloud SQL Database
EXPORT_DB_HOST='35.202.178.130'
EXPORT_DB_NAME='magestore_db_clone'
EXPORT_USER='root'
EXPORT_PASS='Buu0JDFL0Hxa6nI0'

CUR_DIR=$( pwd )

## read cloud sql root password
echo "Clone database from host(${EXPORT_DB_HOST}):"
read DB_HOST
echo "Clone database from db_name(${EXPORT_DB_NAME}):"
read DB_NAME
echo "Clone database from user(${EXPORT_USER}):"
read USER
echo "Clone database from pass:"
read PASS

EXPORT_DB_HOST=${DB_HOST:-$EXPORT_DB_HOST}
EXPORT_DB_NAME=${DB_NAME:-$EXPORT_DB_NAME}
EXPORT_USER=${USER:-$EXPORT_USER}
EXPORT_PASS=${PASS:-$EXPORT_PASS}

## Mysql client user/password
cat <<EOF > mysql_pass.cnf
[client]
host     = ${EXPORT_DB_HOST}
user     = ${EXPORT_USER}
password = ${EXPORT_PASS}
EOF

## read new domain to install
echo "Enter new domain to install (https://..):"
read DOMAIN

## Install
echo "Installing"

echo "Pull source code from git source, enter github username & password:"
## clear data/www/
echo "clearning data/www/*"
mv data/www/app/etc/local.xml local.xml.bak # backup local file
#rm -rf data/www
mkdir -p data/www
if [ ! -d "data/.www/.git" ]; then
  echo "Cloning source:"
  rm -rf data/.www
  git clone https://github.com/Magestore/Magestore-1.9.3.2.git data/.www
else
  echo "Load source from cached"
  cd data/.www && git pull
fi
cd $CUR_DIR
#echo "Sync source:"
#rsync -aA ${CUR_DIR}/data/.www/ ${CUR_DIR}/data/www/
echo "copy source to www:"
cp -Rf ${CUR_DIR}/data/.www/* ${CUR_DIR}/data/www/
rm -rf data/www/.git # remove git info
## create local.xml file
mv local.xml.bak data/www/app/etc/local.xml # restore local.xml file
if [ ! -f "data/www/app/etc/local.xml" ]; then
  mv data/www/app/etc/local.xml.template data/www/app/etc/local.xml
fi

## create function
randpw(){ < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo;}

## get datetime before 1 month from current time
DATE_TIME=$(date -u "+%Y")                           # get year
DATE_MONTH=$(( $(date -u "+%-m" ) - 1 ))             # decrement by 1 month
if [ ${DATE_MONTH} -lt 10 ]; then
  DATE_MONTH="0${DATE_MONTH}"    # add 0 to number
fi
DATE_TIME=$( date -u "+${DATE_TIME}-${DATE_MONTH}-%d %H:%M:%S" ) # compile all together

## Export database with ignored tables
PULL_DATABASE=true
if [ "$PULL_DATABASE" == "true" ]; then
  echo "Pull database for schema, enter root password:"
  
  echo "mysqldump --host=${EXPORT_DB_HOST} --user=${EXPORT_USER} --opt --single-transaction --quick --set-gtid-purged=OFF \
  --no-data ${EXPORT_DB_NAME} > magestore_db_schema.sql"
  
  if [ ! -f "magestore_db_schema.sql" ]; then
    mysqldump --host=${EXPORT_DB_HOST} --user=${EXPORT_USER} --opt --single-transaction \
      --defaults-extra-file=${CUR_DIR}/mysql_pass.cnf \
      --quick --set-gtid-purged=OFF --no-data \
    ${EXPORT_DB_NAME} > magestore_db_schema.sql
  else
    echo "Use magestore_db_schema.sql from cached"
  fi

  echo "Pull database for data:"
  
  echo "mysqldump --host=${EXPORT_DB_HOST} --user=${EXPORT_USER} --opt --single-transaction --quick --set-gtid-purged=OFF \
  --no-create-db --no-create-info ..."
  
  if [ ! -f "magestore_db_data.sql" ]; then
    mysqldump --host=${EXPORT_DB_HOST} --user=${EXPORT_USER} --opt --single-transaction --quick --set-gtid-purged=OFF \
      --defaults-extra-file=${CUR_DIR}/mysql_pass.cnf \
      --no-create-db --no-create-info \
      --ignore-table=${EXPORT_DB_NAME}.catalogsearch_fulltext \
      --ignore-table=${EXPORT_DB_NAME}.catalogsearch_query    \
      --ignore-table=${EXPORT_DB_NAME}.catalogsearch_result   \
      --ignore-table=${EXPORT_DB_NAME}.core_session \
      --ignore-table=${EXPORT_DB_NAME}.customer_address_entity          \
      --ignore-table=${EXPORT_DB_NAME}.customer_address_entity_datetime \
      --ignore-table=${EXPORT_DB_NAME}.customer_address_entity_decimal  \
      --ignore-table=${EXPORT_DB_NAME}.customer_address_entity_int      \
      --ignore-table=${EXPORT_DB_NAME}.customer_address_entity_text     \
      --ignore-table=${EXPORT_DB_NAME}.customer_address_entity_varchar  \
      --ignore-table=${EXPORT_DB_NAME}.customer_eav_attribute           \
      --ignore-table=${EXPORT_DB_NAME}.customer_eav_attribute_website   \
      --ignore-table=${EXPORT_DB_NAME}.customer_entity                  \
      --ignore-table=${EXPORT_DB_NAME}.customer_entity_datetime         \
      --ignore-table=${EXPORT_DB_NAME}.customer_entity_decimal          \
      --ignore-table=${EXPORT_DB_NAME}.customer_entity_int              \
      --ignore-table=${EXPORT_DB_NAME}.customer_entity_text             \
      --ignore-table=${EXPORT_DB_NAME}.customer_entity_varchar          \
      --ignore-table=${EXPORT_DB_NAME}.customer_flowpassword            \
      --ignore-table=${EXPORT_DB_NAME}.customer_form_attribute          \
      --ignore-table=${EXPORT_DB_NAME}.customer_group                   \
      --ignore-table=${EXPORT_DB_NAME}.dataflow_batch \
      --ignore-table=${EXPORT_DB_NAME}.dataflow_batch_export \
      --ignore-table=${EXPORT_DB_NAME}.dataflow_batch_import \
      --ignore-table=${EXPORT_DB_NAME}.dataflow_import_data \
      --ignore-table=${EXPORT_DB_NAME}.dataflow_session \
      --ignore-table=${EXPORT_DB_NAME}.log_url \
      --ignore-table=${EXPORT_DB_NAME}.log_url_info \
      --ignore-table=${EXPORT_DB_NAME}.log_visitor \
      --ignore-table=${EXPORT_DB_NAME}.log_visitor_info \
      --ignore-table=${EXPORT_DB_NAME}.log_visitor_online \
      --ignore-table=${EXPORT_DB_NAME}.newsletter_problem \
      --ignore-table=${EXPORT_DB_NAME}.newsletter_queue \
      --ignore-table=${EXPORT_DB_NAME}.newsletter_queue_link \
      --ignore-table=${EXPORT_DB_NAME}.newsletter_queue_store_link \
      --ignore-table=${EXPORT_DB_NAME}.newsletter_subscriber \
      --ignore-table=${EXPORT_DB_NAME}.newsletter_template \
      --ignore-table=${EXPORT_DB_NAME}.report_compared_product_index \
      --ignore-table=${EXPORT_DB_NAME}.report_event \
      --ignore-table=${EXPORT_DB_NAME}.report_viewed_product_aggregated_daily \
      --ignore-table=${EXPORT_DB_NAME}.report_viewed_product_aggregated_monthly \
      --ignore-table=${EXPORT_DB_NAME}.report_viewed_product_aggregated_yearly \
      --ignore-table=${EXPORT_DB_NAME}.report_viewed_product_index \
      ${EXPORT_DB_NAME} > magestore_db_data.sql
    else
      echo "Use magestore_db_data.sql from cached"
    fi
fi

echo "create media dir:"
mkdir -p data/www/media
chown -R www-data:www-data data/www/media

echo "clear var/"
rm -rf data/www/var/*

echo "chown data/www:"
chown -R www-data:www-data data/www

echo "clear data/database:"
rm -rf data/database

## Run docker-compose
echo "Run docker-compose:"
docker-compose up -d

## Import db
db_name="magestore_live"
db_user="magestore"
db_user_pass=$(randpw)
newrootpass=$(randpw)

## Import database
container_id_mysql=$( docker ps -q --filter=ancestor=thinlt/mysql:5.6 ) # get container id

echo "Copy database files to mysql container:"
docker cp magestore_db_schema.sql ${container_id_mysql}:/tmp/magestore_db_schema.sql
docker cp magestore_db_data.sql ${container_id_mysql}:/tmp/magestore_db_data.sql

## wait for mysql status healthy
counter=0
docker_compose_check=0
while true ; do
  let counter+=1
  CHECK_STATUS=$( docker ps --filter=ancestor=thinlt/mysql:5.6 | grep "(healthy)" | wc -l )
  echo "Waiting for container ${container_id_mysql} (mysql:5.6)'s healthy status: ${CHECK_STATUS}"
  if [ $CHECK_STATUS -ne 1 ]; then
    sleep 10
  else
    echo "docker mysql container status:"
    docker ps --filter=ancestor=thinlt/mysql:5.6 | grep "(healthy)"
    break
  fi
  if [ $counter -gt 100 ]; then
    echo "docker mysql container status:"
    docker ps --filter=ancestor=thinlt/mysql:5.6 | grep "(healthy)"
    break
  fi
  ## try to restart docker-compos
  if [ $docker_compose_check -ge 4 ]; then
    docker_compose_check=0
    echo "restart docker-compose"
    docker-compose restart
  fi
  let docker_compose_check+=1
done

echo "Importing database:"
#CHECK_MYSQL=$( mysql -Va 2>/dev/null | grep mysql )
#if [ "$CHECK_MYSQL" != '' ]; then
#  mysql -u root -p'root' --host= ${db_name} < magestore_db_schema.sql
#  mysql -u root -p'root' --host= ${db_name} < magestore_db_data.sql
#fi
docker exec -it ${container_id_mysql} /bin/bash -c "mysql -u root -p'root' ${db_name} < /tmp/magestore_db_schema.sql"
docker exec -it ${container_id_mysql} /bin/bash -c "mysql -u root -p'root' ${db_name} < /tmp/magestore_db_data.sql"


echo "delete Customer in database container:"
docker exec -it ${container_id_mysql} /bin/bash -c "mysql -u root -p'root' -e \"DELETE FROM customer_entity WHERE created_at < '{DATE_TIME}'\" ${db_name}"

echo "change domain:"
docker exec -it ${container_id_mysql} /bin/bash -c "mysql -u root -p'root' -e \"UPDATE core_config_data \
  SET value = '${DOMAIN}' WHERE path LIKE '%base_url%' \" ${db_name}"

echo "change cookie donain/path:"
DOMAIN_NAME=$( echo ${DOMAIN} | sed 's/https:\/\///' | sed 's/http:\/\///' | awk -F'/' '{print $1}' )
docker exec -it ${container_id_mysql} /bin/bash -c "mysql -u root -p'root' -e \"UPDATE core_config_data \
  SET value = '${DOMAIN_NAME}' WHERE path = 'web/cookie/cookie_domain' \" ${db_name}"

## Clean files
echo "Delete sql files in mysql container:"
docker exec -it ${container_id_mysql} rm /tmp/magestore_db_schema.sql
docker exec -it ${container_id_mysql} rm /tmp/magestore_db_data.sql
echo "Delete file magestore_db_schema.sql"
rm magestore_db_schema.sql
echo "Delete file magestore_db_data.sql"
rm magestore_db_data.sql

## create database user
echo "create user \`${db_user}\` access database:"
#docker exec -it ${container_id_mysql} mysql -u root -p'root' -e "CREATE USER IF NOT EXISTS ${db_user}" # mysql > 5.7
docker exec -it ${container_id_mysql} mysql -u root -p'root' -e "CREATE USER ${db_user}" # mysql < 5.6
docker exec -it ${container_id_mysql} mysql -u root -p'root' -e "SET PASSWORD FOR '${db_user}'@'%' = PASSWORD('${db_user_pass}')"
docker exec -it ${container_id_mysql} mysql -u root -p'root' -e "GRANT ALL ON ${db_name}.* TO '${db_user}'@'%'"

echo "change new root password:"
docker exec -it ${container_id_mysql} mysql -u root -p'root' -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${newrootpass}')"

## replace database account info
sed 's/<host>.*<\/host>/<host><!\[CDATA\[mysql\]\]><\/host>/' data/www/app/etc/local.xml > /tmp/sed_local_temp.xml && cat /tmp/sed_local_temp.xml > data/www/app/etc/local.xml
sed 's/<username>.*<\/username>/<username><!\[CDATA\['${db_user}'\]\]><\/username>/' data/www/app/etc/local.xml > /tmp/sed_local_temp.xml && cat /tmp/sed_local_temp.xml > data/www/app/etc/local.xml
sed 's/<password>.*<\/password>/<password><!\[CDATA\['${db_user_pass}'\]\]><\/password>/' data/www/app/etc/local.xml > /tmp/sed_local_temp.xml && cat /tmp/sed_local_temp.xml > data/www/app/etc/local.xml
sed 's/<dbname>.*<\/dbname>/<dbname><!\[CDATA['${db_name}'\]\]><\/dbname>/' data/www/app/etc/local.xml > /tmp/sed_local_temp.xml && cat /tmp/sed_local_temp.xml > data/www/app/etc/local.xml

cat <<EOF > info.txt
#################
---Info---
Mysql root password: ${newrootpass}
Db User: ${db_user} / ${db_user_pass}
EOF

cat info.txt
