CREATE VIEW UT_Product_Incorrect_Status
AS
	SELECT *
	FROM Products WITH (NOLOCK)
	WHERE Status = 0

GO

