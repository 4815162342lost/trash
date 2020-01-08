#!/bin/bash
###script for make backup of the postgres database
###criterias: make backup every day except weekends
###make backup on Jan 1 and store permanently
###remove backup automatically older than retention_period variable
###store monthly backup in 366 days

#database connection params
database_name="bars_web_bb"
database_user="web_bb"
datapase_host="127.0.0.1"
database_port=5432

#backup stored dir
daily_backup_dir="/home/backup/backup_db/daily/"
monthly_backup_dir="/home/backup/backup_db/monthly/"
yearly_backup_dir="/home/backup/backup_db/yearly/"

#rsync ip addr and dir
#rsync_command_args="root@10.1.4.72:/root/backup/bars_web_bb.backup"

#get current date
day_of_month=`date +%d`
day_of_year=`date +%j`
day_of_week=`date +%u`


#keep backups 7 days and generate backup name
retention_period=7
file_name=`date +%d_%m_%Y.dump`

#determine is now weekends or not
if [ "$day_of_week" -eq "1" ] || [ "$day_of_week" -eq "7" ]
  then
    echo 'were weekends, do not make on Sunday or Monday (bacuse we are running script at 03:00 am)'
    weekends="yes"
    #if Sunday then retention day + 1, if Monday +2
    if [ "$day_of_week" -eq "7" ] 
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
    pg_dump -p $database_port -U $database_user -h $datapase_host -Fc -f $daily_backup_dir$database_name$file_name -d $database_name
    #make rsync
    #rsync -zvh $daily_backup_dir$database_name$file_name $rsync_command_args
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
    pg_dump -p $database_port -U $database_user -h $datapase_host -Fc -f $monthly_backup_dir$database_name$file_name $database_name
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
    elif [ "$weekends" == "yes" ] && [ "$day_of_month" -eq "1" ]
      then
      cp $monthly_backup_dir$file_name $yearly_backup_dir
    else
      echo "Starting backup creation..."
      pg_dump -p $database_port -U $database_user -h $datapase_host -Fc -f $yearly_backup_dir$database_name$file_name $database_name
    fi
fi

#delete old backups
find $daily_backup_dir -name '*.dump' -mtime +$retention_period -delete
find $monthly_backup_dir -name '*.dump' -mtime +366 -delete
