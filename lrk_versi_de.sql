declare @YYYYMMDD date = eomonth(dateadd(m,-1,getdate()))
declare @JulianDate int = dbo.fn_yyyymmdd_to_julian(replace(@YYYYMMDD,'-',''))
;


WITH JHFXRT AS(
	select 
		JFXCOD
		, JFXRT8
		, JULIAN_MIS_DATE
	from HISTORY_JHFXRT
	where JULIAN_MIS_DATE = @JulianDate
)
, BIPARA11 AS (
	select DISTINCT 
		BIAGACD
		, BIAGADS
		, BIANTCD
		, BIANTDS
	from CURRENT_BIPARA11
)
, KRP AS (
	select 
		periodeData as Tanggal
		, nomorRekening 
		, tanggalMulai as Open_date
		, tanggalJatuhTempo as Mat_date
		, kualitas as BIKOLE
		, plafon as Plafon_IDR
		, bakiDebet as CBAL_IDR
		, jumlah as [O/S IDR PSAK]
		, CASE WHEN sifatKreditPembiayaan = 1 OR sifatKreditPembiayaan = 5 THEN 'YES' else 'NO' END as KET_REST
		, CASE WHEN sifatKreditPembiayaan = 5 THEN 'YES' else 'NO' END as KET_REST_Covid
		, CASE 
			WHEN kualitas > 1 THEN 'YES'
			WHEN kualitas = 1 AND sifatKreditPembiayaan = 1 THEN 'YES'
			ELSE 'NO'
		END	AS KKR
		, CASE 
			WHEN kualitas > 1 THEN 'YES'
			WHEN kualitas = 1 AND (sifatKreditPembiayaan = 1 OR sifatKreditPembiayaan = 5) THEN 'YES'
			ELSE 'NO'
		END	AS KKR_INC_COVID
		, b.BIAGACD AS KODE_SEKO
		, b.BIAGADS AS SEKTOR_EKONOMI
		, b.BIANTCD
		, b.BIANTDS
		, COALESCE (cadanganKerugianPenurunanNilaiAsetBaik, cadanganKerugianPenurunanNilaiAsetKurangBaik, cadanganKerugianPenurunanNilaiAsetTidakBaik) CKPN
	from [10.15.42.34].Antasena.krp01.kreditPembiayaanBulanan a 
	left join BIPARA11 b on a.sektorEkonomi = b.BIANTCD
)
, BASE_LNMAST_ODMAST AS (
	SELECT *
	FROM stg_host_restore.dbo.TEMP_CRMG_BASE_LNMAST
	UNION ALL 
	SELECT *
	FROM stg_host_restore.dbo.TEMP_CRMG_BASE_ODMAST
)
, JHDATA as (
	SELECT 
		A.JDBR AS KODE_CABANG
		, A.JDNAME AS NAMA_CABANG
		, C.JDNAME AS REGIONAL
		, B.JHREG as kode_reg
	FROM CURRENT_JHDATA A
	LEFT JOIN CURRENT_JHLOCA B ON A.JDBR = B.JDBR 
	LEFT JOIN CURRENT_JHDATA C ON B.JHREG = C.JDBR
	LEFT JOIN PARAM_AREA_NTOP D ON A.JDBR = D.Kode_Cabang
)
, LNMAST_ODMAST as (
	SELECT 
		a.*
		, b.NAMA_CABANG
		, b.REGIONAL
		, d.LGDESC
		, case 
			when flagging in ('PRK','KMK-FLPT') then LNACN1
			when SUBSTRING(cast([group] as varchar), 2, 1) = '6' then d.LGDESC
			when LDGRUP = 190 then c.LDNAME 
			else LNACN1
		end as NAMA_DEALER
		, case 
			when e.PTYPE is not null and e.PRDCUR is not null then 'YES'
			else 'NO'
		end	AS FLAG_JF
		, f.JFXRT8 as RATE_CURRENCY
	FROM BASE_LNMAST_ODMAST a
	LEFT JOIN JHDATA b on a.BR# = b.KODE_CABANG
	LEFT JOIN CURRENT_LNDEAL c on a.DLRNO = c.LDLNUM
	LEFT JOIN CURRENT_LNDLGP d on c.LDGRUP = d.LGDLGP 
	LEFT JOIN CURRENT_UTMPRD e on e.PTYPE = a.PRODUCT_CODE and a.CURRENCY = e.PRDCUR
	LEFT JOIN JHFXRT f on a.CURRENCY = f.JFXCOD
)
, LNMAST_ODMAST2 AS (
	SELECT 
		a.*
		, c.CKPN_Kolektif
		, '' DPD
	FROM LNMAST_ODMAST  a 
	left join stg_host_restore.dbo.TEMP_CRMG_PSCKPN c on a.ACCTNO = cast(c.PSACCT as varchar)
)
, LNGRDBDPF AS(
	SELECT 
		JULIAN_MIS_DATE
		, GRDCIF
		, GRDNUMM
	FROM HISTORY_LNGRDBDPF
	WHERE JULIAN_MIS_DATE = @JulianDate
)
, LNGRDBMPF AS(
	SELECT 
		JULIAN_MIS_DATE
		, GRDDES
		, GRDNUM
	FROM HISTORY_LNGRDBMPF
	WHERE JULIAN_MIS_DATE = @JulianDate
)
, gab as (
	SELECT  
		a.*
		, b.*
		, CASE 
			WHEN substring(cast(a.[GROUP] as varchar),2,1) = '1' THEN 'KORPORASI'
			WHEN substring(cast(a.[GROUP] as varchar),2,1) = '2' THEN 'KOMERSIL'
			WHEN substring(cast(a.[GROUP] as varchar),2,1) = '3' THEN 'UKM-KUM'
			WHEN substring(cast(a.[GROUP] as varchar),2,1) = '4' THEN 'UKM-KUK'
			WHEN substring(cast(a.[GROUP] as varchar),2,1) = '5' AND LEFT(a.PRODUCT_NAME,3) = 'KUM' THEN 'UKM-KUM'
			WHEN substring(cast(a.[GROUP] as varchar),2,1) = '5' AND LEFT(a.PRODUCT_NAME,3) = 'KUK' THEN 'UKM-KUK'
			WHEN substring(cast(a.[GROUP] as varchar),2,1) = '5' AND LEFT(a.PRODUCT_NAME,3) NOT IN ('KUM','KUK') THEN 'KONSUMER'
			WHEN substring(cast(a.[GROUP] as varchar),2,1) = '6' THEN 'FINANCING'
			WHEN LEN(b.nomorRekening) = 20 THEN 'KARTU KREDIT'
		END AS SEGMEN
		, case 
			when CAST(d.GRDNUM AS VARCHAR) is null then a.CIFNO
			WHEN LEN(b.nomorRekening) = 20 THEN ''
			else CAST(d.GRDNUM AS VARCHAR) end as KD_GRP 
		, case 
			when d.GRDDES is null then a.LNACN1
			WHEN LEN(b.nomorRekening) = 20 THEN ''
			else d.GRDDES end as NAMA_GRP 
	FROM KRP b
	left join LNMAST_ODMAST a  on a.ACCTNO  = b.nomorRekening 
	left join LNGRDBDPF c on c.GRDCIF = a.CIFNO
	left join LNGRDBMPF d on d.GRDNUM = c.GRDNUMM
)
--- point 1
, deb_inti as (
	select *
		, concat([TYPE], ' ', CCY) as codecur_debin
	from stg_host_restore.dbo.exclude_debitur_inti
)
, FLAG_DEBITUR_INTI_CBAL_PSAK AS (
	select 
		KD_GRP
		, NAMA_GRP
		, sum([O/S IDR PSAK]) as OS_PSAK
		, ROW_NUMBER () OVER (ORDER BY sum([O/S IDR PSAK]) DESC) RN 
	from gab
	where concat(PRODUCT_CODE, ' ', rtrim(currency)) not in (select codecur_debin from deb_inti)
	and LEN(nomorRekening) <> 20
	and KD_GRP <> '166'
	group by KD_GRP,NAMA_GRP
)
, PORTO as ( 
	select 
		Tanggal 
		, segmen
		, bikole
		, 'PORTFOLIO' flag
		, '' kd_grp
		, '' nama_grp
		, sum([O/S IDR PSAK]) OS
		, KET_REST, KET_REST_Covid, KKR, KKR_INC_COVID
		, sum(ckpn)ckpn
	from gab
	WHERE SEGMEN IS NOT NULL
	GROUP BY Tanggal, segmen, bikole, KET_REST, KET_REST_Covid, KKR, KKR_INC_COVID
)
, DEBITUR_INTI AS (
	select DISTINCT 
		Tanggal 
		, '' segmen
		, '' bikole
		, 'DEBITUR INTI' AS FLAG
		, a.kd_grp
		, rtrim(a.nama_grp) nama_grp
	--	, SUM([O/S IDR PSAK]) OS
		, OS_PSAK
		, '' KET_REST
		, '' KET_REST_Covid, '' KKR, '' KKR_INC_COVID
		, 0 ckpn
	FROM FLAG_DEBITUR_INTI_CBAL_PSAK C
	LEFT JOIN gab A ON C.KD_GRP = A.KD_GRP
	WHERE C.RN BETWEEN 1 AND 25
--GROUP BY Tanggal,a.kd_grp, a.nama_grp
)
SELECT *
FROM PORTO
UNION ALL
SELECT *
FROM DEBITUR_INTI