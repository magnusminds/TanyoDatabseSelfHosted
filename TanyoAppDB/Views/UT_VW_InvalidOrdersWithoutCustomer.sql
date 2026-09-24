

CREATE VIEW [dbo].[UT_VW_InvalidOrdersWithoutCustomer]
WITH ENCRYPTIONAS
SELECT *
from Orders o
where not exists(
	select 1
	from customers c
	where c.CustomerID = o.CustomerID
)

GO

