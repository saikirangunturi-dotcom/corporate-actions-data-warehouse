CREATE INDEX idx_fact_company_key
ON gold.fact_corporate_actions_tbl(company_key); ---Used when joining fact table with gold.dim_companies_tbl

CREATE INDEX idx_fact_event_type_key
ON gold.fact_corporate_actions_tbl(event_type_key); ---Used when filtering/reporting by event type like Dividend, Split, Merger

DROP INDEX idx_fact_event_type_key
ON gold.fact_corporate_actions_tbl; --Dropped the index

CREATE INDEX idx_fact_announcement_date_key
ON gold.fact_corporate_actions_tbl(announcement_date_key); --Used for monthly/yearly trend reports based on announcement date

CREATE INDEX idx_fact_security_key
ON gold.fact_corporate_actions_tbl(security_key); --useful when joining with security/ticker/ISIN dimension

CREATE INDEX idx_fact_ca_status
ON gold.fact_corporate_actions_tbl(ca_status); --useful when filtering by status like COMPLETED, PENDING, CANCELLED

DROP INDEX idx_fact_ca_status
ON gold.fact_corporate_actions_tbl; --Dropped the index

CREATE INDEX idx_fact_ex_date_key
ON gold.fact_corporate_actions_tbl(ex_date_key); --useful for dividend/split reports where ex-date is important

DROP INDEX idx_fact_ex_date_key
ON gold.fact_corporate_actions_tbl --Dropped the index

CREATE INDEX idx_fact_event_date
ON gold.fact_corporate_actions_tbl(event_type_key, announcement_date_key); --Event and Date analytics

CREATE INDEX idx_fact_company_event
ON gold.fact_corporate_actions_tbl(company_key, event_type_key); -- Company and event analytics
