select
	et.id as revenue_id,
    fm.id AS franchise_id,
    concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,
	sum(et.amount) as "Revenue Actual",
	ifnull(goals.revenue,0) as "Revenue Goal",
    sum(COALESCE(etc.rev_amt_c * er_current_month.conversion_rate, etc.rev_amt_c * er_max.conversion_rate)) AS revenue_CAD,
    sum(etc.rev_amt_c) as revenue,
	COALESCE(goals.revenue * er_current_month.conversion_rate, goals.revenue * er_max.conversion_rate) AS revenue_goal_CAD,	
    MONTH(CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c)) AS revenue_month,
    WEEK(CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c)) AS revenue_week,
    year(CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c)) AS revenue_year,
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
    cnc.name as franchise_country
from
	et_enrollment_transaction et 
	join et_enrollment_transaction_cstm etc on etc.id_c = et.id
	join fr_franchisee_management_cstm fmc on fmc.id_c = et.franchise_id
	join fr_franchisee_management fm on fmc.id_c = fm.id
    LEFT JOIN
        coch_coach coach ON fmc.lss_ffc_c = coach.id
    left join
		currencies c ON c.id = fmc.currency_c
	LEFT JOIN
        er_exchange_rate er_current_month
        ON er_current_month.currency_id = fmc.currency_c
            AND er_current_month.effective_start_date = (
                SELECT MAX(effective_start_date)
                FROM er_exchange_rate
                WHERE currency_id = fmc.currency_c
                    AND (
                        (MONTH(effective_start_date) = MONTH(etc.payement_date_c) AND YEAR(effective_start_date) = YEAR(etc.payement_date_c))
                        OR
                        (MONTH(effective_start_date) = MONTH(etc.payement_date_c) - 1 AND YEAR(effective_start_date) = YEAR(etc.payement_date_c))
                    )
                ORDER BY YEAR(effective_start_date) DESC, MONTH(effective_start_date) DESC
                LIMIT 1
            )
    LEFT JOIN
        er_exchange_rate er_max
        ON er_max.currency_id = fmc.currency_c
            AND er_max.effective_start_date = (
                SELECT MAX(effective_start_date)
                FROM er_exchange_rate
                WHERE currency_id = er_max.currency_id
            )
    LEFT JOIN
	user_addresses ua on fm.id = ua.record_id and ua.address_type = 1
		join 
	cn_country cnc on ua.country = cnc.countrycode
		left join
	set_goals goals on fm.id = goals.franchise_id and MONTH(et.date_entered) = goals.month and YEAR(et.date_entered) = goals.year
where
						
    YEAR((CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c))) <= YEAR(CURDATE())
    AND YEAR((CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c))) >= (YEAR(CURDATE()) - 1)
	AND et.deleted = 0
	AND et.amount != 0
	AND et.status NOT IN ('adjustment' , 'discount_applied', 'discount_reversed')
	AND et.transaction_id IS NULL
	AND et.payment_method != 'unspecified'
    AND fm.deleted = 0
	AND fmc.fr_status_c != 2
	AND fm.name NOT LIKE '%(Duplicated)%'
	AND fm.name NOT LIKE '%(Demo)%'
        group by 
		    fm.id, 
    YEAR(CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c)), 
    MONTH(CONVERT_TZ(etc.payement_date_c, 'GMT', fmc.fr_timezone_c))