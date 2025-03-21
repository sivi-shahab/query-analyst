/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [ACOBCIF#]
      ,[ACOBACNO]
      ,[open_date_yyyymmdd]
      ,[cfeadd]
      ,[cfeadd_formatted]
      ,[NTB_FLAG]
  FROM [dev_dm].[dbo].[mgm_ntb_funding_dummy]

 INSERT INTO [dev_dm].[dbo].[mgm_ntb_funding_dummy]
(
    [ACOBCIF#],
    [ACOBACNO],
    [open_date_yyyymmdd],
    [cfeadd],
    [cfeadd_formatted],
    [NTB_FLAG]
)
VALUES
(
    '1244578', -- [ACOBCIF#] - nomor CIF
    4201920152868798, -- [ACOBACNO] - nomor rekening
    '20250321', -- [open_date_yyyymmdd] - tanggal pembukaan rekening
    '085956771419', -- [cfeadd] - alamat email
    '+6285956771419', -- [cfeadd_formatted] - nomor telepon yang diformat
    'NTB' -- [NTB_FLAG] - flag New-to-Bank

);