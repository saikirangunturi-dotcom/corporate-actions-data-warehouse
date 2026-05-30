/*
===============================================================================
DDL Script: Create Gold Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'gold' schema, dropping existing tables 
    if they already exist.
	  Run this script to queried directly for analytics and reporting
===============================================================================
*/

USE CorporateActions;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END;
GO

-- Companies dimension gold table

IF OBJECT_ID('gold.dim_companies', 'U') IS NOT NULL
    DROP TABLE gold.dim_companies;
GO

CREATE TABLE gold.dim_companies
(
    company_key     INT IDENTITY(1,1) PRIMARY KEY,
    company_id      NVARCHAR(10),
    company_name    NVARCHAR(50),
    sector          NVARCHAR(50),
    country         NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Securities dimension gold table

IF OBJECT_ID('gold.dim_securities', 'U') IS NOT NULL
    DROP TABLE gold.dim_securities;
GO

CREATE TABLE gold.dim_securities
(
    security_key    INT IDENTITY(1,1) PRIMARY KEY,
    security_id     NVARCHAR(10),
    ticker          NVARCHAR(50),
    isin            NVARCHAR(50),
    company_id      NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Event types dimension gold table

IF OBJECT_ID('gold.dim_event_types', 'U') IS NOT NULL
    DROP TABLE gold.dim_event_types;
GO

CREATE TABLE gold.dim_event_types
(
    event_type_key      INT IDENTITY(1,1) PRIMARY KEY,
    event_type_standard NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- Dates dimension gold table

IF OBJECT_ID('gold.dim_dates', 'U') IS NOT NULL
    DROP TABLE gold.dim_dates;
GO

CREATE TABLE gold.dim_dates
(
    date_key        INT IDENTITY(1,1) PRIMARY KEY,
    calendar_date   DATE,
    day_number      INT,
    day_name        NVARCHAR(20),
    day_of_week     INT,
    week_number     INT,
    month_number    INT,
    month_name      NVARCHAR(20),
    quarter_number  INT,
    year_number     INT,
    is_weekend      NVARCHAR(10),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Main corporate actions gold fact table

IF OBJECT_ID('gold.fact_corporate_actions', 'U') IS NOT NULL
    DROP TABLE gold.fact_corporate_actions;
GO

CREATE TABLE gold.fact_corporate_actions
(
    corporate_action_id         INT IDENTITY(1,1) PRIMARY KEY,
    action_id                   INT,
    company_key                 INT,
    security_key                INT,
    event_type_key              INT,

    announcement_date           DATE,
    ex_date                     DATE,
    record_date                 DATE,
    payment_date                DATE,

    dividend_amount             DECIMAL(18,2),
    currency                    NVARCHAR(50),
    split_ratio                 NVARCHAR(50),
    target_company              NVARCHAR(100),
    acquirer_company            NVARCHAR(100),
    ca_status                   NVARCHAR(50),

    is_action_id_missing        BIT,
    is_event_type_invalid       BIT,
    is_company_ticker_mismatch  BIT,
    is_date_sequence_invalid    BIT,
    is_mandatory_date_missing   BIT,

    validation_status           NVARCHAR(20),
    validation_message          NVARCHAR(100),
    dwh_create_date             DATETIME2 DEFAULT GETDATE()
);
GO

/*--All gold Tables

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold';*/
