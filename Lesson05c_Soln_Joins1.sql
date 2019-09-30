/* Basic Select Exercise Answers */

/*         
1.	Show a listing of all consultants who live in Linlithgow and Whitecross (towns.)
OBJECTIVE: Table JOIN and translating from english to SQL.  The choice of the word "and" in the question was deliberate.  Trainees need to
figure out the meaning of AND and OR.
PITFALLS:  Trainees will try AND and get no rows returned.
If trainees use IN they will not fall into the trap. ie.  town IN ('Linlithgow','Whitecross')
Solution:
*/
SELECT 
   c.first_name,
   c.last_name,
   a.town
FROM consultant c
   JOIN address A
     ON A.address_id = c.address_id
WHERE A.town = 'Linlithgow' 
  OR A.town = 'Whitecross'
;

/* 2.  Rewrite to join in a different order
*/
SELECT 
   c.first_name,
   c.last_name,
   a.town
FROM address A
   JOIN 
     consultant c
     ON A.address_id = c.address_id
WHERE A.town = 'Linlithgow' 
  OR A.town = 'Whitecross'
;

/* 
3.	List all clients in Falkirk and Armadale.
OBJECTIVE: Same as #3.  More practice
Solution:
*/
SELECT 
    c.client_id,
    c.client_name,
    a.town
FROM client c
   JOIN address a
     ON a.address_id = c.address_id
WHERE a.town = 'Falkirk'
   OR a.town = 'Armadale';

SELECT 
    c.client_id,
    c.client_name,
    a.town
FROM client c
   JOIN address a
     ON a.address_id = c.address_id
WHERE a.town IN ('Falkirk', 'Armadale');
   
/*
4.	Show a list of all consultants, the descriptions of the jobs that they have done, 
and the comment they made about the job.
OBJECTIVE: This is the first query involving more than two tables.  (Just because you
know how to join two tables does NOT mean you can join more.  However, if you know how
to join 3 tables you will be able to join more.)  
*/
SELECT
   con.first_name,
   con.last_name,
   c.client_name,
   a.comments
FROM consultant con
  JOIN assignment a
     ON a.consultant_id = con.consultant_id
  JOIN client c
      ON c.client_id = a.client_id;

/* 
5.	Create a listing which shows consultants, the towns where they 
live, the assignment ids and the names of the clients for their 
assignments. Sort the records by town, and client name.
*/
SELECT 
   c.first_name || ' ' || c.last_name consultant,
   cad.town,
   ca.assignment_id,
   cl.client_name
FROM address cad
  JOIN consultant c
     ON c.address_id = cad.address_id
  JOIN assignment ca
     ON ca.consultant_id = c.consultant_id
  JOIN client cl
     ON cl.client_id = ca.client_id
ORDER BY cad.town, cl.client_name;


/*      
6.	Create a listing of consultants and the jobs (description, and 
address info) for the jobs that they performed in their own 
home town.
OBJECTIVE: This query requires a MAJOR BREAKTHROUGH of understanding.
You must join to the the address table more than once: once for the
address of the consultant, and a second time for the address of the 
job.  This is also a pre-cursor to self-loops.
PITFALLS: The two address tables must have distinct table aliases.
*/
SELECT 
   con.first_name,
   con.last_name,
   cona.town AS "Consultant town",
   cl.client_name,
   cla.town  AS "Client Town"
FROM consultant con
   JOIN address cona
      ON cona.address_id = con.address_id
   JOIN assignment a
      ON a.consultant_id =  con.consultant_id
   JOIN client cl
      ON cl.client_id = a.client_id
   JOIN address cla
      ON cla.address_id = cl.address_id
WHERE  cla.town = cona.town
;

/*
Challenge Exercise:
7.  Create a listing  which shows consultants, clients and towns
where the consultant lives in the same town where the client's
office is.

*/
SELECT 
   con.first_name,
   con.last_name,
   cona.town      AS "Consultant Town",
   c.client_name,
   cla.town       AS "Client Town"
FROM consultant con
   JOIN address cona
      ON cona.address_id = con.address_id
   JOIN address cla
      ON cla.town = cona.town
   JOIN client c
      ON c.address_id = cla.address_id
;

-- Another solution.
SELECT 
  first_name,
  last_name,
  cona.town,
  cl.client_name,
  cla.town
FROM consultant con
  JOIN address cona
    ON cona.address_id = con.address_id
  JOIN client cl
         JOIN address cla
           ON cla.address_id = cl.address_id
    ON cla.town = cona.town;


