Select gj.date_entered, gj.id, gj_job_match_status_c, gj.description, gj_tutor_match_status, ffm.id AS franchise_id,
    concat(ffm.name, ' ', '(', ffm.franchise_code, ')') AS franchise_name from jobs_global gj
LEFT JOIN jobs_global_cstm gjc ON gj.id = id_c
LEFT join en_enrollment en ON gj.gj_enrollment_id = en.id
LEFT JOIN en_enrollment_cstm enc on en.id = enc.id_c
LEFT JOIN fr_franchisee_management ffm ON enc.franchise_id_c = ffm.id
WHERE ffm.deleted = 0
        AND ffm.name NOT LIKE '%(Duplicated)%'
        AND ffm.name NOT LIKE '%(Demo)%'