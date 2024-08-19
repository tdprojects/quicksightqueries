SELECT 
    l.id AS lead_id,
    l.date_entered,
    ifnull(goals.leads,0) as "Leads Goal",
    fm.id AS franchise_id,
    fmc.operations_start_date_c as operations_start_date,
    concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,
    MONTH(l.date_entered) AS lead_month,
    WEEK(l.date_entered) AS lead_week,
    cmp.name as campaign_name,
    chc.channel as channel_name,
    lsr.lead_source as lead_source_name,
    CASE
        WHEN YEAR(l.date_entered) = YEAR(CURDATE()) THEN 'Current Year'
        ELSE 'Previous Year'
    END AS lead_year,
    CAST((CONCAT(extract(YEAR from now()), '-' , LPAD(extract(MONTH from l.date_entered),2,0), '-', LPAD(extract(DAY from l.date_entered),2,0))) AS DATE) as MMDD_date,
    CASE WHEN COALESCE(coach.name, '') THEN 'No Coach Selected'
        WHEN '0' THEN 'No Coach Selected'
        ELSE coach.name
    END AS coach,
          CASE
        WHEN fmc.fr_status_c = 2 THEN 'Yes'
        ELSE 'No'
    END AS terminated_franchisee,
    case when year(l.date_entered) = YEAR(CURDATE()) then 1 else 0 end as current_year_leads,
    case when year(l.date_entered) = (YEAR(CURDATE()) - 1) then 1 else 0 end as previous_year_leads,
    cnc.name as franchise_country,
   CASE
        WHEN DATE_ADD(CURDATE(), INTERVAL -12 MONTH) <= fmc.operations_start_date_c THEN 'Yes'
        ELSE 'No'
    END AS new_franchisee
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
    LEFT join
    campaigns cmp on l.campaign_id = cmp.id
	left   join
    ch_channel chc on lc.channel_c = chc.channel_id
    left   join
    nls_newleadsource lsr on lc.new_lead_source_c = lsr.lead_source_id
    left join
	set_goals goals on fm.id = goals.franchise_id and MONTH(l.date_entered) = goals.month and YEAR(l.date_entered) = goals.year
WHERE
    YEAR(l.date_entered) <= YEAR(CURDATE())
        AND YEAR(l.date_entered) >= (YEAR(CURDATE()) - 1)
        AND lc.category_c != 'nonClientLead'
        AND fm.deleted = 0
        AND fm.name NOT LIKE '%(Duplicated)%'
        AND fm.name NOT LIKE '%(Demo)%'