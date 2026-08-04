/*==============================================================
  E-Commerce Analytics Project
  Author: Parsa
==============================================================*/


/*==============================================================
1. CATEGORY PROFITABILITY ANALYSIS
Calculate revenue, profit, profit margin and cost drivers
for each product category.
==============================================================*/

DROP VIEW IF EXISTS vw_category_profitability;

CREATE VIEW vw_category_profitability AS

SELECT
    primary_category,

    SUM(items_ordered) AS total_items_ordered,

    ROUND(SUM(gross_revenue),0) AS total_revenue,

    ROUND(SUM(profit),0) AS total_profit,

    ROUND(SUM(profit) / SUM(gross_revenue),2) AS profit_margin,

    ROUND(SUM(product_cost) / SUM(gross_revenue) ,2) AS product_cost_pct,

    ROUND(SUM(shipping_cost) / SUM(gross_revenue) ,2) AS shipping_cost_pct,

    ROUND(SUM(discount_amount) / SUM(gross_revenue) ,2) AS discount_pct,

    ROUND(SUM(refund_amount) / SUM(gross_revenue),2) AS refund_pct,

    ROUND(
        SUM(CASE WHEN returned='Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2) AS return_rate

FROM orders
GROUP BY primary_category;



/*==============================================================
2. SALES CHANNEL PERFORMANCE
Compare profitability across sales channels.
==============================================================*/

DROP VIEW IF EXISTS vw_channel_profitability;

CREATE VIEW vw_channel_profitability AS

SELECT

    channel,

    SUM(items_ordered) AS total_items_ordered,

    ROUND(SUM(gross_revenue), 0) AS total_revenue,

    ROUND(SUM(profit), 0) AS total_profit,

    ROUND(SUM(profit)/SUM(gross_revenue), 2) AS profit_margin,

    ROUND(AVG(profit), 2) AS avg_profit_per_order,

    ROUND(SUM(platform_fee)/SUM(gross_revenue), 2) AS platform_fee_pct

FROM orders

GROUP BY channel;



/*==============================================================
3. CATEGORY RETURN ANALYSIS
Identify categories with the highest return rate and
greatest revenue loss.
==============================================================*/

DROP VIEW IF EXISTS vw_category_returns;

CREATE VIEW vw_category_returns AS

WITH return_analysis AS(

SELECT

    primary_category,

    ROUND(

        SUM(CASE WHEN returned='Yes' THEN 1 ELSE 0 END) / COUNT(*)

    ,2) AS return_rate,

    ROUND(

        SUM(
            CASE
                WHEN returned='Yes'
                THEN gross_revenue
                ELSE 0
            END)

    ,2) AS lost_revenue

FROM orders

GROUP BY primary_category

)

SELECT *

FROM(

SELECT

*,

RANK() OVER(ORDER BY return_rate DESC) AS return_rate_rank,

RANK() OVER(ORDER BY lost_revenue DESC) AS revenue_loss_rank

FROM return_analysis

)t;



/*==============================================================
4. CHANNEL RETURN ANALYSIS
Compare return performance across sales channels.
==============================================================*/

DROP VIEW IF EXISTS vw_channel_returns;

CREATE VIEW vw_channel_returns AS

WITH return_analysis AS(

SELECT

    channel,

    ROUND(

        SUM(CASE WHEN returned='Yes' THEN 1 ELSE 0 END) / COUNT(*)

    ,2) AS return_rate,

    ROUND(

        SUM(
            CASE
                WHEN returned='Yes'
                THEN gross_revenue
                ELSE 0
            END)

    ,2) AS lost_revenue

FROM orders

GROUP BY channel

)

SELECT *

FROM(

SELECT

*,

RANK() OVER(ORDER BY return_rate DESC) AS return_rate_rank,

RANK() OVER(ORDER BY lost_revenue DESC) AS revenue_loss_rank

FROM return_analysis

)t;



/*==============================================================
5. MARKETING PLATFORM PERFORMANCE
Compare ROAS, total spend and attributed revenue.
==============================================================*/

DROP VIEW IF EXISTS vw_marketing_platforms;

CREATE VIEW vw_marketing_platforms AS

WITH platform_analysis AS(

SELECT

    platform,

    ROUND(AVG(roas),2) AS avg_roas,

    ROUND(SUM(spend),2) AS total_spend,

    ROUND(SUM(revenue_attributed),2) AS total_revenue

FROM marketing_spend

GROUP BY platform

)

SELECT *

FROM(

SELECT

*,

RANK() OVER(ORDER BY avg_roas DESC) AS roas_rank,

RANK() OVER(ORDER BY total_spend DESC) AS spend_rank

FROM platform_analysis

)t;



/*==============================================================
6. PLATFORM CPA & CPC
Marketing acquisition efficiency.
==============================================================*/

DROP VIEW IF EXISTS vw_platform_efficiency;

CREATE VIEW vw_platform_efficiency AS

SELECT

    platform,

    ROUND(AVG(cpa),2) AS avg_cpa,

    ROUND(AVG(cpc),2) AS avg_cpc

FROM marketing_spend

GROUP BY platform;



/*==============================================================
7. CAMPAIGN ROI ANALYSIS
Rank campaigns from lowest ROI to highest ROI and
calculate cumulative budget that could be cut first.
==============================================================*/

DROP VIEW IF EXISTS vw_campaign_roi;

CREATE VIEW vw_campaign_roi AS

WITH campaign_analysis AS(

SELECT

    platform,

    month,

    ROUND(SUM(spend),2) AS spend,

    ROUND(AVG(roas),2) AS avg_roas,

    ROUND(
        (SUM(revenue_attributed)-SUM(spend))
        / SUM(spend)
    ,2) AS roi

FROM marketing_spend

GROUP BY platform,month

)

SELECT

*,

ROUND(

SUM(spend) OVER(

ORDER BY roi

)

,2) AS cumulative_cut_budget

FROM campaign_analysis;