-- 1. Створіть схему pandemic у базі даних за допомогою SQL-команди.
DROP SCHEMA IF EXISTS pandemic;
CREATE SCHEMA IF NOT EXISTS pandemic;

-- Оберіть її як схему за замовчуванням за допомогою SQL-команди.
USE pandemic;

-- 2. Нормалізуйте таблицю infectious_cases до 3ї нормальної форми. 
-- Збережіть у цій же схемі дві таблиці з нормалізованими даними.
DROP TABLE IF EXISTS entities;
CREATE TABLE IF NOT EXISTS entities (
  entity_ID INT PRIMARY KEY AUTO_INCREMENT,
  entity_Code VARCHAR(8),
  Entity VARCHAR(255)
);

INSERT INTO entities (entity_Code, Entity)
(SELECT DISTINCT Code, Entity
FROM infectious_cases);

DROP TABLE IF EXISTS infect_types;
CREATE TABLE IF NOT EXISTS infect_types (
    id INT PRIMARY KEY AUTO_INCREMENT,
    entity_ID INT,
    Year YEAR,
    Number_yaws VARCHAR(45),
    polio_cases INT,
    cases_guinea_worm INT,
    Number_rabies VARCHAR(45),
    Number_malaria VARCHAR(45),
    Number_hiv VARCHAR(45),
    Number_tuberculosis VARCHAR(45),
    Number_smallpox VARCHAR(45),
    Number_cholera_cases VARCHAR(45),
    FOREIGN KEY (entity_ID)
        REFERENCES entities (entity_ID)
);

INSERT INTO infect_types (entity_ID, Year, Number_yaws, polio_cases, cases_guinea_worm, Number_rabies, Number_malaria, Number_hiv, Number_tuberculosis, Number_smallpox, Number_cholera_cases)
SELECT
    e.entity_ID,
    ic.Year,
    ic.Number_yaws,
    ic.polio_cases,
    ic.cases_guinea_worm,
    ic.Number_rabies,
    ic.Number_malaria,
    ic.Number_hiv,
    ic.Number_tuberculosis,
    ic.Number_smallpox,
    ic.Number_cholera_cases
FROM
    infectious_cases AS ic
    JOIN entities AS e ON ic.Entity = e.Entity AND ic.Code = e.entity_Code;

DESCRIBE infect_types;

-- 3. Проаналізуйте дані:
SELECT
    DISTINCT entity_ID,
    AVG(CAST(Number_rabies AS FLOAT)) AS avgCases_rabies,
    MIN(CAST(Number_rabies AS FLOAT)) AS minCases_rabies,
    MAX(CAST(Number_rabies AS FLOAT)) AS maxCases_rabies,
    SUM(CAST(Number_rabies AS FLOAT)) AS sumCases_rabies
FROM (
        SELECT *
        FROM infect_types
        WHERE Number_rabies <> ''
    ) AS filtered_data
GROUP BY entity_ID;

-- Для кожної унікальної комбінації Entity та Code або їх id порахуйте середнє, 
-- мінімальне, максимальне значення та суму для атрибута Number_rabies.
-- Результат відсортуйте за порахованим середнім значенням у порядку спадання.
-- Оберіть тільки 10 рядків для виведення на екран.
SELECT
    e.entity_ID,
    e.entity_Code,
    AVG(CAST(t.Number_rabies AS DECIMAL(7,2))) AS avgCases_rabies,
    MIN(CAST(t.Number_rabies AS DECIMAL(7,2))) AS minCases_rabies,
    MAX(CAST(t.Number_rabies AS DECIMAL(7,2))) AS maxCases_rabies,
    SUM(CAST(t.Number_rabies AS DECIMAL(7,2))) AS sumCases_rabies
FROM infect_types AS t
JOIN entities AS e ON t.entity_ID = e.entity_ID
WHERE t.Number_rabies <> ''
GROUP BY e.entity_ID, e.entity_Code
ORDER BY avgCases_rabies DESC
LIMIT 10;

-- 4. Побудуйте колонку різниці в роках.
-- Для оригінальної або нормованої таблиці для колонки Year побудуйте 
-- з використанням вбудованих SQL-функцій:
    -- атрибут, що створює дату першого січня відповідного року,
    -- атрибут, що дорівнює поточній даті,
    -- атрибут, що дорівнює різниці в роках двох вищезгаданих колонок.
SELECT
    t.entity_ID,
    MAKEDATE(t.Year, 1) AS Date_case,
    TIMESTAMPDIFF(YEAR, MAKEDATE(t.Year, 1), CURDATE()) AS Years_from_now,
    SUM(CAST(t.Number_rabies AS DECIMAL(7,2))) AS Rabies_case_per_year
FROM infect_types t
WHERE t.Number_rabies <> ''
GROUP BY t.entity_ID, Date_case, Years_from_now;
    
-- 5. Побудуйте власну функцію.
-- Створіть і використайте функцію, що будує такий же атрибут, як і в попередньому завданні: 
-- функція має приймати на вхід значення року, 
-- а повертати різницю в роках між поточною датою та датою, 
-- створеною з атрибута року (1996 рік → ‘1996-01-01’).
DELIMITER //
CREATE FUNCTION calculate_years(Input_year INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE years_diff INT;
    SET years_diff = TIMESTAMPDIFF(YEAR, MAKEDATE(Input_year, 1), CURDATE());
    RETURN years_diff;
END//
DELIMITER ;

SELECT
    t.entity_ID,
    MAKEDATE(t.Year, 1) AS Date_case,
    calculate_years(t.Year) AS Years_from_now,
    SUM(CAST(t.Number_rabies AS DECIMAL(7,2))) AS Rabies_case_per_year
FROM infect_types t
WHERE t.Number_rabies <> ''
GROUP BY t.entity_ID, Date_case, Years_from_now;

-- Якщо ви не виконали попереднє завдання, то можете побудувати іншу функцію — функцію, 
-- що рахує кількість захворювань за певний період. Для цього треба поділити кількість 
-- захворювань на рік на певне число: 
-- 12 — для отримання середньої кількості захворювань на місяць, 
-- 4 — на квартал або 2 — на півріччя. 
-- Таким чином, функція буде приймати два параметри: 
-- кількість захворювань на рік та довільний дільник. 
-- Ви також маєте використати її — запустити на даних. 
-- Оскільки не всі рядки містять число захворювань, вам необхідно буде відсіяти ті, 
-- що не мають чисельного значення (≠ ‘’).
DELIMITER //
CREATE FUNCTION calculate_cases(year_case INT, divisor INT)
RETURNS decimal(7,2)
DETERMINISTIC
BEGIN
    DECLARE cases_per_period FLOAT;
    SET cases_per_period = CAST(year_case / divisor AS FLOAT);
    RETURN cases_per_period;
END//
DELIMITER ;

SELECT 
    t.entity_ID,
    MAKEDATE(t.Year, 1) AS Date,
    calculate_cases(CAST(t.Number_rabies AS FLOAT),
            12) AS CasesPerMonth,
    calculate_cases(CAST(t.Number_rabies AS FLOAT),
            4) AS CasesPerQuarter,
    calculate_cases(CAST(t.Number_rabies AS FLOAT),
            2) AS CasesPerSemester
FROM
    infect_types t
WHERE
        CAST(t.Number_rabies AS FLOAT) IS NOT NULL;