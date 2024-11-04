/* Checking the QUALITY of uploaded data tables*/
SELECT * FROM dbo.movie_box_office;

SELECT * FROM dbo.movie_dataset;

SELECT * FROM dbo.movie_industry;

SELECT * FROM dbo.streaming_titles;

/*-----------------------------------------------------------------------------------------------------------*/

/* 1. What are the highest grossing movies in 2023?*/

/*A. 2024*/
SELECT TOP 10 Movie, SUM(Gross) AS gross
FROM dbo.movie_box_office
WHERE YEAR(ReleaseDate) = 2024
GROUP BY Movie
ORDER BY SUM(Gross) DESC;

/*B. Of All Time*/
SELECT TOP 10 Movie, SUM(Gross) AS gross
FROM dbo.movie_box_office
GROUP BY Movie
ORDER BY SUM(Gross) DESC;

/*-----------------------------------------------------------------------------------------------------------*/

/*2. What are the movies with highest ROI?
 - Indie movies with highest returns.*/
SELECT TOP 20 Released,
			  name,
			  genre,
			  budget,
			  gross,
			  company
FROM dbo.movie_industry
WHERE gross IS NOT NULL
ORDER BY budget/gross;

/*-----------------------------------------------------------------------------------------------------------*/

/*3. Which genre movies are likely to collect more at the box office?
 - Visualization of Box office collections vs genres.*/
SELECT genre, SUM(gross) GrossCollection,
			  ROUND(AVG(gross), 2) AverageCollection
FROM dbo.movie_industry
GROUP BY genre
ORDER BY SUM(gross) DESC;

/*-----------------------------------------------------------------------------------------------------------*/

/*4. Is Cinema dying?
 - Visualization of Box Office collections vs time (years).*/
WITH MAY AS (
	SELECT *, MONTH(ReleaseDate) AS month, YEAR(ReleaseDate) AS year
	FROM dbo.movie_box_office)

SELECT year, month, SUM(Gross) AS total_gross
FROM MAY
GROUP BY year, month
ORDER BY year, month;

/*-----------------------------------------------------------------------------------------------------------*/

/*5. Is Streaming killing Cinema?
 - Vizualization and analysis of Netflix (streaming) releases vs box office collections.*/

/*A. Count of movies added to streaming over the years*/
WITH USAStreams AS (
	SELECT * FROM dbo.streaming_titles
	WHERE type = 'Movie'
	  AND country = 'United States')

SELECT YEAR(date_added) AS year,
	   MONTH(date_added) AS month,
	   COUNT(title) AS num_streaming_releases
FROM USAStreams
GROUP BY YEAR(date_added), MONTH(date_added)
ORDER BY YEAR(date_added), MONTH(date_added);

/*B. Box Office Collections over time*/
WITH MoviesAfterStreaming AS (
	SELECT * FROM dbo.movie_box_office
	WHERE YEAR(ReleaseDate) > (
		SELECT YEAR(MIN(date_added)) FROM dbo.streaming_titles))

SELECT YEAR(ReleaseDate) AS year,
	   MONTH(ReleaseDate) AS month,
	   SUM(Gross) AS total_boxoffice,
	   AVG(Gross) AS avg_boxoffice,
	   SUM(Tickets_Sold) AS total_tickets,
	   AVG(Tickets_Sold) AS avg_tickets
FROM dbo.movie_box_office
GROUP BY YEAR(ReleaseDate), MONTH(ReleaseDate)
ORDER BY YEAR(ReleaseDate), MONTH(ReleaseDate);

/*-----------------------------------------------------------------------------------------------------------*/

/*6. Which directors and actors were associated with the highest-grossing movies of 2024?
 - Matrix of highest grossing Directors and Actors.*/

/*A. Directors*/
SELECT TOP 10 director,
	   SUM(gross) AS total_gross,
	   AVG(gross) AS avg_gross
FROM dbo.movie_industry
GROUP BY director
ORDER BY SUM(gross) DESC;

/*A. Actors*/
SELECT TOP 10 star,
	   SUM(gross) AS total_gross,
	   AVG(gross) AS avg_gross
FROM dbo.movie_industry
GROUP BY star
ORDER BY SUM(gross) DESC;

/*-----------------------------------------------------------------------------------------------------------*/


/*7. How did movie releases during different seasons in 2024 affect box office performance?
 - Analysis of Box office trends over year, seasonally.*/
WITH BOCollections AS (
	SELECT ReleaseDate, Movie,
		   SUM(Gross) AS gross,
		   SUM(Tickets_Sold) AS Tickets_Sold
	FROM dbo.movie_box_office
	GROUP BY ReleaseDate, Movie)

SELECT YEAR(ReleaseDate) AS year,
	   MONTH(ReleaseDate) AS month,
	   SUM(gross) AS total_mon_gross,
	   SUM(Tickets_Sold) AS total_tickets_sold
FROM BOCollections
GROUP BY YEAR(ReleaseDate), MONTH(ReleaseDate);

/*-----------------------------------------------------------------------------------------------------------*/


/*8. What are the top 3 highest-grossing movies in each genre?*/
WITH TGM AS (
	SELECT ReleaseDate, Movie, Genre, SUM(Gross) total_gross
	FROM dbo.movie_box_office
	GROUP BY ReleaseDate, Movie, Genre),

GenreMovies AS (
	SELECT *, RANK() OVER(PARTITION BY Genre ORDER BY total_gross DESC) AS rnk
	FROM TGM
	WHERE Genre IS NOT NULL)

SELECT Genre, rnk, Movie, total_gross, ReleaseDate
FROM GenreMovies
WHERE rnk <= 3;

/*-----------------------------------------------------------------------------------------------------------*/

/*9. Total box office revenue and average rating for each director.*/
SELECT director, SUM(gross) AS total_revenue,
	   CAST(AVG(score) AS DECIMAL(10,2)) AS avg_rating
FROM dbo.movie_industry
GROUP BY director
HAVING COUNT(name) > 1
ORDER BY AVG(score) DESC;

/*-----------------------------------------------------------------------------------------------------------*/

/*10. What are the genres that have the highest increase in average rating over the past 5 years.*/
WITH avg_year_scores AS (
	SELECT genre, year, AVG(score) AS avg_score
	FROM dbo.movie_industry
	WHERE year > 2015
	GROUP BY genre, year),

score_increases AS (
	SELECT * , avg_score - LAG(avg_score)
			   OVER(PARTITION BY genre ORDER BY year) AS score_inc
	FROM avg_year_scores)

SELECT genre, MAX(score_inc) AS max1, SUM(score_inc) AS net_inc
FROM score_increases
WHERE score_inc IS NOT NULL
GROUP BY genre
ORDER BY MAX(score_inc) DESC;

/*-----------------------------------------------------------------------------------------------------------*/

/*Is there a correlation between critical ratings and box office earnings for 2024 films?
 - Comparision of IMDb scores and box office collections. IMDb ratings (or avg) of highest box office movies.*/

/*A. Audience Scores*/
SELECT mbo.Movie, mbo.ReleaseDate,
	   AVG(md.runtime) AS runtime,
	   AVG(md.vote_average) AS vote_avg,
	   AVG(md.vote_count) AS vote_count,
	   AVG(mbo.Gross) AS Gross
FROM dbo.movie_dataset md
JOIN dbo.movie_box_office mbo
ON md.title = mbo.Movie
AND md.release_date = mbo.ReleaseDate
GROUP BY mbo.Movie, mbo.ReleaseDate
ORDER BY vote_avg DESC;

/*B. IMDb Ratings*/
SELECT year, name,
	   score, gross
FROM dbo.movie_industry
ORDER BY gross DESC;

/*-----------------------------------------------------------------------------------------------------------*/

/*Are domestic box office results hits also do the same internationally?
 - Trends of Domestic Box office hits vs international box office hits.*/
SELECT dm.ReleaseDate, dm.Movie,
	   SUM(dm.Gross) AS domestic_gross,
	   AVG(int.gross) AS international_gross
FROM dbo.movie_box_office dm
JOIN dbo.movie_industry int
ON dm.ReleaseDate = int.Released
AND dm.Movie = int.name
GROUP BY dm.ReleaseDate, dm.Movie
ORDER BY domestic_gross DESC;

/*-----------------------------------------------------------------------------------------------------------*/

/*For each director, what is their "specialized genre"
 — most movies by average box office revenues within that genre.*/
SELECT director, genre,
	   COUNT(name) AS num_movies,
	   CAST(AVG(gross) AS bigint) AS revenue
FROM dbo.movie_industry
WHERE gross IS NOT NULL
GROUP BY director, genre
ORDER BY COUNT(name) DESC, AVG(gross) DESC;
