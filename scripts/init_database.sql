/*
===============================================
CREATE DATABASE AND SCHEMAS
===============================================

Purpose of the script:
  This script checks if there exists the database named 'DataWarehouse' and aims 
  to delete it for a fresh start. It then creates the new database with gold, 
  silver and bronze schemas to follow the medallion architecture.

WARNING:
  Running this script would drop the database 'DataWarehouse' completely if it 
  exists. Please consider checking it beforehand to eliminate potential data
  loss. Proceed with caution.
*/

USE master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE name='DataWarehouse')
BEGIN
  ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE DataWarehouse;
END;
GO
    
-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

-- Using the DataWarehouse
USE DataWarehouse;
GO

-- Creating Schemas (bronze, silver, gold)
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
