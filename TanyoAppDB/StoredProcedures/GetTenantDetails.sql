CREATE PROCEDURE GetTenantDetails (@TenantID INT)
AS
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

