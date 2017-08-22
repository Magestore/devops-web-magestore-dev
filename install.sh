#!/bin/bash

## Install

echo "Installing"

echo "Pull source code from git source, enter github username & password:"

## clear data/www/
mkdir -p data/www
rm -rf data/www/*
git clone https://github.com/Magestore/Magestore-1.9.3.2.git data/www/

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
echo "Pull database, enter root password:"
EXPORT_DB_HOST='35.202.178.130'
EXPORT_DB_NAME='magestore_db_clone'
mysqldump --host=${EXPORT_DB_HOST} -u root -p --opt --single-transaction --quick --set-gtid-purged=OFF \
--ignore-table=${EXPORT_DB_NAME}.catalogsearch_fulltext \
--ignore-table=${EXPORT_DB_NAME}.catalogsearch_query \
--ignore-table=${EXPORT_DB_NAME}.catalogsearch_result \
--ignore-table=${EXPORT_DB_NAME}.core_session \
--ignore-table=${EXPORT_DB_NAME}.customer_address_entity \
--ignore-table=${EXPORT_DB_NAME}.customer_address_entity_datetime \
--ignore-table=${EXPORT_DB_NAME}.customer_address_entity_decimal \
--ignore-table=${EXPORT_DB_NAME}.customer_address_entity_int \
--ignore-table=${EXPORT_DB_NAME}.customer_address_entity_text \
--ignore-table=${EXPORT_DB_NAME}.customer_address_entity_varchar \
--ignore-table=${EXPORT_DB_NAME}.customer_entity \
--ignore-table=${EXPORT_DB_NAME}.customer_entity_datetime \
--ignore-table=${EXPORT_DB_NAME}.customer_entity_decimal \
--ignore-table=${EXPORT_DB_NAME}.customer_entity_int \
--ignore-table=${EXPORT_DB_NAME}.customer_entity_text \
--ignore-table=${EXPORT_DB_NAME}.customer_entity_varchar \
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
${EXPORT_DB_NAME} > magestore_db.sql

## Export customer schema
mysqldump --no-data --quick --set-gtid-purged=OFF \
--where="created_at < '${DATE_TIME}'" \
${EXPORT_DB_NAME} \
${EXPORT_DB_NAME}.customer_address_entity \
${EXPORT_DB_NAME}.customer_address_entity_datetime \
${EXPORT_DB_NAME}.customer_address_entity_decimal \
${EXPORT_DB_NAME}.customer_address_entity_int \
${EXPORT_DB_NAME}.customer_address_entity_text \
${EXPORT_DB_NAME}.customer_address_entity_varchar \
${EXPORT_DB_NAME}.customer_entity \
${EXPORT_DB_NAME}.customer_entity_datetime \
${EXPORT_DB_NAME}.customer_entity_decimal \
${EXPORT_DB_NAME}.customer_entity_int \
${EXPORT_DB_NAME}.customer_entity_text \
${EXPORT_DB_NAME}.customer_entity_varchar \
> magestore_db_customer.sql

echo "chown data/www:"

chown www-data:www-data data/www

echo "chown data/database:"

chown mysql:mysql data/database

## Run docker-compose
echo "Run docker-compose:"

docker-compose up -d

## Import db
db_name="magestore_live"
db_user="magestore"
db_user_pass=$(randpw)
newrootpass=$(randpw)

## Import database
echo "Importing database:"
mysql -u root -p'' ${db_name} < magestore_db.sql
mysql -u root -p'' ${db_name} < magestore_db_customer.sql

echo "Delete file magestore_db.sql"
rm magestore_db.sql

echo "delete Customer:"
mysql -u root -p'' -e "DELETE FROM customer_entity WHERE created_at < '{DATE_TIME}'" ${db_name}

## create database user
echo "create user \`${db_user}\` access database:"

mysql -u root -p'' -e "CREATE USER IF NOT EXISTS ${db_user}"
mysql -u root -p'' -e "SET PASSWORD FOR '${db_user}'@'%' = PASSWORD('${db_user_pass}')"
mysql -u root -p'' -e "GRANT ALL ON ${db_name}.* TO '${db_user}'@'%'"

echo "change new root password:"
mysql -u root -p'' -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${newrootpass}')"

echo "#################"
echo "---Info---"
echo "Mysql root password: ${newrootpass}"
echo "Db User: ${db_user} / ${newpass}"
