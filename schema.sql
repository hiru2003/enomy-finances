-- =============================================================================
-- Database Initialization Script for Enomy-Finances
-- Target RDBMS: MySQL 8.0+
-- File: schema.sql
-- Description: Production-ready relational schema with ACID integrity,
--              foreign keys, constraints, and baseline seed data.
-- =============================================================================

-- Disable foreign key checks for safe idempotent re-runs
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- Database Creation & Context
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS enomy_finances
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE enomy_finances;

-- -----------------------------------------------------------------------------
-- Drop Existing Tables (Reverse-Dependency Order)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS InvestmentQuote;
DROP TABLE IF EXISTS Transaction;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS SavingsPlan;
DROP TABLE IF EXISTS Currency;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- Table Structure Definitions
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Currency (Lookup Table for Exchange Rates relative to base GBP)
-- -----------------------------------------------------------------------------
CREATE TABLE Currency (
    CurrencyCode VARCHAR(3) NOT NULL,
    ExchangeRate DECIMAL(10, 4) NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT PK_Currency PRIMARY KEY (CurrencyCode),
    CONSTRAINT CHK_ExchangeRate_Positive CHECK (ExchangeRate > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 2. SavingsPlan (Lookup Table for Investment Business Rules & Rates)
-- -----------------------------------------------------------------------------
CREATE TABLE SavingsPlan (
    PlanID INT AUTO_INCREMENT NOT NULL,
    PlanName VARCHAR(50) NOT NULL,
    MinMonthly DECIMAL(10, 2) NOT NULL,
    MaxYearly DECIMAL(12, 2) NULL, -- NULL indicates unlimited contributions
    PredictedReturnMin DECIMAL(5, 4) NOT NULL,
    PredictedReturnMax DECIMAL(5, 4) NOT NULL,
    RBSXFee DECIMAL(5, 4) NOT NULL,
    CONSTRAINT PK_SavingsPlan PRIMARY KEY (PlanID),
    CONSTRAINT CHK_MinMonthly_Positive CHECK (MinMonthly >= 0),
    CONSTRAINT CHK_ReturnRange CHECK (PredictedReturnMin <= PredictedReturnMax)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 3. Customer (Client Master Table)
-- -----------------------------------------------------------------------------
CREATE TABLE Customer (
    CustomerID VARCHAR(10) NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Phone VARCHAR(20) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Customer PRIMARY KEY (CustomerID),
    CONSTRAINT UQ_Customer_Email UNIQUE (Email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 4. Transaction (Currency Conversion Ledger)
-- -----------------------------------------------------------------------------
CREATE TABLE Transaction (
    TransactionID VARCHAR(15) NOT NULL,
    CustomerID VARCHAR(10) NOT NULL,
    InitialCurrency VARCHAR(3) NOT NULL,
    TargetCurrency VARCHAR(3) NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    FeeApplied DECIMAL(5, 4) NOT NULL,
    FinalAmount DECIMAL(10, 2) NOT NULL,
    TransactionDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_Transaction PRIMARY KEY (TransactionID),
    CONSTRAINT FK_Transaction_Customer FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT FK_Transaction_InitialCurrency FOREIGN KEY (InitialCurrency)
        REFERENCES Currency(CurrencyCode)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT FK_Transaction_TargetCurrency FOREIGN KEY (TargetCurrency)
        REFERENCES Currency(CurrencyCode)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT CHK_Transaction_Amount CHECK (Amount BETWEEN 300.00 AND 5000.00),
    CONSTRAINT CHK_Transaction_Fee CHECK (FeeApplied >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 5. InvestmentQuote (Investment Projections History)
-- -----------------------------------------------------------------------------
CREATE TABLE InvestmentQuote (
    QuoteID INT AUTO_INCREMENT NOT NULL,
    CustomerID VARCHAR(10) NOT NULL,
    PlanID INT NOT NULL,
    InitialLumpSum DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    MonthlyAmount DECIMAL(10, 2) NOT NULL,
    QuoteDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_InvestmentQuote PRIMARY KEY (QuoteID),
    CONSTRAINT FK_InvestmentQuote_Customer FOREIGN KEY (CustomerID)
        REFERENCES Customer(CustomerID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT FK_InvestmentQuote_SavingsPlan FOREIGN KEY (PlanID)
        REFERENCES SavingsPlan(PlanID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT CHK_InitialLumpSum_NonNegative CHECK (InitialLumpSum >= 0),
    CONSTRAINT CHK_MonthlyAmount_Positive CHECK (MonthlyAmount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- Baseline Seed Data Insertion
-- =============================================================================

-- 1. Insert Base & Exchange Currencies (Base: GBP)
INSERT INTO Currency (CurrencyCode, ExchangeRate) VALUES
('GBP', 1.0000),
('USD', 1.2715),
('EUR', 1.1692),
('BRL', 6.3540),
('JPY', 191.4800),
('TRY', 42.8150);

-- 2. Insert Investment / Savings Plans
INSERT INTO SavingsPlan (PlanID, PlanName, MinMonthly, MaxYearly, PredictedReturnMin, PredictedReturnMax, RBSXFee) VALUES
(1, 'Basic Saver', 50.00, 20000.00, 0.0120, 0.0240, 0.0025),
(2, 'Savings Plan Plus', 50.00, 30000.00, 0.0300, 0.0550, 0.0030),
(3, 'Managed Stock Investments', 150.00, NULL, 0.0400, 0.2300, 0.0130);

-- 3. Insert Baseline Mock Customers
INSERT INTO Customer (CustomerID, FullName, Email, Phone) VALUES
('CL-101', 'John Doe', 'john.doe@enomy-client.com', '+44 7700 900101'),
('CL-102', 'Jane Smith', 'jane.smith@enomy-client.com', '+44 7700 900102');

-- 4. Insert Sample Currency Conversion Transactions
INSERT INTO Transaction (TransactionID, CustomerID, InitialCurrency, TargetCurrency, Amount, FeeApplied, FinalAmount, TransactionDate) VALUES
('TXN-2026-0001', 'CL-101', 'GBP', 'USD', 1000.00, 0.0270, 1237.17, '2026-08-15 09:30:00'),
('TXN-2026-0002', 'CL-102', 'GBP', 'EUR', 3000.00, 0.0150, 3454.99, '2026-08-15 10:15:00');

-- 5. Insert Sample Investment Quotes
INSERT INTO InvestmentQuote (CustomerID, PlanID, InitialLumpSum, MonthlyAmount, QuoteDate) VALUES
('CL-101', 2, 500.00, 150.00, '2026-08-15 09:35:00'),
('CL-102', 3, 2500.00, 300.00, '2026-08-15 10:20:00');

-- =============================================================================
-- End of Script
-- =============================================================================
