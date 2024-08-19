select
	et.id as revenue_id,
    fm.id AS franchise_id,
    concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,	
    lc.sector_c,
    enc.id_c,
    etc.rev_amt_c as revenue,
    et.amount * er.conversion_rate AS revenue_CAD,
	etc.payement_date_c AS revenue_date,
    CONVERT_TZ(etc.payement_date_c,
		'GMT',
		fmc.fr_timezone_c) AS revenue_test,
	MONTH(etc.payement_date_c) AS revenue_month,
    WEEK(etc.payement_date_c) AS revenue_week,
	CASE
        WHEN YEAR(etc.payement_date_c) = YEAR(CURDATE()) THEN 'Current Year'
        ELSE 'Previous Year'
    END AS revenue_year,
CAST((CONCAT(EXTRACT(YEAR FROM NOW()),
            '-',
            LPAD(EXTRACT(MONTH FROM CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c)), 2, '0'),
            '-',
            LPAD(EXTRACT(DAY FROM CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c)), 2, '0')))
     AS DATE) AS MMDD_date,
	CASE fmc.fr_region_c
        WHEN 'usmidwst' THEN 'US Midwest'
        WHEN 'emea' THEN 'EMEA'
        WHEN 'ussouth' THEN 'US South'
        WHEN 'usnest' THEN 'US Northeast'
        WHEN 'uswst' THEN 'US West'
        WHEN 'latam' THEN 'Latin America'
        WHEN 'canada' THEN 'Canada'
        WHEN 'usspacific' THEN 'US Pacific'
        WHEN 'canada' THEN 'Canada'
        WHEN '' THEN '--Select Region--'
        ELSE fmc.fr_region_c
    END AS Region,
	 CASE WHEN COALESCE(coach.name, '') THEN 'No Coach Selected'
        WHEN '0' THEN 'No Coach Selected'
        ELSE coach.name
    END AS coach,
    CASE
        WHEN YEAR(etc.payement_date_c) = YEAR(CURDATE()) THEN etc.rev_amt_c
        ELSE 0
    END AS current_year_revenue,

    CASE
        WHEN sector_c = 1 AND YEAR(etc.payement_date_c) = YEAR(CURDATE()) THEN etc.rev_amt_c 
        ELSE 0
    END AS b2b_current_year,
    CASE
        WHEN sector_c = 1  AND YEAR(et.date_entered) = (YEAR(CURDATE()) - 1) THEN etc.rev_amt_c
        ELSE 0
    END AS b2b_previous_year,
    
        CASE
        WHEN YEAR(etc.payement_date_c) = (YEAR(CURDATE()) - 1) THEN et.amount
        ELSE 0
    END AS previous_year_revenue,
    CASE
        WHEN sector_c = 2 AND YEAR(etc.payement_date_c) = YEAR(CURDATE()) THEN etc.rev_amt_c
        ELSE 0
    END AS b2c_current_year,
    CASE
        WHEN sector_c = 2  AND YEAR(et.date_entered) = (YEAR(CURDATE()) - 1) THEN etc.rev_amt_c
        ELSE 0
    END AS b2c_previous_year,
CASE
    WHEN (sector_c IS NULL OR sector_c = '') AND YEAR(etc.payement_date_c) = YEAR(CURDATE()) THEN etc.rev_amt_c
    ELSE 0
END AS other_current_year,
    
CASE
    WHEN (sector_c IS NULL OR sector_c = '') AND YEAR(etc.payement_date_c) = YEAR(CURDATE()-1) THEN etc.rev_amt_c
    ELSE 0
END AS other_previous_year,
    
    
    cnc.name as franchise_country
from
	et_enrollment_transaction et 
	join et_enrollment_transaction_cstm etc on etc.id_c = et.id
    LEFT JOIN en_enrollment_cstm enc ON et.enrollment_id = enc.id_c
    LEFT JOIN contacts con ON enc.contact_iid_c = con.id
    LEFT JOIN leads l ON con.id = l.contact_id
    LEFT JOIN leads_cstm lc ON l.id = lc.id_c
	join fr_franchisee_management_cstm fmc on fmc.id_c = et.franchise_id
	join fr_franchisee_management fm on fmc.id_c = fm.id
    LEFT JOIN
        coch_coach coach ON fmc.lss_ffc_c = coach.id
    left join
		currencies c ON c.id = fmc.currency_c
	LEFT JOIN
    (SELECT 
        currency_id, MAX(date_modified) AS date_modified
    FROM
        er_exchange_rate
    GROUP BY currency_id) er_max ON er_max.currency_id = fmc.currency_c
        LEFT JOIN
    er_exchange_rate er ON er.date_modified = er_max.date_modified
        AND er.currency_id = er_max.currency_id
        left join
	user_addresses ua on fm.id = ua.record_id and ua.address_type = 1
		join 
	cn_country cnc on ua.country = cnc.countrycode
where
						
	YEAR((CONVERT_TZ(etc.payement_date_c,
		'GMT',
		fmc.fr_timezone_c))) <= YEAR(CURDATE())
	AND YEAR((CONVERT_TZ(etc.payement_date_c,
		'GMT',
		fmc.fr_timezone_c))) >= (YEAR(CURDATE()) - 1)
	AND et.deleted = 0
	AND et.amount != 0
	AND et.status NOT IN ('adjustment' , 'discount_applied', 'discount_reversed')
	AND et.transaction_id IS NULL
	AND et.payment_method != 'unspecified'
    AND fm.deleted = 0
	AND fmc.fr_status_c != 2
    AND ua.country = 'UK'
	AND fm.name NOT LIKE '%(Duplicated)%'
	AND fm.name NOT LIKE '%(Demo)%'