WITH GrowthRate AS (
    SELECT
        organization_name,
        monthly_timeline,
        CASE 
            WHEN LAG(followers_end_of_month) OVER (PARTITION BY organization_name ORDER BY monthly_timeline) IS NULL THEN NULL 
            ELSE ( (followers_end_of_month - LAG(followers_end_of_month) OVER (PARTITION BY organization_name ORDER BY monthly_timeline))
            / NULLIF(LAG(followers_end_of_month) OVER (PARTITION BY organization_name ORDER BY monthly_timeline), 0) ) * 100 
        END AS MoM_Growth_Rate
    FROM `katapult-vc.linkedin_company_pages.Monthly_aggregate_data`
),

MedianGrowth AS (
    SELECT
        PERCENTILE_CONT(MoM_Growth_Rate, 0.5) OVER() AS Median_Growth
    FROM GrowthRate
    WHERE MoM_Growth_Rate IS NOT NULL
    LIMIT 1  #To ensure only one median value is returned
)

SELECT
    g.organization_name,
    g.monthly_timeline,
    g.MoM_Growth_Rate,
    CASE
        WHEN g.MoM_Growth_Rate IS NULL THEN 'No Information'
        WHEN g.MoM_Growth_Rate > m.Median_Growth THEN 'Above Median Growth'
        ELSE 'Below Median Growth'
    END AS Growth_Category
FROM GrowthRate g, MedianGrowth m
ORDER BY g.monthly_timeline DESC