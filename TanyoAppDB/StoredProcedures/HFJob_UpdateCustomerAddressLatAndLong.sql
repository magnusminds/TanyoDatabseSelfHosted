CREATE   PROCEDURE HFJob_UpdateCustomerAddressLatAndLong (
	@CustomerAddressId BIGINT
	,@Latitude VARCHAR(25)
	,@Longitude VARCHAR(25)
	)
WITH ENCRYPTIONAS
BEGIN
	UPDATE CA
	SET CA.Latitude = @Latitude
		,CA.Longitude = @Longitude
	FROM CustomerAddresses CA
	WHERE CustomerAddressId = @CustomerAddressId
END

GO

