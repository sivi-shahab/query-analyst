ALTER TABLE [stg_host].[dbo].[acct_no]
ADD acctno VARCHAR(19);
UPDATE [stg_host].[dbo].[acct_no]
SET acctno = RIGHT(REPLICATE('0', 19) + CAST(fin_acctno AS VARCHAR(19)), 19);

SELECT a.acctno, c.CRDACCT_NBR, c.CRDACCT_OUTSTD_BAL, CRDACCT_OUTSTD_INSTL 
FROM [stg_host].[dbo].[acct_no] a
LEFT JOIN (
    SELECT CRDACCT_NBR, CRDACCT_OUTSTD_BAL, CRDACCT_OUTSTD_INSTL
    FROM [10.11.88.218].[stg_host].[dbo].[CURRENT_CC_SCMCACCP]
) c ON a.acctno = c.CRDACCT_NBR



WITH OrderedAccounts AS (
   SELECT 
       fin_acctno,
       ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as original_order
   FROM adhoc.acct_no
),
UnionedData AS (
   SELECT 
       a.fin_acctno,
       h."TXN_AMOUNT"
   FROM 
       OrderedAccounts oa
       JOIN adhoc.acct_no a ON oa.fin_acctno = a.fin_acctno
       LEFT JOIN adhoc.history_cc_scmolstp h ON a.fin_acctno = h."ACCOUNT_NUMBER"
   UNION ALL
   SELECT 
       a.fin_acctno,
       h."TXN_AMOUNT"
   FROM 
       OrderedAccounts oa
       JOIN adhoc.acct_no a ON oa.fin_acctno = a.fin_acctno
       LEFT JOIN adhoc.current_cc_scmctdtp h ON a.fin_acctno = h."ACCOUNT_NUMBER"
)
SELECT 
   oa.fin_acctno,
   SUM(ud."TXN_AMOUNT") as TOTAL_TXN_AMOUNT,
   CASE 
       WHEN SUM(ud."TXN_AMOUNT") IS NOT NULL THEN 'Ada'
       ELSE 'tidak ada'
   END as STATUS_TRX
FROM 
   OrderedAccounts oa
   LEFT JOIN UnionedData ud ON oa.fin_acctno = ud.fin_acctno
GROUP BY
   oa.fin_acctno,
   oa.original_order
ORDER BY 
   oa.original_order;