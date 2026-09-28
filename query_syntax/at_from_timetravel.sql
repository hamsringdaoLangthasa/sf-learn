/*
SELECT ...
FROM ...
  { AT | BEFORE }
  (
    { TIMESTAMP => <timestamp> |
      OFFSET => <time_difference> |
      STATEMENT => <id> |
      STREAM => '<name>' }
  )
[ ... ]

*/



CREATE OR REPLACE TABLE t1 (
  id number(8) NOT NULL,
  c1 varchar(255) default NULL
);

-- Enable change tracking on the table.
ALTER TABLE t1 SET CHANGE_TRACKING = TRUE;

-- Initialize a session 'start timestamp' variable for the current timestamp.
SET ts1 = (SELECT CURRENT_TIMESTAMP());

INSERT INTO t1 (id,c1)
VALUES
(1,'red'),
(2,'blue'),
(3,'green');

-- Initialize a session 'end timestamp' variable for the current timestamp.
SET ts2 = (SELECT CURRENT_TIMESTAMP());

DELETE FROM t1 WHERE id = 3;
SET last_query_id = (SELECT LAST_QUERY_ID());

-- Create a table populated by the change data between the start and end timestamps.
CREATE OR REPLACE TABLE t2 (
  c1 varchar(255) default NULL
  )
AS SELECT C1
  FROM t1
  CHANGES(INFORMATION => APPEND_ONLY)
  AT(TIMESTAMP => $ts1)
  END(TIMESTAMP => $ts2);

SELECT * FROM t2;

+-------+
| C1    |
|-------|
| red   |
| blue  |
| green |
+-------+

-- Create a table populated by the change data between the start timestamp and end statement.
-- This example demonstrates that END is inclusive of the statement passed in.
CREATE OR REPLACE TABLE t3 (
  c1 varchar(255) default NULL
  )
AS SELECT C1
  FROM t1
  CHANGES(INFORMATION => DEFAULT)
  AT(TIMESTAMP => $ts1)
  END(STATEMENT => $last_query_id);

+-------+
| C1    |
|-------|
| red   |
| blue  |
+-------+

SELECT * FROM t1 AT (timestamp => $ts3);

select $ts2;

