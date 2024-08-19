SELECT 
    fm.id AS franchise_id, 
    concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name, 
    Sales.sales_id, 
    Sales.local_sales_amount AS sales, 
    Sales.conversion_rate as conversion_rate, 
    Sales.cad_sales_amount AS sales_CAD, 
    Sales.sales_date, 
    Sales.enrollment_type AS enrollment_type, 
    month(Sales.sales_date) as sales_month, 
    week(Sales.sales_date) as sales_week, 
    CASE WHEN DATE_ADD(CURDATE(), INTERVAL -12 MONTH) <= fmc.operations_start_date_c THEN 'Yes' ELSE 'No' END AS new_franchisee, 
    CASE WHEN YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN 'Current Year' ELSE 'Previous Year' END AS sales_year, 
    CAST((CONCAT(EXTRACT(YEAR FROM NOW()), '-', LPAD(EXTRACT(MONTH FROM CONVERT_TZ(Sales.sales_date, 'GMT', fmc.fr_timezone_c)), 2, '0'), '-', LPAD(EXTRACT(DAY FROM CONVERT_TZ(Sales.sales_date, 'GMT', fmc.fr_timezone_c)), 2, '0'))) AS DATE) AS MMDD_date, 
    CASE fmc.fr_region_c WHEN 'usmidwst' THEN 'US Midwest' WHEN 'emea' THEN 'EMEA' WHEN 'ussouth' THEN 'US South' WHEN 'usnest' THEN 'US Northeast' WHEN 'uswst' THEN 'US West' WHEN 'latam' THEN 'Latin America' WHEN 'canada' THEN 'Canada' WHEN 'usspacific' THEN 'US Pacific' WHEN 'canada' THEN 'Canada' WHEN '' THEN '--Select Region--' ELSE fmc.fr_region_c END AS Region, 
    CASE WHEN fmc.fr_status_c = 2 THEN 'Yes' ELSE 'No' END AS terminated_franchisee, 
    CASE WHEN COALESCE(coach.name, '') THEN 'No Coach Selected' WHEN '0' THEN 'No Coach Selected' ELSE coach.name END AS coach, 
    CASE WHEN YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN 1 ELSE 0 END AS current_year_sales_count, 
    CASE WHEN YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN 1 ELSE 0 END AS previous_year_sales_count, 
    CASE WHEN Sales.enrollment_type = 'New' AND YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN 1 ELSE 0 END AS new_enrollments_current_year, 
    CASE WHEN Sales.enrollment_type = 'New' AND YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN 1 ELSE 0 END AS new_enrollments_previous_year, 
    CASE WHEN Sales.enrollment_type = 'Renewal' AND YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN 1 ELSE 0 END AS renew_enrollments_current_year, 
    CASE WHEN Sales.enrollment_type = 'Renewal' AND YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN 1 ELSE 0 END AS renew_enrollments_previous_year, 
    CASE WHEN YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN Sales.local_sales_amount ELSE 0 END AS current_year_sales_total, 
    CASE WHEN YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN Sales.local_sales_amount ELSE 0 END AS previous_year_sales_total, 
    CASE WHEN YEAR(Sales.sales_date) = YEAR(CURDATE()) THEN Sales.cad_sales_amount ELSE 0 END AS current_year_sales_total_CAD, 
    CASE WHEN YEAR(Sales.sales_date) = (YEAR(CURDATE()) - 1) THEN Sales.cad_sales_amount ELSE 0 END AS previous_year_sales_total_CAD, 
    cnc.name as franchise_country 
FROM 
    fr_franchisee_management_cstm fmc 
JOIN 
    fr_franchisee_management fm ON fmc.id_c = fm.id 
LEFT JOIN 
    (
        SELECT 
            en.id as sales_id, 
            en.date_entered as sales_date, 
            enc.enrollment_type_c as enrollment_type, 
            COALESCE(er_current_month.conversion_rate, er_previous_month.conversion_rate) as conversion_rate, 
            ROUND(enc.enrollment_rate_c, 2) AS local_sales_amount, 
            ROUND(enc.enrollment_rate_c * COALESCE(er_current_month.conversion_rate, er_previous_month.conversion_rate), 2) AS cad_sales_amount, 
            fm.id AS sales_fm_id 
        FROM 
            fr_franchisee_management fm 
        INNER JOIN 
            fr_franchisee_management_cstm fmc ON fm.id = fmc.id_c 
        LEFT JOIN 
            en_enrollment_cstm enc ON fm.id = enc.franchise_id_c 
        JOIN 
            en_enrollment en ON enc.id_c = en.id 
        LEFT JOIN 
            er_exchange_rate er_current_month ON er_current_month.currency_id = fmc.currency_c AND er_current_month.effective_start_date = ( SELECT MAX(effective_start_date) FROM er_exchange_rate WHERE currency_id = fmc.currency_c AND MONTH(effective_start_date) = MONTH(en.date_entered) AND YEAR(effective_start_date) = YEAR(en.date_entered) ) 
        LEFT JOIN 
            er_exchange_rate er_previous_month ON er_previous_month.currency_id = fmc.currency_c AND er_previous_month.effective_start_date = ( SELECT MAX(effective_start_date) FROM er_exchange_rate WHERE currency_id = er_previous_month.currency_id AND MONTH(effective_start_date) = MONTH(DATE_SUB(en.date_entered, INTERVAL 1 MONTH)) AND YEAR(effective_start_date) = YEAR(DATE_SUB(en.date_entered, INTERVAL 1 MONTH)) ) 
        WHERE 
            YEAR((CONVERT_TZ(en.date_entered, "GMT", fmc.fr_timezone_c))) <= YEAR(CURDATE()) AND YEAR((CONVERT_TZ(en.date_entered, "GMT", fmc.fr_timezone_c))) >= (YEAR(CURDATE()) - 1) 
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
    AND fm.name NOT LIKE '(Test)%'