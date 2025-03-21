/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [account]
      ,[mobile_phone]
      ,[date_trx]
      ,[amt_trx]
  FROM [dev_dm].[dbo].[api_trx_cc_mgm]

INSERT INTO [dev_dm].[dbo].[api_trx_cc_mgm]
(
    [account],
    [mobile_phone],
    [date_trx],
    [amt_trx]
)
VALUES
(
    '4201920152868798', -- [account] - nomor akun
    '085956771419', -- [mobile_phone] - nomor telepon
    20250321, -- [date_trx] - tanggal transaksi
    250000 -- [amt_trx] - jumlah transaksi
);

DELETE FROM [dev_dm].[dbo].[api_trx_cc_mgm]
WHERE [account] = '4201920152868798'
  AND [mobile_phone] = '085956771419'
  AND [date_trx] = 20250321
  AND [amt_trx] = 250000;