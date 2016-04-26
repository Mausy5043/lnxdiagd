# MySQL script
# create table for system network traffic
# [ ] systemp = create table for system CPU temperatures
# [ ] sysload = create table for system CPU load
# [x] sysnet  = create table for system networkload
# [ ] sysdskt = create table for system disk temperatures
# [ ] sysmem  = create table for system memory usage

USE domotica;

DROP TABLE IF EXISTS sysnet;

CREATE TABLE `sysnet` (
  `sample_time`   datetime,
  `sample_epoch`  bigint(20) unsigned,
  `host`          varchar(24),
  `loIn`          bigint(20) unsigned,
  `loOut`         bigint(20) unsigned,
  `etIn`          bigint(20) unsigned,
  `etOut`         bigint(20) unsigned,
  `wlIn`          bigint(20) unsigned,
  `wlOut`         bigint(20) unsigned,
  `id`            varchar(24),
  PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM sysnet where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv
