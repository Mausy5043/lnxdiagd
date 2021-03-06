# MySQL script
# create table for system CPU load
# [ ] systemp = create table for system CPU temperatures
# [x] sysload = create table for system CPU load
# [ ] sysnetw = create table for system networkload
# [ ] sysdskt = create table for system disk temperatures
# [ ] sysmem  = create table for system memory usage

USE domotica;

DROP TABLE IF EXISTS sysload;

CREATE TABLE `sysload` (
  `sample_time`   datetime,
  `sample_epoch`  bigint(20) unsigned,
  `host`          varchar(24),
  `load1min`      decimal(5,3),
  `load5min`      decimal(5,3),
  `load15min`     decimal(5,3),
  `active_procs`  int(6) unsigned,
  `total_procs`   int(6) unsigned,
  `last_pid`      int(6) unsigned,
  `user`          decimal(6,3),
  `system`        decimal(6,3),
  `idle`          decimal(6,3),
  `waiting`       decimal(6,3),
  `stolen`        decimal(6,3),
  `id`            varchar(24),
  PRIMARY KEY (`id`),
  INDEX (`sample_epoch`),
  INDEX (`host`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysload where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv
