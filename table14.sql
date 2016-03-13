# MySQL script
# create table for system network traffic
# [ ] systemp = create table for system CPU temperatures
# [ ] sysload = create table for system CPU load
# [ ] sysnet  = create table for system networkload
# [ ] sysdskt = create table for system disk temperatures
# [x] sysmem  = create table for system memory usage

USE domotica;

DROP TABLE IF EXISTS sysnet;

CREATE TABLE `sysnet` (
  `sample_time`   datetime,
  `sample_epoch`  int(11) unsigned,
  `host`          varchar(24),
  outMemTotal, outMemUsed, outMemBuf, outMemCache, outMemFree, outMemSwapTotal, outMemSwapFree, outMemSwapUsed)

  `loIn`          int(11),
  `loOut`         int(11),
  `etIn`          int(11),
  `etOut`         int(11),
  `wlIn`          int(11),
  `wlOut`         int(11),
  PRIMARY KEY (`sample_time`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysnet where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv
