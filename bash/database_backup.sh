#!/bin/bash
mkdir /tmp/daily /tmp/monthly /tmp/yearly
#save the current dates to variables
day_of_month=`date +%d  -d 'Jan 1 13:34:04 MSK 2019'`
day_of_year=`date +%j  -d 'Jan 1 13:34:04 MSK 2019'`
day_of_week=`date +%u -d 'Jan 1 13:34:04 MSK 2019'`

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
        retention_period=$retention_period+1
    else
      retention_period=$retention_period+2
    fi
else
  weekends="no"
fi

#do backup if no weekends
if [ "$weekends" -ne "yes" ]
  then
    echo "dump" >>/tmp/daily/$file_name
fi

#make backup if first day of month and weekends, or just copy if not weekends
if [ "$day_of_month" -eq "1" ]
  then
    echo 'copy first day of month'
  if [ "$weekends" -ne "yes" ]
    then
      cp /tmp/daily/$file_name /tmp/monthly/
  else
    echo "dump" >>/tmp/monthly/$file_name
  fi
fi

#make backup if first day of year and weekends, or just copy if not weekends
if [ "$day_of_year" -eq "001" ]
  then
    echo "first day of the year"
    if [ "$weekends" -ne "yes" ]
      cp /tmp/daily/$file_name /tmp/yearly/
    else
      echo "dump" >>/tmp/yearly/$file_name
   fi
fi

#delete old backups
find /tmp/daily -name '*.dump' -mday +$retention_period
