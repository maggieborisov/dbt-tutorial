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
    WHERE organization_name IN ('Katapult', 'Katapult Ocean')
),

SelfComparison AS (
    SELECT 
        organization_name,
        monthly_timeline,
        MoM_Growth_Rate,
        LAG(MoM_Growth_Rate) OVER (PARTITION BY organization_name ORDER BY monthly_timeline) AS Previous_MoM_Growth_Rate
    FROM GrowthRate
)

SELECT
    s.organization_name,
    s.monthly_timeline,
    s.MoM_Growth_Rate,
    CASE
        WHEN s.MoM_Growth_Rate IS NULL THEN 'No Information'
        WHEN s.MoM_Growth_Rate > s.Previous_MoM_Growth_Rate THEN 'Higher Growth than Last Month'
        WHEN s.MoM_Growth_Rate < s.Previous_MoM_Growth_Rate THEN 'Lower Growth than Last Month'
        ELSE 'Same Growth as Last Month'
    END AS Growth_Comparison
FROM SelfComparison s
ORDER BY s.monthly_timeline DESC
