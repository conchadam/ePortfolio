
/***BE SURE TO DROP ALL TABLES IN WORK THAT BEGIN WITH "CASE_"***/

/*Set Time Zone*/
set time_zone='-4:00';
select now();

/***PRELIMINARY ANALYSIS***/

/*Create a VIEW in WORK called CASE_SCOOT_NAMES that is a subset of the prod table
which only contains scooters.
Result should have 7 records.*/


CREATE OR REPLACE VIEW work.case_scoot_names AS
  SELECT *
  FROM ba710case.ba710_prod
  WHERE product_type = 'scooter';

select * from work.case_scoot_names;

/*The following code uses a join to combine the view above with the sales information.
  Can the expected performance be improved using an index?
  A) Calculate the EXPLAIN COST.
  B) Create the appropriate indexes.
  C) Calculate the new EXPLAIN COST.
  D) What is your conclusion?:
*/

SELECT a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, DATE(b.sales_transaction_date) AS sale_date,
    b.sales_amount, b.channel, b.dealership_id
FROM work.case_scoot_names a 
INNER JOIN ba710case.ba710_sales b
    ON a.product_id=b.product_id;
    
 /* A) Calculate the EXPLAIN COST.*/
EXPLAIN  SELECT a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, DATE(b.sales_transaction_date) AS sale_date,
    b.sales_amount, b.channel, b.dealership_id
FROM work.case_scoot_names a 
INNER JOIN ba710case.ba710_sales b
    ON a.product_id=b.product_id;
    
EXPLAIN format=json SELECT a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, DATE(b.sales_transaction_date) AS sale_date,
    b.sales_amount, b.channel, b.dealership_id
FROM work.case_scoot_names a 
INNER JOIN ba710case.ba710_sales b
    ON a.product_id=b.product_id;

/*What is the cost:4,592.01 */
/***
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "4592.01"
    },
    "nested_loop": [
      {
        "table": {
          "table_name": "ba710_prod",
          "access_type": "ALL",
          "rows_examined_per_scan": 12,
          "rows_produced_per_join": 1,
          "filtered": "10.00",
          "cost_info": {
            "read_cost": "1.33",
            "eval_cost": "0.12",
            "prefix_cost": "1.45",
            "data_read_per_join": "67"
          },
          "used_columns": [
            "product_id",
            "model",
            "product_type"
          ],
          "attached_condition": "(`ba710case`.`ba710_prod`.`product_type` = 'scooter')"
        }
      },
      {
        "table": {
          "table_name": "b",
          "access_type": "ALL",
          "rows_examined_per_scan": 37783,
          "rows_produced_per_join": 4533,
          "filtered": "10.00",
          "using_join_buffer": "hash join",
          "cost_info": {
            "read_cost": "56.60",
            "eval_cost": "453.40",
            "prefix_cost": "4592.01",
            "data_read_per_join": "212K"
          },
          "used_columns": [
            "customer_id",
            "product_id",
            "sales_transaction_date",
            "sales_amount",
            "channel",
            "dealership_id"
          ],
          "attached_condition": "(`ba710case`.`b`.`product_id` = `ba710case`.`ba710_prod`.`product_id`)"
        }
      }
    ]
  }
}
***/

/*B) Create the appropriate indexes.*/
/*drop index idx_prodid on ba710case.ba710_prod;*/


CREATE INDEX idx_prodid ON ba710case.ba710_sales (product_id);


/*C) Calculate the new EXPLAIN COST.*/

EXPLAIN SELECT a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, DATE(b.sales_transaction_date) AS sale_date,
    b.sales_amount, b.channel, b.dealership_id
FROM work.case_scoot_names a 
INNER JOIN ba710case.ba710_sales b
    ON a.product_id=b.product_id;
    
EXPLAIN format=json SELECT a.model, a.product_type, a.product_id,
    b.customer_id, b.sales_transaction_date, DATE(b.sales_transaction_date) AS sale_date,
    b.sales_amount, b.channel, b.dealership_id
FROM work.case_scoot_names a 
INNER JOIN ba710case.ba710_sales b
    ON a.product_id=b.product_id;

/*What is the cost: 616.13*/
/***    
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "616.13"
    },
    "nested_loop": [
      {
        "table": {
          "table_name": "ba710_prod",
          "access_type": "ALL",
          "rows_examined_per_scan": 12,
          "rows_produced_per_join": 1,
          "filtered": "10.00",
          "cost_info": {
            "read_cost": "1.33",
            "eval_cost": "0.12",
            "prefix_cost": "1.45",
            "data_read_per_join": "67"
          },
          "used_columns": [
            "product_id",
            "model",
            "product_type"
          ],
          "attached_condition": "((`ba710case`.`ba710_prod`.`product_type` = 'scooter') and (`ba710case`.`ba710_prod`.`product_id` is not null))"
        }
      },
      {
        "table": {
          "table_name": "b",
          "access_type": "ref",
          "possible_keys": [
            "idx_prodid"
          ],
          "key": "idx_prodid",
          "used_key_parts": [
            "product_id"
          ],
          "key_length": "9",
          "ref": [
            "ba710case.ba710_prod.product_id"
          ],
          "rows_examined_per_scan": 3434,
          "rows_produced_per_join": 4121,
          "filtered": "100.00",
          "cost_info": {
            "read_cost": "202.50",
            "eval_cost": "412.18",
            "prefix_cost": "616.13",
            "data_read_per_join": "193K"
          },
          "used_columns": [
            "customer_id",
            "product_id",
            "sales_transaction_date",
            "sales_amount",
            "channel",
            "dealership_id"
          ]
        }
      }
    ]
  }
}
***/
/*D) What is your conclusion? Based on the results above, the creation of index on product_id resulted in a lower query cost from 4592.01 to 616.13.  This means that the creation of the index has likely
improved the performance of the query.*/

/***PART 1: INVESTIGATE BAT SALES TRENDS***/  
    
/*The following creates a table of daily sales with four columns and will be used in the following step.*/

CREATE TABLE work.case_daily_sales AS
	select p.model, p.product_id, date(s.sales_transaction_date) as sale_date, 
		   round(sum(s.sales_amount),2) as daily_sales
	from ba710case.ba710_sales as s 
    inner join ba710case.ba710_prod as p
		on s.product_id=p.product_id
    group by date(s.sales_transaction_date),p.product_id,p.model;

select * from work.case_daily_sales;

/*Create a view (5 columns)of cumulative sales figures for just the Bat scooter from
the daily sales table you created.
Using the table created above, add a column that contains the cumulative
sales amount (one row per date).
Hint: Window Functions, Over*/
    
CREATE VIEW work.cumulative_bat_sales AS 
	SELECT model, product_id, sale_date, daily_sales,
    SUM(daily_sales) OVER(PARTITION BY product_id ORDER BY sale_date) AS cumulative_sales
    FROM work.case_daily_sales
    WHERE model = 'Bat';

select * from work.cumulative_bat_sales;

/*Using the view above, create a VIEW (6 columns) that computes the cumulative sales 
for the previous 7 days for just the Bat scooter. 
(i.e., running total of sales for 7 rows inclusive of the current row.)
This is calculated as the 7 day lag of cumulative sum of sales
(i.e., each record should contain the sum of sales for the current date plus
the sales for the preceeding 6 records).
*/
 
CREATE VIEW work.cumulative_bat_sales_7_days AS
	SELECT model, product_id, sale_date, daily_sales, cumulative_sales,
    SUM(daily_sales) OVER (rows between 6 preceding and current row) AS cumulative_7days_sales
    FROM work.cumulative_bat_sales;
    
select * from work.cumulative_bat_sales_7_days;
    
/*Using the view you just created, create a new view (7 columns) that calculates
the weekly sales growth as a percentage change of cumulative sales
compared to the cumulative sales from the previous week (seven days ago).

See the Word document for an example of the expected output for the Blade scooter.*/
/* first option*/ 
CREATE VIEW work.weekly_sales_growth AS
    SELECT model, product_id, sale_date, daily_sales, cumulative_sales, cumulative_7days_sales,
        ((cumulative_sales - lag(cumulative_sales, 7) OVER (PARTITION BY model, product_id ORDER BY sale_date)) 
				/ lag(cumulative_sales, 7) OVER (PARTITION BY model, product_id ORDER BY sale_date)) * 100
        AS weekly_sales_growth_percentage
    FROM work.cumulative_bat_sales_7_days;
        
select * from work.weekly_sales_growth limit 10;
select * from work.weekly_sales_growth;

/*Paste a screenshot of at least the first 10 records of the table
  and answer the questions in the Word document*/
  
  

/*********************************************************************************************
Is the launch timing (October) a potential cause for the drop?
Replicate the Bat sales cumulative analysis for the Bat Limited Edition.
Answer: Based on the results, there might be some factor for the launch timing (October) for Bat.  
It took less days before cumulative sales growth dropped below 10% for Bat compared to Bat Limited when 
it was launched in February.
*/

/*Paste a screenshot of at least the first 10 records of the table
  and answer the questions in the Word document*/
  
/* cumulative bat sales for Bat Limited Edition*/
CREATE VIEW work.cumulative_bat_sales_BLE AS 
	SELECT model, product_id, sale_date, daily_sales,
    SUM(daily_sales) OVER(PARTITION BY product_id ORDER BY sale_date) AS cumulative_sales
    FROM work.case_daily_sales
    WHERE model = 'Bat Limited Edition';

select * from work.cumulative_bat_sales_BLE;  

/*cumulative bat sales for 7 days*/
CREATE VIEW work.cumulative_bat_sales_7_days_BLE AS
	SELECT model, product_id, sale_date, daily_sales, cumulative_sales,
    SUM(daily_sales) OVER (rows between 6 preceding and current row) AS cumulative_7days_sales
    FROM work.cumulative_bat_sales_BLE;
    
select * from work.cumulative_bat_sales_7_days_BLE;

/*weekly sales growth*/
CREATE VIEW work.weekly_sales_growth_BLE AS
    SELECT model, product_id, sale_date, daily_sales, cumulative_sales, cumulative_7days_sales,
        ((cumulative_sales - lag(cumulative_sales, 7) OVER (PARTITION BY model, product_id ORDER BY sale_date)) 
				/ lag(cumulative_sales, 7) OVER (PARTITION BY model, product_id ORDER BY sale_date)) * 100
        AS weekly_sales_growth_percentage
    FROM work.cumulative_bat_sales_7_days_BLE;
        
select * from work.weekly_sales_growth_BLE limit 10;
select * from work.weekly_sales_growth_BLE;  

/*********************************************************************************************
However, the Bat Limited was at a higher price point.
Let's take a look at the 2013 Lemon model, since it's a similar price point.  
Is the launch timing (October) a potential cause for the drop?
Replicate the Bat sales cumulative analysis for the 2013 Lemon model.*/

/*Paste a screenshot of at least the first 10 records of the table
  and answer the questions in the Word document*/

/* cumulative Lemon sales*/
CREATE VIEW work.cumulative_bat_sales_Lemon AS 
	SELECT model, product_id, sale_date, daily_sales,
    SUM(daily_sales) OVER(PARTITION BY product_id ORDER BY sale_date) AS cumulative_sales
    FROM work.case_daily_sales
    WHERE model = 'Lemon';

select * from work.cumulative_bat_sales_Lemon;  

/*cumulative Lemon sales for 7 days*/
CREATE VIEW work.cumulative_bat_sales_7_days_Lemon AS
	SELECT model, product_id, sale_date, daily_sales, cumulative_sales,
    SUM(daily_sales) OVER (rows between 6 preceding and current row) AS cumulative_7days_sales
    FROM work.cumulative_bat_sales_Lemon;
    
select * from work.cumulative_bat_sales_7_days_Lemon;

/*weekly sales growth*/
CREATE VIEW work.weekly_sales_growth_Lemon AS
    SELECT model, product_id, sale_date, daily_sales, cumulative_sales, cumulative_7days_sales,
        ((cumulative_sales - lag(cumulative_sales, 7) OVER (PARTITION BY model, product_id ORDER BY sale_date)) 
				/ lag(cumulative_sales, 7) OVER (PARTITION BY model, product_id ORDER BY sale_date)) * 100
        AS weekly_sales_growth_percentage
    FROM work.cumulative_bat_sales_7_days_Lemon;
        
select * from work.weekly_sales_growth_Lemon limit 10;
select * from work.weekly_sales_growth_Lemon; 

/*END*/
