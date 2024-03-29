--Part 1: Database and tables
--Creating the database
CREATE DATABASE TheLibrary;

USE TheLibrary;
GO

--Creating the Members table
CREATE TABLE Members (
												MemberID int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
												FirstName nvarchar(50) NOT NULL CHECK (FirstName = UPPER(LEFT(FirstName, 1)) + LOWER(SUBSTRING(FirstName, 2, LEN(FirstName) - 1))),
												LastName nvarchar(50) NOT NULL CHECK (LastName = UPPER(LEFT(LastName, 1)) + LOWER(SUBSTRING(LastName, 2, LEN(LastName) - 1))),
												ContactAddress nvarchar(200) NOT NULL,
												DOB date NOT NULL,
												EmailAddress nvarchar(100) NULL CHECK (EmailAddress LIKE '%_@_%._%'),
												TelephoneNumber char(11) NULL,
												UserName nvarchar(10) UNIQUE NOT NULL CHECK (LEN(UserName) >= 4 AND UserName = LOWER(UserName)),
												PWD nvarchar(16) NOT NULL CHECK (LEN(PWD) >= 8),
												DateJoined date NOT NULL,
												DateLeft date NULL
												);
GO

CREATE TRIGGER EncryptPassword
ON Members
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Members
    SET PWD = CONVERT(varbinary(32), ENCRYPTBYPASSPHRASE('****', i.PWD))
    FROM inserted AS i
    WHERE Members.MemberID = i.MemberID;
END;

--Creating the Catalogue table
CREATE TABLE Catalogue (
												 ItemID int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
												 Title nvarchar(100) NOT NULL,
												 ItemType nvarchar(20) NOT NULL CHECK (ItemType IN ('Book', 'Journal', 'DVD', 'Other Media')),
												 Author nvarchar(50) NOT NULL,
												 YearOfPublication date NOT NULL CHECK (YearOfPublication = DATEFROMPARTS(DATEPART(YEAR, YearOfPublication), 1, 1)),
												 DateAdded date NOT NULL,
												 CurrentStatus nvarchar(20) NOT NULL CHECK (CurrentStatus IN ('On Loan', 'Overdue', 'Available', 'Lost/Removed')),
												 ISBN char(17) NULL
												);

--Creating LostRemoved table
CREATE TABLE LostRemoved (
														LostRemovedID int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
														ItemID int NOT NULL FOREIGN KEY (ItemID) REFERENCES Catalogue (ItemID),
														DateLostRemoved date NOT NULL
														);

--Creating the Loans table
CREATE TABLE Loans (
										  LoanID int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
										  MemberID int NOT NULL FOREIGN KEY (MemberID) REFERENCES Members (MemberID), 
										  ItemID int NOT NULL FOREIGN KEY (ItemID) REFERENCES Catalogue (ItemID),
										  LoanDate date NOT NULL,
										  DueDate AS DATEADD(day, 30, LoanDate) PERSISTED,
										  ReturnDate date NULL,
										  OverDueDays int NULL
										 );

GO

CREATE TRIGGER UpdateOverDueDays
ON Loans
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Loans
	SET OverDueDays = CASE WHEN i.ReturnDate <=  i.DueDate THEN 0
												   WHEN i.ReturnDate IS NULL AND GETDATE() <= i.DueDate THEN 0
												   WHEN i.ReturnDate IS NULL AND GETDATE() > i.DueDate THEN DATEDIFF(day, i.DueDate, GETDATE()) 
										ELSE DATEDIFF(day, i.DueDate, i.ReturnDate) 
										END
										FROM inserted AS i
    WHERE Loans.LoanID = i.LoanID;
END;

--Creating the Fines table
CREATE TABLE Fines (
										FineID int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
										LoanID int NOT NULL FOREIGN KEY (LoanID) REFERENCES Loans (LoanID),
										AmountOwed money NOT NULL
										);

GO

CREATE TRIGGER InsertFines
ON Loans
AFTER INSERT, UPDATE
AS
BEGIN
INSERT INTO Fines (LoanID, AmountOwed)
SELECT i.LoanID, 0.10 * i.OverDueDays
FROM inserted AS i
INNER JOIN Loans AS l
ON i.LoanID = l.LoanID
WHERE i.OverDueDays > 0
END;

--Creating the Repayment table
CREATE TABLE Repayment (
													RepaymentID int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
													FineID int NOT NULL FOREIGN KEY (FineID) REFERENCES Fines (FineID),
													AmountRepaid money NOT NULL,
													OutstandingBal money NOT NULL,
													DateRepaid date NOT NULL,
													RepaymentMethod char(4) NOT NULL CHECK (RepaymentMethod IN ('Cash', 'Card')) 
												  );


--Part 2: Database objects
--(a)Stored procedure to search the Catalogue table for matching character strings by Title and results sorted with the most recent publication date first
CREATE PROCEDURE SearchCatalogueTitle
    @SearchTitle nvarchar(100)
AS
BEGIN
    SELECT ItemID, Title, ItemType, Author, YearOfPublication, DateAdded, CurrentStatus, ISBN
    FROM Catalogue
    WHERE Title LIKE '%' + @SearchTitle + '%'
    ORDER BY YearOfPublication DESC
END;

--(b) User-defined function to return a full list of all items currently on loan which have a due date of less than 5 days from the current date
CREATE FUNCTION NearDueLoans()
RETURNS TABLE
AS
RETURN
    SELECT l.LoanID, c.Title, l.DueDate
		FROM Loans AS l
		JOIN Catalogue AS c 
		ON l.ItemID = c.ItemID
    WHERE l.ReturnDate IS NULL AND l.DueDate < DATEADD(day, 5, GETDATE());

--(c) Stored procedure to insert a new member into the database
CREATE PROCEDURE InsertNewMember
    @FirstName nvarchar(50),
    @LastName nvarchar(50),
    @ContactAddress nvarchar(200),
    @DOB date,
    @EmailAddress nvarchar(100) = NULL,
    @TelephoneNumber char(11) = NULL,
    @UserName nvarchar(10),
    @PWD nvarchar(16),
    @DateJoined date
AS
BEGIN
    IF EXISTS (SELECT * FROM Members WHERE EmailAddress = @EmailAddress)
    BEGIN
        RAISERROR ('Email address already exists.', 16, 1)
        RETURN
    END

    IF EXISTS (SELECT * FROM Members WHERE UserName = @UserName)
    BEGIN
        RAISERROR ('Username already exists.', 16, 1)
        RETURN
    END

    INSERT INTO Members (FirstName, LastName, ContactAddress, DOB, EmailAddress, TelephoneNumber, UserName, PWD, DateJoined)
    VALUES (@FirstName, @LastName, @ContactAddress, @DOB, @EmailAddress, @TelephoneNumber, @UserName, @PWD, @DateJoined)
END;

--(d) Stored procedure to update the details for an existing member
CREATE PROCEDURE UpdateMemberDetails
@MemberID int,
@FirstName nvarchar(50),
@LastName nvarchar(50),
@ContactAddress nvarchar(200),
@DOB date,
@EmailAddress nvarchar(100),
@TelephoneNumber char(11),
@UserName nvarchar(10),
@PWD nvarchar(16),
@DateJoined date,
@DateLeft date
AS
BEGIN
UPDATE Members
SET FirstName = @FirstName,
LastName = @LastName,
ContactAddress = @ContactAddress,
DOB = @DOB,
EmailAddress = @EmailAddress,
TelephoneNumber = @TelephoneNumber,
UserName = @UserName,
PWD = @PWD,
DateJoined = @DateJoined,
DateLeft = @DateLeft
WHERE MemberID = @MemberID;
END;


--(e) View of the loan history showing all previous and current loans, and including details of the item borrowed, borrowed date, due date and any associated fines for each loan.
CREATE VIEW LoanHistory AS
SELECT l.LoanID, m.FirstName + ' ' + m.LastName AS BorrowerName, c.Title, l.LoanDate, l.DueDate, f.AmountOwed AS AssociatedFines
	FROM Loans AS l
    INNER JOIN Members AS m 
	ON l.MemberID = m.MemberID 
    INNER JOIN Catalogue AS c
	ON l.ItemID = c.ItemID 
    LEFT JOIN Fines AS f
	ON l.LoanID = f.LoanID;


--(f) Trigger that updates the current status of an item to Available when the book is returned
DROP TRIGGER IF EXISTS UpdateCatalogueStatus;

GO

CREATE TRIGGER UpdateCatalogueStatus
ON Loans
AFTER UPDATE
AS
BEGIN
    IF UPDATE(ReturnDate)
    BEGIN
        UPDATE Catalogue
        SET CurrentStatus = 'Available'
        FROM Catalogue AS c
        INNER JOIN inserted AS i
		ON c.ItemID = i.ItemID
        WHERE i.ReturnDate IS NOT NULL
    END
END;


--(g) SELECT query which allows the library to identify the total number of loans made on a specified date.
SELECT LoanDate, COUNT(*) AS Total_Loans
FROM Loans
WHERE LoanDate = '2023-01-05'
GROUP BY LoanDate;


--Part 3: Inserting dummy data into the different tables
--(a) Inserting records into the Members table
INSERT INTO Members (FirstName, LastName, ContactAddress, DOB, EmailAddress, TelephoneNumber, UserName, PWD, DateJoined, DateLeft)
VALUES ('Oluwaseyi', 'Ibikunle', '55 Sugar Mill Square, Salford M5 5EB', '1993-11-28', NULL, '07494320610', 'seyifunmi', 'libraryMcr2', '2023-01-05', NULL),
				('Oluwole', 'Ola', '5 Weaste Lane, Salford M6 6XR', '1992-07-23', 'wolexis@gmail.com', '07467867401', 'wolexis', 'Imaginary23', '2019-04-01', '2022-12-23'),
				('Anjola', 'Badmus', 'Bolton BL1 1AR', '2000-01-01', NULL, NULL, 'anjie', 'Tiara&OLUWA1', '2021-05-28', NULL),
				('Kusibe', 'Daramola', '5 Crescent Way, Liverpool L10 0AR', '1993-12-13', 'kuskus@yahoo.co.uk', NULL, 'kusibe', 'olaotanKusibe93', '2020-05-10', '2020-12-05'),
				('Opeyemi',  'Ajose', '11 Warrington Road WA11 5DB', '2003-01-15', 'opijay@hotmail.com', '07184245628', 'opijay', 'Opi4yemi', '2019-09-08', NULL);

SELECT * 
	FROM Members;

--(b) Inserting records into the Catalogue table
INSERT INTO Catalogue (Title, ItemType, Author, YearOfPublication, DateAdded, CurrentStatus, ISBN)
VALUES ('Half of a Yellow Sun', 'Book', 'Chimamanda N. Adichie', '2006', '2021-12-01', 'On Loan', '978-0-00-720028-3'),
       ('Gone Girl', 'Book', 'Gillian Flynn', '2012', '2022-01-01', 'Lost/Removed', '978-0-30-758836-4'),
       ('The Great Gatsby', 'Book', 'F. Scott Fitzgerald', '1925', '2020-11-28', 'Available', '978-3-16-148410-0'),
       ('The New York Times', 'Journal', 'Arthur Ochs Sulzberger Jr.', '1851', '2021-01-02', 'Available', NULL),
       ('The Shawshank Redemption', 'DVD', 'Frank Darabont', '1994', '2022-01-03', 'On Loan', NULL),
       ('To Kill a Mockingbird', 'Book', 'Harper Lee', '1960', '2022-05-04', 'Lost/Removed', '978-0-44-631078-9'),
       ('The Lord of the Rings', 'Other Media', 'J.R.R. Tolkien', '1954', '2022-01-05', 'Available', NULL),
       ('Things Fall Apart', 'Book', 'Chinua Achebe', '1958', '2023-01-03', 'On Loan', '978-0-38-547454-2');

SELECT *
	FROM Catalogue;

--(c) Inserting records into the LostRemoved table
INSERT INTO LostRemoved (ItemID, DateLostRemoved)
VALUES (2, '2022-11-17'),
				(6, '2023-04-09');

SELECT *
	FROM LostRemoved;

--(d) Inserting records into the Loans table
INSERT INTO Loans (MemberID, ItemID, LoanDate, ReturnDate)
VALUES (1, 1, '2022-12-03', '2023-02-01'),
       (3, 5, '2023-01-05', '2023-01-30'),
	   (4, 6, '2023-03-10', '2023-04-10'),
       (5, 8, '2023-03-28',NULL);

SELECT * 
	FROM Loans;

--Confirming InsertFines trigger worked
SELECT *
	FROM Fines;

--(e) Inserting records into Repayment table
INSERT INTO Repayment (FineID, AmountRepaid, OutstandingBal, DateRepaid, RepaymentMethod)
VALUES (1, 1.25, 1.75, '2023-02-01', 'Card'),
				(2, 0.10, 0.00, '2023-04-10', 'Cash');

SELECT *
	FROM Repayment

--Part 4: Demonstrating the additional database objects
--(a) Executing the SearchCatalogueTitle stored procedure
EXEC SearchCatalogueTitle @SearchTitle = '%the%';

--(b) Executing the NearDueLoans user-defined function
SELECT * 
	FROM NearDueLoans();

--(c) Executing the InsertNewMember stored procedure
EXEC InsertNewMember
    @FirstName = 'Mary',
    @LastName = 'Aisagbonhi',
    @ContactAddress = '1Georgetown Avenue, Worsley, M28 1MA',
    @DOB = '1992-02-01',
    @EmailAddress = 'mary.a@yahoo.com',
    @TelephoneNumber = '07763357673',
    @UserName = 'mary92',
    @PWD = 'sefoh$58',
    @DateJoined = '2023-04-01';

SELECT * 
	FROM Members;

--(d) Executing the UpdateMemberDetails stored procedure
EXEC UpdateMemberDetails 
	@MemberID = 6, 
	@FirstName = 'Mary',
    @LastName = 'Aisagbonhi',
    @ContactAddress = '1Georgetown Avenue, Worsley, M28 1MA',
    @DOB = '1992-01-02',
    @EmailAddress = 'mary.a@yahoo.com',
    @TelephoneNumber = '07763357673',
    @UserName = 'mary92',
    @PWD = 'sefoh$58',
    @DateJoined = '2023-04-01',
	@DateLeft = NULL;

SELECT *  
	FROM Members 
WHERE MemberID = 6;

--(e) Executing the LoanHistory view
SELECT * 
	FROM LoanHistory;

--(f) Demonstrating the UpdateCatalogueStatus trigger
--Step 1: Create and execute the UpdateCatalogueStatus trigger
--Step 2: Update return date of LoanID 4 (ItemID 8) in the Loans table with current date
UPDATE Loans
SET ReturnDate = CONVERT(date, GETDATE())
WHERE LoanID = 4;

--Step 3: Confirm status update of the item with ItemID 8 in the Catalogue table
SELECT l.LoanID, c.ItemID, l.LoanDate, l.ReturnDate, c.CurrentStatus
	FROM Loans AS l
	JOIN Catalogue AS c
	ON l.ItemID = c.ItemID
WHERE l.ItemID = 8;

--(g) Executing the SELECT statement
SELECT LoanDate, COUNT(*) AS Total_Loans
	FROM Loans
WHERE LoanDate = '2023-01-05'
GROUP BY LoanDate;


--Part 5: Additional database objects
--(a) Creating a trigger on the Catalogue table to automatically populate the LostRemoved table when an item is recorded as lost/removed
DROP TRIGGER IF EXISTS LostRemovedCatalogue;

GO

CREATE TRIGGER LostRemovedCatalogue
ON Catalogue
AFTER UPDATE, INSERT
AS
BEGIN
  IF UPDATE (CurrentStatus) AND EXISTS (SELECT * FROM inserted WHERE CurrentStatus = 'Lost/Removed')
  BEGIN
    INSERT INTO LostRemoved (ItemID, DateLostRemoved)
    SELECT ItemID, CONVERT(date, GETDATE())
    FROM inserted
    WHERE CurrentStatus = 'Lost/Removed'
  END
END;

--Demonstrating the LostRemovedCatalogue trigger
UPDATE Catalogue
SET CurrentStatus = 'Lost/Removed'
WHERE ItemID = 4;

SELECT *
	From LostRemoved;

--(b) Creating a view that tracks library membership
CREATE VIEW MembershipTrend AS
SELECT 
	FORMAT(DateJoined, 'yyyy') AS TimePeriod,
    SUM(CASE WHEN DateJoined IS NOT NULL THEN 1 ELSE 0 END) AS MembersJoined,
	SUM(CASE WHEN DateLeft IS NOT NULL THEN 1 ELSE 0 END) AS MembersLeft
FROM 
    Members
GROUP BY FORMAT(DateJoined, 'yyyy');

--Executing the MembershipTrend view
SELECT *
	FROM MembershipTrend;


--Database Security: Schemas creation and database objects transfer
--Creating MembershipMgt schema and transferring database objects into them
CREATE SCHEMA MembershipMgt;

GO

ALTER SCHEMA MembershipMgt TRANSFER dbo.Members
ALTER SCHEMA MembershipMgt TRANSFER dbo.InsertNewMember
ALTER SCHEMA MembershipMgt TRANSFER dbo.UpdateMemberDetails
ALTER SCHEMA MembershipMgt TRANSFER dbo.MembershipTrend

--Creating Inventory schema and transferring database objects into them
CREATE SCHEMA Inventory;

GO

ALTER SCHEMA Inventory TRANSFER dbo.Catalogue
ALTER SCHEMA Inventory TRANSFER dbo.LostRemoved
ALTER SCHEMA Inventory TRANSFER dbo.Loans
ALTER SCHEMA Inventory TRANSFER dbo.SearchCatalogueTitle
ALTER SCHEMA Inventory TRANSFER dbo.LoanHistory

--Creating Accounting schema and transferring database objects into them
CREATE SCHEMA Accounting;

GO

ALTER SCHEMA Accounting TRANSFER dbo.Fines
ALTER SCHEMA Accounting TRANSFER dbo.Repayment
ALTER SCHEMA Accounting TRANSFER dbo.NearDueLoans

--Demonstrating the schemas
SELECT m.MemberID, m.FirstName + ' ' + m.LastName AS FullName, l.OverDueDays
	FROM MembershipMgt.Members AS m
	INNER JOIN Inventory.Loans AS l
	ON m.MemberID = l.MemberID
WHERE l.OverDueDays > 0;


--Database backup and recovery: Confirming backup can be restored successfully
RESTORE VERIFYONLY
FROM DISK = 'C:\TheLibrary_Backup\TheLibrary.bak' 
WITH CHECKSUM;
