-- I just found a mini project on LinkedIn and decided to try. link: https://bit.ly/4aE53zD

-- 1. IMPORTING THE DATA 
-- CREATE NEW SCHEMA named 'online_retail'
-- this code is to make sure we work on the new schema, not others
USE online_retail;

-- CREATE TABLE before importing the data
	CREATE TABLE retail_raw (
		InvoiceNo VARCHAR(50),
		StockCode VARCHAR(20),
		Description TEXT,
		Quantity INT,
		InvoiceDate DATETIME,
        UnitPrice DECIMAL(10,2),
		CustomerID VARCHAR(20),
		Country VARCHAR(100)
	);
    

-- IMPORT YOUR DATA

-- to import data just right click on 'online_retail' schema 
-- choose 'Table Data Import Wizard'
-- I wait for a while and then boom! I run into a problem because my 'innodb_buffer_pool_size' was too small = 128MB, so they lagging or not responding
-- I need to change from 128MB to 4G in 'my.ini' configuration (open it through Notepad), here's my path ---> "C:\ProgramData\MySQL\MySQL Server 8.0\my.ini"
-- actually I don't know what I am doing, but I tried my best and ask GPT for guidance

-- after the changes, the importing process using 'Table Data Import Wizard' still running soooo slow

#------------ERROR CODE 1290---------------------#
-- let's try another way, using LOAD DATA INFILE
-- I encounter error code 1290, MySQL couldn't find the file I want
-- turns out, there are problem with 'the permission to read the file' 
-- again, i need to modify 'my.ini' configuration and add 'local_infile=1' below [mysqld] block --> then restart MySQL
-- write this --> SHOW VARIABLES LIKE 'local_infile'; in MySQL to check if the value already ON

#------------ERROR CODE 2068---------------------#
-- I tried to import, but still got an error code 2068
-- It says I have to edit connection (just right click your Local instance connection) --> tab Advanced
-- write this on 'Others' --> OPT_LOCAL_INFILE=1 --> OK --> restart MySQL

#------------ERROR CODE 2---------------------#
-- now, change query to --> LOAD DATA LOCAL INFILE
-- got an error code 2, MySQL couldn't find the files 

#------------ERROR CODE 2---------------------#
-- I ask GPT again and it told me to move the file to 'Uploads' folder in MySQL server
-- Here's the path in my PC ---> "C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\OnlineRetail.csv"

LOAD DATA LOCAL INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/OnlineRetail.csv"
INTO TABLE retail_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
;

-- still error code 2
-- GPT suggest to add this --> CHARACTER SET latin1
-- It says maybe the dataset had an old encoding which is 'latin1'

LOAD DATA LOCAL INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/OnlineRetail.csv"
INTO TABLE retail_raw
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
;

-- It works!  I was so happy, but then something feels off. the dataset looks similar! OMG, another problem TT
-- GPT said need to change 'latin1' --> 'utf8mb4'

LOAD DATA LOCAL INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/OnlineRetail.csv"
INTO TABLE retail_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
;

-- and yep, it's not work as I expected
-- only 110 rows return out of 541909 rows, plus so many warnings

-- I had a feeling that something must be wrong with the file, not MySQL query
-- when i check the 111th rows with Notepad, BANG! there are unwanted double quotes, and additional spaces everywhere
-- that's why MySQL couldn't read the file since the format is so messy 
-- I need to clean the dataset using python at Google Colab
-- and here's what GPT suggest me to write in MySQL, there's additional query for tranforming the data before entering the table 

LOAD DATA LOCAL INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/OnlineRetail.csv"
INTO TABLE retail_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS
(@InvoiceNo, @StockCode, @Description, @Quantity, @InvoiceDate, @UnitPrice, @CustomerID, @Country)
SET
InvoiceNo = @InvoiceNo,
StockCode = @StockCode,
Description = @Description,
Quantity = @Quantity,
InvoiceDate = STR_TO_DATE(@InvoiceDate, '%m/%d/%Y%H:%i'),
UnitPrice = @UnitPrice,
CustomerID = @CustomerID,
Country = @Country;

-- FINALLY IT WORKS! such a long drama LOL


-- 2. DATA CLEANING
-- FIRST: Removing duplicates
-- we're checking duplicates using Windows Function
	SELECT *
	FROM (
		SELECT InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice,  CustomerID, Country,
		ROW_NUMBER() OVER (
				PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country
				) AS row_num
		FROM 
			retail_raw
	) duplicates
	WHERE 
		row_num > 1;
		
-- Create another TABLE with new column since we can't do anything to a raw data (delete directly).
-- just right click 'retail' -> copy to clipboard -> create statement -> paste here
    
	CREATE TABLE `retail_staging` (
	  `InvoiceNo` varchar(50) DEFAULT NULL,
	  `StockCode` varchar(20) DEFAULT NULL,
	  `Description` text,
	  `Quantity` int DEFAULT NULL,
	  `InvoiceDate` datetime DEFAULT NULL,
      `UnitPrice` decimal(10,2) DEFAULT NULL,
	  `CustomerID` varchar(20) DEFAULT NULL,
	  `Country` varchar(100) DEFAULT NULL,
	  `row_num` int
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- another table is ready
	SELECT *
	FROM retail_staging;

-- now insert the same value into new table with row_num column using Window Function
	INSERT INTO retail_staging
	SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country) as row_num
	FROM retail_raw;

-- check the duplicate again
	SELECT *
	FROM retail_staging
	WHERE row_num > 1;

-- finally we can get rid of those duplicates
	DELETE
	FROM retail_staging
	WHERE row_num > 1;
    
-- we're done with duplicate, now we can delete row_num column
	ALTER TABLE retail_staging
	DROP COLUMN row_num;

-- NEXT: Handle NULLs / empty strings
-- something you need to ask, is it okay to have NULLs?
-- where the NULLs came from? 
	SELECT
		SUM(InvoiceNo IS NULL) AS null_invoice,
		SUM(StockCode IS NULL) AS null_SC,
		SUM(Description IS NULL) AS null_DESC,
		SUM(Quantity IS NULL) AS null_Q,
		SUM(UnitPrice IS NULL) AS null_UP,
		SUM(InvoiceDate IS NULL) AS null_DATE,
		SUM(CustomerID IS NULL) AS null_ID,
		SUM(Country IS NULL) AS null_C
	FROM retail_staging;


-- CHECK for missing value which is -> ''
-- Description: has empty strings -> convert to NULL
-- CustomerID: has empty strings -> represents guest checkout, convert to NULL  
-- UnitPrice: 0.00 means free sample/gift -> deleted, since we don't use them for analyze
-- Country: verified no empty strings or NULLs -> no action needed
	
    SELECT COUNT(*) FROM retail_staging
	WHERE Description = '';

	SELECT * FROM retail_staging
	WHERE Description = '';

-- change the missing value to NULL
	UPDATE retail_staging
	SET Description = NULL
	WHERE Description = '';
    
    UPDATE retail_staging
	SET CustomerID = NULL
	WHERE CustomerID = '';
    
-- DELETE UnitPrice = 0 
    DELETE FROM retail_staging
	WHERE UnitPrice = 0;
    
-- NEXT: Standardizing the Data
-- CHECK each column format
	DESCRIBE retail_staging;

-- Check the column with TEXT STRING is there any misspelling?
-- use DISTINCT
	SELECT DISTINCT country
	FROM retail_staging;
    
-- remove unwanted space and period
-- be careful, use SELECT statement to make sure you're doing it right before permanent UPDATE
-- remove unwanted space at the front and end
	SELECT 
	LENGTH(InvoiceNo), 
	LENGTH(TRIM(InvoiceNo)),
    
    LENGTH(StockCode),
	LENGTH(TRIM(StockCode)),
    
    LENGTH(Description),
	LENGTH(TRIM(Description)),
	
    LENGTH(Quantity),
	LENGTH(TRIM(Quantity)),
    
    LENGTH(InvoiceDate),
	LENGTH(TRIM(InvoiceDate)),
    
    LENGTH(UnitPrice),
	LENGTH(TRIM(UnitPrice)),
    
    LENGTH(CustomerID),
	LENGTH(TRIM(CustomerID)),
    
    LENGTH(Country),
	LENGTH(TRIM(Country))
	FROM retail_staging;
    
-- if you're sure, UPDATE it
    UPDATE retail_staging 
	SET InvoiceNo = TRIM(InvoiceNo),
		StockCode = TRIM(StockCode),
		Description = TRIM(Description),
		Quantity = TRIM(Quantity),
		InvoiceDate = TRIM(InvoiceDate),
		UnitPrice = TRIM(UnitPrice),
		CustomerID = TRIM(CustomerID),
		Country = TRIM(Country);
    
-- remove double space
SELECT Description
FROM retail_staging
WHERE Description LIKE '%  %';

-- how many are they?
SELECT COUNT(*)
FROM retail_staging
WHERE Description LIKE '%  %';

-- then UPDATE it (run twice to catch the triple space '   ')
UPDATE retail_staging
SET Description = REPLACE(Description, '  ', ' ')
WHERE Description LIKE '%  %';
    
-- remove additional period '.'
	SELECT 
	TRIM(BOTH '.' FROM InvoiceNo)   AS InvoiceNo, 
	LENGTH(InvoiceNo) ori, 
    LENGTH(TRIM(BOTH '.' FROM InvoiceNo)) after,
		
	TRIM(BOTH '.' FROM StockCode)   AS StockCode, 
	LENGTH(StockCode) ori, 
    LENGTH(TRIM(BOTH '.' FROM StockCode)) after,
		
	TRIM(BOTH '.' FROM Description) AS Description, 
	LENGTH(Description) ori, 
	LENGTH(TRIM(BOTH '.' FROM Description)) after,
		
	TRIM(BOTH '.' FROM Country)     AS Country, 
	LENGTH(Country) ori, 
	LENGTH(TRIM(BOTH '.' FROM Country)) after
	FROM retail_staging;

-- if you're sure, UPDATE it
UPDATE retail_staging 
SET InvoiceNo = TRIM(BOTH '.' FROM InvoiceNo),
	StockCode = TRIM(BOTH '.' FROM StockCode),
	Description = TRIM(BOTH '.' FROM Description),
	Country = TRIM(BOTH '.' FROM Country);

-- NEXT: Remove returns & invalid quantities
-- Remove returns (InvoiceNo starting with 'C') and all those negative Quantity
	DELETE FROM retail_staging
	WHERE InvoiceNo LIKE 'C%' OR Quantity < 0;

-- check if your doing it right
	SELECT InvoiceNo, Quantity 
    FROM retail_staging
	WHERE InvoiceNo LIKE 'C%' OR Quantity < 0;
    
-- we need to remove adjustment too (like thrown away, mouldy or missing) 
-- since it's not sale and would distort sales analysis
    
    DELETE FROM retail_staging
	WHERE Description LIKE '%ADJUST%'
    OR Description LIKE '%THROWN AWAY%'
    OR Description LIKE '%MOULDY%'
	OR Description LIKE '%MISSING%'
    OR Description LIKE '%DAMAGED%'
    OR Description LIKE '%POSTAGE%'
    OR Description LIKE '%DISCOUNT%'
    OR Description LIKE '%CRUK%';

-- KPI's (Key Performance Indicator) for Dashboards
-- 1. Total Revenue after data cleaning
SELECT CONCAT('£', FORMAT(SUM(TotalSales) / 1000000, 2),' ', 'M') AS TotalRevenue
FROM retail_staging;

-- 2. Total Orders (unique invoices)
SELECT COUNT(DISTINCT(InvoiceNo)) AS TotalOrders
FROM retail_staging;

-- 3. Total Customers
SELECT COUNT(DISTINCT(CustomerID)) AS TotalCustomers
FROM retail_staging; 

-- 4. Repeat Customer rate
SELECT 
    COUNT(DISTINCT CustomerID) AS total_customers,
    COUNT(DISTINCT CASE WHEN order_count >= 2 THEN CustomerID END) AS repeat_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN order_count >= 2 THEN CustomerID END) * 100.0 
        / COUNT(DISTINCT CustomerID), 2
    ) AS repeat_customer_rate_pct

FROM (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM retail_staging
    GROUP BY CustomerID
) AS customer_orders; 


-- 3. RUN THE ANALYSIS
-- Scope: UK-only analysis for focused insights
	DELETE FROM retail_staging
	WHERE Country != 'United Kingdom';
    
-- to check the number of rows left after filter
	SELECT COUNT(*) FROM retail_staging
	WHERE Country LIKE 'United Kingdom';

-- NEXT: ADD NEW COLUMN TotalSales
-- Create Calculated Field -> TotalSales = Quantity x UnitPrice
	SELECT Quantity, 
		UnitPrice, 
		Quantity * UnitPrice as TotalSales
	FROM retail_staging;

-- add a new column
	ALTER TABLE retail_staging
	ADD COLUMN TotalSales DECIMAL(10,2);

-- then add the values
	UPDATE retail_staging
	SET TotalSales = Quantity * UnitPrice;
    
-- Analysis 1: Top 10 Bestselling Products
-- Quantity > 0 means -> cancel and returns are skipped
SELECT Description, SUM(Quantity) AS TotalSold
FROM retail_staging
WHERE Quantity > 0
GROUP BY Description 
ORDER BY TotalSold DESC LIMIT 10;

-- Analysis 2: Top 10 Revenue Products
SELECT Description, SUM(TotalSales) AS revenue
FROM retail_staging
WHERE Quantity > 0
GROUP BY Description 
ORDER BY revenue DESC LIMIT 10;

-- Analysis 3: Sales by Hour
-- which hour had the highest sales
SELECT 
    HOUR(InvoiceDate) AS hour,
    SUM(TotalSales) AS total_sales
FROM retail_staging
WHERE Quantity > 0
GROUP BY hour
ORDER BY total_sales DESC LIMIT 5;

-- Analysis 4: Sales by Day of Week
SELECT 
    DAYNAME(InvoiceDate) AS day_name,
    SUM(TotalSales) AS total_sales
FROM retail_staging
WHERE Quantity > 0
GROUP BY day_name
ORDER BY total_sales DESC;

-- FINALIZATION
-- to export your result to csv
SELECT *
INTO OUTFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/OnlineRetail_cleaned.csv"
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM retail_staging;

-- I had a problem visualize this result, it doesn't have column names, the format turns messy, and additional null columns everywhere. OMG.
-- of course TABLEAU hate this kind of messy stuff. so they vomit it back. another headache confirm LOL.
-- at the end, I got help from AI to generate python script and run them in Google Colab.
-- it works perfectly!
-- check the python script in this file 'OnlineRetail_cleaning.ipynb'


