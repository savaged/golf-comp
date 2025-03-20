#!/bin/sh

csvsql --query "$(cat util/leaderboard.sql)" filtered.csv > leaderboard.csv

