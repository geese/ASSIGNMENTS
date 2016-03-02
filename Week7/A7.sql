USE CHODOS_TRAMS
GO

PRINT '';
PRINT
'1.	Writing user-defined function:
		name:		dbo.GetLodgingTaxRate
		parameters:	PropertyID, date
		returns:	taxrate (as decimal) for PropertyID 
					where taxtype = ''L'' (for Lodging Tax)
					and date falls between start and end dates
					of the found taxrate.
		or returns:	0 for the taxrate if there is not a lodging
					type taxrate for the property, or the date
					is out of range.'
PRINT '';

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

PRINT '';
PRINT
'2.	Writing user-defined function:
		name:		dbo.CalculateDeposit
		parameters:	UnitRateID, CheckIn Date
		returns:	(small money) Current Unit Rate * (1 + (dbo.GetLodgingTaxRate(PropertyID, CheckinDate) / 100) )
		calls:		function #1 -- dbo.GetLodgingTaxRate()'
PRINT '';

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
		SET @result = @CurrentRate * (1 + (dbo.GetLodgingTaxRate(@PropID,@CheckInDate))/100)

		RETURN @result
	END
GO




PRINT '';
PRINT
'3.	Demonstrating the above functions:

	3A:		Making new Reservation:			
				ResDate = Today
				ResStatus = "A"
				Check-in Date = ''15 Aug 2015''
				Nights = 3
				Quoted Rate = dbo.CalculateDeposit
				Deposit Paid = dbo.CalculateDeposit
				CC Auth = ''3A Results''
				Unit Rate ID = 13
				Person ID = 7
	3B:		Making new Reservation:				
				ResDate = Today
				ResStatus = "A"
				Check-in Date = ''27 Aug 201''
				Nights = 3
				Quoted Rate = dbo.CalculateDeposit
				Deposit Paid = dbo.CalculateDeposit
				CC Auth = ''3B Results''
				Unit Rate ID = 21
				Person ID = 8
	3C:		Making new Reservation:					
				ResDate = Today
				ResStatus = "A"
				Check-in Date = ''25 Sep 2015''
				Nights = 3
				Quoted Rate = dbo.CalculateDeposit
				Deposit Paid = dbo.CalculateDeposit
				CC Auth = ''3C Results''
				Unit Rate ID = 29
				Person ID = 9'
PRINT '';

GO


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


GO
PRINT ''
PRINT ''
PRINT 
'3D:	Selecting * from Reservation to show the results:'
PRINT '';

GO

SELECT * FROM Reservation

GO

PRINT ''
PRINT
'4A:	Writing user-defined function:
			name:		dbo.CalculateCancellationFees
			parameters:	reservationID, CancellationDate
			returns:	TABLE with ReservationID, Original CheckIn Date, Deposit Paid, Cancellation Charge

		Cancellation Policies:
		Regardless of property or season, all cancellations made:
			with more than 30 days’ notice are entitled to a 100% refund of the deposit paid (less a $25 administration fee).
			14-30 days’ cancellation notice (75% refund, less a $25 administration fee)
			8-13 days’ cancellation notice (50% refund, less a $25 administration fee)
			7 days of less cancellation notice – No refund'
PRINT ''

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

PRINT ''
PRINT
'4B:	Demonstrating 4A -- dbo.CalculateCancellationFees() by passing in the reservations created in 3A, 3B, and 3C.
		Cancellation date is 14 Aug 2015.'
PRINT ''
PRINT ''

SELECT * 
FROM dbo.CalculateCancellationFees(46, '14 Aug 2015')

UNION 

SELECT *FROM
dbo.CalculateCancellationFees(47, '14 Aug 2015')

UNION 

SELECT *FROM
dbo.CalculateCancellationFees(48, '14 Aug 2015')



GO

PRINT ''
PRINT
'5:		Writing user-defined function:
			name:		dbo.fn_QuotedRate
			parameters:	begin date, end date, PropertyID, UnitTypeID
			returns:	TABLE @ValidRates
						@ValidRates shows:	the maximum UnitRate applicable during any season/rate
											that falls into the given date range,
											and Unit Type Description
											and additional field for Unit Rate Description
											OR custom error message'
PRINT ''


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
		DECLARE @DEBUG_message varchar(70) = '';
		IF DATEDIFF(day, @BeginDate, @EndDate) < 0
			BEGIN
			SET @DEBUG_message = CONCAT(CONVERT(char(12),@BeginDate,107), ' - ', CONVERT(char(12),@EndDate,107), ' is not a valid date range.')
			INSERT INTO @ValidRates
			VALUES(0, CONCAT(REPLICATE(' ',5),'----'), @DEBUG_message)
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

PRINT ''
PRINT 
'5A:	Demonstrating dbo.fn_QuotedRate with parameters:
			begin date:	1 July, 2015
			end date:	30 Nov, 2015
			propertyID:	10000
			unitTypeID:	4'
PRINT ''

GO

SELECT * FROM dbo.fn_QuotedRate('1 july, 2015', '30 NOV, 2015',10000,4) 


GO

PRINT ''
PRINT ''
PRINT 
'5B:	Demonstrating dbo.fn_QuotedRate with parameters:
			begin date:	1 July, 2015
			end date:	30 Nov, 2015
			propertyID:	11000
			unitTypeID:	4'
PRINT ''

GO


SELECT * FROM dbo.fn_QuotedRate('1 july, 2015', '30 NOV, 2015',11000,4)


GO

PRINT ''
PRINT ''
PRINT 
'5C:	Demonstrating dbo.fn_QuotedRate with parameters:
			begin date:	30 Nov, 2015
			end date:	1 July, 2015	--BAD DATE RANGE
			propertyID:	10000
			unitTypeID:	4'
PRINT ''

GO


SELECT * FROM dbo.fn_QuotedRate('30 NOV, 2015', '1 july, 2015',11000,4)  