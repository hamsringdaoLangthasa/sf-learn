CREATE STORAGE INTEGRATION azure_store_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'AZURE'
  ENABLED = TRUE
  AZURE_TENANT_ID = '3c953cb8-445e-4052-b437-5d29312bafea'
  STORAGE_ALLOWED_LOCATIONS = ('azure://boratstore.blob.core.windows.net/datalake/ecommerce/');

SHOW STORAGE INTEGRATIONS;

DESC STORAGE INTEGRATION azure_store_int;

SELECT SYSTEM$VALIDATE_STORAGE_INTEGRATION( 'azure_int', '', '<test_file_name>', '<validate_action>' );

CREATE NOTIFICATION INTEGRATION azure_notif_int
  ENABLED = TRUE
  TYPE = QUEUE
  NOTIFICATION_PROVIDER = AZURE_STORAGE_QUEUE
  AZURE_STORAGE_QUEUE_PRIMARY_URI = 'https://boratstore.queue.core.windows.net/sf-queue'
  AZURE_TENANT_ID = '3c953cb8-445e-4052-b437-5d29312bafea';

DESC NOTIFICATION INTEGRATION azure_notif_int;

CREATE OR REPLACE DATABASE ecommerce;
CREATE OR REPLACE SCHEMA stage;

USE SCHEMA ecommerce.stage;

CREATE OR REPLACE STAGE azure_ecommerce_stage
  URL = 'azure://boratstore.blob.core.windows.net/datalake/ecommerce/raw/'
  STORAGE_INTEGRATION = azure_store_int;

LIST @azure_ecommerce_stage;

CREATE PIPE snowpipe_db.public.mypipe
  AUTO_INGEST = true
  INTEGRATION = 'MY_NOTIFICATION_INT'
  AS
    COPY INTO snowpipe_db.public.mytable
      FROM @snowpipe_db.public.mystage
      FILE_FORMAT = (type = 'JSON');

CREATE WAREHOUSE IF NOT EXISTS LOADER_WH
    WAREHOUSE_SIZE    = 'XSMALL'
    AUTO_SUSPEND      = 60
    AUTO_RESUME       = TRUE
    COMMENT           = 'Snowpipe + COPY INTO';


show pipes;

select * from raw_events_staging_stream;

select count(*) from snowflake_sample_data.tpch_sf1.customer;

show tasks;

alter task raw_events_task resume;


alter pipe pipe_inventory refresh;
alter pipe pipe_categories set pipe_execution_paused = False;

SELECT SYSTEM$PIPE_STATUS('pipe_categories');

truncate table categories;

SHOW DYNAMIC TABLES;

select * from ECOMMERCE.GOLD.GOLD_REVENUE_DAILY;

show tables;

-- truncate table CATEGORIES;
-- truncate table COUPONS;
-- truncate table CUSTOMERS;
-- truncate table INVENTORY;
-- truncate table PRODUCTS;
-- truncate table PROMOTIONS;
-- truncate table SELLERS;
-- truncate table WAREHOUSES;

select * from CATEGORIES;
select * from COUPONS;
select * from CUSTOMERS;
select * from INVENTORY;
select * from PRODUCTS;
select * from PROMOTIONS;
select * from SELLERS;
select * from WAREHOUSES;

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'inventory',
        START_TIME => DATEADD('DAY', -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;

SELECT
    FILE_NAME,
    STATUS,
    FIRST_ERROR_MESSAGE,
    FIRST_ERROR_LINE_NUMBER,
    ROW_COUNT
FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE PIPE_NAME = 'pipe_inventory'
ORDER BY LAST_LOAD_TIME DESC;

CREATE USER IF NOT EXISTS ecom
  LOGIN_NAME='ecom'
  TYPE=SERVICE
  RSA_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtu7ELvT8wCqztDF/yLIT
SsHyZtyp4K0F82I0CX3Sh6TSVqP2r/rt+MMGFRlCo2+G39FpGH7BgHVZ8DhlK2PA
Ujcxbw73j1uxX/jnkY/s15u1GexhaO6Gdeua5xQEyoo07zWQUcn+8RI1hW/zZdDD
tqpTCtcZyRuOFwsConKPoAkc/AhSVcNsYSfovckve2CVWxRsABRNljuqmwaImmjs
rXwMcHTAbV9vCUGYYwvOZsI8pYBrycs37zR4iaTgzwrN7dYJgpbHdhZ99EfHJ9q9
tT20zMP64o6pxay7N/hvDhYXe8xRE/Vbf9HdHQkGP+ARlldulEEnzMOlzzBk8P7a
2wIDAQAB
-----END PUBLIC KEY-----"
  DEFAULT_ROLE=ADMIN
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_NAMESPACE='ECOMMERCE.'
  COMMENT='DBT user used for data transformation';

select * from raw_events;ECOMMERCE.SILVER

select * from raw_events_staging;

SELECT
    record_content:event_id::VARCHAR,
    record_content:session_id::VARCHAR,
    record_content:customer_id::VARCHAR,
    record_content:persona_type::VARCHAR,
    record_content:event_type::VARCHAR,
    record_content:event_ts::TIMESTAMP_TZ,
    record_content:device_type::VARCHAR,
    record_content:ip_address::VARCHAR,
    record_content:payload::VARIANT,
    record_metadata:topic::VARCHAR,
    record_metadata:partition::INT,
    record_metadata:offset::INT,
    record_metadata:CreateTime::TIMESTAMP_TZ
FROM raw_events_staging_stream;

DROP SCHEMA SILVER;

select array_contains('\"johndoe\"'::variant, '["johndoe"]'::variant);

select '["johndoe"]'::ECOMMERCE.GOLDvariant;

USE ROLE ACCOUNTADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA ECOMMERCE.GOLD TO ROLE REPORTER;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA ECOMMERCE.GOLD TO ROLE REPORTER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA ECOMMERCE.GOLD TO ROLE REPORTER;
GRANT SELECT ON FUTURE DYNAMIC TABLES IN SCHEMA ECOMMERCE.GOLD TO ROLE REPORTER;

select * from gold.gold_cart_abandonment;

SELECT * FROM GOLD.GOLD_REVENUE_DAILY LIMIT 1;


select * from gold.gold_payment_health limit 10;

SELECT
    SERVICE_TYPE,
    SUM(CREDITS_USED) AS CREDITS_USED
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE START_TIME >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY SERVICE_TYPE
ORDER BY CREDITS_USED DESC;

SELECT
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS CREDITS_USED
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD(day, -30, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME
ORDER BY CREDITS_USED DESC;

SELECT
    WAREHOUSE_NAME,
    USER_NAME,
    QUERY_TYPE,
    COUNT(*) AS QUERY_COUNT,
    SUM(TOTAL_ELAPSED_TIME) / 1000 / 60 AS TOTAL_MINUTES
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD(day, -7, CURRENT_TIMESTAMP())
  AND WAREHOUSE_NAME IS NOT NULL
GROUP BY
    WAREHOUSE_NAME,
    USER_NAME,
    QUERY_TYPE
ORDER BY TOTAL_MINUTES DESC;

COPY INTO @~/customer/single_file.csv
FROM snowflake_sample_data.tpch_sf100.customer
FILE_FORMAT = (
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
)
MAX_FILE_SIZE = 5368709120
SINGLE = TRUE
OVERWRITE = TRUE;

list @~;