SELECT
    date_added AS received,
    CAST(`from` AS INTEGER) AS player,
    SUBSTR(body, 1, INSTR(body, ' ') - 1) AS hole,
    SUBSTR(body, INSTR(body, ' ') + 1, CASE WHEN INSTR(SUBSTR(body, INSTR(body, ' ') + 1), ' ') = 0 THEN LENGTH(body) ELSE INSTR(SUBSTR(body, INSTR(body, ' ') + 1), ' ') -1 END) AS gross,
    SUBSTR(body, INSTR(body, ' ') + INSTR(SUBSTR(body, INSTR(body, ' ') + 1), ' ') + 1) AS points
FROM smshistory
WHERE direction = 'in'
AND DATE(date_added) = DATE('now')
AND body REGEXP '^[1-9]+ [1-9]+ [1-9]+$';
