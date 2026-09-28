/*
SELECT ...
FROM ...
   CHANGES ( INFORMATION => { DEFAULT | APPEND_ONLY } )
   AT ( { TIMESTAMP => <timestamp> | OFFSET => <time_difference> | STATEMENT => <id> | STREAM => '<name>' } ) | BEFORE ( STATEMENT => <id> )
   [ END( { TIMESTAMP => <timestamp> | OFFSET => <time_difference> | STATEMENT => <id> } ) ]
[ ... ]
*/

CREATE OR REPLACE TABLE t1 (
id number(8) NOT NULL,
c1 varchar(255) default NULL
);

-- Enable change tracking on the table.
ALTER TABLE t1 SET CHANGE_TRACKING = TRUE;

-- Initialize a session variable for the current timestamp.
SET ts1 = (SELECT CURRENT_TIMESTAMP());

INSERT INTO t1 (id,c1)
VALUES
(1,'red'),
(2,'blue'),
(3,'green');

DELETE FROM t1 WHERE id = 1;

UPDATE t1 SET c1 = 'purple' WHERE id = 2;

-- Query the change tracking metadata in the table during the interval from $ts1 to the current time.
-- Return the full delta of the changes.
SELECT *
FROM t1
CHANGES(INFORMATION => DEFAULT)
AT(TIMESTAMP => $ts1);

+----+--------+-----------------+-------------------+------------------------------------------+
| ID | C1     | METADATA$ACTION | METADATA$ISUPDATE | METADATA$ROW_ID                          |
|----+--------+-----------------+-------------------+------------------------------------------|
|  2 | purple | INSERT          | False             | 1614e92e93f86af6348f15af01a85c4229b42907 |
|  3 | green  | INSERT          | False             | 86df000054a4d1dc64d5d74a44c3131c4c046a1f |
+----+--------+-----------------+-------------------+------------------------------------------+

-- Query the change tracking metadata in the table during the interval from $ts1 to the current time.
-- Return the append-only changes.
SELECT *
FROM t1
CHANGES(INFORMATION => APPEND_ONLY)
AT(TIMESTAMP => $ts1);

+----+-------+-----------------+-------------------+------------------------------------------+
| ID | C1    | METADATA$ACTION | METADATA$ISUPDATE | METADATA$ROW_ID                          |
|----+-------+-----------------+-------------------+------------------------------------------|
|  1 | red   | INSERT          | False             | 6a964a652fa82974f3f20b4f49685de54eeb4093 |
|  2 | blue  | INSERT          | False             | 1614e92e93f86af6348f15af01a85c4229b42907 |
|  3 | green | INSERT          | False             | 86df000054a4d1dc64d5d74a44c3131c4c046a1f |
+----+-------+-----------------+-------------------+------------------------------------------+

--------------------------------------------------------

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

--------------------------------------------------------

CREATE OR REPLACE TABLE t1 (
id number(8) NOT NULL,
c1 varchar(255) default NULL
);

-- Create a stream on the table.
CREATE OR REPLACE STREAM s1 ON TABLE t1;

INSERT INTO t1 (id,c1)
VALUES
(1,'red'),
(2,'blue'),
(3,'green');

-- Initialize a session 'end timestamp' variable for the current timestamp.
SET ts2 = (SELECT CURRENT_TIMESTAMP());

DELETE FROM t1;

-- Create a table populated by the change data between the current
-- s1 offset and the end timestamp.
CREATE OR REPLACE TABLE t2 (
c1 varchar(255) default NULL
)
AS SELECT C1
FROM t1
CHANGES(INFORMATION => APPEND_ONLY)
AT(STREAM => 's1')
END(TIMESTAMP => $ts2);

SELECT * FROM t2;

+-------+
| C1    |
|-------|
| red   |
| blue  |
| green |
+-------+
