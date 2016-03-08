--Trams Creation/Insertion Script
--Gisela Chodos, 2/2/2016
--CS 3550, A4b
--creates database diagrammed in A4a and bulk inserts data from provided files
--LOCAL

USE Master

IF EXISTS (SELECT * FROM sysdatabases WHERE name='CHODOS_TRAMS')
DROP DATABASE CHODOS_TRAMS

GO

CREATE DATABASE CHODOS_TRAMS
ON PRIMARY
(
NAME = 'CHODOS_TRAMS',
FILENAME = 'C:\Users\MSSQL$SQLEXPRESS\Documents\CHODOS_TRAMS.mdf',
SIZE = 4MB,
MAXSIZE = 6MB,
FILEGROWTH = 10%
)

LOG ON

(
NAME = 'CHODOS_TRAMS_Log',
FILENAME = 'C:\Users\MSSQL$SQLEXPRESS\Documents\CHODOS_TRAMS.ldf',
SIZE = 1200KB,
MAXSIZE = 5MB,
FILEGROWTH = 1250KB --heavy read/write, 25% growth
)
GO

USE CHODOS_TRAMS

CREATE TABLE Person
(
PersonID  			int  			NOT NULL  IDENTITY(1,1),
PersonFirst  		nvarchar(50)  	NOT NULL,
PersonLast  		nvarchar(50)  	NOT NULL,
PersonAddress  		varchar(200)  	NOT NULL,
PersonCity  		varchar(50)  	NOT NULL,
PersonState  		char(2)  		NULL,
PersonPostalCode  	varchar(10) 	NOT NULL,
PersonCountry  		varchar(20)  	NOT NULL,
PersonPhone  		varchar(20)  	NOT NULL,
PersonEmail  		varchar(200)  	NOT NULL
)

CREATE TABLE UnitType
(
UnitTypeID  			tinyint  		NOT NULL 	IDENTITY(1,1),
UnitTypeDescription  	varchar(20)  	NOT NULL
)

CREATE TABLE Amenity
(
AmenityID  			smallint  		NOT NULL 	IDENTITY(1,1),
AmenityDescription  varchar(50)  	NOT NULL
)

CREATE TABLE TaxLocation
(
TaxLocationID  		smallint  		NOT NULL 	IDENTITY(1,1),
TaxCounty  			varchar(50)  	NOT NULL,
TaxState  			char(2)  		NOT NULL
)

CREATE TABLE TransCategory
(
TransCategoryID  			smallint  		NOT NULL 	IDENTITY(1,1),
TransCategoryDescription  	varchar(50)  	NOT NULL,
TransTaxType  				char(1)  		NOT NULL
)

CREATE TABLE Reservation
(
ReservationID  		int  			NOT NULL 	IDENTITY(1,1),
ResDate  			smalldatetime  	NOT NULL,
ResStatus  			char(1)  		NOT NULL,
ResCheckInDate  	date  			NOT NULL,
ResNights  			tinyint  		NOT NULL,
ResQuotedRate  		smallmoney  	NOT NULL,
ResDepositPaid  	smallmoney  	NOT NULL,
ResCCAuth  			varchar(25)  	NOT NULL,
UnitRateID  		smallint  		NOT NULL,
PersonID  			int  			NOT NULL
)

CREATE TABLE UnitRate
(
UnitRateID  		smallint  		NOT NULL 	IDENTITY(1,1),
UnitRate  			smallmoney  	NOT NULL,
UnitRateBeginDate  	date  			NOT NULL,
UnitRateEndDate  	date  			NOT NULL,
UnitRateDescription varchar(50) 	NULL,
UnitRateActive  	bit  			NOT NULL,
PropertyID  		smallint  		NOT NULL,
UnitTypeID  		tinyint  		NOT NULL
)

CREATE TABLE Property
(
PropertyID  		smallint  		NOT NULL,
PropertyName  		varchar(50)  	NOT NULL,
PropertyAddress  	varchar(200)  	NOT NULL,
PropertyCity  		varchar(50)  	NOT NULL,
PropertyState  		char(2)  		NULL,
PropertyPostalCode  varchar(10)  	NOT NULL,
PropertyCountry  	varchar(20)  	NOT NULL,
PropertyPhone  		varchar(20)  	NOT NULL,
PropertyMgmtFee  	decimal(4,2)  	NOT NULL,
PropertyWebAddress  varchar(100)  	NULL,
TaxLocationID		smallint		NULL
)

CREATE TABLE Unit
(
UnitID  		smallint  		NOT NULL,
UnitNumber  	varchar(5)  	NOT NULL,
PropertyID  	smallint  		NULL,
UnitTypeID  	tinyint  		NOT NULL
)

CREATE TABLE UnitOwner
(
UnitID  		smallint  	NOT NULL,
PersonID  		int  		NOT NULL,
OwnerStartDate  date  		NOT NULL,
OwnerEndDate  	date  		NULL
)

CREATE TABLE UnitAmenity
(
AmenityID  		smallint  	NOT NULL,
UnitID  		smallint  	NOT NULL
)

CREATE TABLE PropertyAmenity
(
AmenityID  		smallint  	NOT NULL,
PropertyID  	smallint  	NOT NULL
)

CREATE TABLE Folio
(
FolioID  			int  			NOT NULL IDENTITY(1,1),
FolioStatus  		char(1)  		NOT NULL,
FolioRate  			smallmoney  	NOT NULL,
FolioCheckInDate  	smalldatetime  	NOT NULL,
FolioCheckOutDate  	smalldatetime  	NULL,
UnitID  			smallint  		NOT NULL,
ReservationID  		int  			NOT NULL
)

CREATE TABLE FolioTransaction
(
TransID  			bigint  		NOT NULL 	IDENTITY(1,1),
TransDate  			datetime  		NOT NULL,
TransAmount  		smallmoney  	NOT NULL,
TransDescription  	varchar(50)  	NOT NULL,
TransCategoryID  	smallint  		NOT NULL,
FolioID  			int  			NOT NULL
)

CREATE TABLE TaxRate
(
TaxID  				int  			NOT NULL IDENTITY(1,1),
TaxRate  			decimal(5,3)  	NOT NULL,
TaxType  			char(1)  		NOT NULL,
TaxDescription  	varchar(50)  	NOT NULL,
TaxStartDate  		date  			NOT NULL,
TaxEndDate  		date  			NULL,
TaxLocationID  		smallint 		NOT NULL
)

GO

ALTER TABLE Person
	ADD CONSTRAINT PK_PersonID
	PRIMARY KEY (PersonID)

ALTER TABLE UnitOwner
	ADD CONSTRAINT PK_UnitID_PersonID
	PRIMARY KEY (UnitID,PersonID)

ALTER TABLE Reservation
	ADD CONSTRAINT PK_ReservationID
	PRIMARY KEY (ReservationID)

ALTER TABLE UnitType
	ADD CONSTRAINT PK_UnitTypeID
	PRIMARY KEY (UnitTypeID)

ALTER TABLE Unit
	ADD CONSTRAINT PK_UnitID
	PRIMARY KEY (UnitID)

ALTER TABLE UnitRate
	ADD CONSTRAINT PK_UnitRateID
	PRIMARY KEY (UnitRateID)

ALTER TABLE UnitAmenity
	ADD CONSTRAINT PK_AmenityID_UnitID
	PRIMARY KEY (AmenityID, UnitID)

ALTER TABLE Folio
	ADD CONSTRAINT PK_FolioID
	PRIMARY KEY (FolioID)

ALTER TABLE Property
	ADD CONSTRAINT PK_PropertyID
	PRIMARY KEY (PropertyID)

ALTER TABLE PropertyAmenity
	ADD CONSTRAINT PK_AmenityID_PropertyID
	PRIMARY KEY (AmenityID, PropertyID)

ALTER TABLE Amenity
	ADD CONSTRAINT PK_AmenityID
	PRIMARY KEY (AmenityID)

ALTER TABLE FolioTransaction
	ADD CONSTRAINT PK_TransID
	PRIMARY KEY (TransID)

ALTER TABLE TransCategory
	ADD CONSTRAINT PK_TransCategoryID
	PRIMARY KEY (TransCategoryID)

ALTER TABLE TaxLocation
	ADD CONSTRAINT PK_TaxLocationID
	PRIMARY KEY (TaxLocationID)

ALTER TABLE TaxRate
	ADD CONSTRAINT PK_TaxID
	PRIMARY KEY (TaxID)

GO




ALTER TABLE UnitOwner
	ADD 
	CONSTRAINT FK_UnitID
	FOREIGN KEY (UnitID) REFERENCES Unit (UnitID)
	ON UPDATE Cascade
	ON DELETE Cascade,
	
	CONSTRAINT FK_1_PersonID  -- unique from FK_PersonID
	FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
	ON UPDATE Cascade
	ON DELETE Cascade

ALTER TABLE Reservation
	ADD 
	CONSTRAINT FK_UnitRateID
	FOREIGN KEY (UnitRateID) REFERENCES UnitRate (UnitRateID)
	ON UPDATE Cascade
	ON DELETE Cascade,
	
	CONSTRAINT FK_PersonID
	FOREIGN KEY (PersonID) REFERENCES Person (PersonID)
	ON UPDATE Cascade
	ON DELETE Cascade

ALTER TABLE Unit
	ADD 
	CONSTRAINT FK_UnitTypeID
	FOREIGN KEY (UnitTypeID) REFERENCES UnitType (UnitTypeID)
	ON UPDATE Cascade
	ON DELETE Cascade

ALTER TABLE UnitRate
	ADD 
	CONSTRAINT FK_PropertyID
	FOREIGN KEY (PropertyID) REFERENCES Property (PropertyID)
	ON UPDATE Cascade
	ON DELETE Cascade,
	
	CONSTRAINT UnitTypeID
	FOREIGN KEY (UnitTypeID) REFERENCES UnitType (UnitTypeID)
	ON UPDATE Cascade
	ON DELETE Cascade

ALTER TABLE UnitAmenity
	ADD 
	CONSTRAINT FK_AmenityID
	FOREIGN KEY (AmenityID) REFERENCES Amenity (AmenityID)
	ON UPDATE Cascade
	ON DELETE Cascade,
	
	CONSTRAINT FK_1_UnitID  -- unique from FK_UnitID
	FOREIGN KEY (UnitID) REFERENCES Unit (UnitID)
	ON UPDATE Cascade
	ON DELETE Cascade

ALTER TABLE Folio
	ADD 
	CONSTRAINT FK_ReservationID
	FOREIGN KEY (ReservationID) REFERENCES Reservation (ReservationID)
	ON UPDATE No Action
	ON DELETE No Action

ALTER TABLE Property
	ADD 
	CONSTRAINT FK_TaxLocationID
	FOREIGN KEY (TaxLocationID) REFERENCES TaxLocation (TaxLocationID)
	ON UPDATE Cascade
	ON DELETE Cascade

ALTER TABLE PropertyAmenity
	ADD 
	CONSTRAINT FK_1_AmenityID
	FOREIGN KEY (AmenityID) REFERENCES Amenity (AmenityID)
	ON UPDATE Cascade
	ON DELETE Cascade,
	
	CONSTRAINT FK_1_PropertyID
	FOREIGN KEY (PropertyID) REFERENCES Property (PropertyID)
	ON UPDATE Cascade
	ON DELETE Cascade

ALTER TABLE FolioTransaction
	ADD 
	CONSTRAINT FK_TransCategoryID
	FOREIGN KEY (TransCategoryID) REFERENCES TransCategory (TransCategoryID)
	ON UPDATE Cascade
	ON DELETE Cascade,
	
	CONSTRAINT FK_FolioID
	FOREIGN KEY (FolioID) REFERENCES Folio (FolioID)
	ON UPDATE Cascade
	ON DELETE Cascade

ALTER TABLE TaxRate
	ADD 
	CONSTRAINT FK_1_TaxLocationID
	FOREIGN KEY (TaxLocationID) REFERENCES TaxLocation (TaxLocationID)
	ON UPDATE Cascade
	ON DELETE Cascade

GO


ALTER TABLE Reservation
	ADD CONSTRAINT CK_ResStatus
	CHECK (ResStatus IN ('A', 'C', 'X'))  
	-- A:Active, C:Complete, X:Cancelled

ALTER TABLE Folio
	ADD CONSTRAINT CK_FolioStatus
	CHECK (FolioStatus IN ('B', 'C', 'X'))  
	-- B:Billed, C:CheckedIn, X:Cancelled

ALTER TABLE TransCategory
	ADD CONSTRAINT CK_TransTaxType
	CHECK (TransTaxType IN ('N', 'L', 'G', 'F'))  
	-- N:NonTaxable, L:Lodging, G:GoodsAndServices, F:FoodAndBeverage

ALTER TABLE TaxRate
	ADD CONSTRAINT CK_TaxType
	CHECK (TaxType IN ('L', 'G', 'F'))  
	-- L:Lodging, G:GoodsAndServices, F:FoodAndBeverage


BULK INSERT Amenity FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\Amenity.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT Folio FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\Folio.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT FolioTransaction FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\FolioTransaction.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT Person FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\Person.txt' WITH (FIELDTERMINATOR='|',DATAFILETYPE='widechar')
BULK INSERT Property FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\Property.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT PropertyAmenity FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\PropertyAmenity.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT Reservation FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\Reservation.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT TaxLocation FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\TaxLocation.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT TaxRate FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\TaxRate.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT TransCategory FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\TransCategory.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT Unit FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\Unit.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT UnitAmenity FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\UnitAmenity.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT UnitOwner FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\UnitOwner.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT UnitRate FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\UnitRate.txt' WITH (FIELDTERMINATOR='|')
BULK INSERT UnitType FROM 'C:\Users\Gisela\Dropbox\WSU\CS 3550 Database\ASSIGNMENTS\Week4b\TRAMS_DATA\UnitType.txt' WITH (FIELDTERMINATOR='|')