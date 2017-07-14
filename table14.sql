# MySQL script
# create table for system network traffic
# [ ] systemp = create table for system CPU temperatures
# [ ] sysload = create table for system CPU load
# [ ] sysnet  = create table for system networkload
# [ ] sysdskt = create table for system disk temperatures
# [x] sysmem  = create table for system memory usage

USE domotica;

DROP TABLE IF EXISTS sysmem;

CREATE TABLE `sysmem` (
  `sample_time`   datetime,
  `sample_epoch`  bigint(20) unsigned,
  `host`          varchar(24),
  `total`         int(11) unsigned,
  `used`          int(11) unsigned,
  `buffers`       int(11) unsigned,
  `cached`        int(11) unsigned,
  `free`          int(11) unsigned,
  `swaptotal`     int(11) unsigned,
  `swapfree`      int(11) unsigned,
  `swapused`      int(11) unsigned,
  `id`            varchar(24),
  PRIMARY KEY (`id`),
  INDEX (`sample_epoch`),
  INDEX (`host`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM sysnet where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv
