CREATE TABLE Customers (
    Email VARCHAR(50) PRIMARY KEY NOT NULL,
    FirstName VARCHAR(30) Null, 
    LastName VARCHAR(30) Null,	
	[Loyalty Status]  VARCHAR(10) default 'Regular',
    Password VARCHAR(20)  NOT Null,
    [Adress-Country] VARCHAR(50) Null,
    [Adress-Apartment] VARCHAR(10) Null,
    [Adress-Street] VARCHAR(100) Null,
    [Adress-City] VARCHAR(30) Null,
    [Adress-Zip] VARCHAR(10)Null
);


CREATE TABLE CreditCards (
    CardNumber VARCHAR(16) PRIMARY KEY NOT NULL,
    [Validity month] VARCHAR(2) NOT Null ,
	 [Validity year] VARCHAR(5) NOT Null ,
    CVV VARCHAR(5)  NOT Null,
	Email VARCHAR(50) NOT Null
);

CREATE TABLE Orders (
    OrderID VARCHAR(100) PRIMARY KEY NOT NULL,
    OrderDT DATETIME NULL,
    CardNumber VARCHAR(16) NOT NULL 
);


CREATE TABLE Searches (
    SearchIP VARCHAR(15) NOT NULL,
    SearchDT DATETIME NOT NULL,
    SearchContent VARCHAR(255) NULL,
	OrderId VARCHAR(100) NULL 
    PRIMARY KEY (SearchIP, SearchDT)
	);


CREATE TABLE Browsings (
    SearchIP VARCHAR(15) NOT NULL,
    SearchDT DATETIME NOT NULL,
    Email VARCHAR(50) NOT NULL,
    PRIMARY KEY (SearchIP, SearchDT, Email)
);

CREATE TABLE Products (
    ProductName VARCHAR(100) PRIMARY KEY NOT NULL,
    Description VARCHAR(255) NOT NULL,
    Price MONEY NOT NULL
);

CREATE TABLE  SearchResults(
   SearchIP VARCHAR(15) NOT NULL,
   SearchDT DATETIME NOT NULL,
   ProductName VARCHAR(100)  NOT NULL,
    PRIMARY KEY(SearchIP,SearchDT,ProductName)
	);



CREATE TABLE Designs (
   DesignID VARCHAR(15)  NOT NULL,
   ProductName VARCHAR(100)  NOT NULL,
   PRIMARY KEY(DesignID,ProductName)
);


CREATE TABLE SmallSeedsDesigns(
  DesignID VARCHAR(15) NOT NULL,
  ProductName VARCHAR(100)  NOT NULL,
  SmallSeed VARCHAR(15) NOT NULL,
  PRIMARY KEY (DesignID,ProductName,SmallSeed)
  );


CREATE TABLE BigSeedsDesigns( 
  DesignID VARCHAR(15) NOT NULL,
  ProductName VARCHAR(100)  NOT NULL,
  BigSeed VARCHAR(15) NOT NULL,
  PRIMARY KEY (DesignID,ProductName,BigSeed)
  );



CREATE TABLE Details(
  OrderID VARCHAR(100) NOT NULL,
  DesignID VARCHAR(15) NOT NULL,
  ProductName VARCHAR(100)  NOT NULL,
  Quantity int default 0 ,
   PRIMARY KEY(OrderID,DesignID,ProductName)
   );
---------------------------------------------------------------------------------------------

-- אלוצים בטבלאות
ALTER TABLE Customers 
ADD CONSTRAINT CK_Email CHECK (Email LIKE '%@%.%'),
CONSTRAINT CK_Password CHECK (
    LEN(Password) BETWEEN 8 AND 20 AND 
    Password LIKE '%[A-Z]%' AND 
    Password LIKE '%[a-z]%' AND 
    Password LIKE '%[0-9]%' AND 
    Password LIKE '%[^A-Za-z0-9]%'
);
ALTER TABLE CreditCards 
ADD CONSTRAINT CK_cardmonth CHECK( (LEN([Validity Month]) = 1 AND [Validity Month] BETWEEN '1' AND '9') 
    OR 
    (LEN([Validity Month]) = 2 AND [Validity Month] BETWEEN '01' AND '12')),
 CONSTRAINT CK_cardyear CHECK ([Validity Year] >= YEAR(GETDATE())),
 CONSTRAINT CK_CreditCard CHECK (LEN(CardNumber) = 16 AND CardNumber LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
CONSTRAINT CK_CVV CHECK (CVV LIKE '[1-9][0-9][0-9]');

ALTER TABLE Products 
ADD CONSTRAINT CK_Price CHECK (Price >= 0);

ALTER TABLE Searches 
ADD CONSTRAINT CK_IP CHECK (SearchIP LIKE '%.%.%.%');


--מפתחות זרים בטבלת CreditCard
ALTER TABLE CreditCards
ADD CONSTRAINT FK_CreditCard_Customers FOREIGN KEY (Email) REFERENCES Customers(Email);

-- מפתחות זרים בטבלת Orders
ALTER TABLE Orders 
ADD CONSTRAINT FK_CreditCards_Orders FOREIGN KEY (CardNumber) REFERENCES CreditCards(CardNumber);

-- מפתחות זרים בטבלת Searches
ALTER TABLE Searches
ADD CONSTRAINT FK_Search_Order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID);

-- מפתחות זרים בטבלת Browsings
ALTER TABLE Browsings 
ADD CONSTRAINT FK_Browsings_Searches FOREIGN KEY (SearchIP, SearchDT) REFERENCES Searches(SearchIP, SearchDT),
CONSTRAINT FK_Browsings_Customers FOREIGN KEY (Email) REFERENCES Customers(Email);

--מפתחות זרים בטבלת SearchResults

ALTER TABLE SearchResults 
ADD CONSTRAINT FK_SearchResults_Searches FOREIGN KEY (SearchIP, SearchDT) REFERENCES Searches(SearchIP, SearchDT),
 CONSTRAINT FK_SearchResults_Product FOREIGN KEY (ProductName) REFERENCES Products(ProductName);

-- מפתחות זרים בטבלת Designs
ALTER TABLE Designs 
ADD CONSTRAINT FK_Designs_Products FOREIGN KEY (ProductName) REFERENCES Products(ProductName);

 --מפתחות זרים בטבלת BigSeedsDesigns  SmallSeedsDesigns
 ALTER TABLE BigSeedsDesigns
 ADD CONSTRAINT FK_BigSeedsDesigns_Designs FOREIGN KEY (DesignID,ProductName) REFERENCES Designs(DesignID,ProductName);

 ALTER TABLE SmallSeedsDesigns
 ADD CONSTRAINT FK_SmallSeedsDesigns_Designs FOREIGN KEY (DesignID,ProductName) REFERENCES Designs( DesignID, ProductName);
 
 --מפתחות זרים בטבלת DETAILS

ALTER TABLE Details
ADD CONSTRAINT FK_Details_Designs FOREIGN KEY ( DesignID, ProductName) REFERENCES Designs( DesignID, ProductName),
 CONSTRAINT FK_Details_Orders FOREIGN KEY (OrderID) REFERENCES ORDERS(OrderID);


 ---הכנסת נתונים שלב  

 CREATE TABLE Cities (
    City VARCHAR(30) PRIMARY KEY NOT NULL
);

INSERT INTO Cities
SELECT DISTINCT [Adress-City]
FROM Customers;

ALTER TABLE Customers 
ADD CONSTRAINT FK_City FOREIGN KEY ([Adress-City]) REFERENCES Cities(City);

CREATE TABLE Countries (
    Country VARCHAR(50) PRIMARY KEY NOT NULL
);

INSERT INTO Countries
SELECT DISTINCT [Adress-Country]
FROM Customers;

ALTER TABLE Customers 
ADD CONSTRAINT FK_Country FOREIGN KEY ([Adress-Country]) REFERENCES Countries(Country);



--------------------------------------------
-- הסרת אלוצים

ALTER TABLE Browsings 
DROP CONSTRAINT FK_Browsings_Searches,
 CONSTRAINT FK_Browsings_Customers;

ALTER TABLE Designs
DROP CONSTRAINT FK_Designs_Products;

ALTER TABLE Products
DROP CONSTRAINT CK_price ;

ALTER TABLE Searches 
DROP CONSTRAINT CK_IP,
 CONSTRAINT FK_Search_Order;

ALTER TABLE Orders 
Drop CONSTRAINT FK_CreditCards_Orders;

ALTER TABLE Details
 Drop CONSTRAINT FK_Details_Designs, 
 CONSTRAINT FK_Details_Orders;

ALTER TABLE CreditCards
DROP CONSTRAINT CK_cardmonth,
  CONSTRAINT CK_cardyear,
  CONSTRAINT CK_CreditCard,
  CONSTRAINT CK_CVV,
  CONSTRAINT FK_CreditCard_Customers;

  ALTER TABLE Customers
DROP CONSTRAINT FK_City,
 CONSTRAINT FK_Country,
 CONSTRAINT CK_Email,
 CONSTRAINT CK_Password
 ;

-- הסרת טבלאות
DROP TABLE Cities;
DROP TABLE Countries;
DROP TABLE Details;
DROP TABLE BigSeedsDesigns;
DROP TABLE SmallSeedsDesigns;
DROP TABLE Designs;
DROP TABLE SearchResults;
DROP TABLE Products;
DROP TABLE Browsings;
DROP TABLE Searches;
DROP TABLE Orders;
DROP TABLE CreditCards;
DROP TABLE Customers;