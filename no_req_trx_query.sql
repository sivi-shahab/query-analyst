SELECT MIS_DATE, Amount, other_merch, reff_2, acct_source
  FROM [10.11.88.218].[stg_host].[dbo].[HISTORY_MSP_QR_Code_Data_History]
  WHERE MIS_DATE='16022025'
  and amount = 35000
  and other_merch LIKE '%IJOOZ%'
  -- delete last number
  AND [reff_2] = '936008990000014335'

SELECT [ACCTNO],[CIFNO]   
  FROM [10.11.88.218].[stg_host].[dbo].[CURRENT_DDMast]
  WHERE ACCTNO = ''