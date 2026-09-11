




-- =============================================
-- Author:      MagnusMinds
-- Create date: 24-11-2023
-- Description: List of Invalid Orders
-- =============================================
--select * from [UT_InvalidOrderAmount] order by OrderDate DESC
CREATE VIEW [dbo].[UT_InvalidOrderAmount] 
AS
SELECT t.TenantName
	,t.TenantId
	,o.OrderId 
	,o.OrderNo
	,o.Status
	,o.CreatedBy
	,o.Discount
	,o.TotalAmount
	,o.CreatedDate AS OrderDate
	,o.ApprovedDate
	,'EXEC dbo.UpdateOrderRefreshInquiry
		@OrderId = ' + CAST(o.OrderID AS VARCHAR(20)) +'
		,@TenantId =  ' + CAST(o.TenantId AS VARCHAR(20)) +'
		,@UserId =  ' + CAST(o.CreatedBy AS VARCHAR(20)) +''
		AS ExecuteStatement
FROM dbo.Orders o WITH (NOLOCK)
INNER JOIN dbo.Tenants t WITH (NOLOCK) ON t.TenantId = o.TenantId
WHERE o.TotalAmount <= 0
	AND o.Status <> 9
AND o.ApprovedDate > '2026-07-22'

GO

