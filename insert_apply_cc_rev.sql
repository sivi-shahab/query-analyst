INSERT INTO [dev_dm].[dbo].[api_apply_cc_rev]
(
    [JULIAN_MIS_DATE],
    [cust_id],
    [source],
    [source_code],
    [crdacct_nbr],
    [card_nbr],
    [apply_date],
    [approve_date],
    [activated_date],
    [card_blk_code],
    [card_prv_blk_code],
    [card_dte_prvblk_code],
    [card_dte_blk_code],
    [mobile_phone],
    [email_addr],
    [cust_local_name],
    [gcn_number]
)
VALUES
(
    20250321, -- [JULIAN_MIS_DATE] - contoh format tanggal Julian
    'CUST12345', -- [cust_id]
    '', -- [source]
    '', -- [source_code]
    '4201920152868798', -- [crdacct_nbr]
    '5412345678901234', -- [card_nbr]
    '20250321', -- [apply_date]
    20250321, -- [approve_date]
    20250321, -- [activated_date]
    '', -- [card_blk_code]
    '', -- [card_prv_blk_code]
    NULL, -- [card_dte_prvblk_code]
    NULL, -- [card_dte_blk_code]
    '085956771419', -- [mobile_phone]
    'gatot@email.com', -- [email_addr]
    'Gatot Bramantyo', -- [cust_local_name]
    'GCNTEST008' -- [gcn_number]
);