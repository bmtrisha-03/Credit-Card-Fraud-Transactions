create database credit_card;
use credit_card;

# Data Cleansing

select * from credit_card_transaction;

-- 03/01/2024

-- 2014-10-29
desc credit_card_transaction;

set sql_safe_updates=0;

UPDATE credit_card_transaction 
SET card_Date = CASE 
        WHEN card_Date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
        THEN DATE_FORMAT(STR_TO_DATE(card_date, '%m/%d/%Y'),'%Y-%m-%d')
    END;
    
-- 03/03/2022
-- ALTER TABLE  credit_card_transaction
-- CHANGE DATE card_date varchar(50);
ALTER TABLE credit_card_transaction
MODIFY card_date date;



-- ALTER TABLE credit_card_transaction
-- change  dates card_date   date;

alter table credit_card_transaction
modify city varchar(50),
modify card_type varchar(20),
modify exp_type varchar(20),
modify gender varchar(10);





desc credit_card_transaction;

/*
delimiter //
CREATE PROCEDURE gender_base(gender_spend VARCHAR(2))
BEGIN 
with cte as(
SELECT *, (case when  amount > 200000 then 'extr_exp' 
                   when  amount > 100000 then 'high_exp' 
                   when  amount > 70000 then 'nor_exp'
                   when  amount > 40000 then 'min_exp' else 'less_exp' end) as total_amount,
		DENSE_RANK()over(PARTITION BY  (case  when  amount > 200000 then 'extr_exp' 
                                              when  amount > 100000 then 'high_exp' 
                                              when  amount > 70000 then 'nor_exp'
                                              when  amount > 40000 then 'min_exp' else 'less_exp' end) 
									ORDER BY amount desc  )as rn
FROM credit_card_transaction
where card_type='gold' 
ORDER BY amount desc
)
SELECT * FROM cte
WHERE gender=gender_spend
;
end //

call gender_base('f');

SELECT  card_type , sum(amount)FROM credit_card_transaction
where amount<(SELECT avg(amount) FROM credit_card_transaction)
GROUP BY card_type
;

delimiter //
create procedure updated_exp_type()
begin
update  credit_card_transaction
set exp_type='bill'
where exp_type='bills';
end //

# call updated_exp_type();

SELECT 
    gender,
    city,
    MIN(CASE WHEN exp_type = 'bill' THEN amount END) AS bill_spend,
    MIN(CASE WHEN exp_type = 'food' THEN amount END) AS food_spend,
    MIN(CASE WHEN exp_type = 'Entertainment' THEN amount END) AS Entertainment_spend,
    MIN(CASE WHEN exp_type = 'grocery' THEN amount END) AS grocery_spend,
    MIN(CASE WHEN exp_type = 'fuel' THEN amount END) AS fuel_spend,
    MIN(CASE WHEN exp_type = 'travel' THEN amount END) AS travel_spend
FROM
    credit_card_transaction
WHERE
    amount > 0
GROUP BY 1 , 2;

SELECT 
    gender, exp_type, MIN(amount)
FROM
    credit_card_transaction
WHERE
    amount > 0
GROUP BY 1 , exp_type;

create view monthly_groeth as (

SELECT  year(card_date) as month,
(sum(amount)-lag(sum(amount))over( ORDER BY year(card_date)))
              /lag(sum(amount))over(ORDER BY year(card_date))*100  as total FROM credit_card_transaction
GROUP BY 1)
;

SELECT 
    *
FROM
    monthly_groeth;

with cte as( 
SELECT extract(year from card_Date) as year, sum(amount),card_type,
LAG(sum(amount))OVER(PARTITION BY card_type ORDER BY extract(year from card_Date)) as prv,
100*coalesce((sum(amount)-LAG(avg(amount))OVER(PARTITION BY card_type ORDER BY extract(year from card_Date)))
/ LAG(sum(amount))OVER(PARTITION BY card_type ORDER BY extract(year from card_Date)),0) as growth
 FROM credit_card_transaction
GROUP BY 1,card_type)
SELECT year,card_type,growth
FROM cte
where growth>0 and growth<70
;
SELECT 
    SUM(amount)
FROM
    credit_card_transaction
WHERE
    city LIKE 'bengaluru%';

SELECT 
    AVG(amount) AS total
FROM
    credit_card_transaction
;

(SELECT 
    *
FROM
    credit_card_transaction);
SELECT 
    *
FROM
    hello;
DROP view hello;

ALTER TABLE credit_card_transaction 
drop COLUMN hello;

ALTER TABLE credit_card_transaction 
add COLUMN hello VARCHAR(11);

SELECT DISTINCT
    city
FROM
    credit_card_transaction
WHERE
    city LIKE '__s%' OR city LIKE '__l%';

SELECT 
    SUBSTRING_INDEX(city, ',', 1) AS city,
    SUBSTRING_INDEX(city, ',', - 1) AS country
FROM
    credit_card_transaction;
    
    
SELECT 
    card_type, COUNT(1) AS total_transaction
FROM
    credit_card_transaction
GROUP BY 1;

SELECT 
    card_type,
    SUM(CASE
        WHEN card_type IS NULL THEN 1
        ELSE 0
    END) AS sum_of_nuull
FROM
    credit_card_transaction
GROUP BY 1;
*/
-- ---------------------------// Prject Start // -----------------------------------------------------------------------------------

 select count(*) from credit_card_transaction;

-- 1.write a query to print top 5 cities highest spent and percenatage of contribution of total credit card spends
WITH total as 
(SELECT 
    city, SUM(amount) AS city_total_spent
FROM
    credit_card_transaction
GROUP BY city
ORDER BY city_total_spent DESC
)
,total_city as 
(SELECT 
    SUM(amount) AS spent_total -- total amount
FROM
    credit_card_transaction
)
SELECT 
    t.city,
    t.city_total_spent,
    ROUND((t.city_total_spent / tc.spent_total), 4) * 100 AS total_perc_city
FROM
    total t
        JOIN
    total_city tc -- ON 1 = 1
LIMIT 5;

 -- or 
SELECT 
    cc.city,
    SUM(amount) AS total_spent,
    ROUND(SUM(cc.amount) / (SELECT SUM(ct.amount) FROM credit_card_transaction ct) * 100, 2) AS city_total
FROM
    credit_card_transaction cc
GROUP BY 1
ORDER BY city_total DESC , cc.city ASC
LIMIT 5;
 

select distinct card_type from  credit_card_transaction;
/* 2.write a query to print highest spend month and amount spend in that month for each card type.*/

WITH date_wise AS
(SELECT 
    card_type,
    MONTHNAME(card_date) AS month,  -- , date_format(card_date, '%M'),
    YEAR(card_date) AS year,  -- date_format(card_date, '%Y')
    SUM(amount) AS total_spend
	, dense_rank()OVER(PARTITION BY  card_type ORDER BY SUM(amount) DESC) AS highest_rank
FROM
    credit_card_transaction  
GROUP BY 1 , month , year -- ,  date_format(card_date, '%M')
) 
SELECT 
    card_type, month, year, total_spend
FROM
    date_wise
WHERE
    highest_rank = 1;

/* 3.write a query to print transaction details(all column from table) for each card type when its reaches a
cumulative of 100000 total spends.*/

WITH cumulative AS (
SELECT *,
      SUM(amount) OVER(PARTITION BY card_type ORDER BY card_date,amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative
FROM credit_card_transaction
) , cte2 as( select *,
dense_rank()over(partition by card_type order by cumulative) as rn_cmt
 from cumulative where cumulative>=100000
 )
 select 
  city, card_date, card_type cumulative
 from cte2 where rn_cmt=1
 ;
, 
cte2 AS 
(SELECT *,
       DENSE_RANK()OVER(PARTITION BY  card_type ORDER BY  cumulative ) AS cum_rank
FROM cte 
WHERE cumulative>=100000
)
SELECT 
    city, card_type, cumulative
FROM
    cte2
WHERE
    cum_rank = 1;
  
/* 4.write a query to find the city which had lowest percenate spend for gold card type.*/

WITH  gold_spend_city  AS
(SELECT 
    city, SUM(amount)AS gold_spend FROM credit_card_transaction
WHERE card_type = 'gold'
GROUP BY city
ORDER BY gold_spend
)
,total_spend AS 
(SELECT 
    city, SUM(amount) AS spend_city
FROM
    credit_card_transaction
GROUP BY city)
SELECT 
    gc.city,
    gc.gold_spend,
    ROUND((gold_spend / spend_city) * 100, 2) AS perc
FROM
    gold_spend_city gc
        INNER JOIN
    total_spend ts ON gc.city = ts.city
GROUP BY 1
ORDER BY perc
LIMIT 3;



SELECT 
    city,sum(amount) city_total,
    sum(case when card_type  = 'gold'  then amount else 0 end) as gold_spend,
    sum(case when card_type  = 'gold'  then amount else 0 end)/sum(amount)*100 as perc
    -- sum(case when card_type  = 'gold'  then amount else 0 end)/ sum(amount)
     -- sum(case when card_type  = 'silver'  then amount else 0 end) as sliver_spend,
     -- sum(case when card_type  = 'platinum'  then amount else 0 end) as platinum_spend,
     -- sum(case when card_type  = 'signature'  then amount else 0 end) as signature
    -- ROUND(SUM(CASE WHEN card_type = 'gold' THEN amount ELSE 0 END) * 100 / SUM(amount), 2) AS city_total
FROM
    credit_card_transaction
GROUP BY city
 HAVING perc > 0
ORDER BY perc -- limit 3
;

SELECT 
    ct.city,
    SUM(ct.amount),
    SUM(ct.amount) / SUM(cc.amount) * 100 AS total_trans
FROM
    credit_card_transaction ct
        INNER JOIN
    credit_card_transaction cc ON ct.city = cc.city
WHERE
    ct.card_type = 'gold'
GROUP BY 1
ORDER BY total_trans
;
with cte as(
SELECT 
    city,
    card_type,
    SUM(amount) AS total,
    SUM(CASE WHEN card_type = 'gold' THEN amount ELSE 0 END) AS city_total
FROM
    credit_card_transaction
GROUP BY city , card_type , amount
)
SELECT 
    city, SUM(city_total) / SUM(total) AS perc_spent_gold
FROM
    cte
GROUP BY 1
HAVING perc_spent_gold > 0
ORDER BY perc_spent_gold
;
       
--  and  for platinum
with platinum_spend_city as 
(SELECT 
    city, SUM(amount) AS spend
FROM
    credit_card_transaction
WHERE
    card_type = 'platinum'
GROUP BY city)
,total_spend as 
(SELECT 
    city, SUM(amount) AS spend_city
FROM
    credit_card_transaction
GROUP BY city)
SELECT 
    pc.city,
    pc.spend,
    ROUND((spend / spend_city) * 100, 2) AS perc
FROM
    platinum_spend_city pc
        JOIN
    total_spend ts ON pc.city = ts.city
ORDER BY perc
LIMIT 1;



-- 5.write a query to top3: city, highest_exp, lowest_exp, (ex: delhi,bills, fuel)


WITH spend_amount AS (
SELECT 
    city AS city, exp_type AS expense, SUM(amount) AS spend
FROM
    credit_card_transaction
GROUP BY city , exp_type
) 
,high_low AS 
(SELECT 
    city , -- , expense,
    MAX(spend) AS highest_exp, MIN(spend) AS lowest_exp
FROM
    spend_amount
GROUP BY city -- ,expense
) 
SELECT 
    sa.city,
    MAX(CASE WHEN spend = highest_exp THEN expense END) AS highest_expp,
    MIN(CASE WHEN spend = lowest_exp THEN expense END) AS lowest_expp
FROM
    spend_amount sa
        JOIN
    high_low hl ON sa.city = hl.city
GROUP BY sa.city
ORDER BY sa.city
;


-- 6.write a query to percentage contribution by female each exp_type,
SELECT 
    exp_type,SUM(CASE WHEN gender = 'f' THEN amount else 0 END) as female,SUM(amount) total_spend,
    ROUND(SUM(CASE WHEN gender = 'f' THEN amount else 0 END) * 100.0 / SUM(amount),2) AS percentage_contribution
FROM
    credit_card_transaction
GROUP BY 1;
# or



WITH female_spents AS 
(SELECT exp_type, SUM(amount) AS female_spent
FROM credit_card_transaction
WHERE
    gender = 'f'
GROUP BY exp_type)
,total_spends AS 
(SELECT 
    exp_type, SUM(amount) AS total_spent
FROM
    credit_card_transaction
GROUP BY exp_type)
SELECT 
    fs.exp_type,
    (fs.female_spent) / total_spent*100 AS female_percantage_spent
FROM
    female_spents fs
        JOIN
    total_spends ts ON fs.exp_type = ts.exp_type
GROUP BY fs.exp_type , fs.female_spent , ts.total_spent;
 
-- 7.write a query to percentage contribution by male each exp_type,
SELECT 
    exp_type,
    ROUND(SUM(CASE
                WHEN gender = 'm' THEN amount
                ELSE 0
            END) * 100.0 / SUM(amount),
            2) AS percentage_contribution
FROM
    credit_card_transaction
GROUP BY 1;
  
  # or
  
WITH male_spents as 
(SELECT 
    exp_type, SUM(amount) AS male_spent
FROM
    credit_card_transaction
WHERE
    gender = 'm'
GROUP BY exp_type)
,total_spends AS 
(SELECT 
    exp_type, SUM(amount) AS total_spent
FROM
    credit_card_transaction
GROUP BY exp_type)
SELECT 
    ms.exp_type,
    ROUND((ms.male_spent / ts.total_spent), 2) * 100 AS male_percantage_spent
FROM
    male_spents ms
        JOIN
    total_spends ts ON ms.exp_type = ts.exp_type
GROUP BY ms.exp_type , ms.male_spent , ts.total_spent;


-- 8.which card and expense type combination saw highest month over month growth in jan-2014
with expense as 
(SELECT 
    card_type,
    exp_type,
    MONTHNAME(card_date) AS month,
    YEAR(card_date) AS year,
    SUM(amount) AS highest_spent
FROM
    credit_card_transaction
    -- where  YEAR(card_date) = 2014 AND MONTHNAME(card_date) = 'january'
GROUP BY card_type , exp_type , month , year
)
, month_year as
(select *,
       lag(highest_spent,1)over(partition by card_type,exp_type  order by  year, month desc) as prv_month_year
from expense
	)
SELECT 
    card_type,
    exp_type,
    month,
    year,
    100 * (highest_spent - prv_month_year) / prv_month_year AS growth
FROM
    month_year
WHERE
    year = 2014 AND month = 'january'
GROUP BY card_type , exp_type , month , year
ORDER BY growth DESC
LIMIT 1;


-- 9. During weekend which city has highest total spends to no_of_transaction ratio
SELECT 
    city,
    SUM(amount) AS total_spents,
    COUNT(1) AS no_of_tranasaction,
    SUM(amount) / COUNT(1) AS ratio
FROM
    credit_card_transaction
WHERE
    DAYNAME(card_date) IN ('sunday' , 'saturday')
GROUP BY 1
ORDER BY ratio DESC
LIMIT 1;


-- 10.which city tooks least number of days to reaches its 500th transaction after first transaction is that city
WITH cte as(     
SELECT *,
   ROW_NUMBER()OVER(PARTITION BY city ORDER BY card_date) as num_trans,
   MIN(card_date)OVER(PARTITION BY city) AS first_trans
FROM credit_card_transaction
)
SELECT 
    city,
    card_date,
    card_type,
    DATEDIFF(card_date, first_trans) AS minimum_500_transaction
FROM
    cte
WHERE
    num_trans = 500
ORDER BY minimum_500_transaction 
LIMIT 1
;

-- 11. write a query to fetch monthly transaction percantege for every year transaction done in bangalore region.
WITH cte AS  (
	SELECT 
    EXTRACT(MONTH FROM card_date) AS months,
    EXTRACT(YEAR FROM card_date) AS year,
    COUNT(1) AS no_of_trans
FROM
    credit_card_transaction
WHERE
    city LIKE 'bengaluru%'
GROUP BY 1 , 2
ORDER BY year , months
) 
,cte2 AS (
   SELECT 
    year, SUM(no_of_trans) AS total
FROM
    cte
GROUP BY year
)
SELECT 
    cte.months,
    cte2.year,
    ROUND((no_of_trans / total) * 100, 2) AS perc_trans
FROM
    cte2
        JOIN
    cte ON cte2.year = cte.year
;

# Write a query to fetch previous year sales
with cte as(
SELECT 
    MAX(card_date) AS max_date
FROM
    credit_card_transaction
)
SELECT 
    card_type, SUM(amount) as total_spend
FROM
    credit_card_transaction
        INNER JOIN
    cte ON 1=1
WHERE
    card_date >= DATE_SUB(max_date, INTERVAL 7  day)
GROUP BY 1;


SELECT 
    card_type, SUM(amount)
FROM
    credit_card_transaction
WHERE
    card_date IN ('2015-05-25' , '2015-05-26', '2015-05-24')
GROUP BY 1;

SELECT 
    MAX(card_date)
FROM
    credit_card_transaction;
    
# Write a query to fetch 7 day rolling average
SELECT 
    city,
    card_date,
	amount, 
	AVG(AMOUNT)OVER(PARTITION BY city ORDER BY card_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW ) AS rolling_avg
FROM credit_card_transaction
WHERE city like 'beng%'
GROUP BY  1,2,3;

year bill , fuel , food, travel
2014 1000   22333  345   4445
with cte as(
SELECT city, COUNT(card_date) as total FROM credit_card_transaction 
GROUP BY 1
ORDER BY COUNT(card_date) DESC
) , 
cte3  as (
SELECT count(1) as cnt
SELECT * FROM credit_card_transaction
)
SELECT city, total/cnt FROM cte inner join cte3
on 1=1
