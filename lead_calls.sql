SELECT 
    l.id as lead_call_id,
    l.title,
    l.phone_mobile,
    l.primary_address_state,
    l.primary_address_city,
    c.id as contact_id, 
    llc.id as lead_cstm_call_id,
    lc.channel_c,
    lc.id_c,
    lc.source_c,
    lcr.start_time_c,
    CONCAT(f.first_name_c, ' ', f.last_name_c) as franchise_name,
    enc.id_c as enrollment_id
FROM 
    `lcm_leadcalls` l
LEFT JOIN 
    `lcm_leadcalls_contacts_1_c` llc ON l.id = llc.lcm_leadcalls_contacts_1lcm_leadcalls_ida
JOIN 
    `lcm_leadcalls_cstm` lc ON l.id = lc.id_c
LEFT JOIN 
    `fr_franchisee_management_cstm` f ON lc.franchise_id_c = f.id_c
LEFT JOIN fr_franchisee_management fm ON fm.id = f.id_c
JOIN 
    `lcm_leadcalls_recordings` lcr ON l.id = lcr.record_id
join contacts c ON c.id = llc.lcm_leadcalls_contacts_1contacts_idb 
left join en_enrollment_cstm enc ON c.id = enc.contact_iid_c

where 
    fm.deleted = 0
    AND fm.name NOT LIKE '%(Duplicated)%'
    AND fm.name NOT LIKE '%(Demo)%'