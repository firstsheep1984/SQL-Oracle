--  Q1
-- The consistent gets of version 1 is 80,
-- while the consistent gets of version 2 is 1156, so choose version 1
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

--  Q2
-- The consistent gets of version 1 is 92,
-- while the consistent gets of version 2 is 77, so choose version 2
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

/* Q3.	Write a query which lists the name of every company that has authorized stock, 
the number of shares authorized, the total shares outstanding, and % of authorized shares that are outstanding.
Shares outstanding is the number of shares owned by external share holders.  
Shares_Authorized = Shares_Outstanding + Shares_UnIssued*/
SELECT COM.NAME,
      SUBSA.SUMA,
      CUR.TOTAL_OUTSTANDING,
      ROUND(CUR.TOTAL_OUTSTANDING/SUBSA.SUMA,2) PERCENTAGE
FROM COMPANY COM
JOIN CURRENT_STOCK_STATS CUR
  ON COM.STOCK_ID = CUR.STOCK_ID
JOIN (
      SELECT SUM(AUTHORIZED)  SUMA,
      STOCK_ID
      FROM SHARES_AUTHORIZED 
      GROUP BY STOCK_ID
      ) SUBSA
  ON SUBSA.STOCK_ID = COM.STOCK_ID
;

/* 4.	For every direct holder: list the name of the holder, the names of the companies invested in by this direct holder,
number of shares currently held, % this holder has of the shares outstanding, and % this holder has of the total authorized shares. 
Sort the output by direct holder last name, first name, and company name and display the percentages to two decimal places.*/
SELECT DH.LAST_NAME,
        DH.FIRST_NAME,
        COM.NAME,
        CSS.SHARES,
        ROUND(CSS.SHARES/SUBSA.SUMA,2) PERCENTAGE
FROM DIRECT_HOLDER DH
JOIN CURRENT_SHAREHOLDER_SHARES CSS
  ON DH.DIRECT_HOLDER_ID = CSS.SHAREHOLDER_ID
JOIN COMPANY COM
  ON COM.STOCK_ID = CSS.STOCK_ID
  JOIN (
      SELECT SUM(AUTHORIZED)  SUMA,
      STOCK_ID
      FROM SHARES_AUTHORIZED 
      GROUP BY STOCK_ID
      ) SUBSA
  ON SUBSA.STOCK_ID = COM.STOCK_ID
ORDER BY DH.LAST_NAME
;
/*5.	For every institutional holder (companies who hold stock): list the name of the holder, 
the names of the companies invested in by this holder, shares currently held, % this holder has of the total shares outstanding,
and % this holder has of that total authorized shares.  
For this report, include only the external holders (not treasury shares).  
Sort the output by holder name, and company owned name and display the percentages to two decimal places.*/
SELECT HOLDER.NAME HOLDERNAME,
        COM.NAME INVESTCOMPANY,
        CSS.SHARES,
        CSS.SHARES/CUR.TOTAL_OUTSTANDING,
        ROUND(CSS.SHARES/SUBSA.SUMA,2) PERCENTAGE
FROM CURRENT_SHAREHOLDER_SHARES CSS
JOIN COMPANY HOLDER
  ON CSS.SHAREHOLDER_ID = HOLDER.COMPANY_ID
JOIN CURRENT_STOCK_STATS CUR
  ON CUR.STOCK_ID = CSS.STOCK_ID
JOIN COMPANY COM
  ON COM.STOCK_ID = CUR.STOCK_ID
JOIN (
      SELECT SUM(AUTHORIZED)  SUMA,
      STOCK_ID
      FROM SHARES_AUTHORIZED 
      GROUP BY STOCK_ID
      ) SUBSA
  ON SUBSA.STOCK_ID = COM.STOCK_ID
WHERE HOLDER.NAME != COM.NAME
;
/*6.	Write a query which displays all trades where more than 50000 shares were traded on the secondary markets.  
Please include the trade id, stock symbol, name of the company being traded, stock exchange symbol, number of shares traded,
price total (including broker fees) and currency symbol. */
SELECT T.TRADE_ID,
        SL.STOCK_SYMBOL,
        COM.NAME,
        SE.SYMBOL,
        T.SHARES,
        T.PRICE_TOTAL,
        CUR.SYMBOL
FROM TRADE T
JOIN STOCK_LISTING SL
  ON T.STOCK_ID = SL.STOCK_ID
  AND T.STOCK_EX_ID = SL.STOCK_EX_ID
JOIN COMPANY COM
 ON SL.STOCK_ID = COM.STOCK_ID
JOIN STOCK_EXCHANGE SE
  ON SE.STOCK_EX_ID = SL.STOCK_EX_ID
JOIN CURRENCY CUR
  ON SE.CURRENCY_ID = CUR.CURRENCY_ID
WHERE T.SHARES > 50000
;

/*7.	For each stock listed at each stock exchange, display the exchange name, stock symbol and the date and time when that the stock was last traded.
Sort the output by stock exchange name, stock symbol.  If a stock has not been traded show NULL for the date last traded.*/
SELECT SE.NAME,
        SL.STOCK_SYMBOL,
        MAX(T.TRANSACTION_TIME)
FROM STOCK_LISTING SL
JOIN STOCK_EXCHANGE SE
  ON SL.STOCK_EX_ID = SE.STOCK_EX_ID
LEFT JOIN TRADE T
  ON SL.STOCK_EX_ID = T.STOCK_EX_ID
  AND SL.STOCK_ID = T.STOCK_ID
GROUP BY SE.NAME,
        SL.STOCK_SYMBOL
ORDER BY SE.NAME,
        SL.STOCK_SYMBOL
;
--SELECT * FROM TRADE;
/*8.	Display the trade_id, name of the company and number of shares for the single largest trade made on any secondary market 
(in terms of the number of shares traded).  Unless there are multiple trades with the same number of shares traded, 
only one record should be returned.
*/
SELECT T.TRADE_ID,
        COM.NAME,
      T.SHARES
FROM TRADE T
JOIN STOCK_LISTING SL
  ON SL.STOCK_EX_ID = T.STOCK_EX_ID
  AND SL.STOCK_ID = T.STOCK_ID
JOIN COMPANY COM
  ON COM.STOCK_ID = SL.STOCK_ID
WHERE T.SHARES =
(
              SELECT MAX(TSUB.SHARES)
              FROM TRADE TSUB              
              WHERE TSUB.STOCK_EX_ID IS NOT NULL
)
;

/*Data Manipulation
Write the necessary INSERT, UPDATE and/or DELETE statements to complete the following data changes.  
Add a Direct Holder
9.	Add “Jeff Adams” as a new direct holder.  You will have to insert a record into the shareholder table and make a separate statement 
to insert into the direct_holder table.*/
INSERT INTO SHAREHOLDER (SHAREHOLDER_ID, TYPE)
VALUES (26,'Direct_Holder');
INSERT INTO DIRECT_HOLDER (DIRECT_HOLDER_ID, FIRST_NAME, LAST_NAME)
VALUES (26,'Jeff','Adams');

/*Add an Institutional Holder
10.	Add “Makoto Investing” as a new institutional holder that has its head office in Tokyo, Japan.  
Makoto does not currently have a stock id.  A record must be inserted into the shareholder table and a corresponding 
record must be inserted into the company table.*/
INSERT INTO SHAREHOLDER (SHAREHOLDER_ID, TYPE)
VALUES (27,'Company');
INSERT INTO COMPANY (COMPANY_ID, NAME, PLACE_ID)
VALUES (27,'Makoto Investing',4);

/*Initial Public Offering (IPO)
11.	“Makoto Investing” would like to declare stock.  As of today’s date, they are authorizing 100,000 shares at a starting price of 50 yen.  
To complete the work, you will need to update the company table to give Makoto its own stock id, and insert a new entry in the shares_authorized table.
Listing on an Exchange */
UPDATE COMPANY
SET STOCK_ID = 9, STARTING_PRICE = 50, CURRENCY_ID = 5
WHERE COMPANY_ID = 27;
INSERT INTO SHARES_AUTHORIZED (STOCK_ID, TIME_START, AUTHORIZED)
VALUES (9,'9-SEP-19',100000);

/*12.	 “Makoto Investing” would like to list on the Tokyo Stock Exchange under the stock symbol “Makoto”.  
You will need to insert into the stock_listing table and the stock_price table.*/
INSERT INTO STOCK_LISTING (STOCK_ID,STOCK_EX_ID, STOCK_SYMBOL)
VALUES (9,4,'Makoto');
INSERT INTO STOCK_PRICE (STOCK_ID,STOCK_EX_ID, PRICE,TIME_START)
VALUES (9,4,50,'9-SEP-19');

/*13.	Display the trade id, the stock id and the total price (in US dollars) for the secondary market trade with the highest total price. 
Convert all prices to US dollars.*/

SELECT T.TRADE_ID,
       T.STOCK_ID,
       ROUND(T.PRICE_TOTAL * CON.EXCHANGE_RATE,2) HIGHEST_PRICE_TOTAL_USD
FROM TRADE T
JOIN STOCK_EXCHANGE SE
  ON T.STOCK_EX_ID = SE.STOCK_EX_ID
JOIN CURRENCY CUR
  ON CUR.CURRENCY_ID = SE.CURRENCY_ID
JOIN CONVERSION CON
  ON CUR.CURRENCY_ID = CON.FROM_CURRENCY_ID
WHERE CON.TO_CURRENCY_ID = 1
   AND T.STOCK_EX_ID IS NOT NULL
   AND T.PRICE_TOTAL * CON.EXCHANGE_RATE = (
   SELECT MAX(TSUB.PRICE_TOTAL * CON.EXCHANGE_RATE)
   FROM TRADE TSUB
   JOIN STOCK_EXCHANGE SE
  ON TSUB.STOCK_EX_ID = SE.STOCK_EX_ID
JOIN CURRENCY CUR
  ON CUR.CURRENCY_ID = SE.CURRENCY_ID
JOIN CONVERSION CON
  ON CUR.CURRENCY_ID = CON.FROM_CURRENCY_ID
  WHERE CON.TO_CURRENCY_ID = 1
   AND TSUB.STOCK_EX_ID IS NOT NULL
   )
;

/*14.	Display the name of the company and trade volume for the company whose stock has the largest total volume of shareholder trades worldwide.
[Example calculation: A company declares 20000 shares, and issues 10000 on the new issue market (primary market), and 1000 shares is sold to a
stockholder on the secondary market. Later that stockholder sells 500 shares to another stockholder (or back to the company itself).
The number of shareholder trades is 2 and the total volume of shareholder trades is 1500.] */
SELECT COM.NAME,
      SUM(T.SHARES)
FROM COMPANY COM
JOIN STOCK_LISTING SL
  ON COM.STOCK_ID = SL.STOCK_ID
JOIN TRADE T
  ON T.STOCK_ID = SL.STOCK_ID
  AND T.STOCK_EX_ID = SL.STOCK_EX_ID
GROUP BY COM.NAME
HAVING SUM(T.SHARES)=(
          SELECT MAX(SUM(TSUB.SHARES))
          FROM COMPANY COM
          JOIN STOCK_LISTING SL
            ON COM.STOCK_ID = SL.STOCK_ID
          JOIN TRADE TSUB
            ON TSUB.STOCK_ID = SL.STOCK_ID
            AND TSUB.STOCK_EX_ID = SL.STOCK_EX_ID
          GROUP BY COM.NAME
          )
;

/*15.	For each stock exchange, display the symbol of the stock with the highest total trade volume. 
Show the stock exchange name, stock symbol and total trade volume.  Sort the output by the name of the stock exchange and the stock symbol.*/
/*SELECT SUB.EXCHANGE_NAME,        
       MAX(SUB.SUM_SHARES)
FROM (
      SELECT SE.NAME EXCHANGE_NAME,
              SL.STOCK_SYMBOL STOCK_SYMBOL,
              SUM(T.SHARES) SUM_SHARES
      FROM STOCK_EXCHANGE SE
      JOIN STOCK_LISTING SL
        ON SE.STOCK_EX_ID = SL.STOCK_EX_ID
      JOIN TRADE T
        ON T.STOCK_ID = SL.STOCK_ID
        AND T.STOCK_EX_ID = SL.STOCK_EX_ID
      GROUP BY SE.NAME,
              SL.STOCK_SYMBOL ) SUB
GROUP BY SUB.EXCHANGE_NAME
;
*/
WITH SUB AS
(
SELECT SE.NAME EXCHANGE_NAME,
              SL.STOCK_SYMBOL STOCK_SYMBOL,
              SUM(T.SHARES) SUM_SHARES
      FROM STOCK_EXCHANGE SE
      JOIN STOCK_LISTING SL
        ON SE.STOCK_EX_ID = SL.STOCK_EX_ID
      JOIN TRADE T
        ON T.STOCK_ID = SL.STOCK_ID
        AND T.STOCK_EX_ID = SL.STOCK_EX_ID
      GROUP BY SE.NAME,
              SL.STOCK_SYMBOL
)
SELECT SUB.EXCHANGE_NAME, 
      SUB.STOCK_SYMBOL,
       SUB.SUM_SHARES
FROM SUB
WHERE SUB.SUM_SHARES IN
(
SELECT MAX(SUBSUB.SUM_SHARES)
FROM SUB SUBSUB

GROUP BY SUBSUB.EXCHANGE_NAME
)
;

/*16.	List all companies on the New York Stock Exchange.  Display the company name, shareholder trade volume, 
the current price and the percentage change for the last price change, and sort the output in descending order of shareholder trade volume.*/
WITH LAST_PRICE AS
    (SELECT P.STOCK_EX_ID STOCK_EX_ID,
             P.STOCK_ID STOCK_ID,
             P.PRICE PRICE,
            P.TIME_END  
        FROM STOCK_PRICE P
        WHERE P.TIME_END = (
              SELECT MAX(PSUB.TIME_END)
              FROM STOCK_PRICE PSUB
              WHERE PSUB.STOCK_ID = P.STOCK_ID
              AND PSUB.STOCK_EX_ID = P.STOCK_EX_ID
             )
    )
    
SELECT SE.NAME,
      COM.NAME COMPANY_NAME,
      SUM(T.SHARES)TRADE_VOLUMN,
      P.PRICE,
      ROUND((P.PRICE-LP.PRICE)/LP.PRICE*100,2)||'%' PERCENTAGE      
FROM STOCK_EXCHANGE SE
JOIN STOCK_LISTING SL
  ON SE.STOCK_EX_ID = SL.STOCK_EX_ID
JOIN COMPANY COM
  ON COM.STOCK_ID = SL.STOCK_ID
JOIN STOCK_PRICE P
  ON SL.STOCK_ID = P.STOCK_ID
  AND SL.STOCK_EX_ID = P.STOCK_EX_ID
JOIN TRADE T
  ON T.STOCK_ID = SL.STOCK_ID
JOIN LAST_PRICE LP
  ON LP.STOCK_EX_ID = SL.STOCK_EX_ID
  AND LP.STOCK_ID = SL.STOCK_ID
WHERE SE.NAME = 'New York Stock Exchange'
  AND P.TIME_END IS NULL
GROUP BY SE.NAME,
      COM.NAME,
      P.PRICE,
      (P.PRICE-LP.PRICE)/LP.PRICE
ORDER BY TRADE_VOLUMN DESC
;
