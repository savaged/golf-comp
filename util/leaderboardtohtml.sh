#!/bin/sh

echo "<html><body><table>"

# Read the header row
header=$(head -n 1 leaderboard.csv)
header=$(echo "$header" | sed 's/,/<\/th><th>/g')
echo "<tr><th>$header</th></tr>"

# Process the data rows
tail -n +2 leaderboard.csv | while IFS=, read -r player total; do
  echo "<tr><td>$player</td><td>$total</td></tr>"
done

echo "</table></body></html>"