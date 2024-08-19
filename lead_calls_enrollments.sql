select     CONCAT(f.first_name_c, ' ', f.last_name_c) as franchise_name, enc.id_c as enrollment_id, enc.franchise_id_c as franchisee_id  from lcm_leadcalls_contacts_1_c llc
left join contacts c ON c.id = llc.lcm_leadcalls_contacts_1contacts_idb 
left join en_enrollment_cstm enc ON c.id = enc.contact_iid_c
LEFT JOIN  `fr_franchisee_management_cstm` f ON enc.franchise_id_c = f.id_c
LEFT JOIN fr_franchisee_management fm ON fm.id = f.id_c
where 
    fm.deleted = 0
    AND fm.name NOT LIKE '%(Duplicated)%'
    AND fm.name NOT LIKE '%(Demo)%'