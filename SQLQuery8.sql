SELECT  TOP 1 
    DET.ProductName,c.[Adress-Country],
    SUM(Quantity) AS QUANTITY 
FROM Orders o
    JOIN Details det ON o.OrderID = det.OrderID
    JOIN CreditCards AS CC on O.CardNumber= CC.CardNumber
    JOIN Customers c ON CC.Email = c.Email
WHERE 
    YEAR(o.OrderDT) = 2024
    AND c.[Adress-Country] = 'France'
GROUP BY 
 DET.ProductName , c.[Adress-Country]
ORDER BY 
QUANTITY DESC;
---------------------------------------
SELECT TOP 5
    C.Email, 
    C.FirstName, 
    C.LastName,
    COUNT(O.OrderID) AS TotalOrders
FROM Customers C
JOIN CreditCards CC ON C.Email = CC.Email
JOIN Orders O ON CC.CardNumber = O.CardNumber
WHERE YEAR(O.OrderDt) = 2024  -- סינון על פי שנת ההזמנה
GROUP BY C.Email, C.FirstName, C.LastName
HAVING COUNT(O.OrderID) >= 10
ORDER BY TotalOrders DESC  -- סדר מהלקוח שהזמין הכי הרבה
-------------------------------
SELECT 
    C.Email,
    C.FirstName,
    C.LastName,
    (SELECT AVG(D.Quantity * P.Price)
     FROM Orders O
     JOIN Details D ON O.OrderID = D.OrderID
     JOIN Products P ON D.ProductName = P.ProductName
     JOIN CreditCards CC ON O.CardNumber = CC.CardNumber
     WHERE CC.Email = C.Email) AS AverageSpent
FROM 
    Customers C;
------------------------------------------
SELECT ProductName
FROM SearchResults 
WHERE MONTH(SearchDT) = MONTH(GETDATE()) 
      AND YEAR(SearchDT) = YEAR(GETDATE())
GROUP BY ProductName
HAVING COUNT(*) < (
    SELECT COUNT(*)
    FROM SearchResults
    WHERE MONTH(SearchDT) = MONTH(DATEADD(MONTH, -1, GETDATE())) 
          AND YEAR(SearchDT) = YEAR(DATEADD(MONTH, -1, GETDATE()))
          AND ProductName = SearchResults.ProductName
);
---------------------------------------
UPDATE Customers
SET [Loyalty Status] = 'Inactive'
WHERE Email IN (
    SELECT C.Email
    FROM Customers C
    JOIN CreditCards CC ON C.Email = CC.Email
    JOIN Orders O ON CC.CardNumber = O.CardNumber
    WHERE C.Email NOT IN (
        SELECT B.Email
        FROM Browsings B
        WHERE YEAR(B.SearchDT) = 2024
    )
    GROUP BY C.Email
    HAVING DATEDIFF(YY, MAX(O.OrderDT), GETDATE()) >= 1
-------------------------------------------------
SELECT DISTINCT cc.Email
FROM Orders o
JOIN CreditCards cc ON o.CardNumber = cc.CardNumber
WHERE YEAR(o.OrderDT) = '2024'

INTERSECT

SELECT Email
FROM Browsings
WHERE YEAR(SearchDT) = '2023' AND Email NOT IN (
    -- שאילתה מקוננת למציאת לקוחות שביצעו הזמנה בשנת 2023
    SELECT DISTINCT cc2.Email
    FROM Orders o2
    JOIN CreditCards cc2 ON o2.CardNumber = cc2.CardNumber
    WHERE YEAR(o2.OrderDT) = '2023')
GROUP BY Email
HAVING COUNT(*) > 3
SELECT * FROM BROWSINGS
-------------------------------------------------
CREATE VIEW vw_CustomerOrderSummary AS
SELECT 
    C.Email, 
    C.FirstName, 
    C.LastName, 
    O.OrderID, 
	Sum(P.Price*D.Quantity) AS OrderSum
FROM 
Customers C JOIN CreditCards CC ON C.Email = CC.Email
JOIN Orders O ON CC.CardNumber = O.CardNumber
JOIN Details D ON O.OrderID = D.OrderID
JOIN DESIGNS AS DES ON DES.PRODUCTNAME= D.PRODUCTNAME
AND DES.DESIGNID= D.DESIGNID
JOIN Products P ON D.ProductName = P.ProductName  
GROUP BY C.Email,  C.FirstName,   C.LastName, O.OrderID;
--------------------------------------
CREATE FUNCTION GetCustomersWithMinOrders(
    @minOrders INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        C.Email,
        C.FirstName,
        C.LastName,
        COUNT(O.OrderID) AS OrderCount
    FROM 
        Customers AS C
    JOIN 
        CreditCards AS CC ON C.Email = CC.Email
    JOIN 
        Orders AS O ON CC.CardNumber = O.CardNumber
    GROUP BY 
        C.Email, C.FirstName, C.LastName
    HAVING 
        COUNT(O.OrderID) > @minOrders -- רק לקוחות עם יותר מ-X הזמנות
);

-- דוגמת קריאה לפונקציה
SELECT * 
FROM GetCustomersWithMinOrders(100);
------------------------------------------
CREATE FUNCTION GetCustomerCountByLoyaltyStatus(
    @loyaltyStatus NVARCHAR(10)
)
RETURNS INT
AS
BEGIN
    DECLARE @customerCount INT;

    SELECT @customerCount = COUNT(*)
    FROM Customers
    WHERE [Loyalty Status] = @loyaltyStatus;

    RETURN @customerCount;
END;

-- דוגמת קריאה לפונקציה
SELECT dbo.GetCustomerCountByLoyaltyStatus('Regular') AS RegularCustomerCount;
----------------------------------------------
DROP TRIGGER trg_UpdateLoyaltyStatus;
CREATE TRIGGER trg_UpdateLoyaltyStatus
ON Orders
AFTER INSERT, UPDATE
AS
BEGIN
    -- עדכון סטטוס נאמנות עבור הלקוח שביצע הזמנה
    UPDATE Customers
    SET [Loyalty Status] = CASE 
        WHEN TotalOrders >= 40 THEN 'PLATINUM'
        WHEN TotalOrders BETWEEN 9 AND 39 THEN 'GOLD'
        WHEN TotalOrders BETWEEN 3 AND 8 THEN 'SILVER'
        ELSE 'REGULAR'
    END
    FROM Customers C
    JOIN (
        SELECT  
            CC.Email,
            COUNT(O.OrderID) AS TotalOrders
        FROM CreditCards CC
        JOIN Orders O ON CC.CardNumber = O.CardNumber
        GROUP BY CC.Email
    ) AS OrderSummary ON C.Email = OrderSummary.Email
    WHERE C.Email IN (
        SELECT CC.Email
        FROM CreditCards CC
        JOIN INSERTED I ON CC.CardNumber = I.CardNumber
    );
END
------------------------------------------
drop PROCEDURE ChangeUserPassword
CREATE PROCEDURE ChangeUserPassword
    @Email VARCHAR(50),
    @OldPassword VARCHAR(20),
    @NewPassword VARCHAR(20)
AS
BEGIN
    -- בדיקה אם הלקוח קיים עם הסיסמא הנוכחית
    IF EXISTS (SELECT 1 FROM Customers WHERE Email = @Email AND Password = @OldPassword)
    BEGIN
        -- בדיקה אם הסיסמא החדשה עומדת בתנאים
        IF LEN(@NewPassword) BETWEEN 8 AND 20 
           AND @NewPassword LIKE '%[A-Z]%' 
           AND @NewPassword LIKE '%[a-z]%' 
           AND @NewPassword LIKE '%[0-9]%' 
           AND @NewPassword LIKE '%[^A-Za-z0-9]%'
        BEGIN
            -- עדכון הסיסמא
            UPDATE Customers
            SET Password = @NewPassword
            WHERE Email = @Email;

            PRINT 'Password updated successfully.';
        END
        ELSE
        BEGIN
            PRINT 'New password does not meet the security requirements.';
        END
    END
    ELSE
    BEGIN
        PRINT 'Invalid email or current password.';
    END
END;
-------------------------------
WITH CustomerSearchCounts AS (
    SELECT 
        b.Email,
        COUNT(*) AS SearchCount
    FROM 
        Browsings b
    GROUP BY 
        b.Email
), RankedSearches AS (
    SELECT 
        csc.Email,
        csc.SearchCount,
        RANK() OVER (ORDER BY csc.SearchCount DESC) AS CustomerRank
    FROM 
        CustomerSearchCounts csc
)
SELECT 
    r.Email,
    r.CustomerRank,
    r.SearchCount,
    ROW_NUMBER() OVER (PARTITION BY r.Email ORDER BY s.SearchDT) AS SearchRowNum,
    s.SearchDT
FROM 
    RankedSearches r
JOIN 
    Browsings s ON r.Email = s.Email
ORDER BY 
    r.CustomerRank, s.SearchDT;
-----------------------------------------------------
SELECT 
    C.Email, 
    O.OrderID, 
    O.OrderDT, 
    LAG(O.OrderDT) OVER (PARTITION BY C.Email ORDER BY O.OrderDT) AS PreviousOrderDT,
    LEAD(O.OrderDT) OVER (PARTITION BY C.Email ORDER BY O.OrderDT) AS NextOrderDT,
    DATEDIFF(DAY, LAG(O.OrderDT) OVER (PARTITION BY C.Email ORDER BY O.OrderDT), O.OrderDT) AS DaysSinceLastOrder,
    DATEDIFF(DAY, O.OrderDT, LEAD(O.OrderDT) OVER (PARTITION BY C.Email ORDER BY O.OrderDT)) AS DaysUntilNextOrder
FROM 
    Customers C
JOIN 
    CreditCards CC ON C.Email = CC.Email
JOIN 
    Orders O ON CC.CardNumber = O.CardNumber
WHERE 
    C.Email = 'user15@example.com'
ORDER BY 
    O.OrderDT;
-----------------------------------------
WITH 
-- שאילתה ראשונה שמחשבת את סך הכספים שהוזמנו לפי מדינה
TotalOrdersByCountry AS (
    SELECT C.[Adress-Country], SUM(P.Price * D.Quantity) AS TotalSpent
   FROM 
    Customers C
JOIN 
    CreditCards CC ON C.Email = CC.Email
JOIN 
    Orders O ON CC.CardNumber = O.CardNumber
JOIN 
    Details D ON O.OrderID = D.OrderID
JOIN 
    Products P ON D.ProductName = P.ProductName
	 GROUP BY C.[Adress-Country]
),

-- שאילתה שנייה שמביאה את מספר הלקוחות הפעילים (שהזמינו לפחות פעם אחת) לפי מדינה
ActiveCustomersByCountry AS (
    SELECT C.[Adress-Country], COUNT(DISTINCT C.Email) AS ActiveCustomers
    FROM Customers C
    JOIN CreditCards CC ON C.Email = CC.Email
    JOIN Orders O ON CC.CardNumber = O.CardNumber
    WHERE YEAR(O.OrderDT) = 2024
    GROUP BY C.[Adress-Country]
),

-- שאילתה שלישית שמביאה את כמות החיפושים שבוצעו בכל מדינה לפי מועד
SearchesByCountryAndDate AS (
    SELECT C.[Adress-Country],  COUNT(S.SearchIP) AS TotalSearches
    FROM Customers C
    JOIN Browsings B ON C.Email = B.Email
    JOIN Searches S ON B.SearchIP = S.SearchIP AND B.SearchDT = S.SearchDT
    GROUP BY C.[Adress-Country]
),

-- שאילתה רביעית שמבצעת חיבור של הנתונים משתי השאילתות הראשונות
CombinedData AS (
    SELECT 
        T.[Adress-Country],
        T.TotalSpent,
        A.ActiveCustomers
    FROM TotalOrdersByCountry T
    JOIN ActiveCustomersByCountry A ON T.[Adress-Country] = A.[Adress-Country]
)

-- השאילתה הסופית המשלבת את כלל הנתונים ומוסיפה עמודות נוספות
SELECT 
    C.[Adress-Country],
    C.TotalSpent,
    C.ActiveCustomers,
    S.TotalSearches,
    CASE 
        WHEN C.TotalSpent > 30000000 THEN 'VIP'
        ELSE 'Regular'
    END AS CustomerType
FROM CombinedData C
LEFT JOIN SearchesByCountryAndDate S ON C.[Adress-Country] = S.[Adress-Country]
ORDER BY C.[Adress-Country];
--------------------------------------------

