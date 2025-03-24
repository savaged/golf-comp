SELECT
    p.name AS player,
    SUM(CAST(f.points AS INTEGER)) AS total,
    MAX(CAST(f.hole AS INTEGER)) AS thru
FROM filtered f
LEFT JOIN players p ON CAST(f.player AS INTEGER) = p.mobile
GROUP BY f.player
ORDER BY total;
