#!/bin/bash
#
# FUNCION Makes a full backup of Moodle and its MySQL database

EXIT_OK=0
EXIT_ERROR=1

MOODLE_SERVICE=httpd
MOODLE_HOME='/var/www_vhost/moodle'
BACKUP_HOME='/opt/backup'

function get_parameter {
   result=`grep $2 $1 | cut -f2 -d"'"`
   echo $result
}

MYDATE=`date +%Y-%m-%d`
MOODLE_CONFIG=$MOODLE_HOME'/config.php'

if [ ! -f $MOODLE_CONFIG ]; then
    echo "ERROR: File not found "$MOODLE_CONFIG
    exit $EXIT_ERROR
fi

MOODLE_DBHOST=`get_parameter $MOODLE_CONFIG dbhost`
MOODLE_DBNAME=`get_parameter $MOODLE_CONFIG dbname`
MOODLE_DBUSR=`get_parameter $MOODLE_CONFIG dbuser`
MOODLE_DBPWD=`get_parameter $MOODLE_CONFIG dbpass`
MOODLE_DATA=`get_parameter $MOODLE_CONFIG dataroot`

MOODLE_BACKUP=$BACKUP_HOME"/"$MYDATE"_"$MOODLE_DBNAME
MOODLE_SQL=$MOODLE_BACKUP".sql"
MOODLE_HTML_TGZ=$MOODLE_BACKUP"_html.tgz"
MOODLE_DATA_TGZ=$MOODLE_BACKUP"_data.tgz"

# Enable maintenance mode
mv $MOODLE_DATA/climaintenance.off $MOODLE_DATA/climaintenance.html

echo "Dumping MySQL - Host:"$MOODLE_DBHOST" Database:"$MOODLE_DBNAME" User:"$MOODLE_DBUSR"..."
mysqldump --add-drop-database --user=$MOODLE_DBUSR --password=$MOODLE_DBPWD --host=$MOODLE_DBHOST --add-drop-table --databases $MOODLE_DBNAME --result-file=$MOODLE_SQL
ls -lh $MOODLE_SQL

echo "Copying Moodle HTML directory...."
cd $MOODLE_HOME
tar cvzf $MOODLE_HTML_TGZ * > /dev/null
ls -lh $MOODLE_HTML_TGZ

echo "Copying Moodle DATA directory...."
cd $MOODLE_DATA
tar cvzf $MOODLE_DATA_TGZ * > /dev/null
ls -lh $MOODLE_DATA_TGZ

# Disable maintenance mode
mv $MOODLE_DATA/climaintenance.html $MOODLE_DATA/climaintenance.off
sync
service $MOODLE_SERVICE graceful

exit $EXIT_OK
