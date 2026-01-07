--step 1 running dari 218 stg_host
select DISTINCT a.CIFNO
into STG_HOST_RESTORE.DBO.CIFMOJF_manaf
from [10.11.88.218].[stg_host].[dbo].CURRENT_LNMAST a
LEFT JOIN [10.11.88.218].[stg_host].[dbo].CURRENT_CFAcct b on a.CIFNO = b.CFCIF# AND CFATYP IN ('S', 'D')
WHERE a.DLRGP in (407, 408, 409)
AND b.CFCIF# is null

drop table STG_HOST_RESTORE.DBO.CIFMOJF_manaf


--step 2 running dari 218 stg_host (adjust CFORGD)
WITH BASE1 AS (
SELECT 
	'303' as ID_PJK,
	'1' as Kode_Nasabah,
	a.cfna1 as Nama_Nasabah,
	a.cfybip as Tempat_Lahir,
	CAST(dbo.fn_julian_to_date(CASE 
		WHEN RIGHT(CONVERT(VARCHAR, cfbir6), 2) < '20' THEN 
			CONCAT(CONCAT('20', RIGHT(CONVERT(VARCHAR, cfbir6), 2)), SUBSTRING(CONVERT(VARCHAR, cfbird), 5, 3))
		ELSE 
			CONCAT(CONCAT('19', RIGHT(CONVERT(VARCHAR, cfbir6), 2)), SUBSTRING(CONVERT(VARCHAR, cfbird), 5, 3))
	END ) as DATE) as Tanggal_Lahir,
	REPLACE((select CONCAT(b.cfna2, ' ' , b.cfna3, ' ', b.cfna4)), '00001', '') as Alamat,
	REPLACE(a.cfssno, '*', '') as Nomor_Identitas,
	'-' as Nomor_Identitas_Lain, 
	a.CFCIF# as Nomor_CIF, 
	'-' as Nomor_NPWP,
	CAST(dbo.fn_julian_to_date(a.cforgd) as DATE) as open_date
  FROM [10.11.88.218].[stg_host].[dbo].CURRENT_CFMAST a
  left join [10.11.88.218].[stg_host].[dbo].CURRENT_CFADDR b on a.CFCIF# = b.cfcif#
  inner JOIN STG_HOST_RESTORE.DBO.CIFMOJF_manaf c on a.CFCIF# = c.CIFNO 
  WHERE CFORGD BETWEEN dbo.fn_date_to_julian('2025-12-01') AND dbo.fn_date_to_julian('2025-12-31')
  AND a.CFCLAS = 'I'
  AND b.CFASEQ = '1'
--  AND c.CIFNO is null
)
, BASE2 AS (
SELECT 
	'303' as ID_PJK,
	'2' as Kode_Nasabah,
	a.cfna1 as Nama_Nasabah,
	'-' as Tempat_Lahir,
	cast(null as date) as Tanggal_Lahir,
	REPLACE((select CONCAT(b.cfna2, ' ' , b.cfna3, ' ', b.cfna4)), '00001', '') as Alamat,
	REPLACE(a.cfssno, '*', '') as Nomor_Identitas,
	'-' as Nomor_Identitas_Lain, 
	a.CFCIF# as Nomor_CIF, 
	d.cfssno as Nomor_NPWP, 
	CAST(dbo.fn_julian_to_date(a.cforgd) as DATE) as open_date
  FROM [10.11.88.218].[stg_host].[dbo].CURRENT_CFMAST a
  left join [10.11.88.218].[stg_host].[dbo].CURRENT_CFADDR b on a.CFCIF# = b.cfcif#
  inner JOIN STG_HOST_RESTORE.DBO.CIFMOJF_manaf c on a.CFCIF# = c.CIFNO 
  left join (select CFCIF#, CFSSNO from [10.11.88.218].[stg_host].[dbo].current_cfaidn where cfsscd = 'NP' group by CFCIF#,cfssno) d on a.CFCIF# = d.CFCIF#
  WHERE CFORGD BETWEEN dbo.fn_date_to_julian('2025-12-01') AND dbo.fn_date_to_julian('2025-12-31')
  AND a.CFCLAS <> 'I'
  AND b.CFASEQ = '1'
--  AND c.CIFNO is null
)
SELECT *
FROM BASE1
UNION ALL
SELECT *
FROM BASE2

where NOMOR_CIF = 'DC68200'


select *
from CURRENT_CFAIDN cc 
where CFSSCD = 'NP'