SELECT 
    count(l.id) AS "Leads Actual",
    ifnull(goals.leads,0) as "Leads Goal",
    fm.id AS franchise_id,
    concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,
    MONTH(l.date_entered) AS lead_month,
	YEAR(l.date_entered) AS lead_year, 
   CASE WHEN COALESCE(coach.name, '') THEN 'No Coach Selected'
        WHEN '0' THEN 'No Coach Selected'
        ELSE coach.name
    END AS coach,
    cnc.name as franchise_country
FROM
    leads_cstm lc
        JOIN
    leads l ON lc.id_c = l.id
        JOIN
    fr_franchisee_management fm ON lc.franchise_id_c = fm.id
        JOIN
    fr_franchisee_management_cstm fmc ON fm.id = fmc.id_c
        left join
    coch_coach coach ON fmc.lss_ffc_c = coach.id
        left join
	user_addresses ua on fm.id = ua.record_id and ua.address_type = 1
		join 
	cn_country cnc on ua.country = cnc.countrycode
		left join
	set_goals goals on fm.id = goals.franchise_id and MONTH(l.date_entered) = goals.month and YEAR(l.date_entered) = goals.year
WHERE
		YEAR(l.date_entered) >= '2022'
        AND YEAR(l.date_entered) < '2025'
        AND lc.category_c != 'nonClientLead'
        AND fm.deleted = 0
        AND fmc.fr_status_c != 2
        AND fm.name NOT LIKE '%(Duplicated)%'
        AND fm.name NOT LIKE '%(Demo)%'
        group by lead_month, franchise_name, lead_year