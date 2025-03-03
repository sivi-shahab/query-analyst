declare @date varchar(8)		= (select replace(convert(varchar,dateadd(day,-1,getdate()),103),'/',''))
declare @j_start int			= (select dbo.fn_ddmmyyyy_to_julian(@date))
declare @datestart numeric		= (select cast(dbo.fn_julian_to_yyyymmdd(@j_start) as numeric))
declare @date_start date		= (select dbo.fn_julian_to_date(@j_start))
;
with 
 data_apply_cc as(
 select * 
 from [10.15.42.96].stg_host.dbo.current_nls_request_cc_2020 
 where 
-- CAST(datecreated AS DATE)>= @date_start date
-- and 
-- source_code = 'MPIREGM0000' 
--and 
 status not in ('Rejected') 
)
select distinct
a.JULIAN_MIS_DATE, 
 a.cust_id,
 a.source,
 a.source_code,
 c.crdacct_nbr,
d.card_nbr,
convert(varchar,cast(a.datecreated as date),112) as apply_date,
c.crdacct_dte_open as approve_date,
case 
	when card_dte_prvblk_code <> 0 and  card_prv_blk_code = 'ni' and card_blk_code in ('',' ') then card_dte_blk_code
	else 0
end as activated_date,
d.card_blk_code,
card_prv_blk_code,card_dte_prvblk_code,card_dte_blk_code ,
b.cust_mobile_phone as mobile_phone,
b.cust_email_addr as email_addr,
b.cust_local_name,
e.gcn_number
--into stg_today.dbo.api_apply_cc
from data_apply_cc a
inner join current_cc_scmcardp d 
	on a.reff_id = d.CARD_APPL_NBR 
	and a.source_code = d.CARD_APPL_SRC_CD 
left join current_cc_scmcaccp c on d.card_acct_nbr = c.crdacct_nbr
left join current_cc_scmcustp b 
	on a.cust_id = b.cust_nbr
left join s_acc_flag_gcn2_contact e on c.crdacct_nbr = e.acctnbr
left join current_msp_account_list f on e.gcn_number = f.gcn_number

;