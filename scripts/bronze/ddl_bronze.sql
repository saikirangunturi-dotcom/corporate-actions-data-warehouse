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

IF OBJECT_ID('bronze.mdv_companies', 'U') IS NOT NULL
    DROP TABLE bronze.mdv_companies;
GO

CREATE TABLE bronze.mdv_companies (
    company_id      NVARCHAR(50),
    company_name    NVARCHAR(50),
    sector          NVARCHAR(50),
    country         NVARCHAR(50)
);
GO

-- Securities raw table

IF OBJECT_ID('bronze.mdv_securities', 'U') IS NOT NULL
    DROP TABLE bronze.mdv_securities;
GO

CREATE TABLE bronze.mdv_securities (
    security_id     NVARCHAR(50),
    ticker          NVARCHAR(50),
    isin            NVARCHAR(50),
    company_id      NVARCHAR(50)
);
GO

-- Event types raw table

IF OBJECT_ID('bronze.mdv_event_types', 'U') IS NOT NULL
    DROP TABLE bronze.mdv_event_types;
GO

CREATE TABLE bronze.mdv_event_types (
    event_type_id   NVARCHAR(50),
    event_name      NVARCHAR(50)
);
GO

-- Main corporate actions raw table

IF OBJECT_ID('bronze.mdv_corporate_actions', 'U') IS NOT NULL
    DROP TABLE bronze.mdv_corporate_actions;
GO

CREATE TABLE bronze.mdv_corporate_actions (
    action_id           NVARCHAR(50),
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

IF OBJECT_ID('bronze.mdv_dividends', 'U') IS NOT NULL
    DROP TABLE bronze.mdv_dividends;
GO

CREATE TABLE bronze.mdv_dividends (
    action_id           NVARCHAR(50),
    dividend_amount     NVARCHAR(50),
    currency            NVARCHAR(20)
);
GO

-- Split-specific raw table

IF OBJECT_ID('bronze.mdv_splits', 'U') IS NOT NULL
    DROP TABLE bronze.mdv_splits;
GO

CREATE TABLE bronze.mdv_splits (
    action_id           NVARCHAR(50),
    split_ratio         NVARCHAR(50)
);
GO

-- Merger-specific raw table

IF OBJECT_ID('bronze.mdv_mergers', 'U') IS NOT NULL
    DROP TABLE bronze.mdv_mergers;
GO

CREATE TABLE bronze.mdv_mergers (
    action_id           NVARCHAR(50),
    target_company      NVARCHAR(50),
    acquirer_company    NVARCHAR(50)
);
GO

-- Date dimension raw table

IF OBJECT_ID('bronze.mdv_dates', 'U') IS NOT NULL
    DROP TABLE bronze.mdv_dates;
GO

CREATE TABLE bronze.mdv_dates (
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

--Retrieve All Bronze Tables

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'bronze';
