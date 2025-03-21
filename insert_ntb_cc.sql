INSERT INTO [dev_dm].[dbo].[mgm_ntb_cc_dummy]
(
    [card_nbr],
    [phone],
    [apply_date],
    [approve_date],
    [NTB_FLAG]
)
VALUES
(
    '5412345678901234', -- [card_nbr] - nomor kartu
    '085956771419', -- [phone] - nomor telepon
    CONVERT(datetime, '2025-03-21 10:30:00'), -- [apply_date] - timestamp aplikasi
    CONVERT(datetime, '2025-03-21 14:45:00'), -- [approve_date] - timestamp persetujuan
    'NTB' -- [NTB_FLAG] - flag NTB (New-to-Bank)
);