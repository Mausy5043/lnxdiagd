# TODO

- timing of SQL queries should be chosen to keep the load on the SQL server as low as possible
  1. retain already downloaded data locally (in memory or in file)
  2. execute queries on a semi-random cycle to reduce chance of simultaneous queries from different hosts
  3. keep queries small; only query for the required period.
  
- Graphing
  1. GNUplot is faster; `matplotlib` is more challenging
  2. `matplotlib` is slow and resource hungry
  3. GNUplot is not re-iterable. `matplotlib` is?
