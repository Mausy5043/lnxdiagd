USE domotica;
SELECT
  d1.sample_epoch,
  #    d1.diskid,
  d1.diskt AS sdd,
  #    d2.diskid,
  d2.diskt AS hda,
  #	 d3.diskid,
  d3.diskt AS hdb,
  #    d4.diskid,
  d4.diskt AS hdc,
  #    d5.diskid,
  d5.diskt AS hdd
FROM
  disktemp d1,
  disktemp d2,
  disktemp d3,
  disktemp d4,
  disktemp d5
WHERE
  (d1.sample_time >= NOW() - INTERVAL 70 MINUTE)
	AND d1.sample_epoch = d2.sample_epoch
	AND d1.sample_epoch = d3.sample_epoch
	AND d1.sample_epoch = d4.sample_epoch
	AND d1.sample_epoch = d5.sample_epoch
	  AND d1.diskid LIKE '%d6dd5'
		AND d2.diskid LIKE '%20fce'
		AND d3.diskid LIKE '%043e2'
		AND d4.diskid LIKE '%a237b'
		AND d5.diskid LIKE '%7b79c'
		)
;
