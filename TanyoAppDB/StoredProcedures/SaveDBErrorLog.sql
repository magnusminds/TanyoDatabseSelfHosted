CREATE PROC SaveDBErrorLog
(
	@ObjectName VARCHAR(500)
	,@ErrorMsg VARCHAR(MAX)
)
AS
BEGIN
	INSERT INTO DBErrorLogs(ObjectName, ErrorMessage)
	SELECT @ObjectName, @ErrorMsg
END

GO

