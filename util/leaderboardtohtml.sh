#!/bin/sh

output_file="html/index.html"

echo "<html><body><table>" > "$output_file"

# Read the header row
header=$(head -n 1 leaderboard.csv)
header=$(echo "$header" | sed 's/,/<\/th><th>/g')
echo "<tr><th>$header</th></tr>" >> "$output_file"

# Process the data rows
tail -n +2 leaderboard.csv | while IFS=, read -r player total; do
  echo "<tr><td>$player</td><td>$total</td></tr>" >> "$output_file"
done

echo "</table></body></html>" >> "$output_file"

