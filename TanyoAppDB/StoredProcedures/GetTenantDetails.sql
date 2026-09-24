CREATE PROCEDURE GetTenantDetails (@TenantID INT)
WITH ENCRYPTIONAS
BEGIN
	SELECT TenantName
		,PhoneNumber
		,EmailId
		,GSTNo
		,STATE
	FROM Tenants WITH (NOLOCK)
	WHERE TenantID = @TenantID;
END

GO

