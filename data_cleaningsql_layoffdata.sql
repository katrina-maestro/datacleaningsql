SELECT * FROM world_layoffs.layoffs;

-- 1. Removing any duplicate data 

-- Creating a staging table where we can run test queries 
CREATE TABLE layoffs_staging 
LIKE layoffs; 

-- Inserting all data from original table to staging table 
SELECT * FROM world_layoffs.layoffs_staging;
INSERT layoffs_staging
SELECT * FROM layoffs;

-- Testing row marking functionality 
SELECT *,
ROW_NUMBER() OVER(
 PARTITION BY company, location, industry, total_laid_off, `date`) AS row_num
 FROM world_layoffs.layoffs_staging;
 
 
 -- Making a CTE to use all column names to check for duplicate rows 
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
 PARTITION BY company,location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
 FROM world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


--  Removing duplicate rows using CTE 
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
 PARTITION BY company,location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
 FROM world_layoffs.layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- Creating a table to take in the CTE data since it wont allow the delete functionality 
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Checking if the table was created well 
SELECT *
FROM layoffs_staging2;

-- Inserting the updated data with the row numbers into the new table s
INSERT layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
 PARTITION BY company,location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
 FROM world_layoffs.layoffs_staging;
 
 
-- Checking for duplicates in the new created table 
SELECT *
FROM layoffs_staging2
WHERE row_num>1;

-- Deleting duplicate rows 
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Checking if the rows were deleted 
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;



-- 2. Standardising the data

-- Testing out how trimming the company names looks 
SELECT DISTINCT  company, TRIM(company)
FROM layoffs_staging2;

-- Trimming the company names for no spaces 
UPDATE layoffs_staging2
SET company = TRIM(company); 

-- Checking the industry names for duplicates 
SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;

-- Looking at the duplicates of crypto
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'
ORDER BY 1;

-- Updating the industry name for all crypto companies to be Crypto. 
UPDATE  layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Checking the industry names for duplicates after changing crypto industry to be the same name 
SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;


-- Checking the ´location names for duplicates after changing crypto industry to be the same name identified issues, Malmo and MalmA ( will see if it doesnt matter)
SELECT DISTINCT location 
FROM layoffs_staging2
ORDER BY 1;

-- Checking the country names for issues, 
SELECT DISTINCT country 
FROM layoffs_staging2
ORDER BY 1; 

-- Identified isssues We had United States and United States., so we need to update them to look the same 
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- Method 2 to solve the same problem could be trim trail 
UPDATE layoffs_staging2
SET country = TRIM( TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Checking the country names for issues, 
SELECT DISTINCT country 
FROM layoffs_staging2
ORDER BY 1; 

-- Changing the date into a datetimeformat known to SQL by telling it how to read the date text 
SELECT `date`,
STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_staging2; 


-- Updating the date column in the layoffs tabe 
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');


-- Check how code worked 
SELECT `date`
FROM layoffs_staging2; 

-- Change the datatype of the table to date 
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; 

-- Check how code worked 
SELECT *
FROM layoffs_staging2; 


-- 3. Working with Null values 

-- Check where the total laid off is null 
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;  

-- Check where the industry is null 
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry ='';  


-- populating the empty industries 
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Changing the industry blanks to null 
UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = '';

-- Showing the companies with possible matches 
SELECT T1.company, T1.industry, T2.industry
FROM layoffs_staging2 T1
JOIN layoffs_staging2 T2
	ON t1.company = t2.company
    WHERE (T1.industry IS NULL or T1.industry = '' ) 
    AND t2. industry IS NOT NULL;

-- Updating the industry names 
UPDATE layoffs_staging2 t1 
JOIN layoffs_staging2 t2 
	ON 	t1.company = t2.company 
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL; 

-- Checking if we can populate the remaining empty industries 
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';


-- 4. Remove unnecessary columns and rows 

-- Checking for rows where there are no layoff numbers 
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;  

-- Deleting rows where there are no layoff numbers 
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

 
 -- Deleting ROWNUM column where there are no layoff numbers 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

