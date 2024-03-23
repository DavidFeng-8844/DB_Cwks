
-- @author Yujie Feng

/*This is an sql file to put your queries for SQL coursework.
You can write your comment in sqlite with -- or /* * /
To read the sql and execute it in the sqlite, simply
type .read sqlcwk.sql on the terminal after sqlite3 musicstore.db.
*/

/* =====================================================
   WARNNIG: DO NOT REMOVE THE DROP VIEW
   Dropping existing views if exists
   =====================================================
*/
DROP VIEW IF EXISTS vNoCustomerEmployee; 
DROP VIEW IF EXISTS v10MostSoldMusicGenres; 
DROP VIEW IF EXISTS vTopAlbumEachGenre; 
DROP VIEW IF EXISTS v20TopSellingArtists; 
DROP VIEW IF EXISTS vTopCustomerEachGenre; 

/*
============================================================================
Task 1: Complete the query for vNoCustomerEmployee.
DO NOT REMOVE THE STATEMENT "CREATE VIEW vNoCustomerEmployee AS"
============================================================================
*/
CREATE VIEW vNoCustomerEmployee AS
SELECT e.EmployeeId, e.FirstName, e.LastName, e.Title
FROM Employees e
WHERE e.EmployeeId NOT IN (
    SELECT DISTINCT c.SupportRepId
    FROM Customers c
    WHERE c.SupportRepId IS NOT NULL
);


/*
============================================================================
Task 2: Complete the query for v10MostSoldMusicGenres
DO NOT REMOVE THE STATEMENT "CREATE VIEW v10MostSoldMusicGenres AS"
============================================================================
*/
/*
A SQLite query to create a view named v10MostSoldMusicGenres for the 10 best-selling
genres with the following columns:
1. Genre – the name for the 10 most-sold music genres
2. Sales – the total quantity of tracks sold for that genre.
The view is ordered by Sales in descending order
*/
CREATE VIEW v10MostSoldMusicGenres AS
SELECT g.Name AS Genre, SUM(ii.Quantity) AS Sales
FROM Genres g
JOIN Tracks t ON g.GenreId = t.GenreId
JOIN invoice_items ii ON t.TrackId = ii.TrackId
GROUP BY g.Name
ORDER BY Sales DESC
LIMIT 10;



/*
============================================================================
Task 3: Complete the query for vTopAlbumEachGenre
DO NOT REMOVE THE STATEMENT "CREATE VIEW vTopAlbumEachGenre AS"
============================================================================
*/
/*
Write a SQLite query to create a view named vTopAlbumEachGenre for listing the top-selling albums in
each genre with the following columns:
- Genre – the name of the genre
- Album – the name of the album with the most tracks sold for that genre
- Artist – the name of the artist for the album with the most tracks sold for that genre
- Sales – the quantity of tracks sold on that album for that genre.
 */
DROP VIEW IF EXISTS vTopAlbumEachGenre;
CREATE VIEW vTopAlbumEachGenre AS
WITH RankedAlbums AS (
    SELECT
        g.Name AS Genre,
        a.Title AS Album,
        ar.Name AS Artist,
        SUM(ii.Quantity) AS Sales,
        ROW_NUMBER() OVER (PARTITION BY g.Name ORDER BY SUM(ii.Quantity) DESC) AS rank
    FROM
        Genres g
        JOIN Tracks t ON g.GenreId = t.GenreId
        JOIN Albums a ON t.AlbumId = a.AlbumId
        JOIN Artists ar ON a.ArtistId = ar.ArtistId
        JOIN invoice_items ii ON t.TrackId = ii.TrackId
    GROUP BY
        g.Name, a.Title, ar.Name
)
SELECT
    Genre,
    Album,
    Artist,
    Sales
FROM
    RankedAlbums
WHERE
    rank = 1;

-- Better and easier way for vTopAlbumEachGenre
DROP VIEW IF EXISTS vTopAlbumEachGenre;
CREATE VIEW vTopAlbumEachGenre AS
SELECT
    g.Name AS Genre,
    a.Title AS Album,
    ar.Name AS Artist,
    SUM(ii.Quantity) AS Sales
FROM
    Genres g
    JOIN Tracks t ON g.GenreId = t.GenreId
    JOIN Albums a ON t.AlbumId = a.AlbumId
    JOIN Artists ar ON a.ArtistId = ar.ArtistId
    JOIN invoice_items ii ON t.TrackId = ii.TrackId
GROUP BY
    g.Name, a.Title, ar.Name
HAVING
    SUM(ii.Quantity) = (
        SELECT
            SUM(ii.Quantity)
        FROM
            Genres g
            JOIN Tracks t ON g.GenreId = t.GenreId
            JOIN Albums a ON t.AlbumId = a.AlbumId
            JOIN Artists ar ON a.ArtistId = ar.ArtistId
            JOIN invoice_items ii ON t.TrackId = ii.TrackId
        WHERE
            g.Name = Genre
        GROUP BY
            g.Name, a.Title, ar.Name
        ORDER BY
            SUM(ii.Quantity) DESC
        LIMIT 1
    );


/*
============================================================================
Task 4: Complete the query for v20TopSellingArtists
DO NOT REMOVE THE STATEMENT "CREATE VIEW v20TopSellingArtists AS"
============================================================================
*/
/*Write a SQLite query to create a view called v20TopSellingArtists for the 20 top-selling
artists with the following columns:
- Artist – the name of the top 20 artists with the most tracks sold
- TotalAlbum – the number of albums with tracks sold for that artist
- TrackSold – total quantity of tracks sold for that artist.
The view is ordered in descending order of TrackSold*/
DROP VIEW IF EXISTS v20TopSellingArtists;
CREATE VIEW v20TopSellingArtists AS
WITH ArtistSales AS (
    SELECT
        ar.Name AS Artist,
        COUNT(DISTINCT a.AlbumId) AS TotalAlbum,
        SUM(ii.Quantity) AS TrackSold,
        ROW_NUMBER() OVER (ORDER BY SUM(ii.Quantity) DESC) AS rank
    FROM
        Artists ar
        JOIN Albums a ON ar.ArtistId = a.ArtistId
        JOIN Tracks t ON a.AlbumId = t.AlbumId
        JOIN invoice_items ii ON t.TrackId = ii.TrackId
    GROUP BY
        ar.Name
)
SELECT
    Artist,
    TotalAlbum,
    TrackSold
FROM
    ArtistSales
WHERE
    rank <= 20
ORDER BY
    TrackSold DESC;

-- Better and easier way for v20TopSellingArtists
DROP VIEW IF EXISTS v20TopSellingArtists;
CREATE VIEW v20TopSellingArtists AS
SELECT
    ar.Name AS Artist,
    COUNT(DISTINCT a.AlbumId) AS TotalAlbum,
    SUM(ii.Quantity) AS TrackSold
FROM
    Artists ar
    JOIN Albums a ON ar.ArtistId = a.ArtistId
    JOIN Tracks t ON a.AlbumId = t.AlbumId
    JOIN invoice_items ii ON t.TrackId = ii.TrackId
GROUP BY
    ar.Name
ORDER BY
    TrackSold DESC
LIMIT 20;



/*
============================================================================
Task 5: Complete the query for vTopCustomerEachGenre
DO NOT REMOVE THE STATEMENT "CREATE VIEW vTopCustomerEachGenre AS" 
============================================================================
*/
/*
 Write a SQLite query to create a view named vTopCustomerEachGenre for the customer that
spent the most for each genre of music with the columns:
- Genre – the name of the genre
- TopSpender – the full name (in the format firstname lastName) of the customer that
spent the most on each genre of music
- TotalSpending – the total spending of the customer on that genre of music, based on
quantity x unitprice, rounded to two decimal points.
 */
DROP VIEW IF EXISTS vTopCustomerEachGenre;

CREATE VIEW vTopCustomerEachGenre AS
WITH RankedCustomers AS (
    SELECT
        g.Name AS Genre,
        c.FirstName || ' ' || c.LastName AS TopSpender,
        ROUND(SUM(ii.Quantity * ii.UnitPrice), 2) AS TotalSpending,
        ROW_NUMBER() OVER (PARTITION BY g.Name ORDER BY SUM(ii.Quantity * ii.UnitPrice) DESC) AS rank
    FROM
        Genres g
        JOIN Tracks t ON g.GenreId = t.GenreId
        JOIN invoice_items ii ON t.TrackId = ii.TrackId
        JOIN Invoices i ON ii.InvoiceId = i.InvoiceId
        JOIN Customers c ON i.CustomerId = c.CustomerId
    GROUP BY
        g.Name, c.FirstName, c.LastName
)
SELECT
    Genre,
    TopSpender,
    TotalSpending
FROM
    RankedCustomers
WHERE
    rank = 1;

-- Better and easier way for vTopCustomerEachGenre
DROP VIEW IF EXISTS vTopCustomerEachGenre;
CREATE VIEW vTopCustomerEachGenre AS
SELECT
    g.Name AS Genre,
    c.FirstName || ' ' || c.LastName AS TopSpender,
    ROUND(SUM(ii.Quantity * ii.UnitPrice), 2) AS TotalSpending
FROM
    Genres g
    JOIN Tracks t ON g.GenreId = t.GenreId
    JOIN invoice_items ii ON t.TrackId = ii.TrackId
    JOIN Invoices i ON ii.InvoiceId = i.InvoiceId
    JOIN Customers c ON i.CustomerId = c.CustomerId
GROUP BY
    g.Name, c.FirstName, c.LastName
HAVING
    ROUND(SUM(ii.Quantity * ii.UnitPrice), 2) = (
        SELECT
            ROUND(SUM(ii.Quantity * ii.UnitPrice), 2)
        FROM
            Genres g
            JOIN Tracks t ON g.GenreId = t.GenreId
            JOIN invoice_items ii ON t.TrackId = ii.TrackId
            JOIN Invoices i ON ii.InvoiceId = i.InvoiceId
            JOIN Customers c ON i.CustomerId = c.CustomerId
        WHERE
            g.Name = Genre
        GROUP BY
            g.Name, c.FirstName, c.LastName
        ORDER BY
            SUM(ii.Quantity * ii.UnitPrice) DESC
        LIMIT 1
    );


