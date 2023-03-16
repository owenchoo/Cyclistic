
-- DATA CLEANING PHASE

-- Aligning the datatype across the 3 tables

ALTER TABLE cyclistic..jan_tripdata

ALTER COLUMN start_station_id nvarchar(255);

-- Combining all of the data into one table

SELECT * INTO Q1_tripdata_

FROM cyclistic..jan_tripdata UNION ALL 
SELECT * FROM cyclistic..feb_tripdata UNION ALL
SELECT * FROM cyclistic..march_tripdata;

-- Checking the newly combined table

SELECT *

FROM cyclistic..Q1_tripdata_

-- the day_of_week datatype shouldn't be float, might cause some problems when analysing the data later on

ALTER TABLE cyclistic..Q1_tripdata_

ALTER COLUMN day_of_week nvarchar(255);

-- Changing the values to the name of days for easier readability

UPDATE cyclistic..Q1_tripdata_
SET day_of_week = CASE day_of_week 
                WHEN '1' THEN 'Sunday'
                WHEN '2' THEN 'Monday'
                WHEN '3' THEN 'Tuesday'
                WHEN '4' THEN 'Wednesday'
                WHEN '5' THEN 'Thursday'
                WHEN '6' THEN 'Friday'
                WHEN '7' THEN 'Saturday' 
				ELSE NULL
				END

WHERE day_of_week IN ('1', '2', '3','4','5','6','7')


-- DATA ANALYSIS PHASE

-- Looking at total count between anual members and casual riders 

SELECT	COUNT (ride_id) AS totaltrips,
		COUNT (CASE WHEN member_casual = 'member' THEN 1 END) AS totalmemberstrips,
		COUNT (CASE WHEN member_casual = 'casual' THEN 1 END) AS totalcasualstrips,
		AVG(CASE WHEN member_casual = 'member' THEN 1.0 ELSE 0 END)*100 AS memberspercentage,
		AVG(CASE WHEN member_casual = 'casual' THEN 1.0 ELSE 0 END)*100 AS casualspercentage

FROM cyclistic..Q1_tripdata_


-- Calculating the average ride duration

SELECT	AVG(ride_duration_minutes) AS avg_duration_minutes,
		(SELECT AVG(ride_duration_minutes) FROM cyclistic..Q1_tripdata_ WHERE member_casual = 'member') AS avg_duration_member,
		(SELECT AVG(ride_duration_minutes) FROM cyclistic..Q1_tripdata_ WHERE member_casual = 'casual') AS avg_duration_casual

FROM cyclistic..Q1_tripdata_


-- The average duration for casual riders seems a bit too high, let's check the maximum ride duration

SELECT	member_casual,
		MAX(ride_duration_minutes) AS max_ride_duration

FROM cyclistic..Q1_tripdata_
        
GROUP BY member_casual

ORDER BY max_ride_duration DESC

-- let's look at the ride duration in descending order to get a sense of the data
-- ride duration desc for casuals

SELECT	member_casual,
		ride_duration_minutes

FROM cyclistic..Q1_tripdata_

WHERE member_casual = 'casual'

ORDER BY ride_duration_minutes DESC 

-- ride duration desc for members

SELECT	member_casual,
		ride_duration_minutes

FROM cyclistic..Q1_tripdata_

WHERE member_casual = 'member'

ORDER BY ride_duration_minutes DESC 


-- Since there is skewed distribution in the data, let's looks at the median instead.

SELECT DISTINCT	b.median_ride_duration,
				member_casual

FROM (SELECT	ride_id,
				member_casual,
				ride_duration_minutes,
				PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ride_duration_minutes) OVER(PARTITION BY member_casual) AS  median_ride_duration
		
		FROM cyclistic..Q1_tripdata_) b 

ORDER BY b.median_ride_duration


-- looking for the busiest day of the week between members and casuals

WITH mode_cte AS 

	(SELECT DISTINCT	member_casual, 
						day_of_week, 
						ROW_NUMBER() OVER (PARTITION BY member_casual ORDER BY COUNT(day_of_week) DESC) rn  

	FROM cyclistic..Q1_tripdata_

    GROUP BY member_casual, day_of_week)

SELECT	member_casual,
		day_of_week AS mode_day_of_week

FROM mode_cte

WHERE rn = 1

ORDER BY member_casual DESC


-- Let's look at the median ride duration of each days for anual members

WITH median_anual AS 

	 (SELECT	ride_id, member_casual, day_of_week, ride_duration_minutes,
				PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ride_duration_minutes) OVER(PARTITION BY day_of_week) AS  median_ride_duration
        
		FROM cyclistic..Q1_tripdata_
                
        WHERE member_casual = 'member')

SELECT DISTINCT	median_ride_duration,
				member_casual,
				day_of_week

FROM median_anual

ORDER BY median_ride_duration DESC


-- Let's look at the median ride duration of each days for casual riders

WITH median_casual AS 

	 (SELECT	ride_id, member_casual, day_of_week, ride_duration_minutes,
				PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ride_duration_minutes) OVER(PARTITION BY day_of_week) AS  median_ride_duration
        
		FROM cyclistic..Q1_tripdata_
                
        WHERE member_casual = 'casual')

SELECT DISTINCT	median_ride_duration,
				member_casual,
				day_of_week

FROM median_casual

ORDER BY median_ride_duration DESC

 -- Let's explore at total trips of each day of week

SELECT	day_of_week,
		COUNT(DISTINCT ride_id) AS totaltrips,
		SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS membertrips,
		SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS casualtrips

FROM cyclistic..Q1_tripdata_

GROUP BY day_of_week

ORDER BY totaltrips DESC


 -- Start stations: member vs casual
 -- Looking at start station counts

SELECT DISTINCT	start_station_name,
				SUM(CASE WHEN ride_id = ride_id AND start_station_name = start_station_name THEN 1 ELSE 0 END) AS total,
				SUM(CASE WHEN member_casual = 'member' AND start_station_name = start_station_name THEN 1 ELSE 0 END) AS member,
				SUM(CASE WHEN member_casual = 'casual' AND start_station_name = start_station_name THEN 1 ELSE 0 END) AS casual

FROM cyclistic..Q1_tripdata_

GROUP BY start_station_name

ORDER BY total DESC