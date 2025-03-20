#!/bin/sh

csvsql --query "$(cat util/leaderboard.sql)" filtered.csv data/players.csv > leaderboard.csv

