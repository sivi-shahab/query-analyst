-- 10.15.42.96 table stg_host.dbo.current_nls_request_cc
with total_los (
SELECT 
    datecreated::date AS request_date,  -- Extract date part
    datecreated::time AS request_time,  -- Extract time part
    reff_id AS request_id,
    LEFT(reff_id, 3) AS REFF_ID,        -- Take first 3 characters of reff_id
    CASE 
        WHEN LENGTH(cust_id) > 8 THEN CONCAT(
            LEFT(cust_id, 4),
            REPEAT('x', LENGTH(cust_id) - 8),
            RIGHT(cust_id, 4)
        )
        ELSE cust_id
    END AS request_nik,                 -- Masked customer_id as request_nik
    COALESCE(vida_biometric::text, '0.00000') AS score -- Replace NULL with '0' as text
FROM 
    adhoc.acss_los_jan_2025
ORDER BY 
    datecreated ASC
) SELECT COUNT(*) total_los;



-- 10.11.88.218 table obd.obd.user 
WITH total_obd AS (
    SELECT 
        flag_date::date AS request_date,  -- Extract date part
        flag_date::time AS request_time,  -- Extract time part
        id AS request_id,
        LEFT(id, 3) AS REFF_ID,        -- Take first 3 characters of reff_id
        CASE 
            WHEN LENGTH(nik) > 8 THEN CONCAT(
                LEFT(nik, 4),
                REPEAT('x', LENGTH(nik) - 8),
                RIGHT(nik, 4)
            )
            ELSE nik
        END AS request_nik,                 -- Masked customer_id as request_nik
        COALESCE(asliri::text, '0.00000') AS score -- Replace NULL with '0' as text
    FROM 
        public."acss_obd_Dec_2024"
    ORDER BY 
        flag_date ASC
)
SELECT COUNT(*) FROM total_obd;


-- 10.14.18.146 validasi_ocr_liveness

WITH total_liveness (SELECT 
    created_date::date AS request_date,  -- Extract date part
    created_date::time AS request_time,  -- Extract time part
    keyno AS request_id,
    LEFT(keyno, 3) AS REFF_ID,        -- Take first 3 characters of reff_id
    CASE 
        WHEN LENGTH(nik) > 8 THEN CONCAT(
            LEFT(nik, 4),
            REPEAT('x', LENGTH(nik) - 8),
            RIGHT(nik, 4)
        )
        ELSE nik
    END AS request_nik,                 -- Masked customer_id as request_nik
    COALESCE(score_biometric::text, '0.00000') AS score -- Replace NULL with '0' as text
FROM 
    adhoc.validasi_ocr_liveness_manaf
ORDER BY 
    created_date ASC;
) SELECT COUNT(*) total_liveness;