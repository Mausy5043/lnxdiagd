# TODO

- timing of SQL queries should be chosen to keep the load on the SQL server as low as possible
  - [ ] retain and re-use already downloaded data locally (in memory or in file)
  - [x] execute queries on a semi-random cycle to reduce chance of simultaneous queries from different hosts
  - [x] keep queries small; only query for the required period.
  
- graphing
  1. GNUplot is faster; `matplotlib` is more challenging
  2. `matplotlib` is slow and resource hungry
  3. GNUplot is not re-iterable. `matplotlib` is?

## Timing of graphs
  - [x] Hourly graph from  `now()`               to `now() - 70 minutes`;       resolution:  1 minute (60s)
  - [x] Daily graph from   `now() - 70 minutes`  to `now() - 30 hours`(\*);     resolution: 30 minutes (1800s)
  - [x] Weekly graph from  `now() - 24 hours`    to `now() - 8 days`(\*\*);     resolution:  4 hours (14400s)
  - [x] Yearly graph from  `now() - 8 days`      to `now() - 370 days`(\*\*\*)  resolution:  1 day (or 1 week depending on resulting load on the server) 

(\*) = rounded to MOD :30 minutes   
(\*\*) = rounded to MOD 4 hours  
(\*\*\*) = rounded to start of day (00:00) 

As a result of the chosen resolution, the queries can be timed appropriately:
  - [ ] Data for the hourly graph every 1 minute
  - [ ] Data for the daily graph every 30 minutes
  - [ ] Data for the weekly graph every 4 hours
  - [ ] Data for the yearly graph once every day
  
Also, all queries need to be performed at start-up. And it may be considered to have the daemons add the new data to the local store, thus reducing/eliminating the need for queries. That would also mean the need to construct a local data store.
This could be achieved using `rrdtool` (which would add an addtional option for graphing) or a local database (SQL) or a local flat-textfile (CSV)
The use of `rrdtool` on Raspberry Pi is less appropriate as it may reduce the SD-card's lifetime. However, if the RRD database is stored on `tmpfs`s this should not be an issue. 

GNUplot: http://gnuplot.sourceforge.net/demo/fillbetween.html
