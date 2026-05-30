CREATE INDEX ix_ca_action
  ON silver.mdv_corporate_actions(action_id); -- Speeds up joins from corporate actions to dividend, split, and merger detail tables.

CREATE INDEX ix_dim_company 
  ON gold.dim_companies(company_name); -- Improves company lookup when loading fact data and filtering reports by company.

CREATE INDEX ix_dim_security
  ON gold.dim_securities(ticker); -- Improves ticker-based joins and Power BI filtering by ticker.

CREATE INDEX ix_dim_event
  ON gold.dim_event_types(event_type_standard); -- Speeds up event type filtering such as Dividend, Split, and Merger.

CREATE INDEX ix_div_action
  ON silver.mdv_dividends(action_id); -- Speeds up joins between corporate actions and dividend details.

CREATE INDEX ix_split_action
  ON silver.mdv_splits(action_id); -- Speeds up joins between corporate actions and split details.

CREATE INDEX ix_merger_action
  ON silver.mdv_mergers(action_id); -- Speeds up joins between corporate actions and merger details.

CREATE INDEX ix_fact_company_key
  ON gold.fact_corporate_actions(company_key); -- Improves joins between fact table and company dimension.

CREATE INDEX ix_fact_security_key
  ON gold.fact_corporate_actions(security_key); -- Improves joins between fact table and security dimension.

CREATE INDEX ix_fact_event_type_key
  ON gold.fact_corporate_actions(event_type_key); -- Improves joins and filtering by corporate action type.

CREATE INDEX ix_fact_validation_status
  ON gold.fact_corporate_actions(validation_status); -- Speeds up data quality reporting for Valid, Warning, and Invalid records.

CREATE INDEX ix_fact_announcement_date
  ON gold.fact_corporate_actions(announcement_date); -- Improves date-based filtering, trend analysis, and Power BI slicers.
