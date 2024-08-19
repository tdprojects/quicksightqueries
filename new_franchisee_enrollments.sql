SELECT
    fm.id AS franchise_id,
    concat(fm.name, ' ', '(', fm.franchise_code, ')') AS franchise_name,
    Sales.sales_id,
    Sales.local_sales_amount AS sales,
    Sales.cad_sales_amount AS sales_CAD,
    Sales.sales_date,
    Sales.enrollment_type AS enrollment_type,
    month(Sales.sales_date) as sales_month,
    week(Sales.sales_date) as sales_week,
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
     SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 30 DAY)
            THEN 1
            ELSE 0
        END) AS enrollments_30_days,
	SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 60 DAY)
            THEN 1
            ELSE 0
        END) AS enrollments_60_days,
    SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 90 DAY)
            THEN 1
            ELSE 0
        END) AS enrollments_90_days,
    SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 180 DAY)
            THEN 1
            ELSE 0
        END) AS enrollments_180_days,
    SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 365 DAY)
            THEN 1
            ELSE 0
        END) AS enrollments_365_days,


SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 30 DAY)
            THEN Sales.cad_sales_amount
            ELSE 0
        END) AS sales_30_days,
	SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 60 DAY)
            THEN Sales.cad_sales_amount
            ELSE 0
        END) AS sales_60_days,
    SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 90 DAY)
            THEN Sales.cad_sales_amount
            ELSE 0
        END) AS sales_90_days,
    SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 180 DAY)
            THEN Sales.cad_sales_amount
            ELSE 0
        END) AS sales_180_days,
    SUM(CASE 
        WHEN Sales.sales_date BETWEEN fmc.operations_start_date_c AND DATE_ADD(fmc.operations_start_date_c, INTERVAL 365 DAY)
            THEN Sales.cad_sales_amount
            ELSE 0
        END) AS sales_365_days,




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
FROM
    fr_franchisee_management_cstm fmc
        JOIN
    fr_franchisee_management fm ON fmc.id_c = fm.id
        LEFT JOIN
    (SELECT
         en.id as sales_id,
         en.date_entered as sales_date,
         enc.enrollment_type_c as enrollment_type,
         ROUND(enc.enrollment_rate_c, 2) AS local_sales_amount,
         ROUND(enc.enrollment_rate_c * ifnull(er_max.conversion_rate, 1), 2)  AS cad_sales_amount,
         fm.id AS sales_fm_id
     FROM
         fr_franchisee_management fm
             INNER JOIN fr_franchisee_management_cstm fmc ON fm.id = fmc.id_c
             LEFT JOIN en_enrollment_cstm enc ON fm.id = enc.franchise_id_c
             JOIN en_enrollment en ON enc.id_c = en.id
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
    AND fm.name NOT LIKE '(Test)%'
    AND fm.name NOT LIKE '(Terminate%)%'
    AND DATE_ADD(CURRENT_DATE, INTERVAL -18 MONTH) <= fmc.operations_start_date_c

GROUP BY fm.id