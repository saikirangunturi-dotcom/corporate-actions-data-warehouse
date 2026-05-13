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

IF OBJECT_ID('gold.dim_companies_tbl', 'U') IS NOT NULL
    DROP TABLE gold.dim_companies_tbl;
GO

CREATE TABLE gold.dim_companies_tbl (
    company_key     INT PRIMARY KEY,
    company_id      NVARCHAR(10),
    company_name    NVARCHAR(50),
    sector          NVARCHAR(50),
    country         NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Securities dimension gold table

IF OBJECT_ID('gold.dim_securities_tbl', 'U') IS NOT NULL
    DROP TABLE gold.dim_securities_tbl;
GO

CREATE TABLE gold.dim_securities_tbl (
    security_key    INT PRIMARY KEY,
    security_id     NVARCHAR(10),
    ticker          NVARCHAR(50),
    isin            NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Event types dimension gold table

IF OBJECT_ID('gold.dim_event_types_tbl', 'U') IS NOT NULL
    DROP TABLE gold.dim_event_types_tbl;
GO

CREATE TABLE gold.dim_event_types_tbl (
    event_type_key  INT PRIMARY KEY,
    event_type_id   NVARCHAR(10),
    event_name      NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Dates dimension gold table

IF OBJECT_ID('gold.dim_dates_tbl', 'U') IS NOT NULL
    DROP TABLE gold.dim_dates_tbl;
GO

CREATE TABLE gold.dim_dates_tbl (
    date_key        INT PRIMARY KEY,
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

IF OBJECT_ID('gold.fact_corporate_actions_tbl', 'U') IS NOT NULL
    DROP TABLE gold.fact_corporate_actions_tbl;
GO

CREATE TABLE gold.fact_corporate_actions_tbl (
    action_id               INT PRIMARY KEY,
    company_key             INT,
    security_key            INT,
    event_type_key          INT,
    announcement_date_key   INT,
    ex_date_key             INT,
    record_date_key         INT,
    payment_date_key        INT,
    currency                NVARCHAR(10),
    dividend_amount         DECIMAL(10,2),
    split_ratio             NVARCHAR(50),
    ca_status               NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO
