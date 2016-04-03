#!/bin/bash

# This script is used for manually pushing the website content
# For automatic updates use `lnxsvc98.py`
lftp -d -f push.lftp
