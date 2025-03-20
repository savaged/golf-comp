#!/bin/sh

csvsql --query "$(cat util/filterhistory.sql)" smshistory.csv > filtered.csv

