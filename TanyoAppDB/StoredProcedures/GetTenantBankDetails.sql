CREATE PROCEDURE GetTenantBankDetails (@TenantID BIGINT)
WITH ENCRYPTIONAS
BEGIN
	SELECT BankName
		,AccountNo
		,IFSCCode
		,BranchName
		,QRCode
	FROM TenantBankDetails WITH (NOLOCK)
	WHERE TenantID = @TenantID
		AND IsDeleted = 0
END

GO

