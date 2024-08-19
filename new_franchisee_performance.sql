SELECT 
    l.id AS lead_id,
    l.date_entered,
    fm.id AS franchise_id,
    fmc.operations_start_date_c AS operations_start_date,
    concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,
    SUM(CASE 
        WHEN l.date_entered BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 30 DAY)
            THEN 1
            ELSE 0
        END) AS leads_30_days,
    SUM(CASE 
        WHEN l.date_entered BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 60 DAY)
            THEN 1
            ELSE 0
        END) AS leads_60_days,
    SUM(CASE 
        WHEN l.date_entered BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 90 DAY)
            THEN 1
            ELSE 0
        END) AS leads_90_days,
    SUM(CASE 
        WHEN l.date_entered BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 180 DAY)
            THEN 1
            ELSE 0
        END) AS leads_180_days,
    SUM(CASE 
        WHEN l.date_entered BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 365 DAY)
            THEN 1
            ELSE 0
        END) AS leads_365_days
FROM
    leads_cstm lc
        JOIN
    leads l ON lc.id_c = l.id
        JOIN
    fr_franchisee_management fm ON lc.franchise_id_c = fm.id
        JOIN
    fr_franchisee_management_cstm fmc ON fm.id = fmc.id_c

WHERE
    YEAR(l.date_entered) <= YEAR(CURDATE())
        AND YEAR(l.date_entered) >= (YEAR(CURDATE()) - 1)
        AND lc.category_c != 'nonClientLead'
        AND fm.deleted = 0
        AND fmc.fr_status_c != 2
        AND fm.name NOT LIKE '%(Duplicated)%'
        AND fm.name NOT LIKE '%(Demo)%'
        AND DATE_ADD(CURRENT_DATE, INTERVAL -18 MONTH) <= fmc.operations_start_date_c

GROUP BY
    fm.id