SELECT 
	a.id,
    CONVERT_TZ(ac.appointment_date_c,
		'GMT',
		fc.fr_timezone_c) AS appointment_date_c,
    ac.status_c,
    ac.session_type_c,
    ua.country AS Country,
    concat(f.name, ' ', '(', f.franchise_code, ')') AS franchise_name,
    f.id AS franchise_id,
    COALESCE(ac.duration_c/3600, 0) AS hours_delivered,
          CASE
        WHEN fc.fr_status_c = 2 THEN 'Yes'
        ELSE 'No'
    END AS terminated_franchisee,
    cnc.name as franchise_country,
       CASE
        WHEN DATE_ADD(CURDATE(), INTERVAL -12 MONTH) <= fc.operations_start_date_c THEN 'Yes'
        ELSE 'No'
    END AS new_franchisee,
    
    
CASE WHEN COALESCE(coach.name, '') THEN 'No Coach Selected'
        WHEN '0' THEN 'No Coach Selected'
        ELSE coach.name
	END AS coach
FROM
    s_session_reports AS s
        JOIN
    s_session_reports_cstm AS sc ON s.id = sc.id_c
        JOIN
    a_appointment_cstm AS ac ON ac.id_c = sc.appointment_id_c
        JOIN
    a_appointment AS a ON ac.id_c = a.id
        LEFT JOIN
    fr_franchisee_management f ON ac.franchise_id_c = f.id
        LEFT JOIN
    fr_franchisee_management_cstm fc ON f.id = fc.id_c
        LEFT JOIN
    coch_coach coach ON fc.lss_ffc_c = coach.id
        left join
    user_addresses ua ON f.id = ua.record_id AND ua.address_type = 1
        LEFT JOIN 
	cn_country cnc on ua.country = cnc.countrycode
WHERE
        YEAR(CONVERT_TZ(ac.appointment_date_c,	'GMT',
		fc.fr_timezone_c)) >= (YEAR(CURDATE()))
        AND ac.status_c IN ('Report Approved' , 'Report Submitted')
        AND fc.first_name_c NOT LIKE '%(Duplicated%'
        AND fc.first_name_c NOT LIKE '%(Test%'
        AND fc.first_name_c NOT LIKE '%(Demo%'
        AND a.deleted = 0
        

limit 9000000