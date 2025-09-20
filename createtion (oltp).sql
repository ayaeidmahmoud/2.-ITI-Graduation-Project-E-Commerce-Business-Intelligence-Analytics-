CREATE DATABASE E_Commerce;
drop database E_Commerce
GO
USE E_Commerce;
GO
CREATE SCHEMA users;
GO
CREATE SCHEMA products;
GO
CREATE SCHEMA cart;
GO
CREATE SCHEMA orders;
GO

CREATE TABLE users.Customer (
    Cust_ID INT PRIMARY KEY IDENTITY(1,1),
    Cust_Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    Address NVARCHAR(200),
    Phone NVARCHAR(20) UNIQUE,
    Registration_Date DATE DEFAULT GETDATE(),
    Password NVARCHAR(100) NOT NULL
);

EXEC sp_rename 'users.Customer.[Address]', 'Country', 'COLUMN';
ALTER TABLE users.Customer
ALTER COLUMN Country NVARCHAR(100) NOT NULL;


GO

CREATE TABLE products.Category (
    Category_ID INT PRIMARY KEY IDENTITY(1,1),
    Category_Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(200)
);

CREATE TABLE products.Brand (
    Brand_ID INT PRIMARY KEY IDENTITY(1,1),
    Brand_Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(200)
);

CREATE TABLE products.SubCategory (
    SubCat_ID INT PRIMARY KEY IDENTITY(1,1),
    SubCat_Name NVARCHAR(100) NOT NULL,
    Category_ID INT NOT NULL,
    CONSTRAINT FK_SubCategory_Category FOREIGN KEY (Category_ID)
        REFERENCES products.Category(Category_ID)
);

CREATE TABLE products.Product (
    Product_ID INT PRIMARY KEY IDENTITY(1,1),
    Product_Name NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) CHECK (Price >= 0),
    Description NVARCHAR(200),
    Stock_Quantity INT CHECK (Stock_Quantity >= 0),
    Brand_ID INT,
    SubCat_ID INT,
    FOREIGN KEY (Brand_ID) REFERENCES products.Brand(Brand_ID),
    FOREIGN KEY (SubCat_ID) REFERENCES products.SubCategory(SubCat_ID)
);
GO
CREATE TABLE orders.ShipMethod (
    ShipMethod_ID INT PRIMARY KEY IDENTITY(1,1),
    Method_Name NVARCHAR(100) NOT NULL,
    Estimated_Days INT CHECK (Estimated_Days > 0),
    Cost DECIMAL(10,2) CHECK (Cost >= 0)
);

CREATE TABLE orders.Orders (
    Order_ID INT PRIMARY KEY IDENTITY(1,1),
    Cust_ID INT NOT NULL,
    ShipMethod_ID INT NOT NULL,
    Order_Date DATETIME DEFAULT GETDATE(),
    Ship_Date DATETIME,
    Due_Date DATETIME,
    Status NVARCHAR(50) CHECK (Status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled', 'Returned')),
    Total_Amount DECIMAL(10,2) NOT NULL,
    Shipping_Address NVARCHAR(255) NOT NULL,
    FOREIGN KEY (Cust_ID) REFERENCES users.Customer(Cust_ID),
    FOREIGN KEY (ShipMethod_ID) REFERENCES orders.ShipMethod(ShipMethod_ID)
);

CREATE TABLE orders.OrderDetails (
    OrderDetail_ID INT PRIMARY KEY IDENTITY(1,1),
    Quantity INT CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) CHECK (UnitPrice >= 0),
    Order_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES products.Product(Product_ID)
);

CREATE TABLE orders.Returned (
    Return_ID INT PRIMARY KEY IDENTITY(1,1),
    Order_ID INT NOT NULL,
    Product_ID INT NOT NULL,
    Reason NVARCHAR(500),
    Status NVARCHAR(50) NOT NULL CHECK (Status IN ('Requested', 'Approved', 'Rejected', 'Processed')),
    Requested_At DATETIME DEFAULT GETDATE(),
    Processed_At DATETIME,
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES products.Product(Product_ID)
);

CREATE TABLE orders.Payment (
    Payment_ID INT PRIMARY KEY IDENTITY(1,1),
    Order_ID INT NOT NULL,
    Payment_Date DATETIME DEFAULT GETDATE(),
    Payment_Method NVARCHAR(50) NOT NULL CHECK (Payment_Method IN ('Credit Card', 'Debit Card', 'PayPal', 'Cash on Delivery', 'Bank Transfer')),
    Payment_Status NVARCHAR(50) NOT NULL CHECK (Payment_Status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    Amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID)
);
GO
CREATE TABLE users.Review (
    Review_ID INT PRIMARY KEY IDENTITY(1,1),
    Review_Date DATE DEFAULT GETDATE(),
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(300),
    Cust_ID INT,
    Product_ID INT,
    Order_ID INT NULL,
    FOREIGN KEY (Cust_ID) REFERENCES users.Customer(Cust_ID),
    FOREIGN KEY (Product_ID) REFERENCES products.Product(Product_ID),
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID)
);
GO
CREATE TABLE cart.Cart (
    Cart_ID INT PRIMARY KEY IDENTITY(1,1),
    Created_At DATE DEFAULT GETDATE(),
    Cust_ID INT NOT NULL,
    FOREIGN KEY (Cust_ID) REFERENCES users.Customer(Cust_ID)
);

CREATE TABLE cart.Cart_Items (
    Cart_ID INT,
    Product_ID INT,
    Quantity INT CHECK (Quantity > 0),
    PRIMARY KEY (Cart_ID, Product_ID),
    FOREIGN KEY (Cart_ID) REFERENCES cart.Cart(Cart_ID),
    FOREIGN KEY (Product_ID) REFERENCES products.Product(Product_ID)
);

CREATE TABLE cart.Cart_Order (
    Cart_ID INT,
    Order_ID INT,
    PRIMARY KEY (Cart_ID, Order_ID),
    FOREIGN KEY (Cart_ID) REFERENCES cart.Cart(Cart_ID),
    FOREIGN KEY (Order_ID) REFERENCES orders.Orders(Order_ID)
);
GO
select * from cart.Cart
select* from cart.Cart_Items
select * from cart.Cart_Order
select * from users.Review
select* from orders.Orders
select* from orders.OrderDetails
select* from products.Product
select* from users.Customer

DECLARE @i INT = 0;

WHILE @i < 7000
BEGIN
    INSERT INTO cart.Cart (Created_At, Cust_ID)
    VALUES (
        DATEADD(DAY, ABS(CHECKSUM(NEWID())) % DATEDIFF(DAY, '2021-08-01', '2025-10-07'), '2021-08-01'),
        1 + ABS(CHECKSUM(NEWID())) % 5000
    );
    SET @i += 1;
END;



SET NOCOUNT ON;
DECLARE @i INT = 1;

WHILE @i <= 10000
BEGIN
    DECLARE @Cart_ID INT = FLOOR(RAND() * 7000 + 1);
    DECLARE @Product_ID INT = FLOOR(RAND() * 1000 + 1);

    IF NOT EXISTS (
        SELECT 1 FROM cart.Cart_Items
        WHERE Cart_ID = @Cart_ID AND Product_ID = @Product_ID
    )
    BEGIN
        INSERT INTO cart.Cart_Items (Cart_ID, Product_ID, Quantity)
        VALUES (
            @Cart_ID,
            @Product_ID,
            FLOOR(RAND() * 10 + 1)
        );

        SET @i += 1;
    END
END;

SELECT COUNT(*) AS TotalRows FROM cart.Cart_Items;

SET NOCOUNT ON;

DECLARE @i INT = 1;

WHILE @i <= 30000
BEGIN
    INSERT INTO cart.Cart_Order (Cart_ID, Order_ID)
    VALUES (
        FLOOR(RAND(CHECKSUM(NEWID())) * 7000) + 1,  -- ÚÔæÇÆí ãä 1 áÜ 7000
        @i                                          -- Order_ID ÝÑíÏ
    );

    SET @i = @i + 1;
END;

SELECT COUNT(*) AS TotalRows FROM users.Review;


SET NOCOUNT ON;

DECLARE @i INT = 1;
DECLARE @commentList TABLE (ID INT IDENTITY(1,1), Comment NVARCHAR(255));

-- ÊÚáíÞÇÊ æÇÞÚíÉ ÈÇááÛÉ ÇáÅäÌáíÒíÉ
INSERT INTO @commentList (Comment) VALUES 
(N'Excellent product! Highly recommend.'),
(N'Not as expected, quality could be better.'),
(N'Fast delivery and good packaging.'),
(N'Great value for the price.'),
(N'I had some issues with the size.'),
(N'Customer service was very helpful.'),
(N'Would buy again. Very satisfied.'),
(N'Disappointed. Product arrived damaged.'),
(N'Amazing! Just what I needed.'),
(N'So far so good.'),
(N'The quality is better than expected.'),
(N'The item didn’t match the description.'),
(N'I’m impressed with the speed of delivery.'),
(N'The color was slightly different, but still nice.'),
(N'I received the wrong item, but support fixed it fast.'),
(N'Product works perfectly.'),
(N'Packaging could be improved.'),
(N'I got a great discount.'),
(N'Will definitely order again.'),
(N'I love this product!');

DECLARE @commentCount INT = (SELECT COUNT(*) FROM @commentList);
DECLARE @randCommentID INT;

WHILE @i <= 40000
BEGIN
    SET @randCommentID = FLOOR(RAND() * @commentCount + 1);

    INSERT INTO users.Review (Review_Date, Cust_ID, Rating, Comment, Order_ID, Product_ID)
    SELECT
        DATEADD(DAY, ABS(CHECKSUM(NEWID())) % DATEDIFF(DAY, '2021-08-01', '2025-10-07'), '2021-08-01'),
        FLOOR(RAND() * 5000 + 1),
        FLOOR(RAND() * 5 + 1),
        Comment,
        FLOOR(RAND() * 30000 + 1),
        FLOOR(RAND() * 1000 + 1)
    FROM @commentList
    WHERE ID = @randCommentID;

    SET @i = @i + 1;
END;