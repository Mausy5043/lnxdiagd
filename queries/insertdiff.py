#!/usr/bin/env python3

# INPUT : MySQL query outputted data file from network counters (daemon 13)
# ACTION: calculate bitrate
# OUTPUT: Rewritten data file with the bitrates inserted

import os
import sys
import mausy5043funcs.fileops3 as mf

def process_file(fname):
  src = mf.cat(fname).replace(";", " ").splitlines()
  newsrc = []
  # store first sample
  line0 = src[0]
  data0 = list(map(int, line0.split()))

  for line in src[1:-1]:
    data = list(map(int, line.split()))
    # determine temporal displacement between this sample and the previous one
    tsecs = data[0] - data0[0]
    if (tsecs > 0):
      newline = [0] * (len(data)+2)
      newline[0] = data[0]                            # sample_epoch
      newline[1] = data[1]                            # MIN(etIn)
      # calculate bitrate download in BPS
      if (data[2] > data0[2]):
        # use MIN[x] - MIN[x-1]
        newline[2] = (data[2] - data0[2]) / tsecs     # AVG(etIn)
      else:
        newline[2] = 1                                # 1 iso 0 to allow for logscale
      newline[3] = data[2]                            # MAX(etIn)
      newline[4] = data[3]                            # MIN(etOut)
      # calculate bitrate upload in BPS
      if (data[4] > data0[4]):
        newline[5] = (data[4] - data0[4]) / tsecs     # AVG(etOut)
      else:
        newline[5] = 1                                # 1 iso 0 to allow for logscale
      newline[6] = data[4]                            # MAX(etOut)
      newsrc.append(';'.join(map(str, newline)))
    # remember current sample for next loop
    data0 = data

  with open(fname, 'w') as f:
    f.write("\n".join(newsrc))
    f.write("\n")


if __name__ == "__main__":
  if len(sys.argv) == 2:
    IFILE = sys.argv[1]
    if not os.path.isfile(IFILE):
      print("File {0!s} not found".format(IFILE))
      sys.exit(2)
    # START processing
    process_file(IFILE)
    # END processing
    sys.exit(0)
  else:
    print("usage: {0!s} <datafile.csv>".format(sys.argv[0]))
    sys.exit(2)
