# MySQL script
# create table for disk temperatures

USE domotica;

DROP TABLE IF EXISTS disktemp;

CREATE TABLE `disktemp` (
  `sample_time`   datetime,
  `sample_epoch`  bigint(20) unsigned,
  `host`          varchar(24),
  `diskid`        varchar(24),
  `diskt`         int(11) signed,
  `id`            varchar(48),
  PRIMARY KEY (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM syslog where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv
