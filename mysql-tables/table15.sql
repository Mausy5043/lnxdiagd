# MySQL script
# create table for logfile counters

USE domotica;

DROP TABLE IF EXISTS syslog;

CREATE TABLE `syslog` (
  `sample_time`   datetime,
  `sample_epoch`  bigint(20) unsigned,
  `host`          varchar(24),
  `p0`            int(11) unsigned,
  `p1`            int(11) unsigned,
  `p2`            int(11) unsigned,
  `p3`            int(11) unsigned,
  `p4`            int(11) unsigned,
  `p5`            int(11) unsigned,
  `p6`            int(11) unsigned,
  `p7`            int(11) unsigned,
  `id`            varchar(24),
  PRIMARY KEY (`id`),
  INDEX (`sample_epoch`),
  INDEX (`host`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql --skip-column-names -e "USE domotica; SELECT * FROM syslog where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv
