/*
	EXEC RPT_GetOrderPaymentDue
		@TenantId = 2
		,@ApprovedFromDate = '2022-01-01'
		,@ApprovedToDate = '2027-01-01'
		,@OrderStatus = NULL
		,@PageNumber = 1
		,@PageSize = 50
		,@SortBy = 'ApprovedDate'
		,@SortOrder = 'DESC'
		
*/
CREATE PROCEDURE [dbo].[RPT_GetOrderPaymentDue] (
	 @TenantId INT
	,@ApprovedFromDate DATE
	,@ApprovedToDate DATE
	,@OrderStatus VARCHAR(200) = NULL
	--,@PaymentDueStatus TINYINT = NULL
	,@PageNumber INT = 1
	,@PageSize INT = 25
	,@SortBy VARCHAR(50) = 'ApprovedDate'
	,@SortOrder VARCHAR(4) = 'DESC'
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ApprovedFromDateTime DATETIMEOFFSET = NULL
		   ,@ApprovedToDateTime DATETIMEOFFSET = NULL

	SELECT @ApprovedFromDateTime = CAST(@ApprovedFromDate AS VARCHAR(10)) + ' 00:00:00.0000001 +5:30'
		  ,@ApprovedToDateTime = CAST(@ApprovedToDate AS VARCHAR(10)) + ' 23:59:59.9999999 +5:30'

	BEGIN TRY
		SELECT o.OrderId
			,o.OrderNo
			,o.CustomerID AS CustomerId
			,ISNULL(c.FirstName, '') + ' ' + ISNULL(c.LastName, '') AS CustomerName
			,c.PhoneNumber
			,o.ApprovedDate
			,CASE 
				WHEN o.STATUS = 5
					THEN o.DeliveryDate
				ELSE o.TentativeDeliveryDate
				END AS DeliveryDate
			,o.STATUS AS OrderStatus
			,os.STATUS AS OrderStatusName
			,o.TotalAmt AS InvoiceAmount
			,ISNULL(o.AdvanceAmount, 0) AS PaymentReceived
			,(o.TotalAmt - ISNULL(o.AdvanceAmount, 0)) AS PaymentDueAmount
			,CASE 
				-- 1. Check if completely Paid first
				WHEN (o.TotalAmt - ISNULL(o.AdvanceAmount, 0)) = 0
					THEN 1
						-- 2. Check if No Advance has been paid (Fully Due) next
				WHEN ISNULL(o.AdvanceAmount, 0) = 0
					THEN 3
						-- 3. Anything else greater than 0 must be a partial payment
				WHEN (o.TotalAmt - ISNULL(o.AdvanceAmount, 0)) > 0
					THEN 2
				END AS PaymentCollectionStatus
			,CASE 
				-- 1. Check if completely Paid first
				WHEN (o.TotalAmt - ISNULL(o.AdvanceAmount, 0)) = 0
					THEN 'Paid'
						-- 2. Check if No Advance has been paid (Fully Due) next
				WHEN ISNULL(o.AdvanceAmount, 0) = 0
					THEN 'Unpaid'
						-- 3. Anything else greater than 0 must be a partial payment
				WHEN (o.TotalAmt - ISNULL(o.AdvanceAmount, 0)) > 0
					THEN 'Partial Paid'
				END AS PaymentCollectionStatusName
			,COUNT(1) OVER () AS TotalOrdersCount
			,SUM(o.TotalAmt) OVER () AS TotalInvoiceAmount
			,SUM(ISNULL(o.AdvanceAmount, 0)) OVER () AS TotalPaymentReceivedAmount
			,SUM(o.TotalAmt - ISNULL(o.AdvanceAmount, 0)) OVER () AS TotalPaymentDueAmount
		FROM Orders o WITH (NOLOCK)
		INNER JOIN Customers c WITH (NOLOCK) ON c.CustomerId = o.CustomerID
		INNER JOIN OrderStatus os WITH (NOLOCK) ON os.StatusEnumId = o.STATUS
			AND os.TenantId = @TenantId
			AND os.Type = 'Order'
		WHERE o.TenantId = @TenantId
			AND (
				@OrderStatus IS NULL
				OR o.STATUS IN (
					SELECT value
					FROM string_split(@OrderStatus, ',')
					)
				)
			AND o.ApprovedDate BETWEEN @ApprovedFromDateTime
				AND @ApprovedToDateTime
			AND o.STATUS <> 9
			AND (o.TotalAmt - ISNULL(o.AdvanceAmount, 0)) > 0
		ORDER BY CASE 
				WHEN @SortBy = 'ApprovedDate'
					AND @SortOrder = 'ASC'
					THEN o.ApprovedDate
				END ASC
			,CASE 
				WHEN @SortBy = 'ApprovedDate'
					AND @SortOrder = 'DESC'
					THEN o.ApprovedDate
				END DESC
			,CASE 
				WHEN @SortBy = 'DeliveryDate'
					AND @SortOrder = 'ASC'
					THEN o.DeliveryDate
				END ASC
			,CASE 
				WHEN @SortBy = 'DeliveryDate'
					AND @SortOrder = 'DESC'
					THEN o.DeliveryDate
				END DESC
			,CASE 
				WHEN @SortBy = 'OrderStatus'
					AND @SortOrder = 'ASC'
					THEN o.STATUS
				END ASC
			,CASE 
				WHEN @SortBy = 'OrderStatus'
					AND @SortOrder = 'DESC'
					THEN o.STATUS
				END DESC
			,CASE 
				WHEN @SortBy = 'InvoiceAmount'
					AND @SortOrder = 'ASC'
					THEN o.TotalAmt
				END ASC
			,CASE 
				WHEN @SortBy = 'InvoiceAmount'
					AND @SortOrder = 'DESC'
					THEN o.TotalAmt
				END DESC
			,CASE 
				WHEN @SortBy = 'PaymentDueAmount'
					AND @SortOrder = 'ASC'
					THEN (o.TotalAmt - ISNULL(o.AdvanceAmount, 0))
				END ASC
			,CASE 
				WHEN @SortBy = 'PaymentDueAmount'
					AND @SortOrder = 'DESC'
					THEN (o.TotalAmt - ISNULL(o.AdvanceAmount, 0))
				END DESC
			,CASE 
				WHEN @SortBy = 'CustomerName'
					AND @SortOrder = 'ASC'
					THEN ISNULL(c.FirstName, '') + ' ' + ISNULL(c.LastName, '')
				END ASC
			,CASE 
				WHEN @SortBy = 'CustomerName'
					AND @SortOrder = 'DESC'
					THEN ISNULL(c.FirstName, '') + ' ' + ISNULL(c.LastName, '')
				END DESC
			,CASE 
				WHEN @SortBy = 'OrderNo'
					AND @SortOrder = 'ASC'
					THEN o.OrderNo
				END ASC
			,CASE 
				WHEN @SortBy = 'OrderNo'
					AND @SortOrder = 'DESC'
					THEN o.OrderNo
				END DESC OFFSET(@PageNumber - 1) * @PageSize ROWS

		FETCH NEXT @PageSize ROWS ONLY;
	END TRY

	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		RAISERROR (
				@ErrorMessage
				,@ErrorSeverity
				,@ErrorState
				)
	END CATCH
END

GO

