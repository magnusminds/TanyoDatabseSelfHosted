CREATE   PROCEDURE HFJob_UpdateOrderAddressLatAndLong (
	@OrderAddressId BIGINT
	,@Latitude VARCHAR(25)
	,@Longitude VARCHAR(25)
	)
AS
BEGIN
	UPDATE OA
	SET OA.Latitude = @Latitude
		,OA.Longitude = @Longitude
	FROM OrderAddresses OA
	WHERE OrderAddressId = @OrderAddressId;
END

GO

