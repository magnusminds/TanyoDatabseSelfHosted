CREATE TABLE TestTable
(
    CustomerId INT IDENTITY(1,1) PRIMARY KEY,
    CustomerName NVARCHAR(100),
    Email NVARCHAR(150),
    PhoneNumber VARCHAR(20),
    CreditCardNumber VARCHAR(20),
    Salary DECIMAL(18,2),
    CreatedDate DATETIME2
);