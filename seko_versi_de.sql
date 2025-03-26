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
, deb_inti AS (
    SELECT *,
           CONCAT([TYPE], ' ', CCY) AS codecur_debin
    FROM stg_host_restore.dbo.exclude_debitur_inti
),
FLAG_DEBITUR_INTI_CBAL AS (
    SELECT 
        KD_GRP,
        NAMA_GRP,
        SUM(CBAL_IDR) AS OS_IDR,
        ROW_NUMBER() OVER (ORDER BY SUM(CBAL_IDR) DESC) RN 
    FROM gab
    WHERE CONCAT(PRODUCT_CODE, ' ', RTRIM(currency)) NOT IN (SELECT codecur_debin FROM deb_inti)
      AND LEN(nomorRekening) <> 20
      AND KD_GRP <> '166' // exclude group bukan kode_group 166
    GROUP BY KD_GRP, NAMA_GRP
),
DEBITUR_INTI AS (
    SELECT DISTINCT
        a.Tanggal,
        a.segmen,
        a.bikole,
        SUM(a.CBAL_IDR) AS OS_IDR,
        CASE 
            WHEN CAST(b.KD_GRP AS VARCHAR) <> '166' 
                 AND CONCAT(a.PRODUCT_CODE, ' ', RTRIM(a.currency)) NOT IN (SELECT codecur_debin FROM deb_inti) 
                 AND b.RN BETWEEN 1 AND 25 THEN 'DEBITUR_INTI'
            ELSE 'SEKO'
        END AS FLAG,
        a.KODE_SEKO,
        a.SEKTOR_EKONOMI AS SEKO,
        '' AS KET_REST,
        '' AS KET_REST_Covid,
        a.kd_grp,
        a.nama_grp
    FROM gab a
    LEFT JOIN FLAG_DEBITUR_INTI_CBAL b ON a.KD_GRP = b.KD_GRP
    GROUP BY 
        a.Tanggal, 
        a.segmen, 
        a.bikole, 
        a.KODE_SEKO, 
        a.SEKTOR_EKONOMI, 
        a.kd_grp, 
        a.nama_grp, 
        CAST(b.KD_GRP AS VARCHAR), 
        a.PRODUCT_CODE, 
        RTRIM(a.currency), 
        b.RN
),
SEKO AS (
    SELECT 
        Tanggal, 
        segmen,
        bikole,
        SUM(CBAL_IDR) AS OS_IDR,
        'SEKO' AS flag,
        KODE_SEKO,
        SEKTOR_EKONOMI AS SEKO,
        KET_REST, 
        KET_REST_Covid,
        '' AS kd_grp,
        '' AS nama_grp
    FROM gab
    WHERE SEGMEN IS NOT NULL --and kd_grp = '5831'
    GROUP BY Tanggal, segmen, bikole, KODE_SEKO, SEKTOR_EKONOMI, KET_REST, KET_REST_Covid
),
DEBITUR_INTI_SUMMARY AS (
    SELECT DISTINCT 
        Tanggal, 
        SEGMEN, 
        BIKOLE,
        SUM(OS_IDR) AS [O/S IDR],
        KODE_SEKO,
        LTRIM(RTRIM(SEKO)) AS SEKO,
        '' AS KET_REST, 
        '' AS KET_REST_COVID, 
        KD_GRP, 
        LTRIM(RTRIM(NAMA_GRP)) AS NAMA_GRP
    FROM DEBITUR_INTI
    WHERE FLAG = 'DEBITUR_INTI'
    GROUP BY Tanggal, KODE_SEKO, SEKO, BIKOLE, SEGMEN, KD_GRP, NAMA_GRP
)
SELECT 
    TANGGAL, 
    SEGMEN, 
    BIKOLE, 
    OS_IDR, 
    FLAG, 
    KODE_SEKO, 
    LTRIM(RTRIM(SEKO)) AS SEKO, 
    KET_REST, 
    KET_REST_Covid, 
    kd_grp, 
    LTRIM(RTRIM(nama_grp)) AS nama_grp
FROM SEKO 
UNION ALL
SELECT 
    Tanggal, 
    SEGMEN, 
    BIKOLE, 
    [O/S IDR] AS OS_IDR, 
    'DEBITUR_INTI' AS flag, 
    KODE_SEKO, 
    LTRIM(RTRIM(SEKO)) AS SEKO, 
    KET_REST, 
    KET_REST_COVID, 
    KD_GRP, 
    LTRIM(RTRIM(NAMA_GRP)) AS NAMA_GRP
FROM DEBITUR_INTI_SUMMARY
ORDER BY KD_GRP, KODE_SEKO, SEGMEN, BIKOLE;