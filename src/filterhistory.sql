SELECT
    date_added AS received,
    CAST(`from` AS INTEGER) AS player,
    SUBSTR(body, 1, INSTR(body, ' ') - 1) AS hole,
    CASE
        WHEN LENGTH(TRIM(body)) - LENGTH(REPLACE(body, ' ', '')) = 0 THEN 0  -- Handle single number case
        ELSE SUBSTR(body, INSTR(body, ' ') + 1, CASE
                                                     WHEN INSTR(SUBSTR(body, INSTR(body, ' ') + 1), ' ') = 0
                                                     THEN LENGTH(body)
                                                     ELSE INSTR(SUBSTR(body, INSTR(body, ' ') + 1), ' ') - 1
                                                 END)
    END AS gross,
    CASE
        WHEN LENGTH(TRIM(body)) - LENGTH(REPLACE(body, ' ', '')) < 2 THEN 0 --Handle one or zero spaces
        ELSE SUBSTR(SUBSTR(body, INSTR(body, ' ') + 1), INSTR(SUBSTR(body, INSTR(body, ' ') + 1), ' ') + 1)
    END AS points
FROM smshistory
WHERE direction = 'in'
AND DATE(date_added) = DATE('now')
AND body REGEXP '^[0-9]+\s[0-9]+(\s[0-9])*$';
