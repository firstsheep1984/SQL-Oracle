/* This file provides two queries for the current_shareholder_shares
view.  Determine which version is more efficient and use the more efficient
version.
*/

-- Query 1 for current_shareholder_shares
CREATE OR REPLACE VIEW current_shareholder_shares
AS
SELECT 
   nvl(buy.buyer_id, sell.seller_id) AS shareholder_id,
   sh.type,
   nvl(buy.stock_id, sell.stock_id) AS  stock_id, 
   CASE nvl(buy.buyer_id, sell.seller_id)
      WHEN c.company_id THEN NULL
      ELSE nvl(buy.shares,0) - nvl(sell.shares,0)
   END AS shares
FROM (SELECT 
        t_sell.seller_id,
        t_sell.stock_id,
      sum(t_sell.shares) AS shares
      FROM trade t_sell
      WHERE t_sell.seller_id IS NOT NULL
      GROUP BY t_sell.seller_id, t_sell.stock_id) sell
  FULL OUTER JOIN
     (SELECT 
        t_buy.buyer_id,  
        t_buy.stock_id,
        sum(t_buy.shares) AS shares
      FROM trade t_buy
      WHERE t_buy.buyer_id IS NOT NULL
      GROUP BY t_buy.buyer_id, t_buy.stock_id) buy
   ON sell.seller_id = buy.buyer_id
   AND sell.stock_id = buy.stock_id
  JOIN shareholder sh
    ON sh.shareholder_id = nvl(buy.buyer_id, sell.seller_id)
  JOIN company c
    ON c.stock_id = nvl(buy.stock_id, sell.stock_id)
WHERE nvl(buy.shares,0) - nvl(sell.shares,0) != 0
ORDER BY 1,3
;
  
  
-- Query 2 for current_shareholder_shares
SELECT 
  holder.shareholder_id,
  sh.TYPE,
  holder.stock_id,
  CASE holder.shareholder_id
     WHEN c.company_id THEN NULL
     ELSE
  (SELECT nvl(sum(t_buy.shares),0)
   FROM trade t_buy
   WHERE t_buy.buyer_id = holder.shareholder_id
     AND t_buy.stock_id = holder.stock_id)
   - (SELECT nvl(sum(t_sell.shares),0)
     FROM trade t_sell
     WHERE t_sell.seller_id = holder.shareholder_id
      AND t_sell.stock_id = holder.stock_id)
   END AS shares
FROM (SELECT 
        buyer_id AS shareholder_id,
        stock_id
      FROM trade
      WHERE buyer_id IS NOT NULL
      UNION
      SELECT 
        seller_id,
        stock_id
      FROM trade
      WHERE seller_id IS NOT NULL
     ) holder
  INNER JOIN shareholder sh
    ON sh.shareholder_id = holder.shareholder_id
  INNER JOIN company c
    ON c.stock_id = holder.stock_id
WHERE
  (SELECT nvl(sum(t_buy.shares),0)
   FROM trade t_buy
   WHERE t_buy.buyer_id = holder.shareholder_id
     AND t_buy.stock_id = holder.stock_id)
   - (SELECT nvl(sum(t_sell.shares),0)
     FROM trade t_sell
     WHERE t_sell.seller_id = holder.shareholder_id
      AND t_sell.stock_id = holder.stock_id)
  != 0
ORDER BY 1,3
;
    
/* This file provides two queries to use for the current_stock_stats view.
Determine which version is more efficient and use the more efficient
version.
*/
-- Current_stock_stats: query 1
SELECT
  co.stock_id,
  si.authorized current_authorized,
  (SELECT nvl(sum(shares),0)
   FROM trade t_buy
   WHERE t_buy.stock_id = co.stock_id
     AND t_buy.buyer_id != co.company_id) 
    - (SELECT nvl(sum(shares),0)
       FROM trade t_sell
       WHERE t_sell.stock_id = co.stock_id
       AND t_sell.seller_id != co.company_id) AS total_outstanding
FROM company co
  INNER JOIN shares_authorized si
   ON si.stock_id = co.stock_id
    AND si.time_end IS NULL
ORDER BY stock_id    
    ;

-- Current_stock_stats: query 2
CREATE OR REPLACE VIEW Current_stock_stats
AS
SELECT
  co.stock_id,
  si.authorized current_authorized,
  SUM(DECODE(t.seller_id,co.company_id,t.shares)) 
    -NVL(SUM(CASE WHEN t.buyer_id = co.company_id 
             THEN t.shares END),0) AS total_outstanding
FROM company co
  INNER JOIN shares_authorized si
     ON si.stock_id = co.stock_id
    AND si.time_end IS NULL
  LEFT OUTER JOIN trade t
      ON t.stock_id = co.stock_id
GROUP BY co.stock_id, si.authorized
ORDER BY stock_id
;

SET autotrace OFF;

-- Turn on all autotrace options
SET autotrace ON;

-- Display the explain plan only (no statistics)
SET autotrace ON EXPLAIN;

--Or to turn on only the statistics
SET autotrace ON STATISTICS;


