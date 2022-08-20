{{config(materialized='table')}}

WITH table_total_unit_replacement AS (
    SELECT
        DATE_TRUNC('month', date_shipped) AS month,
        COUNT(DISTINCT(CASE WHEN bi.fct_shipment.is_warranty_replacement = TRUE THEN bi.fct_shipment.woo_id END)) AS monthly_unit_replacement
    FROM bi.fct_shipment
    WHERE is_warranty_replacement = TRUE   
    GROUP BY 
        month
    ORDER BY month DESC
),

table_total_quantity_request AS (
    SELECT
        DATE_TRUNC('month', date_created) AS month,
        COUNT(DISTINCT(CASE WHEN public.cc_ticket.status IN ('closed','processing','rejected','logged') THEN public.cc_ticket.id END)) AS total_quantity_request
    FROM public.cc_ticket 
    GROUP BY 
        month
    ORDER BY month DESC
),
table_monthly_unit_sold_smoothskin AS(
    SELECT 
        month,
        monthly_unit_sold_smoothskin
    FROM report.kpis_daily_unit_sold_monthly
    ORDER BY month DESC
),
table_monthly_request_replacement AS (
    SELECT 
        DATE(table_total_quantity_request.month) AS month,
        table_total_quantity_request.total_quantity_request,
        table_total_unit_replacement.monthly_unit_replacement
    FROM table_total_quantity_request
    LEFT JOIN table_total_unit_replacement ON table_total_unit_replacement.month = table_total_quantity_request.month
)

SELECT 
    table_monthly_unit_sold_smoothskin.month,
    table_monthly_unit_sold_smoothskin.monthly_unit_sold_smoothskin,
    table_monthly_request_replacement.total_quantity_request,
    table_monthly_request_replacement.monthly_unit_replacement,
    1.00*NULLIF(table_monthly_request_replacement.total_quantity_request,0)/table_monthly_unit_sold_smoothskin.monthly_unit_sold_smoothskin AS request_vs_unit_sold_ratio,
    1.00*NULLIF(table_monthly_request_replacement.monthly_unit_replacement,0)/NULLIF(table_monthly_request_replacement.total_quantity_request,0) AS replacement_vs_request_ratio,
    1.00*NULLIF(table_monthly_request_replacement.monthly_unit_replacement,0)/table_monthly_unit_sold_smoothskin.monthly_unit_sold_smoothskin AS replacement_vs_unit_sold_ratio
FROM table_monthly_request_replacement
RIGHT JOIN table_monthly_unit_sold_smoothskin
ON TO_CHAR(table_monthly_request_replacement.month,'YYYY-MM-DD') = table_monthly_unit_sold_smoothskin.month

    
    
    
    
    

