#!/bin/bash
# FUNCTION Restores the MySQL database and Moodle backup 
# Backup has to be made with moodle_backup.sh

EXIT_OK=0
EXIT_ERROR=1

MOODLE_SERVICE=httpd
MOODLE_ROOT='/var/www_vhost'
MOODLE_HOME=$MOODLE_ROOT'/moodle'
MOODLE_CONFIG=$MOODLE_HOME'/config.php'
BACKUP_HOME='/opt/backup'
BACKUP_DATE=$1

function get_parameter {
   result=`grep $2 $1 | cut -f2 -d"'"`
   echo $result
}

function exist_file {
   if [ -f $1 ]; then
      echo "Fichero "$1": OK"
      result=$EXIT_OK
   else
      echo "ERROR: No se encuentra el fichero "$1
      result=$EXIT_ERROR
      exit $EXIT_ERROR
   fi
}

if [ -z "$1" ]; then
    echo "ERROR: Missing restore date"
    echo "Modo de uso: "$0" AAAA-MM-DD"
    exit $EXIT_ERROR
fi

# Get keys to connect to MySQL database
exist_file $MOODLE_CONFIG
MOODLE_DBHOST=`get_parameter $MOODLE_CONFIG dbhost`
MOODLE_DBNAME=`get_parameter $MOODLE_CONFIG dbname`
MOODLE_DBUSR=`get_parameter $MOODLE_CONFIG dbuser`
MOODLE_DBPWD=`get_parameter $MOODLE_CONFIG dbpass`
MOODLE_DATA=`get_parameter $MOODLE_CONFIG dataroot`

# Check if all needed files are available
MOODLE_BACKUP=$BACKUP_HOME"/"$BACKUP_DATE"_"$MOODLE_DBNAME
MOODLE_SQL=$MOODLE_BACKUP".sql"
MOODLE_HTML_TGZ=$MOODLE_BACKUP"_html.tgz"
MOODLE_DATA_TGZ=$MOODLE_BACKUP"_data.tgz"
exist_file $MOODLE_SQL
exist_file $MOODLE_HTML_TGZ
exist_file $MOODLE_DATA_TGZ

# Enable maintenance mode
mv $MOODLE_DATA/climaintenance.off $MOODLE_DATA/climaintenance.html

# Remove symbolic link
echo "Old symbolic link: "`ls -l $MOODLE_HOME`
rm $MOODLE_HOME

# Create a new symbolic link
cd $MOODLE_ROOT
mkdir moodle-$BACKUP_DATE
ln -s moodle-$BACKUP_DATE moodle
echo "New symbolic link: "`ls -l $MOODLE_HOME`

# Remove actual data
cd $MOODLE_DATA
rm -Rf $MOODLE_DATA/*

echo "Restoring Moodle application..."
cd $MOODLE_HOME
tar xvfz $MOODLE_HTML_TGZ > /dev/null

echo "Restoring data files..."
cd $MOODLE_DATA
tar xvfz $MOODLE_DATA_TGZ > /dev/null

echo "Restoring database..."
cat $MOODLE_SQL | mysql --user=$MOODLE_DBUSR --password=$MOODLE_DBPWD --host=$MOODLE_DBHOST

sync
service $MOODLE_SERVICE graceful

# Disable maintenance mode
mv $MOODLE_DATA/climaintenance.html $MOODLE_DATA/climaintenance.off

exit $EXIT_OK
