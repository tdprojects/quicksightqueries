SELECT
    fm.id AS franchise_id,
    concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,
    Sales.sales_id,
    Sales.local_sales_amount AS sales,
    Sales.cad_sales_amount AS sales_CAD,
    Sales.sales_date,
    Sales.enrollment_type AS enrollment_type,
    Sales.lead_source_name,
    Sales.channel_name,
    Sales.campaign_name,
    month(Sales.sales_date) as sales_month,
    week(Sales.sales_date) as sales_week,
       CASE
        WHEN DATE_ADD(CURDATE(), INTERVAL -12 MONTH) <= fmc.operations_start_date_c THEN 'Yes'
        ELSE 'No'
    END AS new_franchisee,
          CASE
        WHEN fmc.fr_status_c = 2 THEN 'Yes'
        ELSE 'No'
    END AS terminated_franchisee,
 
    CASE
        WHEN YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN 'Current Year'
        ELSE 'Previous Year'
        END AS sales_year,
      CAST((CONCAT(EXTRACT(YEAR FROM NOW()),
            '-',
            LPAD(EXTRACT(MONTH FROM CONVERT_TZ(Sales.sales_date, 'GMT', fmc.fr_timezone_c)), 2, '0'),
            '-',
            LPAD(EXTRACT(DAY FROM CONVERT_TZ(Sales.sales_date, 'GMT', fmc.fr_timezone_c)), 2, '0')))
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
        WHEN YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN 1
        ELSE 0
        END AS current_year_sales_count,
    CASE
        WHEN YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN 1
        ELSE 0
        END AS previous_year_sales_count,
    CASE 
        WHEN Sales.enrollment_type = 'New' AND YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN 1
        ELSE 0 
    END AS new_enrollments_current_year,
    CASE 
        WHEN Sales.enrollment_type = 'New' AND YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN 1
        ELSE 0 
    END AS new_enrollments_previous_year,
    CASE 
        WHEN Sales.enrollment_type = 'Renewal' AND YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN 1
        ELSE 0 
    END AS renew_enrollments_current_year,
    CASE 
        WHEN Sales.enrollment_type = 'Renewal' AND YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN 1
        ELSE 0 
    END AS renew_enrollments_previous_year,
    CASE
        WHEN YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN Sales.local_sales_amount
        ELSE 0
        END AS current_year_sales_total,
    CASE
        WHEN YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN Sales.local_sales_amount
        ELSE 0
        END AS previous_year_sales_total,
    CASE
        WHEN YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN Sales.cad_sales_amount
        ELSE 0
        END AS current_year_sales_total_CAD,
    CASE
        WHEN YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN Sales.cad_sales_amount
        ELSE 0
        END AS previous_year_sales_total_CAD,
    cnc.name as franchise_country
FROM
    fr_franchisee_management_cstm fmc
        JOIN
    fr_franchisee_management fm ON fmc.id_c = fm.id
        LEFT JOIN
    (SELECT
         en.id as sales_id,
         en.date_entered as sales_date,
         lsr.lead_source as lead_source_name,
         cmp.name as campaign_name,
         chc.channel as channel_name,
         enc.enrollment_type_c as enrollment_type,
         ROUND(enc.enrollment_rate_c, 2) AS local_sales_amount,
         ROUND(enc.enrollment_rate_c * ifnull(er_max.conversion_rate, 1), 2)  AS cad_sales_amount,
         fm.id AS sales_fm_id
        
     FROM
         fr_franchisee_management fm
             INNER JOIN fr_franchisee_management_cstm fmc ON fm.id = fmc.id_c
             LEFT JOIN en_enrollment_cstm enc ON fm.id = enc.franchise_id_c
             JOIN en_enrollment en ON enc.id_c = en.id
             LEFT JOIN contacts c ON enc.contact_iid_c = c.id
             LEFT JOIN leads l ON c.id = l.contact_id
             LEFT JOIN leads_cstm lc ON l.id = lc.id_c
             LEFT join campaigns cmp on l.campaign_id = cmp.id
             left   join ch_channel chc on lc.channel_c = chc.channel_id
            left join nls_newleadsource lsr on lc.new_lead_source_c = lsr.lead_source_id
             LEFT JOIN (SELECT
                            currency_id, MAX(date_modified), conversion_rate
                        FROM
                            er_exchange_rate
                        WHERE
                                effective_start_date = '2021-05-01'
                        GROUP BY currency_id) er_max ON er_max.currency_id = fmc.currency_c
     WHERE
        YEAR((CONVERT_TZ(en.date_entered,
                "GMT",
                fmc.fr_timezone_c))) <= YEAR(CURDATE())
        AND YEAR((CONVERT_TZ(en.date_entered,
                "GMT",
                fmc.fr_timezone_c))) >= (YEAR(CURDATE()) - 1)
    ) Sales ON fm.id = sales_fm_id
        LEFT JOIN
    currencies c ON c.id = fmc.currency_c
        JOIN
    user_addresses ua ON fm.id = ua.record_id and ua.address_type = 1
        left join
    cn_country cnc on ua.country = cnc.countrycode
        LEFT JOIN
    coch_coach coach ON fmc.lss_ffc_c = coach.id
WHERE
    YEAR((CONVERT_TZ(Sales.sales_date, 'GMT', fmc.fr_timezone_c))) <= YEAR(CURDATE())
    AND YEAR((CONVERT_TZ(Sales.sales_date, 'GMT', fmc.fr_timezone_c))) >= (YEAR(CURDATE()) - 1)
    AND fm.name NOT LIKE '(Demo)%'
    AND fm.name NOT LIKE '(Test)%'