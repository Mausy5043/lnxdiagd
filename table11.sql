# MySQL script
# create table for system CPU temperatures
# [x] systemp = create table for system CPU temperatures
# [ ] sysload = create table for system CPU load
# [ ] sysnetw = create table for system networkload
# [ ] sysdskt = create table for system disk temperatures
# [ ] sysmem  = create table for system memory usage

# id is <hostname><sample-epoch>
USE domotica;

DROP TABLE IF EXISTS systemp;

CREATE TABLE `systemp` (
  `sample_time`   datetime,
  `sample_epoch`  bigint(20) unsigned,
  `host`          varchar(24),
  `temperature`   decimal(6,3),
  `id`            varchar(24),
  PRIMARY KEY (`id`),
  INDEX (`sample_epoch`),
  INDEX (`host`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM systemp where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv
