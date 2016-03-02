USE CHODOS_TRAMS
GO

IF EXISTS(SELECT name FROM sys.objects WHERE name = 'GetLodgingTaxRate')
	DROP FUNCTION GetLodgingTaxRate;

GO

CREATE FUNCTION  dbo.GetLodgingTaxRate
(
		@PropID			smallint
	,	@date			date
)
RETURNS decimal(5,3)
AS
	BEGIN
			DECLARE @result decimal(5,3)			
			SET @result = 
				   (SELECT TaxRate
					FROM TaxRate tr
					JOIN Property p
						ON tr.TaxLocationID = p.TaxLocationID 
						AND tr.TaxType = 'L'
						AND p.PropertyID = @PropID
						
						AND (
							(@date BETWEEN tr.TaxStartDate AND tr.TaxEndDate)
							OR 
							(@date > tr.TaxStartDate AND   tr.TaxEndDate IS NULL)
							)
					)
			IF @result IS NULL
				BEGIN
					SET @result = 0
				END
			RETURN @result
	END	

GO

SELECT dbo.GetLodgingTaxRate(10000,'3/1/16')

GO

IF EXISTS(SELECT name FROM sys.objects WHERE name = 'CalculateDeposit')
	DROP FUNCTION CalculateDeposit
GO

CREATE FUNCTION dbo.CalculateDeposit
(
		@UnitRateID		smallint
	,	@CheckInDate	date
)
RETURNS smallmoney
AS
	BEGIN
		DECLARE @CurrentRate smallmoney = (SELECT UnitRate FROM UnitRate WHERE UnitRateID = @UnitRateID)
		DECLARE @PropID smallint = (SELECT PropertyID FROM UnitRate WHERE UnitRateID = @UnitRateID)

		DECLARE @result smallmoney
		SET @result = @CurrentRate * (1 + (.01 * dbo.GetLodgingTaxRate(@PropID,@CheckInDate)))

		RETURN @result
	END
GO

SELECT dbo.CalculateDeposit(42,'3/1/16')


IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE SPECIFIC_NAME = 'sp_InsertReservation')
	DROP PROCEDURE sp_InsertReservation
	
GO

CREATE PROCEDURE sp_InsertReservation
		@ResDate			smalldatetime
	,	@ResStatus			char(1)
	,	@ResCheckInDate		date
	,	@ResNights			tinyint
	,	@ResQuotedRate		smallmoney
	,	@ResDepositPaid		smallmoney
	,	@ResCCAuth			varchar(25)
	,	@UnitRateID			smallint
	,	@PersonID			int

AS
BEGIN
	INSERT INTO Reservation
	VALUES(@ResDate, @ResStatus, @ResCheckInDate, @ResNights, @ResQuotedRate, @ResDepositPaid, @ResCCAuth, @UnitRateID, @PersonID)
END

GO


DECLARE @DateToday smalldatetime = GETDATE()
DECLARE @CheckInDate date = '15 Aug 2015'
DECLARE @QuotedRate smallmoney = dbo.CalculateDeposit(13, @CheckInDate)

EXEC sp_InsertReservation
		@ResDate			=	@DateToday
	,	@ResStatus			=	'A'
	,	@ResCheckInDate		=	@CheckInDate
	,	@ResNights			=	3
	,	@ResQuotedRate		=	@QuotedRate
	,	@ResDepositPaid		=	@QuotedRate
	,	@ResCCAuth			=	'3A Results'
	,	@UnitRateID			=	13
	,	@PersonID			=	7
			

SET @CheckInDate = '27 Aug 2015'
SET @QuotedRate = dbo.CalculateDeposit(21, @CheckInDate)

EXEC sp_InsertReservation
		@ResDate			=	@DateToday
	,	@ResStatus			=	'A'
	,	@ResCheckInDate		=	@CheckInDate
	,	@ResNights			=	3
	,	@ResQuotedRate		=	@QuotedRate
	,	@ResDepositPaid		=	@QuotedRate
	,	@ResCCAuth			=	'3B Results'
	,	@UnitRateID			=	21
	,	@PersonID			=	8


SET @CheckInDate = '25 Sep 2015'
SET @QuotedRate = dbo.CalculateDeposit(29, @CheckInDate)

EXEC sp_InsertReservation
		@ResDate			=	@DateToday
	,	@ResStatus			=	'A'
	,	@ResCheckInDate		=	@CheckInDate
	,	@ResNights			=	3
	,	@ResQuotedRate		=	@QuotedRate
	,	@ResDepositPaid		=	@QuotedRate
	,	@ResCCAuth			=	'3C Results'
	,	@UnitRateID			=	29
	,	@PersonID			=	9


SELECT * FROM Reservation

GO

IF EXISTS(SELECT name FROM sys.objects WHERE name = 'CalculateCancellationFees')
	DROP FUNCTION CalculateCancellationFees 

GO

CREATE FUNCTION dbo.CalculateCancellationFees
(
		@ResID		int
	,	@CancelDate	date
)
RETURNS @CancellationFees	TABLE
(
	[ResID]					[int]			NOT NULL,
	[ResChkInDate]			[date]			NOT NULL,
	[ResDepPaid]			[smallmoney]	NOT NULL,
	[CancellationCharge]	[smallmoney]	NOT NULL
)
AS
BEGIN
	INSERT INTO @CancellationFees 
	SELECT ReservationID, ResCheckInDate, ResDepositPaid, 0
	FROM Reservation 
	WHERE ReservationID = @ResID

	UPDATE @CancellationFees
		SET CancellationCharge = CASE
			WHEN DATEDIFF(day, @CancelDate, [ResChkInDate]) > 30
				THEN 25
			WHEN DATEDIFF(day, @CancelDate, [ResChkInDate]) BETWEEN 14 AND 30
				THEN (.25 * [ResDepPaid]) + 25
			WHEN DATEDIFF(day,  @CancelDate, [ResChkInDate]) BETWEEN 8 AND 13
				THEN (.50 * [ResDepPaid]) + 25
			ELSE [ResDepPaid]		
			END
	RETURN 
END

GO

SELECT * 
FROM dbo.CalculateCancellationFees(46, '14 Aug 2015')

UNION 

SELECT *FROM
dbo.CalculateCancellationFees(47, '14 Aug 2015')

UNION 

SELECT *FROM
dbo.CalculateCancellationFees(48, '14 Aug 2015')



GO

IF EXISTS(SELECT name FROM sys.objects WHERE name = 'fn_QuotedRate')
DROP FUNCTION  fn_QuotedRate

GO

CREATE FUNCTION dbo.fn_QuotedRate
(
		@BeginDate		date
	,	@EndDate		date
	,	@PropID			smallint
	,	@UnitTypeID		tinyint
)
RETURNS @ValidRates	TABLE
(
		[Max Rate]	[smallmoney]	NOT NULL,
	[Unit Type]	varchar(18)  NOT NULL,
	[Unit Rate Description]  varchar(60)  NULL
)
AS
	BEGIN
		IF DATEDIFF(day, @BeginDate, @EndDate) < 0
			BEGIN
			INSERT INTO @ValidRates
			VALUES(0, CONCAT(REPLICATE(' ',5),'----'), CONCAT(CONVERT(char(12),@BeginDate,107), ' - ', CONVERT(char(12),@EndDate,107), ' is not a valid date range.'))
			END
		ELSE
		BEGIN
			INSERT INTO @ValidRates 
			SELECT ur.UnitRate, ut.UnitTypeDescription, ur.UnitRateDescription
			FROM UnitRate ur
			JOIN UnitType ut
				ON ur.UnitTypeID = ut.UnitTypeID
				AND ur.PropertyID = @PropID
				AND ut.UnitTypeID = @UnitTypeID
			WHERE @BeginDate BETWEEN ur.UnitRateBeginDate AND ur.UnitRateEndDate			
		
			UNION

			SELECT ur.UnitRate, ut.UnitTypeDescription, ur.UnitRateDescription
			FROM UnitRate ur
			JOIN UnitType ut
				ON ur.UnitTypeID = ut.UnitTypeID
				AND ur.PropertyID = @PropID
				AND ut.UnitTypeID = @UnitTypeID
			WHERE @EndDate BETWEEN ur.UnitRateBeginDate AND ur.UnitRateEndDate
		
			DECLARE @MaxRate smallmoney = 
				(SELECT MAX([Max Rate])
				FROM @ValidRates)
			
			DELETE @ValidRates
			WHERE [Max Rate]!= @MaxRate
		END

		
	RETURN
	END

GO

SELECT * FROM dbo.fn_QuotedRate('1 july, 2015', '30 NOV, 2015',10000,4) 
SELECT * FROM dbo.fn_QuotedRate('1 july, 2015', '30 NOV, 2015',11000,4)
SELECT * FROM dbo.fn_QuotedRate('30 NOV, 2015', '1 july, 2015',11000,4)  