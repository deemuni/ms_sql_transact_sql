/*
********************************************************************************
CIS276 @PCC using SQL Server 2012
Lab8 By Dipti Muni
Using T-SQL programming language, we will write the following embedded SQL, stored
procedures and triggers. 

SELECT * FROM SALESPERSONS;
SELECT * FROM CUSTOMERS;
SELECT * FROM INVENTORY;
SELECT * FROM ORDERS;
SELECT * FROM ORDERITEMS;


2015.03.02 Vicki Jonathan, Instructor
2018.05.29 Starting Lab 8 by Dipti Muni
2018.05.30 Validating CustId, OrderID, PartID, Qty
2018.06.04 Getnewdetail, insert and update triggers
2018.06.05 addlineitem and lab8proc
2018.06.07 updated error handling and testing
2018.06.09 Testing lab8proc
********************************************************************************
*/
-- activate appropriate db where user has READ/WRITE privilege
USE s276DMuni
/*
--------------------------------------------------------------------------------
CUSTOMERS.CustID validation by Dipti Muni on 6-10-2018.

1. 	ValidateCustID, a procedure that will return a value if the CustID is in 
	the CUSTOMERS table
--------------------------------------------------------------------------------
*/

IF EXISTS (SELECT name FROM sys.objects WHERE name = 'ValidateCustID')
    BEGIN 
        DROP PROCEDURE ValidateCustID; 
    END;    -- must use block for more than one statement and optional for one sttmt. 	
-- END IF;  -- SQL Server does not use END IF 
GO

CREATE PROCEDURE ValidateCustID 
    @vCustID SMALLINT,
    @vCustFound  CHAR(25) OUTPUT 
AS 
BEGIN 
    SET @vCustFound = 'Invalid';  -- initializes my found variable
    SELECT @vCustFound = 'Valid' 
    FROM CUSTOMERS
    WHERE CustID = @vCustID;
END;
GO

-- testing block for ValidateCustID
BEGIN
    
    DECLARE @vCFound CHAR(25);  -- holds value returned from procedure

    PRINT 'Valid CustID';
    EXECUTE ValidateCustID 1, @vCFound OUTPUT;
    PRINT 'ValidateCustID test with valid CustID 1 returns ' + @vCFound;
	-- When @vCFound contains a valid the custid is validated

    PRINT 'Invalid CustID';
    EXECUTE ValidateCustID 5, @vCFound OUTPUT;
    PRINT 'ValidateCustID test with invalid CustID 5 returns ' + @vCFound;
	-- When @vCFound contains invalid the custid is not in the CUSTOMERS table

END;
GO

/*
--------------------------------------------------------------------------------
ORDERS.OrderID validation by Dipti Muni on 06-10-2018.

2. 	ValidateOrderID, a procedure that will return a value if the Orderid is valid 
	for the customer
(1) Check ORDERS for valid OrderID
(2) Check ORDERS for valid CustID/OrderID pairing
This stored procedure has two input values!
--------------------------------------------------------------------------------
*/

-- DROP ValidateOrderID
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'ValidateOrderID')
    BEGIN 
        DROP PROCEDURE ValidateOrderID; 
    END; 
--END IF; -- SQL Server does not use END IF 
GO
-- CREATE ValidateOrderID
CREATE PROCEDURE ValidateOrderID
	@vCustID SMALLINT,
    @vOrderID SMALLINT,
    @vOrderFound	CHAR(25) OUTPUT,
    @vMatch  CHAR(2) OUTPUT 
AS 
BEGIN 
    SET @vOrderFound = 'Invalid';  -- initializes my found variable
    SELECT @vOrderFound = 'Valid'
    FROM ORDERS
    WHERE OrderID = @vOrderID;
    
    IF (@vOrderFound = 'Valid') 
    	BEGIN
    		SET @vMatch = 'N'; --initializes my match variable
    		SELECT @vMatch = 'Y'
    		FROM ORDERS
    		WHERE ORDERS.CustID = @vCustID
    		AND   ORDERS.OrderID = @vOrderID;	
    	END;
    --END IF; -- SQL Server does not use END IF 
END;
GO

-- Test ValidateOrderID:
BEGIN
    
    DECLARE @OrderFound CHAR(25);
    DECLARE @MatchFound CHAR(2);  -- holds value returned from procedure

    -- OrderID, CustID pairing valid
    PRINT 'CUSTID Valid, ORDERID Valid, Pairing Valid';
    EXECUTE ValidateOrderID 1, 6099, @OrderFound OUTPUT, @MatchFound OUTPUT;
    PRINT 'ValidateOrderID test with valid pairing of CustID 1 and OrderID 6099 returns ' + @OrderFound + 'and ' + @MatchFound;;
	
    -- OrderID, CustID pairing invalid
    PRINT 'CUSTID Valid, ORDERID Valid, Pairing Invalid';
    EXECUTE ValidateOrderID 1, 6107, @OrderFound OUTPUT, @MatchFound OUTPUT;
    PRINT 'ValidateOrderID test w/invalid pairing of CustID 1 and OrderID 6107 returns ' + @OrderFound + 'and ' + @MatchFound;;
	
    -- OrderID invalid
    PRINT 'CUSTID Valid, ORDERID Invalid';
    EXECUTE ValidateOrderID 1, 9999, @OrderFound OUTPUT, @MatchFound OUTPUT;
    PRINT 'ValidateOrderID test w/valid CustID 1 and invalid OrderID 9999 returns ' + @OrderFound + 'and ' + @MatchFound;;

    -- OrderID valid	
    PRINT 'CUSTID Invalid, ORDERID Valid';
    EXECUTE ValidateOrderID 5, 6099, @OrderFound OUTPUT, @MatchFound OUTPUT;
    PRINT 'ValidateOrderID test w/invalid CustID 5 and valid OrderID 6099 returns ' + @OrderFound + 'and ' + @MatchFound;

END;
GO

/*
--------------------------------------------------------------------------------
INVENTORY.PartID validation by Dipti Muni on 06-10-2018

3. 	ValidatePartID, a procedure that will return a value if the Partid is in 
	the INVENTORY table
--------------------------------------------------------------------------------
*/

-- DROP ValidatePartID
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'ValidatePartID')
    BEGIN 
        DROP PROCEDURE ValidatePartID; 
    END; 
--END IF; -- SQL Server does not use END IF 
GO
-- CREATE ValidatePartID
CREATE PROCEDURE ValidatePartID 
    @vPartID SMALLINT,
    @vPartFound  CHAR(25) OUTPUT 
AS 
BEGIN 
    SET @vPartFound = 'Invalid';  -- initializes my found variable
    SELECT @vPartFound = Description 
    FROM INVENTORY
    WHERE PartID = @vPartID;
END;
GO
-- Test ValidatePartID
BEGIN
    
    DECLARE @vDescription CHAR(25);  -- holds value returned from procedure

    PRINT 'Valid PartID with description';
    EXECUTE ValidatePartID 1002, @vDescription OUTPUT;
    PRINT 'ValidatePartID test with valid PartID 1002 returns ' + @vDescription;

    PRINT 'Invalid PartID with no description';
    EXECUTE ValidatePartID 9999, @vDescription OUTPUT;
    PRINT 'ValidatePartID test w/invalid PartID 9999 returns ' + @vDescription;

END;
GO

/*
--------------------------------------------------------------------------------
Input quantity validation by Dipti Muni on 06-10-2018

4. 	ValidateQty, a procedure that will return a value if the Qty in the new 
	lineitem is less than zero
--------------------------------------------------------------------------------
*/

-- DROP ValidateQuantity
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'ValidateQty')
    BEGIN 
        DROP PROCEDURE ValidateQty; 
    END;
--END IF; -- SQL Server does not use END IF 
GO

-- CREATE ValidateQuantity
CREATE PROCEDURE ValidateQty 
    @vQty SMALLINT,
    @vQuantityFound  CHAR(25) OUTPUT 
AS 
BEGIN 
    SET @vQuantityFound = 'Invalid';
    IF @vQty > 0
    	BEGIN 
    		SET @vQuantityFound = 'Valid';
    	END;
    --END IF; -- SQL Server does not use END IF 
END;
GO

-- Test ValidateQty
BEGIN
    
    DECLARE @Quantity CHAR(25);  -- holds value returned from procedure

    PRINT 'VALID QTY: POSITIVE';
    EXECUTE ValidateQty 6, @Quantity OUTPUT;
    PRINT 'ValidateQty test with valid Quantity 6 returns ' + @Quantity;
	
    PRINT 'INVALID QTY: NEGATIVE';
    EXECUTE ValidateQty -1, @Quantity OUTPUT;
    PRINT 'ValidateQty test w/invalid Quantity -1 returns ' + @Quantity;

	PRINT 'INVALID QTY: ZERO';
	EXECUTE ValidateQty 0, @Quantity OUTPUT;
    PRINT 'ValidateQty test w/invalid Quantity 0 returns ' + @Quantity;
END;
GO

/*
--------------------------------------------------------------------------------
ORDERITEMS.Detail determines new value by Dipti Muni on 06-10-2018

5. 	GetNewDetail, a procedure that will determine the value of the Detail column 
	for a new line item (SQL Server will not allow you to assign a column value to the 
	newly inserted row inside of the trigger)
You can handle NULL within the projection or it in two steps
(SELECT and then test).  It is important to deal with the possibility of NULL
because the detail is part of the primary key and therefore cannot contain NULL.
--------------------------------------------------------------------------------
*/

-- DROP GetNewDetail
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'GetNewDetail')
	BEGIN 
		DROP PROCEDURE GetNewDetail; 
	END;
--END IF; -- SQL Server does not use END IF 
GO

-- CREATE GetNewDetail 
-- Input OrderID retrieves @vNewDetail (output) via a query
-- Procedure assumes OrderID is valid!
CREATE PROCEDURE GetNewDetail
	@vOrderID SMALLINT,
	@vNewDetail SMALLINT OUTPUT
AS
BEGIN
	SET @vNewDetail = 0;
	SELECT @vNewDetail = ISNULL(MAX(ORDERITEMS.Detail)+1, 1)
	FROM   ORDERITEMS
	WHERE  ORDERITEMS.OrderID = @vOrderID;
END;
GO

BEGIN

-- testing block for GetNewDetail
	DECLARE @NewDetailNo SMALLINT;

	
	EXECUTE GetNewDetail 6099, @NewDetailNo OUTPUT;
	PRINT 'When valid OrderID 6099 is entered, then new detail will be ' + CONVERT(VARCHAR(5), @NewDetailNo);
	
	EXECUTE GetNewDetail 6107, @NewDetailNo OUTPUT;
	PRINT 'When valid OrderID 6107 is entered with no previous detail, ';
	PRINT 'then new detail will be ' + CONVERT(VARCHAR(5), @NewDetailNo);
	
	EXECUTE GetNewDetail 9999, @NewDetailNo OUTPUT;
	PRINT 'When invalid OrderID 9999 is entered, then new detail will be ' + CONVERT(VARCHAR(5), @NewDetailNo);
    --OUTPUTS 1 BUT WILL BE FIXED IN LAB8PROC */
    
END; 
GO
/*
--------------------------------------------------------------------------------
INVENTORY trigger for an UPDATE by Dipti Muni on 06-10-2018

6. 	InventoryUpdateTrg, a trigger on UPDATE for the INVENTORY table
--------------------------------------------------------------------------------
*/

-- DROP InventoryUpdateTRG
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'InventoryUpdateTRG')
	BEGIN 
		DROP TRIGGER InventoryUpdateTRG; 
	END;
--END IF; -- SQL Server does not use END IF 
GO

-- CREATE InventoryUpdateTRG
-- Use (SELECT Stockqty FROM INSERTED) for comparison
CREATE TRIGGER InventoryUpdateTRG
ON INVENTORY
FOR UPDATE
AS 

DECLARE @errMsg    CHAR(80);

BEGIN

	IF (SELECT StockQty FROM INSERTED) < 0
		BEGIN
             -- set @@Error to 50000 and prints out an error message 
            SET @errMsg = 'InventoryUpdateTRG Error: Not Enough In Stock';
			RAISERROR (@errMsg, 12, 2) WITH SetError;
            -- No RollBack so updated value stays
		END;
	--END IF; -- SQL Server does not use END IF 
END;
GO

-- Test InventoryUpdateTRG
-- Requires at least three tests
BEGIN 
    PRINT 'Test 1: Valid StockQty 10 entered, Successful test';
    PRINT 'Before Test Inventory table';
    SELECT * FROM INVENTORY WHERE PartID = 1001;
        UPDATE INVENTORY
        SET StockQty = 10
        WHERE PartID = 1001;
    PRINT 'After Test Inventory table';
    SELECT * FROM INVENTORY WHERE PartID = 1001;

    --Reset 
    UPDATE INVENTORY SET StockQty = 100 WHERE PartID = 1001;

    PRINT 'Test 2: Valid StockQty 0 entered, Successful test';
    PRINT 'Before Test Inventory table';
    SELECT * FROM INVENTORY WHERE PartID = 1001;
        UPDATE INVENTORY
        SET StockQty = 0
        WHERE PartID = 1001;
    PRINT 'After Test Inventory table';
    SELECT * FROM INVENTORY WHERE PartID = 1001;

    --Reset 
    UPDATE INVENTORY SET StockQty = 100  WHERE PartID = 1001;

    PRINT 'Test 3: Invalid StockQty -2 entered, Failed test. Shows Error Message 50000.';
    PRINT 'Before Test Inventory table';
    SELECT * FROM INVENTORY WHERE PartID = 1001;
        UPDATE INVENTORY
        SET StockQty = -2
        WHERE PartID = 1001;
    PRINT 'After Test Inventory table';
    SELECT * FROM INVENTORY WHERE PartID = 1001;
    
    --Reset 
    UPDATE INVENTORY SET StockQty = 100 WHERE PartID = 1001;

END;
GO

/*
--------------------------------------------------------------------------------
ORDERITEMS trigger for an INSERT by Dipti Muni on 06-10-2018

7. 	OrderitemsInsertTrg, a trigger on INSERT for the ORDERITEMS table
--------------------------------------------------------------------------------
*/

-- DROP OrderitemsInsertTRG
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'OrderitemsInsertTRG')
	BEGIN 
		DROP TRIGGER OrderitemsInsertTRG; 
	END;
--END IF; -- SQL Server does not use END IF 
GO
-- CREATE OrderitemsInsertTRG
-- Get new values for quantity and partid from the INSERTED table
-- Retrieve current (changed) StockQty for this PartID
-- UPDATE with current (changed) StockQty 
CREATE TRIGGER OrderitemsInsertTRG
ON ORDERITEMS
FOR INSERT
AS 
	DECLARE @vQty		SMALLINT;
	DECLARE @vPartID	SMALLINT;
	DECLARE @vStockQty 	SMALLINT;
	DECLARE @vError		SMALLINT;
    DECLARE @errMsg     CHAR(80);
	
BEGIN
-- Get new values for quantity and partid from the INSERTED table
	SELECT 	@vQty = Qty
	FROM 	INSERTED;
	
	SELECT 	@vPartID = PartID
	FROM 	INSERTED;
	
-- Retrieve current (changed) StockQty for this PartID
	SELECT 	@vStockQty = StockQty
	FROM 	INVENTORY
	WHERE 	PartID = @vPartID;

-- UPDATE with current (changed) StockQty 
	UPDATE INVENTORY
	SET StockQty = @vStockQty - @vQty
	WHERE PartID = @vPartID;
	
	SET @vError = @@ERROR;
	SET @errMsg = ' ';
	IF @vError != 0
		BEGIN
			SET @errMsg = 'Error for OrderitemsInsertTRG: Not enough Qty available.';
			RAISERROR(@errMsg, 12, 2) WITH SetError;
		END;
END;
	
GO

-- Test OrderItemsInsertTrg 
-- Requires at least three tests
BEGIN
    PRINT 'Test 1: Valid Insert to  ORDERITEMS for PartID 1002 with 60 new StockQty balance, Successful test';
    PRINT 'Before OrderitemsInsertTRG Test';
    SELECT C.CustID,
           C.Cname,
           O.OrderID,
           O.SalesDate,
           OI.Detail,
           OI.PartID,
           OI.Qty,
           INV.Description,
           INV.StockQty
    FROM   CUSTOMERS C 
    FULL JOIN ORDERS O ON C.CustID = O.CustID
    FULL JOIN ORDERITEMS OI ON O.OrderID = OI.OrderID 
    FULL JOIN INVENTORY INV ON OI.PartID = INV.PartID
    WHERE OI.OrderID = 6099
    AND   INV.PartID = 1002;

    PRINT 'INSERT Valid OrderID 6099, Valid PartID 1002 and Valid Qty 9';
    INSERT INTO ORDERITEMS (OrderID, Detail, PartID, Qty)
    VALUES (6099, (SELECT ISNULL(MAX(Detail)+1,1) FROM ORDERITEMS WHERE OrderID = 6099), 1002, 9);

    PRINT 'After OrderitemsInsertTRG Test';
    SELECT C.CustID,
           C.Cname,
           O.OrderID,
           O.SalesDate,
           OI.Detail,
           OI.PartID,
           OI.Qty,
           INV.Description,
           INV.StockQty
    FROM   CUSTOMERS C 
    FULL JOIN ORDERS O ON C.CustID = O.CustID
    FULL JOIN ORDERITEMS OI ON O.OrderID = OI.OrderID 
    FULL JOIN INVENTORY INV ON OI.PartID = INV.PartID
    WHERE OI.OrderID = 6099
    AND   INV.PartID = 1002;

-- Reset Delete
    DELETE FROM ORDERITEMS WHERE OrderID = 6099 AND PartID = 1002 AND Detail = 6;
    UPDATE INVENTORY SET StockQty = 69 WHERE PartID = 1002;

    PRINT 'Test 2: Valid Insert to ORDERITEMS for PartID with 0 new StockQty balance, Successful test';
    PRINT 'Before OrderitemsInsertTRG Test';
    SELECT C.CustID,
           C.Cname,
           O.OrderID,
           O.SalesDate,
           OI.Detail,
           OI.PartID,
           OI.Qty,
           INV.Description,
           INV.StockQty
    FROM   CUSTOMERS C 
    FULL JOIN ORDERS O ON C.CustID = O.CustID
    FULL JOIN ORDERITEMS OI ON O.OrderID = OI.OrderID 
    FULL JOIN INVENTORY INV ON OI.PartID = INV.PartID
    WHERE OI.OrderID = 6109
    AND   INV.PartID = 1010;

    PRINT 'INSERT Valid OrderID 6109, Valid PartID 1010 and Valid Qty 110';
    INSERT INTO ORDERITEMS (OrderID, Detail, PartID, Qty)
    VALUES (6109, (SELECT ISNULL(MAX(Detail)+1,1) FROM ORDERITEMS WHERE OrderID = 6109), 1010, 110);

    PRINT 'After OrderitemsInsertTRG Test';
    SELECT C.CustID,
           C.Cname,
           O.OrderID,
           O.SalesDate,
           OI.Detail,
           OI.PartID,
           OI.Qty,
           INV.Description,
           INV.StockQty
    FROM   CUSTOMERS C 
    FULL JOIN ORDERS O ON C.CustID = O.CustID
    FULL JOIN ORDERITEMS OI ON O.OrderID = OI.OrderID 
    FULL JOIN INVENTORY INV ON OI.PartID = INV.PartID
    WHERE OI.OrderID = 6109
    AND   INV.PartID = 1010;

-- Reset Delete
    DELETE FROM ORDERITEMS WHERE OrderID = 6109 AND PartID = 1010 AND Detail = 5;
    UPDATE INVENTORY SET StockQty = 110 WHERE PartID = 1010;

    PRINT 'Test 3: Invalid Insert to ORDERITEMS for PartID with -12 new StockQty balance, Failed test';
    PRINT 'Before OrderitemsInsertTRG Test';
    SELECT C.CustID,
           C.Cname,
           O.OrderID,
           O.SalesDate,
           OI.Detail,
           OI.PartID,
           OI.Qty,
           INV.Description,
           INV.StockQty
    FROM   CUSTOMERS C 
    FULL JOIN ORDERS O ON C.CustID = O.CustID
    FULL JOIN ORDERITEMS OI ON O.OrderID = OI.OrderID 
    FULL JOIN INVENTORY INV ON OI.PartID = INV.PartID
    WHERE OI.OrderID = 6109
    AND   INV.PartID = 1007;

    PRINT 'INSERT Valid OrderID 6109, Valid PartID 1007 and Valid Qty 22';
    INSERT INTO ORDERITEMS (OrderID, Detail, PartID, Qty)
    VALUES (6109, (SELECT ISNULL(MAX(Detail)+1,1) FROM ORDERITEMS WHERE OrderID = 6109), 1010, 22);

    PRINT 'After OrderitemsInsertTRG Test';
    SELECT C.CustID,
           C.Cname,
           O.OrderID,
           O.SalesDate,
           OI.Detail,
           OI.PartID,
           OI.Qty,
           INV.Description,
           INV.StockQty
    FROM   CUSTOMERS C 
    FULL JOIN ORDERS O ON C.CustID = O.CustID
    FULL JOIN ORDERITEMS OI ON O.OrderID = OI.OrderID 
    FULL JOIN INVENTORY INV ON OI.PartID = INV.PartID
    WHERE OI.OrderID = 6109
    AND   INV.PartID = 1007;

-- Reset Delete
    DELETE FROM ORDERITEMS WHERE OrderID = 6109 AND PartID = 1007 AND Detail = 5;
    UPDATE INVENTORY SET StockQty = 10 WHERE PartID = 1007;

END;
GO

/* 
--------------------------------------------------------------------------------
AddLineItem by Dipti Muni 06-10-2018

8. 	AddLineItem, a procedure that does the transaction processing (adds the order item). 
	This procedure will call GetNewDetail and perform an INSERT to the ORDERITEMS 
	table. Being the transaction, AddLineItem is where the COMMIT / ROLLBACK occur.
--------------------------------------------------------------------------------
*/

-- DROP AddLineItem
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'AddLineItem')
	BEGIN 
		DROP PROCEDURE AddLineItem; 
	END;
--END IF; -- SQL Server does not use END IF 
GO

-- CREATE AddLineItem [with OrderID, PartID and Qty input parameters]
-- Use BEGIN TRANSACTION here or in Lab8proc
CREATE PROCEDURE AddLineItem
	(@inOrderID	SMALLINT,
	 @inPartID	SMALLINT,
	 @inQty		SMALLINT)
AS
	DECLARE @vDetail SMALLINT;
	DECLARE @vError SMALLINT;
	
BEGIN
	BEGIN TRANSACTION
		EXECUTE GetNewDetail @inOrderID, @vDetail OUTPUT;
			
		INSERT INTO ORDERITEMS (OrderID, Detail, PartID, Qty)
			VALUES (@inOrderID, @vDetail, @inPartID, @inQty);
		
		
		IF @@ERROR <> 0
			BEGIN 
				PRINT 'AddLineItem: ROLLBACK. Transaction Canceled.';
				ROLLBACK TRANSACTION;
			END;
		ELSE
			BEGIN 
				PRINT 'AddLineItem: COMMIT. Transaction Succeeded.';
				COMMIT TRANSACTION;
			END;
        --END IF; -- SQL Server does not use END IF 
	--END TRANSACTION
END;
		
GO
/*
BEGIN
-- No AddLineItem tests required, saved for main block testing
-- well, you could EXECUTE AddLineItem 6099,1001,50
 SELECT C.CustID,
           C.Cname,
           O.OrderID,
           O.SalesDate,
           OI.Detail,
           OI.PartID,
           OI.Qty,
           INV.Description,
           INV.StockQty
    FROM   CUSTOMERS C 
    FULL JOIN ORDERS O ON C.CustID = O.CustID
    FULL JOIN ORDERITEMS OI ON O.OrderID = OI.OrderID 
    FULL JOIN INVENTORY INV ON OI.PartID = INV.PartID
    WHERE OI.OrderID = 6099
    AND   INV.PartID = 1001;

EXECUTE AddLineItem 6099, 1001, 50;

  SELECT C.CustID,
           C.Cname,
           O.OrderID,
           O.SalesDate,
           OI.Detail,
           OI.PartID,
           OI.Qty,
           INV.Description,
           INV.StockQty
    FROM   CUSTOMERS C 
    FULL JOIN ORDERS O ON C.CustID = O.CustID
    FULL JOIN ORDERITEMS OI ON O.OrderID = OI.OrderID 
    FULL JOIN INVENTORY INV ON OI.PartID = INV.PartID
    WHERE OI.OrderID = 6099
    AND   INV.PartID = 1001;
END; */
GO

/* 
--------------------------------------------------------------------------------
Lab8proc by Dipti Muni on 06-10-2018

9. 	Lab8proc, a procedure that puts all of the above together to produce a solution 
	for Lab8 done in SQL Server. This is a stored procedure that accepts the 4 pieces 
	of input: Custid, Orderid, Partid, and Qty (in that order please). In this module 
	you will validate all the data and do the transaction processing by calling 
	the previously written and tested modules.
--------------------------------------------------------------------------------
*/

-- DROP Lab8proc
IF EXISTS (SELECT name FROM sys.objects WHERE name = 'Lab8proc')
	BEGIN 
		DROP PROCEDURE Lab8proc; 
	END;
--END IF;
GO

--CREATE Lab8proc (with CustID, OrderID, PartID, Quantity)
    -- PRINT 'Lab8proc by yourname begins';
    -- EXECUTE ValidateCustId
	-- EXECUTE ValidateOrderid
    -- EXECUTE ValidatePartId
    -- EXECUTE ValidateQty
	-- IF everything validates THEN do the TRANSACTION here or in AddLineItem
        -- EXECUTE AddLineItem
    -- ELSE send a message
    -- ENDIF;
    -- PRINT 'Lab8proc ends';
CREATE PROCEDURE Lab8proc
	(@inCustID 	SMALLINT,
	 @inOrderID SMALLINT,
	 @inPartID	SMALLINT,
	 @inQty		SMALLINT)
AS

BEGIN
	PRINT 'Lab8proc by Dipti Muni begins';
	
	---declare
	DECLARE @vCustFound CHAR(25);
	DECLARE @vOrderFound CHAR(25);
    DECLARE @vMatchFound CHAR(2);
	DECLARE @vPartFound CHAR(25);
	DECLARE @vQuantityFound CHAR(25);
	
	---validate
	
	EXECUTE ValidateCustID	@inCustID, @vCustFound OUTPUT;
    PRINT 'CustId is ' + @vCustFound; 
	
	EXECUTE ValidateOrderID @inCustID, @inOrderID, @vOrderFound OUTPUT, @vMatchFound OUTPUT;
	PRINT 'OrderId is ' + @vOrderFound + ' and matches: ' + @vMatchFound; 

	EXECUTE ValidatePartID @inPartID, @vPartFound OUTPUT;
    PRINT 'PartId is ' + @vPartFound;  
	
	EXECUTE ValidateQty @inQty, @vQuantityFound OUTPUT;
    PRINT 'Quantity is ' + @vQuantityFound; 
	
	IF @vCustFound != 'Invalid' AND 
	   @vOrderFound != 'Invalid' AND
       @vMatchFound != 'N' AND
	   @vPartFound != 'Invalid' AND
	   @vQuantityFound != 'Invalid'
			---If input valid
			BEGIN 
				EXECUTE AddLineItem @inOrderID, @inPartID, @inQty;
				PRINT 'AddLineItem completed.';
			END;
	ELSE
			BEGIN
				PRINT 'Not all inputs valid or matches. AddLineitem did not complete.'; 
			END;
	--END IF;
END;	
	
GO 

/*
--------------------------------------------------------------------------------
Testing scripts by Dipti Muni on 06-10-2018

-- testing blocks for Lab8proc goes last

10. Testing of Lab8proc (similar to the testing you did previously 
	for the Oracle labs 6 and 7).
--------------------------------------------------------------------------------
*/

BEGIN 
----inCustID--inOrderID--inPartID--inQty----
/*
Test #1 all bad data
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 1';
EXECUTE Lab8proc 9999, 9999, 9999, -1;

END;
GO
BEGIN
/*
Test #2 All bad except CustID
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 2';
EXECUTE Lab8proc  1, 9999, 9999, -5;

END;
GO
BEGIN
/*
Test #3 All bad except CustID and OrderID that matches
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 3';
EXECUTE Lab8proc 1, 6099, 9999, -10;

END;
GO
BEGIN
/*
Test #4 All bad except CustID and OrderID that doesn't matches
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 4';
EXECUTE Lab8proc  2, 6099, 9999, -99;

END;
GO
BEGIN
/*
Test #5 All bad except CustID and OrderID that matches and PartID
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 5';
EXECUTE Lab8proc 1, 6099, 1001, -10;

END;
GO
BEGIN
/*
Test #6 All bad except CustID and OrderID that doesn't matches and Quantity is valid
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 6';
EXECUTE Lab8proc 2, 6099, 9999, 10;

END;
GO
BEGIN
/*
Test #7 All bad except OrderID 
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 7';
EXECUTE Lab8proc 9999, 6099, 9999, -10;

END;
GO
BEGIN
/*
Test #8 All correct except CustID 
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 8';
EXECUTE Lab8proc 9999, 6099, 1002, 10;

END;
GO
BEGIN
/*
Test #9 All correct except OrderID 
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 9';
EXECUTE Lab8proc 1, 9999, 1002, 10;

END;
GO
BEGIN
/*
Test #10 All correct except PartID
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 10';
EXECUTE Lab8proc 1, 6099, 0000, 10;

END;
GO
BEGIN
/*
Test #11 Bad Qty - when qty is 0
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 11';
EXECUTE Lab8proc 1, 6099, 1001, 0;

END;
GO
BEGIN
/*
Test #12 Bad Qty - when qty is negative
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 12';
EXECUTE Lab8proc 1, 6099, 1001, -100;

END;
GO
BEGIN
/*
Test #13 CustID and OrderID correct but don't match with all valid values
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 13';
EXECUTE Lab8proc 2, 6099, 1001, 10;

END;
GO
BEGIN
/*
Test #14 Invalid CustID and OrderID
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 14';
EXECUTE Lab8proc 999, 9999, 1001, 10;

END;
GO
BEGIN
/*
Test #15 All Input valid and CustID and OrderID match, but Qty requested exceeds Stockqty. Fails
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 15';
EXECUTE Lab8proc 1, 6109, 1009, 100;

END;
GO
BEGIN
/*
Test #16 All Input valid and CustID and OrderID match - ALL GOOD with existing PartID
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 16';
SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 1 
AND         O.OrderID = 6099
ORDER BY    OI.Detail ASC;

EXECUTE Lab8proc 1, 6099, 1002, 2;

SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 1 
AND         O.OrderID = 6099
ORDER BY    OI.Detail ASC;

END;
GO
BEGIN
/*
Test #17 All Input valid and CustID and OrderID match - ALL GOOD with PartID that doesnot exists in that Order.
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 17';
SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 12 
AND         O.OrderID = 6155
ORDER BY    OI.Detail ASC;

EXECUTE Lab8proc 12, 6155, 1008, 9;

SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 12 
AND         O.OrderID = 6155
ORDER BY    OI.Detail ASC;

END;
GO
BEGIN
/*
Test #18 All Input valid and CustID and OrderID match, but Qty requested is exactly amount of Stockqty.
         Therefore new Stockqty is 0.
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 18';
SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 2 
AND         O.OrderID = 6109
ORDER BY    OI.Detail ASC;

EXECUTE Lab8proc 2, 6109, 1001, 100;

SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 2 
AND         O.OrderID = 6109
ORDER BY    OI.Detail ASC;

END;
GO
BEGIN
/*
Test #19 All Input valid and CustID and OrderID match, but the new lineitem is the same as the inputs that already exists.
         Should not cause error it will just have Max(Detail)+1 for that order.
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 19';
SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 3 
AND         O.OrderID = 6128
ORDER BY    OI.Detail ASC;

EXECUTE Lab8proc 3, 6128, 1004, 2;

SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 3 
AND         O.OrderID = 6128
ORDER BY    OI.Detail ASC;

END;
GO
BEGIN
/*
Test #20 All Input valid and CustID and OrderID match, but the new lineitem is entered consecutively or twice
         Not required for this assignment but in real situation, I would display a warning message so the user is aware 
         and they can fix it if it is an error.
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 20';
SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 11 
AND         O.OrderID = 6148
ORDER BY    OI.Detail ASC;

EXECUTE Lab8proc 11, 6148, 1009, 2;
EXECUTE Lab8proc 11, 6148, 1009, 2;

SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 11 
AND         O.OrderID = 6148
ORDER BY    OI.Detail ASC;

END;
GO
BEGIN
/*
Test #21 All Input valid and CustID and OrderID match, but there are no detail line item in OrderItems
*/
PRINT REPLICATE('=',80) + CHAR(10) + 'TESTING 21';

INSERT INTO ORDERS (OrderID, EmpID, CustID, SalesDate) 
    VALUES (8879, 106, 79, GETDATE());

SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 79
AND         O.OrderID = 8879
ORDER BY    OI.Detail ASC;

EXECUTE Lab8proc 79, 8879, 1003, 3;

SELECT      C.CustID,
            C.Cname,
            O.OrderID,
            O.SalesDate,
            OI.Detail,
            OI.PartID,
            OI.Qty,
            INV.Description,
            INV.StockQty
FROM        CUSTOMERS C
FULL JOIN   ORDERS O ON C.CustID = O.CustID
FULL JOIN   ORDERITEMS OI ON O.OrderID = OI.OrderID
FULL JOIN   INVENTORY INV ON OI.PartID = INV.PartID
WHERE       C.CustID = 79
AND         O.OrderID = 8879
ORDER BY    OI.Detail ASC;


END;

