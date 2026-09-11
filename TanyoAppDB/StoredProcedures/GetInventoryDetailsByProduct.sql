/*  
EXEC [dbo].[GetInventoryDetailsByProduct]  
    @TenantId = 1206,  
    @ProductId = 402805;  
*/
CREATE PROCEDURE [dbo].[GetInventoryDetailsByProduct] (
	@TenantId BIGINT
	,@ProductId BIGINT
	)
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;

		DECLARE @dt DATETIMEOFFSET = SYSDATETIMEOFFSET();
		DECLARE @ProductSubjectTypeId INT;
		DECLARE @ApprovedQuantities NUMERIC(18, 2) = 0
			,@ReadyToDelivered NUMERIC(18, 2) = 0
			,@OnHoldCnt NUMERIC(18, 2) = 0
			,@WarehouseTotal NUMERIC(18, 2) = 0
			,@FinalTotal NUMERIC(18, 2) = 0
			,@WarehouseId BIGINT
			,@WareHouseCount INT;

		DROP TABLE IF EXISTS #WareHouse;

	    CREATE TABLE #WareHouse (WAREHOUSEID BIGINT)

		-- 1. Get SubjectTypeId for 'Products'  
		SELECT @ProductSubjectTypeId = SubjectTypeId
		FROM dbo.SubjectTypes WITH (NOLOCK)
		WHERE SubjectTypeName = 'Products'
			AND TenantId = @TenantId
			AND IsDeleted = 0;

		INSERT INTO #WareHouse (WareHouseId)
		SELECT WarehouseId
		FROM ProductQuantitiesByWarehouse
		WHERE ProductId = @ProductId

		-- 2. Calculate Approved Quantities (Same logic as GetInventoryWarehouseDetailsV2)
		SELECT @ApprovedQuantities = ISNULL(SUM(os.Quantity), 0)
		FROM dbo.Orders o WITH (NOLOCK)
		INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
		WHERE o.TenantId = @TenantId
			AND os.IsDeleted = 0
			AND os.SubjectId = @ProductId
			AND os.SubjectTypeId = @ProductSubjectTypeId
			AND (
				o.STATUS IN (2) -- Approved  
				OR (
					o.STATUS IN (3) -- InProgress  
					AND os.ItemStatus IN (
						0
						,1
						,4
						) -- ReadyToManufacturing, Manufacturing, Pending  
					)
				);

		-- 3. Calculate Ready To Deliver Quantities (Order Status = InProgress(3) & ItemStatus = ReadyToDeliver(2))  
		SELECT @ReadyToDelivered = ISNULL(SUM(os.Quantity), 0)
		FROM dbo.Orders o WITH (NOLOCK)
		INNER JOIN dbo.OrderSetItems os WITH (NOLOCK) ON os.OrderId = o.OrderId
		WHERE o.TenantId = @TenantId
			AND os.IsDeleted = 0
			AND os.SubjectId = @ProductId
			AND os.SubjectTypeId = @ProductSubjectTypeId
			AND o.STATUS IN (3)
			AND os.ItemStatus = 2;

		-- 4. Calculate On-Hold Quantities  
		SELECT @OnHoldCnt = ISNULL(SUM(vh.Quantity), 0)
		FROM dbo.vw_HoldItems vh WITH (NOLOCK)
		WHERE vh.TenantId = @TenantId
			AND vh.HoldUptoDate > @dt
			AND vh.SubjectId = @ProductId;

		-- 5. Calculate Warehouse Total & Final Saleable Total (Same logic as GetInventoryWarehouseDetailsV2)
		SET @WareHouseCount = (SELECT COUNT(1) FROM #WareHouse)

		IF (@WareHouseCount) > 0
		BEGIN
			SELECT @FinalTotal = Quantity
			FROM dbo.ProductQuantities WITH (NOLOCK)
			WHERE ProductId = @ProductId;
		END

		SET @FinalTotal = ISNULL(@WarehouseTotal, 0) - ISNULL(@OnHoldCnt, 0) - ISNULL(@ApprovedQuantities, 0) - ISNULL(@ReadyToDelivered, 0);

		IF @FinalTotal < 0
			SET @FinalTotal = ISNULL(@FinalTotal, 0)

		-- =====================================================================  
		-- UNIFIED RESULT SET: Product, Saleable & Warehouse Inventory Details  
		-- =====================================================================  
		SELECT C.CategoryName
			,CAST(CASE 
					WHEN C.CategoryTypeId = 2
						THEN 1
					ELSE 0
					END AS BIT) AS IsFabric
			,P.ProductTitle AS ProductName
			,PQ.MinimumLimit AS ReorderPoint
			,ISNULL(PQ.ProductQuantityId, 0) AS ProductQuantityId
			,ISNULL(PQ.Quantity, 0) AS CurrentQuantity
			,ISNULL(PQ.Quantity, 0) AS UpdateQuantity
			,@OnHoldCnt AS OnHoldQuantities
			,@ApprovedQuantities AS ApprovedQuantities
			,@ReadyToDelivered AS ReadyToDeliver
			,CAST(@FinalTotal AS NUMERIC(18, 2)) AS TotalSaleableQuantity
			,W.Id AS WarehouseId
			,W.Name AS WarehouseName
			,ISNULL(PQBW.ProductQuantityByWarehouseId, 0) AS ProductQuantityByWarehouseId
			,ISNULL(PQBW.Quantity, 0) AS WarehouseCurrentQuantity
			,ISNULL(PQBW.Quantity, 0) AS WarehouseUpdateQuantity
			,CAST(@FinalTotal AS NUMERIC(18, 2)) AS TotalWarehouseQuantity
		FROM dbo.Products P WITH (NOLOCK)
		INNER JOIN dbo.Categories C WITH (NOLOCK) ON C.CategoryId = P.CategoryId
			AND C.TenantId = @TenantId
		INNER JOIN dbo.ProductQuantities PQ WITH (NOLOCK) ON PQ.ProductId = P.ProductId
		INNER JOIN dbo.Warehouse W WITH (NOLOCK) ON W.TenantId = @TenantId
			AND W.IsDeleted = 0
		INNER JOIN dbo.ProductQuantitiesByWarehouse PQBW WITH (NOLOCK) ON PQBW.WarehouseId = W.Id
			AND PQBW.ProductId = P.ProductId
		WHERE P.TenantId = @TenantId
			AND P.ProductId = @ProductId
		ORDER BY W.Name ASC;
	END TRY

	BEGIN CATCH
		DECLARE @ObjectName VARCHAR(500)
			,@ErrorMsg NVARCHAR(4000);

		SET @ObjectName = OBJECT_NAME(@@PROCID);
		SET @ErrorMsg = ERROR_MESSAGE();

		EXEC dbo.SaveDBErrorLog @ObjectName = @ObjectName
			,@ErrorMsg = @ErrorMsg;
	END CATCH
END

GO

