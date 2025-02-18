WITH btc_supply AS (
    SELECT SUM(50/POWER(2, ROUND(height/210000))) AS supply
    FROM bitcoin.blocks
    )
    
, btc_amounts AS (
    SELECT SUM(f.amount) AS tvl
    , (SUM(f.amount) FILTER (WHERE block_time > NOW() - interval '7' day)) AS past_week_flows
    , (SUM(f.amount) FILTER (WHERE block_time >= date('2024-01-10'))) AS flows_usd_since_approval
    , (SUM(f.amount) FILTER (WHERE block_time > NOW() - interval '7' day)) AS past_week_flows_usd
    , 100*SUM(f.amount)/(SELECT supply FROM btc_supply) AS percentage_of_btc
    , SUM(f.amount) FILTER (WHERE block_time > NOW() - interval '28' day) AS past_month_flows
    , SUM(f.amount) FILTER (WHERE block_time > NOW() - interval '14' day) AS past_twoweeks_flows
    , (SELECT supply FROM btc_supply) AS btc_supply
    FROM (
        SELECT i.block_time
        , a.issuer
        , ticker AS etf_ticker
        , 'deposit' AS flow_type
        , CASE WHEN inverse_values THEN -i.value ELSE i.value END AS amount
        FROM bitcoin.outputs i
        INNER JOIN dune.hildobby.dataset_bitcoin_etf_addresses -- Known ETF address list
            a ON a.address=i.address
            AND a.track_inflow
        INNER JOIN dune.hildobby.dataset_bitcoin_etf_metadata eat ON a.issuer=eat.issuer
        WHERE i.value > 0
        AND i.block_time > date('2019-07-24')
        --AND i.block_time <= (SELECT CAST(bitcoin AS timestamp) AS time_limit FROM dune.hildobby.dataset_etf_update_thresholds)
        
        UNION ALL
        
        SELECT i.block_time
        , a.issuer
        , ticker AS etf_ticker
        , 'withdrawal' AS flow_type
        , CASE WHEN inverse_values THEN i.value ELSE -i.value END AS amount
        FROM bitcoin.inputs i
        INNER JOIN dune.hildobby.dataset_bitcoin_etf_addresses -- Known ETF address list
            a ON a.address=i.address
            AND a.track_outflow
        INNER JOIN dune.hildobby.dataset_bitcoin_etf_metadata eat ON a.issuer=eat.issuer
        WHERE i.value > 0
        AND i.block_time > date('2019-07-24')
        AND i.block_time <= (SELECT CAST(bitcoin AS timestamp) AS time_limit FROM dune.hildobby.dataset_etf_update_thresholds)
        
        UNION ALL
        
        SELECT CAST("date" AS timestamp) AS block_time
        , 'Fidelity' AS issuer
        , 'FBTC' AS etf_ticker
        , 'withdrawal' AS flow_type
        , -amount AS amount
        FROM dune.hildobby.dataset_bitcoin_etf_fidelity_outflows
        
        UNION ALL
        
        SELECT t.block_time
        , et.issuer
        , et.ticker AS etf_ticker
        , NULL AS flow_type
        , 0 AS amount
        FROM (
            unnest(sequence(date('2019-07-24'), date(NOW()), interval '1' day)) AS s(block_time)
            ) t
        INNER JOIN dune.hildobby.dataset_bitcoin_etf_metadata et ON 1=1
        ) f
    LEFT JOIN prices.usd pu ON pu.blockchain IS NULL
        AND pu.symbol = 'BTC'
        AND pu.minute=date_trunc('minute', f.block_time)
        AND pu.minute >= date('2024-01-10')
        AND pu.minute <= (SELECT CAST(bitcoin AS timestamp) AS time_limit FROM dune.hildobby.dataset_etf_update_thresholds)
    )

SELECT tvl/1e3 AS tvl_in_thousands
, (tvl*pu.price)/1e9 AS usd_tvl_in_billions
, ba.past_week_flows AS past_week_flows
, flows_usd_since_approval/1e3 AS flows_usd_since_approval_in_thousands
, past_week_flows_usd/1e3 AS past_week_flows_usd_in_thousands
, percentage_of_btc
, btc_supply
, 100*(365/28)*(past_month_flows/btc_supply) AS monthly_annualised_impact_on_supply
, 100*(365/14)*(past_twoweeks_flows/btc_supply) AS byweekly_annualised_impact_on_supply
, 100*(365/7)*(past_week_flows/btc_supply) AS week_annualised_impact_on_supply
FROM btc_amounts ba
LEFT JOIN prices.usd_latest pu ON pu.blockchain IS NULL
    AND pu.symbol = 'BTC'
    