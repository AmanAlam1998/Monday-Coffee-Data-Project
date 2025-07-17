drop table if exists sales;

create table Sales(
sale_id int primary key,
sale_date date,
product_id int,
customer_id int,
total bigint,
rating int,
constraint fk_product foreign key (product_id) references products(product_id),
constraint fk_customer foreign key(customer_id) references customer(customer_id)
);

select * from sales
drop table if exists customer;
create table customer(
customer_id int primary key,
customer_name varchar(100),
city_id int,
constraint fk_city foreign key (city_id) references city(city_id)
);

select * from customer;

create table products(
Product_id int primary key,
product_name varchar(100),
price int
);

select * from products;

create table city(
city_id int primary key,
city_name varchar(100),
population bigint,
estimated_rent bigint,
city_rank int
);

select * from city
select * from sales
select * from products
select * from customer

--1. How may people in each city are estimated to consume coffee given that 25% of the population does
select * from city
select * from customer

select * from
(select city_name,population,population*0.25 as coffee_consuming_popilation,city_rank
from city) as drinking_table
order by coffee_consuming_popilation desc

--2. Total Revenue generated from coffee sales accross all the cities for last quarter of 2023

select * from sales

select sum(total) from sales
where sale_date between '2023-10-1' and '2023-12-31'

select sum(total) as total_revenue from sales
where
extract(year from sale_date)=2023
and
extract(quarter from sale_date)=4

select * from city
select * from customer

select ci.city_name,sum(total) as total_revenue from 
sales as s
join customer as cm
on cm.customer_id=s.customer_id
join
city as ci
on
ci.city_id=cm.city_id
where
extract(year from sale_date)=2023
and
extract(quarter from sale_date)=4
group by ci.city_name
order by total_revenue desc

--3. How many units of each coffee products have been sold
select count(distinct product_name) from products

select * from sales
select * from products;

select count(s.sale_id) as total_units,p.product_name
from products as p
join
sales as s
on 
s.product_id=p.product_id
group by p.product_name
order by total_units desc

--4. what is the average sales amount per customer in each city

select * from city
select * from sales
select * from customer
select *  from products

select
ci.city_name,
sum(s.total)as total_revenue,
count(distinct(cm.customer_id)) as total_customer,
round(sum(s.total)::numeric/count(distinct(cm.customer_id))::numeric,2) as avg_sales
from sales as s
join
customer as cm
on cm.customer_id=s.customer_id
join
city as ci
on
ci.city_id=cm.city_id
group by ci.city_name
order by avg_sales desc

--5. provide list of cities along with their populations and estimated coffee consumers

select * from city
select * from customer

select ci.city_name,ci.population,count(cm.customer_id) as total_customer
from city as ci
join
customer as cm
on cm.city_id=ci.city_id
group by ci.city_name,ci.population
order by total_customer desc

--5. provide the list of cities with their populations and estimated coffee customer

select ci.city_name, ci.population, ci.population*0.25 as estimated_customer,count(cm.customer_id) as total_customer_city
from city as ci
join
customer as cm
on cm.city_id=ci.city_id
group by ci.city_name, ci.population
order by total_customer_city desc

--6 what is the top 3 selling product in each city on the basis of sales volume

select * from sales
select * from products
select * from city
select * from customer

select * from 
(
select 
p.product_name,
count(s.product_id) as total_units_product,
dense_rank()over(partition by city_name order by count(s.product_id) desc) as rank,
ci.city_name
from products as p
join
sales as s
on s.product_id=p.product_id
join
customer as cm
on
s.customer_id=cm.customer_id
join
city as ci
on ci.city_id=cm.city_id
group by p.product_name,ci.city_name
--order by total_units_product desc
--limit 3

) where rank<=3

--7.  HOW many unique customers are their in each city who have purchased coffee products
select * from city
select * from customer
select * from products
select * from sales

select ci.city_name,count(distinct(cm.customer_id))as unique_customer_number
from customer as cm
join
city as ci
on
ci.city_id=cm.city_id
join
sales as s
on
s.customer_id=cm.customer_id
join
products as p
on
p.product_id=s.product_id
group by ci.city_name
order by unique_customer_number desc

--8. Find each city and their average sales per customer and average rent per customer

select * from city
select * from customer
select * from sales


with  city_rent_summary
as
(select
ci.city_name,
ci.estimated_rent,
count(distinct(cm.customer_id)) as sales_number,
sum(s.total) as total_sales,
round(sum(s.total)::numeric/count(distinct cm.customer_id)::numeric,2) as avg_sales,
round((ci.estimated_rent)::numeric/count(distinct cm.customer_id)::numeric,2)  as avg_rent_per_customer
from sales as s
join
customer as cm
on
cm.customer_id=s.customer_id
join
city as ci
on
ci.city_id=cm.city_id
group by ci.city_name,ci.estimated_rent
order by avg_rent_per_customer desc
)
select *,
rank() over( order by avg_sales desc )as avg_sales_rank,
rank() over( order by avg_rent_per_customer desc) as avg_rent_rank
from city_rent_summary

--9. calculate the percenatge growth or decline in sales  over different time periods (monthly)
select * from city
select * from customer
select * from sales


with percenatge_sales
as
(select ci.city_name, 
        extract(year from s.sale_date)as sale_year,
        extract(month from s.sale_date)as sale_month,
		sum(total) as total_sales
		from sales as s
		join
		customer as cm
		on 
		cm.customer_id=s.customer_id
		join
		city as ci
		on
		ci.city_id=cm.city_id
		group by sale_year,sale_month,ci.city_name
		order by 1,2,3 asc
		), growth_suumary as
		
        (select 
		city_name,
		sale_year,
		sale_month,
		total_sales as current_month_sales,
		lag(total_sales,1)over(partition by city_name order by sale_year,sale_month )as last_month_sales
		from percenatge_sales
		)
    select 
	city_name,
	sale_year,
	sale_month,
	current_month_sales,
	last_month_sales,
	round((current_month_sales-last_month_sales)::numeric/last_month_sales::numeric*100,2) as Percentage_growth_rate
	from growth_suumary
	where last_month_sales is not null
		
	
--10. Identify top 3 cities based on highest sales, return city name,total sale,total rent,total customers,estimated coffee consumer

select
ci.city_name,
sum(s.total) as total_sales,
ci.estimated_rent,
count(distinct cm.customer_id) as total_customer,
ci.population*.25 as estimated_consumer,
round(ci.estimated_rent/count(distinct cm.customer_id),2) as avg_rent_per_customer
from sales as s
join
customer as cm
on
cm.customer_id=s.customer_id
join
city as ci
on
ci.city_id=cm.city_id
group by ci.city_name,ci.estimated_rent,estimated_consumer
order by total_sales desc
limit 3



















