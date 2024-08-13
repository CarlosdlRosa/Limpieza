-- First of all, we select the database where the table is
USE clean;
-- It's time to import the .csv file called 'Limpieza', the dataset we will clean, by using Table Data Import Wizard

-- After that, Let's disable safe mode for data modifications. We need to set it to 0 (False)
SET sql_safe_updates = 0;

-- Always execute the two lines above before working: one to select the database, the other to enable certain data modifications

-- Before starting the cleaning process, it might be a good idea to make a copy of the table, just in case we accidentally spoil the data during cleaning 
CREATE TABLE copy_limpieza AS SELECT * FROM limpieza;

-- Let's take a first look to our data
SELECT * FROM limpieza LIMIT 6;

-- We create a procedure to check the table after each cleaning change
DELIMITER //
CREATE PROCEDURE limp()
BEGIN
    SELECT * FROM limpieza;
END //
DELIMITER ;

CALL limp();

-- We'll take a first look at the data types of the table's column
DESCRIBE limpieza;

-- Let's change some column names to have them all in the same language (English) and with no capital letters nor special characters
-- (We use backticks instead of single or double quotes to enclose the column name, which contains special characters that may cause errors)
ALTER TABLE limpieza CHANGE COLUMN `ï»¿Id?empleado` id_emp varchar(20) null;
ALTER TABLE limpieza CHANGE COLUMN `gÃ©nero` gender varchar(20) null; 
ALTER TABLE limpieza CHANGE COLUMN `Name` name varchar(20) null;
ALTER TABLE limpieza CHANGE COLUMN `Apellido` surname varchar(30) null;
ALTER TABLE limpieza CHANGE COLUMN `star_date` start_date varchar(20) null;


-- Now, let's check for duplicates through 'id_emp', which should function as a primary key and, therefore, should not be repeatable
SELECT id_emp, COUNT(*) AS duplicates
FROM limpieza
GROUP BY id_emp
HAVING COUNT(*) > 1;

-- By using a subquery, we'll figure out how many duplicates we have
SELECT COUNT(*) AS count_duplicates 
FROM(
SELECT id_emp, COUNT(*) AS duplicates
FROM limpieza
GROUP BY id_emp
HAVING COUNT(*) > 1
) AS subquery;


-- We'll need a temporary primary key to tell apart the two versions of each duplicated row
ALTER TABLE limpieza ADD COLUMN temp_id INT AUTO_INCREMENT PRIMARY KEY;

-- By using the function ROW_NUMBER, we make sure we select just one version of each duplicated row and not both versions
SELECT t.*
FROM
(
SELECT *,
  ROW_NUMBER() OVER ( PARTITION BY id_emp ORDER BY temp_id
            ) as rn
FROM limpieza
) AS t
WHERE rn > 1;

-- We observe a pattern here: the duplicates are grouped together in the table, so the DELETE statement can be easily written
DELETE FROM limpieza
WHERE temp_id BETWEEN 22021 AND 22029;

-- Let's count again the amount of duplicates. Now, this aggregation must be equal to 0
SELECT COUNT(*) AS count_duplicates 
FROM(
SELECT id_emp, COUNT(*) AS duplicates
FROM limpieza
GROUP BY id_emp
HAVING COUNT(*) > 1
) AS subquery;

-- Before moving forward, we remove the temporary column that was previously created 
ALTER TABLE limpieza DROP COLUMN temp_id;

-- It's time to remove the extra spaces that were recorded by mistake 
SELECT surname FROM limpieza
WHERE LENGTH(surname) - LENGTH(TRIM(surname)) >0;

-- As we had 4 surnames with extra spaces, we update those rows by using the code below
UPDATE limpieza SET surname = TRIM(surname)
WHERE LENGTH(surname) - LENGTH(TRIM(surname)) >0;

-- We will intentionally introduce an error, extra spaces between words, to then learn how to remove them
UPDATE limpieza SET area = REPLACE(area,' ','    ');

-- By using the term REGEXP, we make sure we introduced the intentional extra spaces 
SELECT area FROM limpieza
WHERE area REGEXP '\\s{2,}';

-- Before reverting the mistake, it's better to compare the current incorrect values with the previous correct ones
SELECT area, TRIM(regexp_replace(area, '\\s{2,}', ' ')) AS corrected_area
FROM limpieza
WHERE area REGEXP '\\s{2,}';

-- Our code seems to make the desired changes. Therefore, let's proceed to update the database with it.
UPDATE limpieza SET area = TRIM(regexp_replace(area, '\\s{2,}', ' '));

-- A routine look at our table after each change we make to it
CALL limp();

-- We continue with the cleaning. We detect that the genders in the 'gender' column are expressed in Spanish
-- Before aplying any change, we ensure that there are no typographical errors of any kind, that there are only 'hombre' and 'mujer', with no spaces or spelling mistakes
SELECT DISTINCT gender FROM limpieza;

-- Let´s compare the original column with a new one created using a CASE statement that will allow us to translate the entire column
SELECT gender,
CASE
	WHEN gender = 'hombre' THEN 'male'
	WHEN gender = 'mujer' THEN 'female'
END AS gender1
 FROM limpieza;
 
-- Since the result has been as desired, let's apply the code to update our data 
 UPDATE limpieza SET gender = 
 CASE
	WHEN gender = 'hombre' THEN 'male'
	WHEN gender = 'mujer' THEN 'female'
    ELSE gender
END;

-- After the update, the table looks good
CALL limp();

-- The 'type' column is supposed to indicate whether the employee's job is remote or not
-- However, it contains 0 and 1 as if they were boolean values, and the Import Wizard has detected it as an integer field
DESCRIBE limpieza;

-- Let's modify the data type of the field
-- (We put 'type' in backticks because it's a reserved keyword, so we avoid potential issues, even though it should work fine without the backticks)
ALTER TABLE limpieza MODIFY COLUMN `type` TEXT;

-- Now, before making any further changes, let's ensure that the field contains only 1s or 0s
SELECT DISTINCT `type` FROM limpieza;

-- As expected, there were only 1s and 0s, so let's use a CASE statement again to transform the data
 UPDATE limpieza SET `type` = 
 CASE
	WHEN `type` = '0' THEN 'hybrid'
    WHEN `type` = '1' THEN 'remote'
    ELSE `type`
END;

CALL limp;

-- We notice that the salary column is of type 'text' instead of a numeric type
-- We need to make some transformations to the values to convert them to a decimal type
-- Let's check if the result of the transformations is as desired
SELECT salary, 
	CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL (15,2)) AS corrected_salary
FROM limpieza;

-- Let's update the 'salary' field by copy-pasting the code above, that worked as we wanted
UPDATE limpieza SET salary = 
	CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL (15,2));
    
CALL limp();

-- Since all the salaries are in whole numbers, let's change the column to an INT type
ALTER TABLE limpieza MODIFY COLUMN salary INT NULL;

DESCRIBE limpieza;

-- The next step will be to convert the birth_date column to the YYYY-MM-DD format to then change the field values to the DATE type
-- Let's check first how the outcome of our code looks
SELECT birth_date, 
CASE
    WHEN birth_date LIKE '%/%' THEN 
        DATE_FORMAT(STR_TO_DATE(TRIM(birth_date), '%m/%d/%Y'), '%Y-%m-%d')
END AS corrected_birth_date
FROM limpieza;

-- Since it looked nice, let's update the table
UPDATE limpieza SET birth_date =
CASE
    WHEN birth_date LIKE '%/%' THEN 
        DATE_FORMAT(STR_TO_DATE(TRIM(birth_date), '%m/%d/%Y'), '%Y-%m-%d')
        ELSE birth_date
END;

CALL limp();

-- Now that we have the required format, we change the column to type DATE
ALTER TABLE limpieza MODIFY COLUMN birth_date DATE;

DESCRIBE limpieza;

-- Now it's the turn of the start_date column. Let's repeat the entire process to convert this column to type DATE as well
SELECT start_date, 
CASE
    WHEN start_date LIKE '%/%' THEN 
        DATE_FORMAT(STR_TO_DATE(TRIM(start_date), '%m/%d/%Y'), '%Y-%m-%d')
END AS start_date1
FROM limpieza;

UPDATE limpieza SET start_date =
CASE
    WHEN start_date LIKE '%/%' THEN 
        DATE_FORMAT(STR_TO_DATE(TRIM(start_date), '%m/%d/%Y'), '%Y-%m-%d')
	ELSE start_date
END;

CALL limp();

ALTER TABLE limpieza MODIFY COLUMN start_date DATE;

DESCRIBE limpieza;

-- Regarding the finish_date column, we see that it follows a pattern for expressing date and time
SELECT finish_date FROM limpieza
WHERE finish_date != '';

-- We need to remove the 'UTC' expression from the date and time values and convert blank values to null. Let's test the code below 
SELECT finish_date, 
	CASE 
        WHEN TRIM(finish_date) = '' THEN NULL
        WHEN TRIM(finish_date) LIKE '%UTC%' THEN STR_TO_DATE(REPLACE(TRIM(finish_date), 'UTC', ''), '%Y-%m-%d %H:%i:%s')
        ELSE finish_date
    END AS corrected_finish_date
FROM limpieza;

-- We apply the code to update the data since it gives the results we expected
UPDATE limpieza 
SET finish_date = 
    CASE 
        WHEN TRIM(finish_date) = '' THEN NULL
        WHEN TRIM(finish_date) LIKE '%UTC%' THEN STR_TO_DATE(REPLACE(TRIM(finish_date), 'UTC', ''), '%Y-%m-%d %H:%i:%s')
        ELSE finish_date
    END;
    
CALL limp();

-- However, the time an employee ended their employment seems irrelevant. Let's keep only the date
SELECT finish_date,
    CASE 
        WHEN finish_date IS NULL THEN NULL
        ELSE DATE(finish_date)
    END AS just_date
FROM limpieza;

-- We update the field to convert the date-time expression to just a date
UPDATE limpieza SET finish_date = 
CASE 
        WHEN finish_date IS NULL THEN NULL
        ELSE DATE(finish_date)
    END;
    
CALL limp();

-- Now that it looks the way we want, let's change the column's data type to DATE
ALTER TABLE limpieza MODIFY COLUMN finish_date DATE NULL;

DESCRIBE limpieza;

-- To complete the date transformation, let's address the promotion_date column
SELECT promotion_date,
	CASE
        WHEN TRIM(promotion_date) = '' THEN NULL
        WHEN promotion_date LIKE '%,%' THEN DATE_FORMAT(STR_TO_DATE(promotion_date, '%M %e, %Y'), '%Y-%m-%d')
        ELSE promotion_date
	END AS corrected_promotion_date
FROM limpieza;


UPDATE limpieza
SET promotion_date =
	CASE
        WHEN TRIM(promotion_date) = '' THEN NULL
        WHEN promotion_date LIKE '%,%' THEN DATE_FORMAT(STR_TO_DATE(promotion_date, '%M %e, %Y'), '%Y-%m-%d')
        ELSE promotion_date
	END;

-- We're done with the cleaning process, but before finishing, let's generate two additional columns that might be useful to have
-- Let's now create a new column to express each employee's age
ALTER TABLE limpieza ADD COLUMN age INT;

-- For this, we just need to use the TIMESTAMPDIFF function as shown below
SELECT name, birth_date,
TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS age
FROM limpieza;

UPDATE limpieza SET age =
TIMESTAMPDIFF(YEAR, birth_date, CURDATE()); 

-- The update looks great
SELECT name, birth_date, age FROM limpieza;

-- Now, let's suppose we need to automatically generate an email address for each employee 
-- We can easily do that using the existing data in the table and the CONCAT function
SELECT name, surname, type,
CONCAT(
	SUBSTRING_INDEX(LOWER(name), ' ', 1),
    '.', 
    SUBSTRING(LOWER(surname), 1, 2), 
    '.', 
    SUBSTRING(type, 1, 1), 
    '@limpieza.com'
    ) AS email 
FROM limpieza;

-- So let's create a column to store the generated emails
ALTER TABLE limpieza ADD COLUMN email VARCHAR(80);

-- Once the column is created, we populate it using the email generation code
UPDATE limpieza SET email =
CONCAT(
	SUBSTRING_INDEX(LOWER(name), ' ', 1),
    '.', 
    SUBSTRING(LOWER(surname), 1, 2), 
    '.', 
    SUBSTRING(type, 1, 1), 
    '@limpieza.com'
    );

CALL limp();

-- Any of the SELECT statements can be exported as a .csv file for further visualization and plotting in Excel, Python, Tableau, etc. 
-- A good example is the one below
SELECT area, gender, 
COUNT(area) AS number_employees,
AVG(age) AS average_age
FROM limpieza
GROUP BY area, gender
ORDER BY number_employees DESC;

-- Our job is done here. Let's finish by creating a new table to reorganize the columns and rows
CREATE TABLE clean_limpieza AS
SELECT id_emp, name, surname, gender, age, birth_date, email, area, type, salary, start_date, promotion_date, finish_date
FROM limpieza
ORDER BY area, surname;

-- This way, we can export the new, cleaned version of our data by creating a new .csv file
SELECT *
INTO OUTFILE 'C:\\Users\\carlo\\Documents\\Documentos CSV\\new_limpieza.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM clean_limpieza;