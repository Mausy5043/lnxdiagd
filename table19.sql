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
  PRIMARY KEY (`id`),
  INDEX (`sample_epoch`),
  INDEX (`host`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1 ;

# example to retrieve data:
# mysql -h sql.lan --skip-column-names -e "USE domotica; SELECT * FROM syslog where (sample_time) >=NOW() - INTERVAL 6 HOUR;" | sed 's/\t/;/g;s/\n//g' > /tmp/sql.csv

#
# 2016-09-02 17:19:01;1472829540;boson;wwn-0x50014ee605a043e2;39;wwn-0x50014ee605a043e2@1472829540
# 2016-09-02 16:57:01;1472828220;boson;wwn-0x50026b723c0d6dd5;41;wwn-0x50026b723c0d6dd5@1472828220
