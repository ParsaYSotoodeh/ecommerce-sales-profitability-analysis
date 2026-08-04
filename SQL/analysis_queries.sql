/*==============================================================
  E-Commerce Analytics Project
  Author: Parsa Younessotoodeh
==============================================================*/


/*==============================================================
1. PRODUCT CATEGORY PROFITABILITY
Business Question:
Which product categories generate the highest profit,
and what cost factors reduce profitability?
==============================================================*/

SELECT
    primary_category,
    SUM(items_ordered) AS total_items_ordered,
    ROUND(SUM(gross_revenue),0) AS total_revenue,
    ROUND(SUM(profit),0) AS total_profit,
    ROUND(SUM(profit) / SUM(gross_revenue),2) AS profit_margin,
    ROUND(SUM(product_cost) / SUM(gross_revenue),2) AS product_cost_pct,
    ROUND(SUM(shipping_cost) / SUM(gross_revenue),2) AS shipping_cost_pct,
    ROUND(SUM(discount_amount) / SUM(gross_revenue),2) AS discount_pct,
    ROUND(SUM(refund_amount) / SUM(gross_revenue),2) AS refund_pct,
    ROUND(
        SUM(CASE WHEN returned='Yes' THEN 1 ELSE 0 END) / COUNT(*),
    2) AS return_rate
FROM orders
GROUP BY primary_category
ORDER BY profit_margin DESC;


/*==============================================================
2. SALES CHANNEL PERFORMANCE
Business Question:
Which sales channels generate the highest revenue,
profit, and average profit per order?
==============================================================*/

SELECT
    channel,
    SUM(items_ordered) AS total_items_ordered,
    ROUND(SUM(gross_revenue),0) AS total_revenue,
    ROUND(SUM(profit),0) AS total_profit,
    ROUND(SUM(profit)/SUM(gross_revenue),2) AS profit_margin,
    ROUND(AVG(profit),2) AS avg_profit_per_order,
    ROUND(SUM(platform_fee)/SUM(gross_revenue),2) AS platform_fee_pct
FROM orders
GROUP BY channel;


/*==============================================================
3. PRODUCT RETURN ANALYSIS
Business Question:
Which product categories have the highest return rate
and revenue lost due to returns?
==============================================================*/

WITH return_analysis AS
(
SELECT
    primary_category,

    ROUND(
        SUM(CASE WHEN returned='Yes' THEN 1 ELSE 0 END)/COUNT(*)
    ,2) AS return_rate,

    ROUND(
        SUM(
            CASE
                WHEN returned='Yes'
                THEN gross_revenue
                ELSE 0
            END
        )
    ,2) AS lost_revenue

FROM orders
GROUP BY primary_category
)

SELECT
    *,
    RANK() OVER(ORDER BY return_rate DESC) AS return_rate_rank,
    RANK() OVER(ORDER BY lost_revenue DESC) AS revenue_loss_rank
FROM return_analysis;


/*==============================================================
4. SALES CHANNEL RETURN ANALYSIS
Business Question:
Which sales channels experience the highest return rates
and the greatest revenue loss?
==============================================================*/

WITH return_analysis AS
(
SELECT

    channel,

    ROUND(
        SUM(CASE WHEN returned='Yes' THEN 1 ELSE 0 END)/COUNT(*)
    ,2) AS return_rate,

    ROUND(
        SUM(
            CASE
                WHEN returned='Yes'
                THEN gross_revenue
                ELSE 0
            END
        )
    ,2) AS lost_revenue

FROM orders
GROUP BY channel
)

SELECT
    *,
    RANK() OVER(ORDER BY return_rate DESC) AS return_rate_rank,
    RANK() OVER(ORDER BY lost_revenue DESC) AS revenue_loss_rank
FROM return_analysis;


/*==============================================================
5. MARKETING PLATFORM PERFORMANCE
Business Question:
Compare advertising platforms using ROAS,
marketing spend, and attributed revenue.
==============================================================*/

WITH platform_analysis AS
(
SELECT

    platform,

    ROUND(AVG(roas),2) AS avg_roas,

    ROUND(SUM(spend),2) AS total_spend,

    ROUND(SUM(revenue_attributed),2) AS total_revenue

FROM marketing_spend

GROUP BY platform
)

SELECT
    *,
    RANK() OVER(ORDER BY avg_roas DESC) AS roas_rank,
    RANK() OVER(ORDER BY total_spend DESC) AS spend_rank
FROM platform_analysis;


/*==============================================================
6. CUSTOMER ACQUISITION EFFICIENCY
Business Question:
Compare customer acquisition efficiency using
Cost per Acquisition (CPA) and Cost per Click (CPC).
==============================================================*/

SELECT

    platform,

    ROUND(AVG(cpa),2) AS avg_cpa,

    ROUND(AVG(cpc),2) AS avg_cpc

FROM marketing_spend

GROUP BY platform;


/*==============================================================
7. CAMPAIGN ROI ANALYSIS
Business Question:
Rank campaigns by ROI and calculate the cumulative
marketing budget that could be reduced by removing
the lowest-performing campaigns first.
==============================================================*/

WITH campaign_analysis AS
(
SELECT

    platform,

    month,

    ROUND(SUM(spend),2) AS spend,

    ROUND(AVG(roas),2) AS avg_roas,

    ROUND(
        (SUM(revenue_attributed)-SUM(spend))/SUM(spend)
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