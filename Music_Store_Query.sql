select * from album

-- Q1. who is the senior most employee based on job ?

select * from employee
order by levels desc
limit 1

-- Q2. which countries have the most invocies ?

select count(*) as c , billing_country
from invoice
group by billing_country
order by c desc

-- Q3. what are top 3 values of total invoice

select * from invoice
order by total desc
limit 3 

-- Q4. which city has the best customer ? we would like 
-- to throw a promotional music festical in the city we made 
-- the most money. write a query that retrun ane city we made the most money .
-- write a query thet return one city thet has the higest sun of invoice totals.
-- return both the city name and sum of all invoices totals

select sum(total) as invoice_total , billing_city 
from invoice
group by billing_city
order by invoice_total desc

-- Q5. Who is the best customer ? the customer who has spend the most money
-- will be declared tthe best customer . write a query that return the person who has spent the most 
-- money.

select customer.customer_id , customer.first_name , customer.last_name ,sum(invoice.total) as total
from customer 
join invoice on customer.customer_id = invoice.customer_id 
group by customer.customer_id
order by total desc
limit 1


-- Q1. write query to return the email , first name , last name , &
-- genre of all rock music listiner , retrun your list ordered alphanetically
-- by email starting with A 




select distinct email , first_name , last_name 
from customer
join invoice on customer.customer_id=invoice.customer_id
join invoice_line on invoice.invoice_id=invoice_line.invoice_id
where track_id in(
	select track_id from track 
	join genre on track.genre_id = genre.genre_id
	where genre.name like 'Rock'
)
order by email ;


-- Q2: let invite the artists who have written the music.write a query that return the artist name track count of the 
-- top 10 rock bands


select artist.artist_id , artist.name , count(artist.artist_id) as number_of_songs
from track 
join album on album.album_id = track.album_id 
join artist on artist.artist_id=album.artist_id
join genre on genre.genre_id=track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit  10 ;

-- Q3. return all the track names that have songs length llonger than th average song lenght. return 
-- the name and milliseconds for each track . order by the soong lenght with the longest songs listed first


select name ,milliseconds
from track 
where milliseconds > (
select avg(milliseconds)
from track)
order by milliseconds

-- Q1.Find how much amount spent by each customer on artists ?
-- write a queary to return customer name , artist nname and total spent

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

With best_seller_artist As (
select artist.artist_id as artist_id , artist.name as artist_name ,sum(invoice_line.unit_price*invoice_line)
from invoice_line 
join track on track.track_id =invoice_line.track_id 
join album on album.album_id =track.album_id
join artist on artist.artist_id = album.artist_id
group by 1
order by 3 desc 
limit 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


/* Method 2: : Using Recursive */

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1


/* Method 2: Using Recursive */

WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;


 


















