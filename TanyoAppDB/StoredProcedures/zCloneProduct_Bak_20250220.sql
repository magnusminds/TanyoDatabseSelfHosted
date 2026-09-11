
-- =============================================
-- Author		: MagnusMinds
-- Create date	: 05-09-2023
-- Description	: Copy Product from existing product
-- =============================================
/*
	EXEC [dbo].[CloneProduct]
		@ProductId = 1
		,@FromTenantId = 1
		,@ToTenantId = 1
		,@UserID = 438
		,@CategoryId = 10
		,@VendorId = 0

	EXEC [dbo].[CloneProduct]
		@ProductId = 6
		,@FromTenantId = 1
		,@ToTenantId = 2
		,@UserID = 438
		,@CategoryId = 10
		,@VendorId = 3
*/
CREATE PROCEDURE [dbo].[zCloneProduct_Bak_20250220]
(
	@ProductId BIGINT
	,@FromTenantId BIGINT
	,@ToTenantId BIGINT
	,@UserID BIGINT
	,@CategoryId BIGINT = 0
	,@VendorId BIGINT = 0
	,@IsPublished INT = 0
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRAN

			DECLARE @NewProductId BIGINT
			DECLARE @SubjectTypeId INT
			DECLARE @Date DATETIMEOFFSET = SYSDATETIMEOFFSET()
			DECLARE @UTCDate DATETIME = GETUTCDATE()
			
			IF (@ToTenantId=@FromTenantId)
			BEGIN
				  SELECT @SubjectTypeId = SubjectTypeId
				  FROM dbo.SubjectTypes st WITH (NOLOCK)
				  WHERE st.TenantId = @FromTenantId
				  AND st.SubjectTypeName = 'Products'

				  IF EXISTS (
					SELECT 1
					FROM dbo.Products p WITH (NOLOCK)
					WHERE ProductId = @ProductId
				   )
				  BEGIN
				   INSERT INTO dbo.Products
				   (
					CategoryId
					,ProductTitle
					,ModelNo
					,Width
					,Height
					,Depth
					,FabricNeeded
					,IsVisibleToWholesalers
					,TotalDaysToPrepare
					,Features
					,Comments
					,CostPrice
					,QRImage
					,TenantId
					,Status
					,CreatedBy
					,CreatedDate
					,CreatedUTCDate
					,Diameter
					,RetailerPrice
					,WholesalerPrice
				   )
				   SELECT p.CategoryId
					,p.ProductTitle + ' COPY'
					,CASE
					 WHEN  
					  p.ModelNo <> null or p.ModelNo <> '' THEN   p.ModelNo + '-COPY'
					 ELSE 
					  ''
					 END  
					,p.Width
					,p.Height
					,p.Depth
					,p.FabricNeeded
					,p.IsVisibleToWholesalers
					,p.TotalDaysToPrepare
					,p.Features
					,p.Comments
					,p.CostPrice
					,NULL
					,p.TenantId
					,0
					,@UserID
					,@Date
					,@UTCDate
					,p.Diameter
					,p.RetailerPrice
					,p.WholesalerPrice
				   FROM dbo.Products p WITH (NOLOCK)
				   WHERE ProductId = @ProductId

				   SET @NewProductId = SCOPE_IDENTITY()
				  END

				  IF (@NewProductId > 0)
				  BEGIN
				   INSERT INTO dbo.ProductQuantities
				   (
					ProductId
					,QuantityDate
					,Quantity
					,LastModifiedBy
				   )
				   SELECT @NewProductId
					,@Date
					,0
					,@UserID

					IF EXISTS (
					 SELECT 1
					 FROM dbo.ProductMaterials pm WITH (NOLOCK)
					 WHERE pm.ProductId = @ProductId
					 )
				   BEGIN
					INSERT INTO dbo.ProductMaterials (
					 ProductId
					 ,SubjectTypeId
					 ,SubjectId
					 ,Qty
					 ,CreatedBy
					 ,CreatedDate
					 ,CreatedUTCDate
					 )
					SELECT @NewProductId
					 ,pm.SubjectTypeId
					 ,pm.SubjectId
					 ,pm.Qty
					 ,@UserID
					 ,@Date
					 ,@UTCDate
					FROM ProductMaterials pm WITH (NOLOCK)
					WHERE pm.ProductId = @ProductId
				   END

				   IF EXISTS (
					 SELECT 1
					 FROM dbo.ProductLabours pl WITH (NOLOCK)
					 WHERE pl.ProductId = @ProductId
					 AND pl.IsDeleted = 0
					 )
				   BEGIN
					INSERT INTO dbo.ProductLabours
					(
					 ProductId
					 ,ManufacturingWorkFlowId
					 ,Amount
					 ,CreatedBy
					 ,CreatedDate
					 ,CreatedUTCDate
					)
					SELECT @NewProductId
					 ,pl.ManufacturingWorkFlowId
					 ,pl.Amount
					 ,@UserID
					 ,@Date
					 ,@UTCDate
					FROM ProductLabours pl WITH (NOLOCK)
					WHERE ProductId = @ProductId
					AND pl.IsDeleted = 0
				   END

				   IF EXISTS (
					 SELECT 1
					 FROM dbo.ProductWorkflows pw WITH (NOLOCK)
					 WHERE pw.ProductId = @ProductId
					 )
				   BEGIN
					INSERT INTO dbo.ProductWorkflows
					(
					 ProductID
					 ,ManufacturingWorkflowId
					 ,ContractorUserID
					 ,SupervisorUserID
					 ,TentativeDays
					 ,Position
					 ,CreatedBy
					 ,CreatedDate
					 ,CreatedUTCDate
					)
					SELECT @NewProductId
					 ,pw.ManufacturingWorkflowId
					 ,pw.ContractorUserID
					 ,pw.SupervisorUserID
					 ,pw.TentativeDays
					 ,pw.Position
					 ,@UserID
					 ,@Date
					 ,@UTCDate
					FROM ProductWorkflows pw WITH (NOLOCK)
					WHERE ProductID = @ProductId
				   END

				   INSERT INTO dbo.ActivityLogs
				   (
					SubjectTypeId
					,SubjectId
					,Description
					,Action
					,CreatedBy
					,CreatedDate
					,CreatedUTCDate
				   )
				   SELECT @SubjectTypeId
					,@NewProductId
					,'Product has been copied from ' + p.ProductTitle + ' - ' + p.ModelNo
					,'CLONE'
					,@UserID
					,@Date
					,@UTCDate
				   FROM dbo.Products p WITH (NOLOCK)
				   WHERE ProductId = @ProductId
				  END

				  SELECT *
				  FROM dbo.Products p WITH (NOLOCK)
				  WHERE p.ProductId = @NewProductId
			END
			ELSE
			BEGIN
				SELECT @SubjectTypeId = SubjectTypeId
				FROM dbo.SubjectTypes st WITH (NOLOCK)
				WHERE st.TenantId = @FromTenantId
				AND st.SubjectTypeName = 'Products'

				DECLARE @RetailerPer DECIMAL(18,2)
				DECLARE @WholesalerPer DECIMAL(18,2)

				DECLARE @RetailerPrice DECIMAL(18,2)
				DECLARE @WholesalerPrice DECIMAL(18,2)

				SELECT @RetailerPer = RSPPercentage, 
					   @WholesalerPer = WSPPercentage 
				FROM Categories
				WHERE CategoryId = @CategoryId

				SELECT @RetailerPrice = (CASE IsPriceAutoCalculated 
										 WHEN 1 THEN RetailerPrice + (RetailerPrice * @RetailerPer / 100)
										 ELSE RetailerPrice END)
					  ,@WholesalerPrice = (CASE IsPriceAutoCalculated 
										   WHEN 1 THEN RetailerPrice + (RetailerPrice * @WholesalerPer / 100) 
										   ELSE WholesalerPrice END)
				FROM dbo.Products p WITH (NOLOCK)
					WHERE ProductId = @ProductId

				PRINT N'different tenant blocks'
				IF EXISTS (
						SELECT 1
						FROM dbo.Products p WITH (NOLOCK)
						WHERE ProductId = @ProductId
					)
				BEGIN
					INSERT INTO dbo.Products
					(
						CategoryId
						,ProductTitle
						,ModelNo
						,Width
						,Height
						,Depth
						,FabricNeeded
						,IsVisibleToWholesalers
						,TotalDaysToPrepare
						,Features
						,Comments
						,CostPrice
						,QRImage
						,TenantId
						,Status
						,CreatedBy
						,CreatedDate
						,CreatedUTCDate
						,Diameter
						,RetailerPrice
						,WholesalerPrice
						,IsPriceAutoCalculated
					)
					SELECT @CategoryId
						,p.ProductTitle
						,CASE
							WHEN  
								p.ModelNo <> null or p.ModelNo <> '' THEN   p.ModelNo
							ELSE 
								''
						 END		
						,p.Width
						,p.Height
						,p.Depth
						,p.FabricNeeded
						,p.IsVisibleToWholesalers
						,p.TotalDaysToPrepare
						,p.Features
						,p.Comments
						,p.RetailerPrice-- AS This the price on which this tenant has bought the product
						,NULL
						,@ToTenantId
						,@IsPublished
						,@UserID
						,@Date
						,@UTCDate
						,p.Diameter
						,@RetailerPrice
						,@WholesalerPrice
						,p.IsPriceAutoCalculated
					FROM dbo.Products p WITH (NOLOCK)
					WHERE ProductId = @ProductId

					SET @NewProductId = SCOPE_IDENTITY()
				END

				IF (@NewProductId > 0)
				BEGIN
					INSERT INTO dbo.ProductQuantities
					(
						ProductId
						,QuantityDate
						,Quantity
						,LastModifiedBy
					)
					SELECT @NewProductId
						,@Date
						,0
						,@UserID

					IF (@FromTenantId<>@ToTenantId AND @NewProductId>0
						AND EXISTS (SELECT 1 VendorId FROM Vendors WHERE VendorId=@VendorId AND TenantId=@FromTenantId))
					BEGIN
						INSERT INTO [dbo].[ProductVendorMapping] 
						([ProductId]
					   ,[VendorId]
					   ,[IsDefault]
					   ,[VendorProductId]
					   ,[IsDeleted]
					   ,[CreatedBy]
					   ,[CreatedDate]
					   ,[CreatedUTCDate])
						VALUES
					   (@NewProductId
					   ,@VendorId
					   ,0---------- is default-----
					   ,@ProductId
					   ,0-----------Isdeleted
					   ,@UserID
					   ,@Date
					   ,@UTCDate
					   )
					END
					INSERT INTO dbo.ActivityLogs
					(
						SubjectTypeId
						,SubjectId
						,Description
						,Action
						,CreatedBy
						,CreatedDate
						,CreatedUTCDate
					)
					SELECT @SubjectTypeId
						,@NewProductId
						,'Product has been copied from ' + p.ProductTitle + ' - ' + p.ModelNo
						,'CLONE'
						,@UserID
						,@Date
						,@UTCDate
					FROM dbo.Products p WITH (NOLOCK)
					WHERE ProductId = @ProductId
				END

				SELECT *
				FROM dbo.Products p WITH (NOLOCK)
				WHERE p.ProductId = @NewProductId
			END
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK

		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT

		SELECT @ErrorMessage = ERROR_MESSAGE()
			,@ErrorSeverity = ERROR_SEVERITY()
			,@ErrorState = ERROR_STATE()

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState)
	END CATCH
END

GO

