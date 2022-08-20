{{config(materialized='table')}}

WITH table_monthly_unit_sold_smoothskin AS(
    SELECT 
        month,
        monthly_unit_sold_smoothskin
    FROM report.kpis_daily_unit_sold_monthly
    ORDER BY month DESC
),
unit_sold_smoothskin_with_woo_id AS (
    SELECT 
        date_created,
        woo_id
    FROM bi.fct_orders_item
    WHERE 
        status_order LIKE 'completed'
        AND product_name LIKE 'SmoothSkin%'
),
total_unit_replacement AS (
    SELECT 
    date_shipped,
    woo_id
    FROM bi.fct_shipment
    WHERE is_warranty_replacement = TRUE
    ORDER BY 
        date_shipped DESC
),
table_replacement_lifetime AS (
    SELECT 
        DATE_TRUNC('month',unit_sold_smoothskin_with_woo_id.date_created) AS month,
        COUNT (distinct (unit_sold_smoothskin_with_woo_id.woo_id)) AS total_unit_replacement_lifetime
    FROM unit_sold_smoothskin_with_woo_id
    INNER JOIN total_unit_replacement
    ON unit_sold_smoothskin_with_woo_id.woo_id = total_unit_replacement.woo_id
    GROUP BY 
        month
    ORDER BY 
        month DESC
)        
SELECT 
    table_monthly_unit_sold_smoothskin.month,
    table_monthly_unit_sold_smoothskin.monthly_unit_sold_smoothskin,
    table_replacement_lifetime.total_unit_replacement_lifetime,
    1.00*NULLIF(table_replacement_lifetime.total_unit_replacement_lifetime,0)/table_monthly_unit_sold_smoothskin.monthly_unit_sold_smoothskin AS pct_replacement
FROM table_monthly_unit_sold_smoothskin
LEFT JOIN table_replacement_lifetime
ON table_monthly_unit_sold_smoothskin.month = TO_CHAR (table_replacement_lifetime.month,'YYYY-MM-DD')
      
    
