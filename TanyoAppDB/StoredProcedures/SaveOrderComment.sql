

CREATE PROCEDURE [dbo].[SaveOrderComment] (
    @OrderId BIGINT
    ,@Status INT
    ,@Comment NVARCHAR(MAX) = NULL
    ,@Remarks NVARCHAR(MAX) = NULL
    ,@CreatedBy INT
    ,@CreatedDate DATETIMEOFFSET
    ,@CreatedUTCDate DATETIME
)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@Comment, '') <> ''
    BEGIN
        INSERT INTO dbo.OrderComments (
            OrderId
            ,STATUS
            ,Comments
            ,CreatedBy
            ,CreatedDate
            ,CreatedUTCDate
            )
        VALUES (
            @OrderId
            ,@Status
            ,@Comment
            ,@CreatedBy
            ,@CreatedDate
            ,@CreatedUTCDate
            );
    END

    IF ISNULL(@Remarks, '') <> ''
    BEGIN
        INSERT INTO dbo.OrderComments (
            OrderId
            ,STATUS
            ,Comments
            ,CreatedBy
            ,CreatedDate
            ,CreatedUTCDate
            ,Remarks
            )
        VALUES (
            @OrderId
            ,@Status
            ,''
            ,@CreatedBy
            ,@CreatedDate
            ,@CreatedUTCDate
            ,@Remarks
            );
    END
END

GO

