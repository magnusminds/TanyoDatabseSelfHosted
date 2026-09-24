-- =============================================
-- Author:		Parshwa Kapadia
-- Create date: 04-10-2022
-- Description:	Generate Random ID
-- =============================================
--SELECT * FROM GetRandomID 
CREATE VIEW [dbo].[GetRandomID] 
WITH ENCRYPTIONAS
SELECT NEWID() as RandomID

GO

