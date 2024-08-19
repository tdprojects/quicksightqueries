select
		fm.id as franchise_id,
    	concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,
		count(m.id) as "Actual Consultations",
        ifnull(goals.consultations,0) as "Consultation Goal",
        YEAR(m.date_entered) as consultation_year,
		MONTH(m.date_entered) AS consultation_month,
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
            left join
			set_goals goals on fm.id = goals.franchise_id and MONTH(m.date_entered) = goals.month and YEAR(m.date_entered) = goals.year
			where
				YEAR(m.date_entered) >= "2022"
				AND YEAR(m.date_entered) <= "2025"
				and m.status in (2, 3)
				AND fm.deleted = 0
				AND fmc.fr_status_c != 2
				AND fm.name NOT LIKE '%(Duplicated)%'
				AND fm.name NOT LIKE '%(Demo)%'
                 group by consultation_month, franchise_name, consultation_year