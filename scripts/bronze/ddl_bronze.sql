/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

-- Companies master raw table

IF OBJECT_ID('bronze.companies', 'U') IS NOT NULL
    DROP TABLE bronze.companies;
GO

CREATE TABLE bronze.companies (
    company_id      INT,
    company_name    NVARCHAR(50),
    sector          NVARCHAR(50),
    country         NVARCHAR(50)
);
GO

-- Securities raw table

IF OBJECT_ID('bronze.securities', 'U') IS NOT NULL
    DROP TABLE bronze.securities;
GO

CREATE TABLE bronze.securities (
    security_id     INT,
    ticker          NVARCHAR(50),
    isin            NVARCHAR(50),
    company_id      INT
);
GO

-- Event types raw table

IF OBJECT_ID('bronze.event_types', 'U') IS NOT NULL
    DROP TABLE bronze.event_types;
GO

CREATE TABLE bronze.event_types (
    event_type_id   INT,
    event_name      NVARCHAR(50)
);
GO

-- Main corporate actions raw table

IF OBJECT_ID('bronze.corporate_actions', 'U') IS NOT NULL
    DROP TABLE bronze.corporate_actions;
GO

CREATE TABLE bronze.corporate_actions (
    action_id           INT,
    company_name        NVARCHAR(50),
    ticker              NVARCHAR(50),
    event_type          NVARCHAR(50),
    announcement_date   NVARCHAR(50),
    ex_date             NVARCHAR(50),
    record_date         NVARCHAR(50),
    payment_date        NVARCHAR(50),
    dividend_amount     NVARCHAR(50),
    split_ratio         NVARCHAR(50),
    status              NVARCHAR(50)
);
GO

-- Dividend-specific raw table

IF OBJECT_ID('bronze.dividends', 'U') IS NOT NULL
    DROP TABLE bronze.dividends;
GO

CREATE TABLE bronze.dividends (
    action_id           INT,
    dividend_amount     NVARCHAR(50),
    currency            NVARCHAR(20)
);
GO

-- Split-specific raw table

IF OBJECT_ID('bronze.splits', 'U') IS NOT NULL
    DROP TABLE bronze.splits;
GO

CREATE TABLE bronze.splits (
    action_id           INT,
    split_ratio         NVARCHAR(50)
);
GO

-- Merger-specific raw table

IF OBJECT_ID('bronze.mergers', 'U') IS NOT NULL
    DROP TABLE bronze.mergers;
GO

CREATE TABLE bronze.mergers (
    action_id           INT,
    target_company      NVARCHAR(50),
    acquirer_company    NVARCHAR(50)
);
GO

-- Date dimension raw table

IF OBJECT_ID('bronze.dates', 'U') IS NOT NULL
    DROP TABLE bronze.dates;
GO

CREATE TABLE bronze.dates (
    full_date       NVARCHAR(50),
    day             INT,
    day_name        NVARCHAR(20),
    day_of_week     INT,
    week_of_year    INT,
    month           INT,
    month_name      NVARCHAR(20),
    quarter         INT,
    year            INT,
    is_weekend      NVARCHAR(5)
);
GO
