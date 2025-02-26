-- Request 1 : 
select
distinct market
from dim_customer
where customer = 'AtliQ exclusive' and region = 'APAC';

-- Request 2 

select
count(distinct case when fiscal_year = 2020 then product_code end) as unique_product_2020,
count(distinct case when fiscal_year = 2021 then product_code end) as unique_product_2021,
(count(distinct case when fiscal_year = 2021 then product_code end)-
count(distinct case when fiscal_year = 2020 then product_code end))*100.0
/  count(distinct case when fiscal_year = 2020 then product_code end) as pct_change
from fact_sales_monthly;


-- Request 3

select
segment,
count(distinct product_code) as product_count
from dim_product
group by segment
order by 2 desc;

-- Request 4

with cte as (
select
p.segment,
count(distinct( case when fiscal_year = 2020 then s.product_code end)) as product_count_2020,
count(distinct( case when fiscal_year = 2021 then s.product_code end)) as product_count_2021
from fact_sales_monthly s 
join dim_product p 
using(product_code)
group by 1 
)
select*,
product_count_2021 - product_count_2020 as difference 
from cte
order by difference desc;


-- Request 5

(select
p.product_code,
p.product,
m.manufacturing_cost
from dim_product p 
join fact_manufacturing_cost m 
using(product_code)
order by 3 desc
limit 1)
union 
(select
p.product_code,
p.product,
m.manufacturing_cost
from dim_product p 
join fact_manufacturing_cost m 
using(product_code)
order by 3 asc
limit 1);

-- Request 6 
with cte1 as 
(select
* from fact_pre_invoice_deductions
join dim_customer c 
using(customer_code)
where fiscal_year = 2021
and c.market = 'India')
select
customer_code,
customer,
concat(round(avg(pre_invoice_discount_pct)*100,2),'%') as avg_discount_pct
from cte1
group by 1,2
order by avg(pre_invoice_discount_pct)*100 desc
limit 5;

-- Request 7 

select
monthname(s.date) as Month,
s.fiscal_year as Year,
round(sum(sold_quantity*gross_price),2)as Gross_Sales
from fact_sales_monthly s 
join fact_gross_price g 
using(product_code)
join dim_customer c 
using(customer_code)
where customer = 'AtliQ Exclusive'
group by 1,2
order by 2 asc;

-- Request 8 

select
(case 
when month(date) in (9,10,11) then 'Q1'
when month(date) in (12,1,2) then 'Q2'
when month(date) in (3,4,5) then 'Q3'
when month(date) in (6,7,8) then 'Q4'
end) as Quarter, 
sum(sold_quantity) as total_sold_qty
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter 
order by total_sold_qty desc;

-- Request 9 

with cte1 as 
(select 
c.channel,
round(sum((s.sold_quantity*g.gross_price)/1000000),2) as gross_sales_mln
from dim_customer c 
join fact_sales_monthly s using(customer_code)
join fact_gross_price g using(product_code)
where s.fiscal_year=2021
group by 1)
select
*,
concat(round(gross_sales_mln*100/(select sum(gross_sales_mln) from cte1),2),'%') as pct_contribution
from cte1
order by pct_contribution desc;


-- Request 10 
with cte1 as (
select
p.division,
s.product_code,
concat(p.product," (", p.variant,")") as product, 
sum(s.sold_quantity) as total_sold_qty,
rank()over(partition by p.division order by sum(s.sold_quantity)desc) as rank_order
from dim_product p 
join fact_sales_monthly s using(product_code)
where fiscal_year = 2021
group by 1,2,3
)
select * from cte1 
where rank_order in (1,2,3)
order by division, rank_order asc;
