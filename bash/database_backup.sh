#!/bin/bash
###script for make backup of the postgres database
###criterias: make backup every day except weekends
###make backup on the first day of the mounth and year and store permanently
###remove backup automatically older than retention_period variable
###store monthly backup in 366 days

#database name
database_name="bars_web_bb"

#backup stored dir
daily_backup_dir="/home/backup/backup_db/daily/"
monthly_backup_dir="/home/backup/backup_db/monthly/"
yearly_backup_dir="/home/backup/backup_db/yearly/"

#rsync ip addr and dir
rsync_command_args="root@10.1.4.72:/root/backup/bars_web_bb.backup"

#save the current dates to variables (Jan 1 just for tests and debug purposes)
#day_of_month=`date +%d  -d 'Jan 1 13:34:04 MSK 2019'`
#day_of_year=`date +%j  -d 'Jan 1 13:34:04 MSK 2019'`
#day_of_week=`date +%u -d 'Jan 1 13:34:04 MSK 2019'`
day_of_month=`date +%d`
day_of_year=`date +%j`
day_of_week=`date +%u`


#keep backups 7 days and geberate backup name
retention_period=7
file_name=`date +%d_%m_%Y.dump`

#determine is now weekends or not
if [ "$day_of_week" -eq "6" ] || [ "$day_of_week" -eq "7" ]
  then
    echo 'weekends, not make backup'
    weekends="yes"
    #if Suterday then retention day + 1, if Sunday +2
    if [ "$day_of_week" -eq "6" ] 
      then
        retention_period=$(( $retention_period + 1 ))
    else
      retention_period=$(( $retention_period + 2 ))
    fi
else
  weekends="no"
fi

echo "retention period: $retention_period"
echo "weekends variable: $weekends"

#do backup if no weekends
if [ "$weekends" != "yes" ]
  then
    echo "Starting backup creation..."
    sudo -E -u postgres pg_dump -U web_bb -h 127.0.0.1 -Fc -f $daily_backup_dir$database_name$file_name $database_name
    #make rsync
    rsync -zvh $daily_backup_dir$database_name$file_name $rsync_command_args
fi

#make backup if first day of month and weekends, or just copy if not weekends
if [ "$day_of_month" -eq "1" ]
  then
    echo 'first day of month is true'
  if [ "$weekends" != "yes" ]
    then
      echo "Copying backup to $monthly_backup_dir"
      cp $daily_backup_dir$database_name$file_name $monthly_backup_dir
  else
    echo "Starting backup creation..."
    sudo -E -u postgres pg_dump -U web_bb -h 127.0.0.1 -Fc -f $monthly_backup_dir$database_name$file_name $database_name
  fi
fi

#make backup if first day of year and weekends, or just copy if not weekends
if [ "$day_of_year" == "001" ]
  then
    echo "first day of the year is true"
    if [ "$weekends" != "yes" ]
      then
      echo "Copying backup to $yearly_backup_dir"
      cp $daily_backup_dir$database_name$file_name $yearly_backup_dir
    else
      echo "Starting backup creation..."
      sudo -E -u postgres pg_dump -U web_bb -h 127.0.0.1 -Fc -f $yearly_backup_dir$database_name$file_name $database_name
   fi
fi

#delete old backups
find $daily_backup_dir -name '*.dump' -mtime +$retention_period -delete
find $monthly_backup_dir -name '*.dump' -mtime +366 -delete
