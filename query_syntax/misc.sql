CREATE OR REPLACE TABLE left_table (
  c1 VARCHAR(1),
  c2 TINYINT,
  c3 TIME,
  c4 NUMBER(3,2)
);

CREATE OR REPLACE TABLE right_table (
  c1 VARCHAR(1),
  c2 TINYINT,
  c3 TIME,
  c4 NUMBER(3,2)
);

INSERT INTO left_table VALUES
  ('A',1,'09:15:00',3.21),
  ('A',2,'09:16:00',3.22),
  ('B',1,'09:17:00',3.23),
  ('B',2,'09:18:00',4.23);

INSERT INTO right_table VALUES
  ('A',1,'09:14:00',3.19),
  ('B',1,'09:16:00',3.04);

select * from right_table;