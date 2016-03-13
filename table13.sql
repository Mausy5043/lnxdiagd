# MySQL script
# create table for system network traffic
# [ ] systemp = create table for system CPU temperatures
# [ ] sysload = create table for system CPU load
# [x] sysnet  = create table for system networkload
# [ ] sysdskt = create table for system disk temperatures
# [ ] sysmem  = create table for system memory usage

USE domotica;

DROP TABLE IF EXISTS sysload;

CREATE TABLE `sysnet` (
  `sample_time`   datetime,
  `sample_epoch`  int(11) unsigned,
  `host`          varchar(24),
  `loIn`          decimal(6,3),
  `loOut`         decimal(6,3),
  `etIn`          decimal(6,3),
  `etOut`         decimal(6,3),
  `wlIn`          decimal(6,3),
  `wlOut`         decimal(6,3),
  PRIMARY KEY (`sample_time`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysnet where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv
