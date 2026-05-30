/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' Tables
===============================================================================
*/

USE CorporateActions;
GO

-- Companies silver table

IF OBJECT_ID('silver.mdv_companies', 'U') IS NOT NULL
    DROP TABLE silver.mdv_companies;
GO

CREATE TABLE silver.mdv_companies (
    company_id      NVARCHAR(10),
    company_name    NVARCHAR(50),
    sector          NVARCHAR(50),
    country         NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Securities silver table

IF OBJECT_ID('silver.mdv_securities', 'U') IS NOT NULL
    DROP TABLE silver.mdv_securities;
GO

CREATE TABLE silver.mdv_securities (
    security_id     NVARCHAR(10),
    ticker          NVARCHAR(50),
    isin            NVARCHAR(50),
    company_id      NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Event types silver table

IF OBJECT_ID('silver.mdv_event_types', 'U') IS NOT NULL
    DROP TABLE silver.mdv_event_types;
GO

CREATE TABLE silver.mdv_event_types (
    event_type_id   NVARCHAR(10),
    event_name      NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Main corporate actions silver table

IF OBJECT_ID('silver.mdv_corporate_actions', 'U') IS NOT NULL
    DROP TABLE silver.mdv_corporate_actions;
GO

CREATE TABLE silver.mdv_corporate_actions (
    action_id                   INT,
    company_name                NVARCHAR(100),
    ticker                      NVARCHAR(50),
    master_company_name         NVARCHAR(100),
    event_type_raw              NVARCHAR(100),
    event_type_standard         NVARCHAR(50),
    announcement_date           DATE,
    ex_date                     DATE,
    record_date                 DATE,
    payment_date                DATE,
    dividend_amount             DECIMAL(18,2),
    split_ratio                 NVARCHAR(50),
    ca_status                   NVARCHAR(50),
    is_action_id_missing        BIT,
    is_event_type_invalid       BIT,
    is_company_ticker_mismatch  BIT,
    is_date_sequence_invalid    BIT,
    is_mandatory_date_missing   BIT,
    validation_status           NVARCHAR(20),
    validation_message          NVARCHAR(500),
    dwh_create_date             DATETIME2 DEFAULT GETDATE()
);
GO

-- Dividend-specific silver table

IF OBJECT_ID('silver.mdv_dividends', 'U') IS NOT NULL
    DROP TABLE silver.mdv_dividends;
GO

CREATE TABLE silver.mdv_dividends (
    action_id           INT,
    dividend_amount     DECIMAL(10,2),
    currency            NVARCHAR(20),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- Split-specific silver table

IF OBJECT_ID('silver.mdv_splits', 'U') IS NOT NULL
    DROP TABLE silver.mdv_splits;
GO

CREATE TABLE silver.mdv_splits (
    action_id           INT,
    split_ratio         NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- Merger-specific silver table

IF OBJECT_ID('silver.mdv_mergers', 'U') IS NOT NULL
    DROP TABLE silver.mdv_mergers;
GO

CREATE TABLE silver.mdv_mergers (
    action_id           INT,
    target_company      NVARCHAR(50),
    acquirer_company    NVARCHAR(50),
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO

-- Date dimension silver table

IF OBJECT_ID('silver.mdv_dates', 'U') IS NOT NULL
    DROP TABLE silver.mdv_dates;
GO

CREATE TABLE silver.mdv_dates (
    full_date       DATE,
    day             INT,
    day_name        NVARCHAR(20),
    day_of_week     INT,
    week_of_year    INT,
    month           INT,
    month_name      NVARCHAR(20),
    quarter         INT,
    year            INT,
    is_weekend      NVARCHAR(10),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

--All Silver Tables

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'silver';
