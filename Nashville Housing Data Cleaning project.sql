/* CLEANING DATA SQL QUERIES */

SELECT * FROM nvhousing;

-- SALE DATE STANDARDIZED TO SHOW AS YYYY-MM-DD
SELECT SaleDnvhousingate, STR_TO_DATE(SaleDate,'%M %d,%Y') from nvhousing;
UPDATE nvhousing SET SaleDate = STR_TO_DATE(SaleDate,'%M %d,%Y');

/* POPULATE NULL PROPERTY ADDRESS DATA */

-- FOR THIS CASE, I USED PropertyAddress = '' TO FIND NULL VALUES BECAUSE PropertyAddress IS NULL DOES NOT RETURN ANY NULL FIELDS. 
-- IT SEEMS LIKE THESE EMPTY FIELDS DON'T HAVE NULL VALUES
-- PER THIS SQL DOC: https://dev.mysql.com/doc/refman/8.0/en/problems-with-null.html "the NULL value is never true in comparison to any other value, even NULL"
-- ALSO '' IS AN EMPTY STRING WHILE NULL IS NO VALUE AND IS NOT WHAT A BLANK TEXTBOX HAS AS TEXT (REFERENCE:https://stackoverflow.com/questions/17386547/what-is-the-difference-between-and-null)


SELECT * FROM nvhousing
WHERE PropertyAddress IS NULL; -- THIS DOES NOT PULL UP ANY ROWS BECAUSE IT SEEMS LIKE ALL OF THE EMPTY PROPERTIES ARE 'EMPTY STRING' BUT NOT 'NO VALUE'

SELECT * FROM nvhousing
WHERE PropertyAddress = ''; -- RETRIEVING DATA WITH EMPTY STRING PROPERTY ADDRESS (NOT NULL)

SELECT * FROM nvhousing
ORDER BY ParcelID; -- NOTICED THAT PARCELID MATCHES AN ADDRESS

SELECT ParcelID, PropertyAddress FROM nvhousing
WHERE ParcelID = '015 14 0 060.00'; -- FOR THIS EXAMPLE, WE CAN SEE THAT PARCEL ID 015 14 0 060.00 IS FOR THE ADDRESS 3113  MILLIKEN DR, JOELTON

-- HENCE, WE CAN MATCH THE EMPTY ADDRESS ACCORDING TO ITS PARCELID
-- TO MATCH THE EMPTY ADDRESS ACCORDING TO ITS PARCELID, WE HAVE TO DO SELFJOIN

SELECT a.parcelID, a.propertyaddress AS emptyAddress, b.parcelID, b.propertyaddress, 
CASE -- (5) POPULATION OF EMPTY STRING PROPERTY ADDRESS WITH THE MATCHING ADDRESS ACCORDING TO ITS PARCELID
    WHEN a.propertyaddress = ''
	THEN b.propertyaddress
	ELSE a.propertyaddress
END AS propertyAddress1

FROM nvhousing AS a -- (1) JOINING THE TABLE TO ITSELF  
JOIN nvhousing AS b -- (1) TO LOOK UP IF PARCEL ID IS EQUAL TO AN ADDRESS
ON a.parcelID = b.parcelID -- (2) JOINING ON PARCEL ID 
AND a.uniqueid <> b.uniqueID -- (3) SINCE EVERY ROW HAS UNIQUE IDS, IT WON'T REPEAT ITSELF. THIS MEANS THAT WE'RE SELF-JOINING ON PARCELID ONLY BUT NOT THE UNIQUEID
WHERE a.propertyaddress = ''; -- (4) SINCE THERE'S NO NULL VALUES, ONLY EMPTY STRING, WE'RE PULLING UP PROPERTY ADDRESSES WITH EMPTY STRING ('')

-- UPDATING EMPTY ADDRESS 

UPDATE nvhousing AS a
        JOIN
    nvhousing AS b ON a.parcelID = b.parcelID
        AND a.uniqueID <> b.uniqueID 
SET 
    a.propertyaddress = (CASE
        WHEN a.propertyaddress = '' THEN b.propertyaddress
        ELSE a.propertyaddress
    END);

/* BREAKING ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE) */
-- WILL USE SUBSTRING AND CHARACTER INDEXING TO DO THIS
-- MORE ABOUT SUBSTRING FUNCTION HERE: https://www.w3schools.com/sql/func_mysql_substring.asp
-- MORE ABOUT LOCATE FUNCTION HERE: https://www.dbload.com/articles/charindex-function-in-mssql-and-mysql.htm 

SELECT PROPERTYADDRESS FROM NVHOUSING;

SELECT substring(propertyaddress, 1, locate(',', propertyaddress)-1) AS Address -- USED SUBSTRING FUNCTION HERE TO RETRIEVE THE FIRST PART OF THE ADDRESS FROM THE FIRST COMMA. THEN SET THE LENGTH BY USING THE LOCATE FUNCTION INSIDE THE SUBSTRING FUNCTION
, substring(propertyaddress FROM locate(',', propertyaddress)+1 FOR LENGTH(PROPERTYADDRESS)) -- THIS READS AS 'GET THE SUBSTRING OF propertyaddress FROM THE INDEX NUMBER FROM THE FIRST COMMA PLUS 1 FOR THE LENGTH OF THE PROPERTYADDRESS STRING. 
-- substring(--propertyaddress string-- FROM -string index from the first comma plus 1-- FOR --indicates the length of the propertyaddress string-- 
FROM nvhousing; -- SINCE LOCATE FUNCTION RETURNS THE NUMBER OF CHARACTERS UNTIL THE ',', I USED MINUS 1 TO REMOVE THE EXCESS COMMA IN THE END OF THE ADDRESS

-- ADDING ADDITIONAL COLUMNS FOR THE SPLIT ADDRESS AND CITY

ALTER TABLE nvhousing
ADD COLUMN PAddress VARCHAR(255),
ADD COLUMN PCity VARCHAR(255);

-- UPDATE THE ROWS OF THE ADDED COLUMNS 
UPDATE nvhousing 
SET PAddress = substring(propertyaddress, 1, locate(',', propertyaddress)-1); -- UPDATE THE SPLIT ADDRESS

UPDATE nvhousing 
SET PCity = substring(propertyaddress FROM locate(',', propertyaddress)+1 FOR LENGTH(PROPERTYADDRESS)); -- UPDATE THE SPLIT CITY

SELECT PAddress, PCity  FROM nvhousing;

/* NOW, LET'S UPDATE THE OWNER ADDRESS  */


-- RETURNING THE NULL ADDRESS 

SELECT owneraddress FROM nvhousing;

SELECT owneraddress FROM nvhousing 
WHERE owneraddress IS NULL; -- THIS RETURNS AS 0 ROWS BECAUSE THERE ARE NO owneraddress ROW THAT CONTAINS NO values

SELECT owneraddress FROM nvhousing 
WHERE owneraddress = ''; -- MEANWHILE, THIS RETURNS ROWS WITH EMPTY STRING ('')

-- SEPERATING THE ADDRESS, CITY, AND STATE FROM EACH OTHER FIRST BUT THIS TIME, INSTEAD OF SUBSTRING, WE WILL USE SUBSTRING_INDEX
-- MORE ABOUT SUBSTRING_INDEX HERE: https://www.w3resource.com/mysql/string-functions/mysql-substring_index-function.php 
-- SUBSTRING_INDEX(str, delim, count) | str = string, delim = delimited, count = An integer indicating the number of occurrences of delim

SELECT SUBSTRING_INDEX(owneraddress, ",", 1) AS Address,
SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ",", 2), ",", -1) AS City,
SUBSTRING_INDEX(owneraddress, ",", -1) AS State
FROM nvhousing;

-- ADDING ADDITIONAL COLUMNS FOR THE SPLIT OWNER ADDRESS, CITY AND STATE

ALTER TABLE nvhousing
ADD COLUMN OAddress VARCHAR(255),
ADD COLUMN OCity VARCHAR(255),
ADD COLUMN OState VARCHAR(255);

-- UPDATE THE ROWS OF THE ADDED COLUMNS 
UPDATE nvhousing 
SET OAddress = SUBSTRING_INDEX(owneraddress, ",", 1); -- UPDATE THE SPLIT ADDRESS

UPDATE nvhousing 
SET OCity = SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ",", 2), ",", -1); -- UPDATE THE SPLIT CITY

UPDATE nvhousing 
SET OState = SUBSTRING_INDEX(owneraddress, ",", -1); -- UPDATE THE SPLIT STATE

SELECT OAddress, OCity, OState FROM nvhousing;

/* CHANGE Y AND N TO 'YES' AND 'NO' IN "SoldAsVacant" TABLE */

SELECT DISTINCT soldasvacant, COUNT(*) FROM nvhousing GROUP BY soldasvacant ORDER BY 2; -- UPON PULLING UP, THERE WERE 399 ANSWERED AS Ns AND 52 ANSWERED AS Ys

SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'NO'
    ELSE SoldAsVacant
END
FROM nvhousing; -- RETRIEVING DATA REPLACING Y WITH YES AND N WITH NO

-- UPDATE THE VALUES

UPDATE nvhousing 
SET SoldAsVacant = 
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'NO'
    ELSE SoldAsVacant
END; 

/* REMOVING DUPLICATES */
SELECT * FROM nvhousing;

-- WE ARE CALLING A CTE (Common Table Expression) TO CREATE A TEMPORARY NAMED RESULT FOR ROW_NUMBER OVER DATA PARTITIONED BY THE BELOW COLUMNS 
-- MORE DETAILS ABOUT CTE HERE: https://www.sqlshack.com/sql-server-common-table-expressions-cte/ 
-- MORE DETAILS ABOUT ROW_NUMBER() HERE: https://www.sqlservertutorial.net/sql-server-window-functions/sql-server-row_number-function/ 


-- DELETING IN THE REAL TABLE USING CTE TO GET THE ROWS TO DELETE
WITH RowNumCTE AS ( -- CREATING CTE TO CALL UPON WHEN DELETING DUPLICATES
SELECT *,
	ROW_NUMBER() OVER ( -- IF THE ROW_NUMBER() WINDOW FUNCTION RETURNS MORE THAN 1 ROW (IN AN INTEGRAL SEQUENCE), THEN, THAT ROW IS A DUPLICATE
    PARTITION BY ParcelID, -- PARTITIONING THE ROW_NUMBER() BY parcelid, propertyaddress, saleproce, saledate, legalreference AND ARE ORDERED BY THEIR uniqueid
				 PropertyAddress,
                 SalePrice,
                 SaleDate, 
                 LegalReference
					ORDER BY 
						UniqueID
    ) AS row_num
FROM nvhousing
)
DELETE FROM nvhousing USING nvhousing JOIN RowNumCTE ON nvhousing.UniqueID = RowNumCTE.UniqueID
WHERE RowNumCTE.row_num>1; 

-- DELETE UNUSED COLUMN

SELECT * FROM nvhousing;

ALTER TABLE nvhousing
DROP COLUMN owneraddress,
DROP COLUMN TaxDistrict, 
DROP COLUMN propertyaddress;

