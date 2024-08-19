select
		fm.id as franchise_id,
    	concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,
		MAX(m.id) as consultation_id,
		m.parent_id as parent_id,
        m.date_entered as consultation_date,
		MONTH(m.date_entered) AS consultation_month,
		WEEK(m.date_entered) AS consultation_week,
        cmp.name as campaign_name,
         chc.channel as channel_name,
        lsr.lead_source as lead_source_name,
        CASE
        WHEN fmc.fr_status_c = 2 THEN 'Yes'
        ELSE 'No'
    END AS terminated_franchisee,
		CASE
			WHEN YEAR(m.date_entered) = YEAR(CURDATE()) THEN 'Current Year'
			ELSE 'Previous Year'
		END AS consultation_year,
   CASE
        WHEN DATE_ADD(CURDATE(), INTERVAL -12 MONTH) <= fmc.operations_start_date_c THEN 'Yes'
        ELSE 'No'
    END AS new_franchisee,
		CAST((CONCAT(extract(YEAR from now()), '-' , LPAD(extract(MONTH from m.date_entered),2,0), '-', LPAD(extract(DAY from m.date_entered),2,0))) AS DATE) as MMDD_date,
		case fmc.fr_region_c
			when 'usmidwst' then 'US Midwest'
            when 'emea' then 'EMEA'
            when 'ussouth' then 'US South'
            when 'usnest' then 'US Northeast'
            when 'uswst' then 'US West'
            when 'latam' then 'Latin America'
            when 'canada' then 'Canada'
            when 'usspacific' then 'US Pacific'
            when 'canada' then 'Canada'
            when '' then '--Select Region--'
            else fmc.fr_region_c
		end as Region,
        CASE WHEN COALESCE(coach.name, '') THEN 'No Coach Selected'
        WHEN '0' THEN 'No Coach Selected'
        ELSE coach.name
		END AS coach,
		case when year(m.date_entered) = YEAR(CURDATE()) then 1 else 0 end as current_year_consultation,
		case when year(m.date_entered) = (YEAR(CURDATE()) - 1) then 1 else 0 end as previous_year_consultations,
        cnc.name as franchise_country
			from
				meetings m
			join fr_franchisee_management fm
            on m.creator = fm.id
            join fr_franchisee_management_cstm fmc
            on fm.id = fmc.id_c
			left join
			coch_coach coach ON fmc.lss_ffc_c = coach.id
            JOIN user_addresses ua ON fm.id = ua.record_id and ua.address_type = 1
			left join cn_country cnc on ua.country = cnc.countrycode
            LEFT JOIN contacts c ON m.parent_id = c.id
            LEFT JOIN leads l ON c.id = l.contact_id
            LEFT JOIN leads_cstm lc ON l.id = lc.id_c
            LEFT join campaigns cmp on l.campaign_id = cmp.id
            left   join ch_channel chc on lc.channel_c = chc.channel_id
            left join nls_newleadsource lsr on lc.new_lead_source_c = lsr.lead_source_id
			where
				YEAR(m.date_entered) <= YEAR(CURDATE())
				AND YEAR(m.date_entered) >= (YEAR(CURDATE()) - 1)
				and m.status in (2, 3)
				AND fm.deleted = 0
				AND fm.name NOT LIKE '%(Duplicated)%'
				AND fm.name NOT LIKE '%(Demo)%'
			GROUP BY m.parent_id