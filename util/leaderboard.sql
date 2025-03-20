SELECT
    CAST(player AS INTEGER) AS player,
    SUM(CAST(points AS INTEGER)) AS total
FROM filtered
GROUP BY player
ORDER BY total;
