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
      --T.TRADE_ID,
      SUM(T.SHARES)
      --T.STOCK_ID,
      --T.STOCK_EX_ID
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
SELECT SUB.EXCHANGE_NAME,
       MAX(SUB.SUM_SHARES)
FROM (
      SELECT SE.NAME EXCHANGE_NAME,
              SL.STOCK_SYMBOL,
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
     -- SL.STOCK_SYMBOL,
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
     -- SL.STOCK_SYMBOL,
      COM.NAME,
      P.PRICE,
      (P.PRICE-LP.PRICE)/LP.PRICE
ORDER BY TRADE_VOLUMN DESC
;

/*
SELECT SP.* ,
      SE.NAME,
      COM.NAME
FROM STOCK_PRICE SP
JOIN STOCK_EXCHANGE SE
  ON SP.STOCK_EX_ID = SE.STOCK_EX_ID
JOIN COMPANY COM
  ON COM.STOCK_ID = SP.STOCK_ID
WHERE TIME_END IS NULL;
SELECT * FROM STOCK_LISTING;
SELECT SE.NAME,
      SL.STOCK_SYMBOL,
      COM.NAME COMPANY_NAME  
FROM STOCK_EXCHANGE SE
JOIN STOCK_LISTING SL
  ON SE.STOCK_EX_ID = SL.STOCK_EX_ID
JOIN COMPANY COM
  ON COM.STOCK_ID = SL.STOCK_ID
WHERE SE.NAME = 'New York Stock Exchange'
;
SELECT 
    MAX(TIME_END)
FROM STOCK_PRICE
WHERE STOCK_ID =7

--AND STOCK_EX_ID = 1
;
SELECT * FROM STOCK_LISTING;
*/