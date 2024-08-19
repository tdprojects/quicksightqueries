select request_date, sent, completed, survey_value as 'score', response_text, response_time as 'response_date', raw_name as client_name, opted_out, c.name as franchisee_country, cf.name as franchisee_name from  customer_response cr
LEFT JOIN  customers_survey_request csr ON cr.customers_survey_request_id = csr.id 
LEFT JOIN customer_profile cp ON csr.customer_profile_id = cp.id
LEFT JOIN client_franchises cf ON cp.franchise_id = cf.franchise_id 
LEFT JOIN countries c ON cf.country = c.id
WHERE cf.name NOT LIKE '%(demo)%'
	AND cf.name NOT LIKE '%(Terminated)%'
	AND cf.name NOT LIKE '%(Duplicated)%'
    AND year(request_date) > 2021