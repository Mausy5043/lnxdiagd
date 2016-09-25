USE domotica;
SELECT
  d1.sample_epoch,
  #    d1.diskid,
  d1.diskt AS hda,
  #    d2.diskid,
  d2.diskt AS hdb,
  #	 d3.diskid,
  d3.diskt AS hdc,
  #    d4.diskid,
  d4.diskt AS hdd,
  #    d5.diskid,
  d5.diskt AS sdd
FROM
  disktemp d1,
  disktemp d2,
  disktemp d3,
  disktemp d4,
  disktemp d5
WHERE
  (d1.sample_time >= NOW() - INTERVAL 30 HOUR)
	AND d1.sample_epoch = d2.sample_epoch
	AND d1.sample_epoch = d3.sample_epoch
	AND d1.sample_epoch = d4.sample_epoch
	AND d1.sample_epoch = d5.sample_epoch
	AND (d1.diskid LIKE  '%20fce'
		AND d2.diskid LIKE '%043e2'
		AND d3.diskid LIKE '%a237b'
		AND d4.diskid LIKE '%7b79c'
		AND d5.diskid LIKE '%d6dd5'
		)
;
