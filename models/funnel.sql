WITH leads AS (
    SELECT client_id,
           date_trunc('day', criado_em)::date AS date,
           COUNT(*)::bigint AS leads
    FROM fato_lead
    GROUP BY client_id, date
),
ads AS (
    SELECT client_id,
           date,
           SUM(impressions)::bigint AS impressions,
           SUM(clicks)::bigint      AS clicks,
           SUM(spend)::numeric      AS spend
    FROM (
        SELECT client_id, date, impressions, clicks, spend
        FROM fato_meta_ads
        UNION ALL
        SELECT client_id, date, impressions, clicks, cost AS spend
        FROM fato_google_ads
    ) x
    GROUP BY client_id, date
),
opps AS (
    SELECT client_id,
           data_prevista::date AS date,
           COUNT(*)::bigint AS opportunities,
           COALESCE(SUM(valor * (COALESCE(prob,0)/100.0)),0)::numeric AS expected_revenue
    FROM fato_oportunidade
    GROUP BY client_id, date
)
SELECT
    COALESCE(a.client_id, l.client_id, o.client_id) AS client_id,
    COALESCE(a.date,      l.date,      o.date)      AS date,
    COALESCE(a.impressions, 0)          AS impressions,
    COALESCE(a.clicks,      0)          AS clicks,
    COALESCE(a.spend,       0)          AS spend,
    COALESCE(l.leads,       0)          AS leads,
    COALESCE(o.opportunities,0)         AS opportunities,
    COALESCE(o.expected_revenue,0)      AS expected_revenue
FROM ads a
FULL OUTER JOIN leads l USING (client_id, date)
FULL OUTER JOIN opps  o USING (client_id, date);
