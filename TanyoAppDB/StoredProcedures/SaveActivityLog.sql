CREATE PROCEDURE [dbo].[SaveActivityLog] (
    @SubjectTypeId INT
    ,@SubjectId BIGINT
    ,@Description NVARCHAR(MAX)
    ,@Action VARCHAR(50)
    ,@CreatedBy INT
    ,@CreatedDate DATETIMEOFFSET
    ,@CreatedUTCDate DATETIME
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ActivityLogs (
        SubjectTypeId
        ,SubjectId
        ,Description
        ,Action
        ,CreatedBy
        ,CreatedDate
        ,CreatedUTCDate
        )
    VALUES (
        @SubjectTypeId
        ,@SubjectId
        ,@Description
        ,@Action
        ,@CreatedBy
        ,@CreatedDate
        ,@CreatedUTCDate
        );
END

GO

