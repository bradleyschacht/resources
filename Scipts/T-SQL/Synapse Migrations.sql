IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'history')
EXEC ('CREATE SCHEMA history')
GO

-- DROP TABLE IF EXISTS history.account_acr
-- DROP TABLE IF EXISTS history.cat_account
-- DROP TABLE IF EXISTS history.cat_account_comment
-- DROP TABLE IF EXISTS history.factory_engagement
-- DROP TABLE IF EXISTS history.partner_engagement
-- GO

CREATE TABLE history.account_acr (
    snapshot_date           [varchar](max) 	NULL,
    tpid                    [varchar](8000) NULL,
    fy25_analytics_acr      [bigint] 		NULL,
    fy25_databricks_acr     [bigint] 		NULL,
    fy25_fabric_acr         [bigint] 		NULL,
    fy25_synapse_acr        [bigint] 		NULL,
    fy25_synapse_spark_acr  [bigint] 		NULL,
    created_date            [datetime2](6) 	NOT NULL
)
GO

CREATE TABLE history.cat_account (
    snapshot_date                   [date] NULL,
    account_id                      [varchar](8000) NULL,
    tpid                            [varchar](8000) NULL,
    account_name                    [varchar](8000) NULL,
    account_name_alternative        [varchar](8000) NULL,
    account_description             [varchar](8000) NULL,
    account_state                   [varchar](8000) NULL,
    account_status                  [varchar](8000) NULL,
    executive_sponsor               [varchar](8000) NULL,
    cat_operating_unit              [varchar](8000) NULL,
    cat_lead                        [varchar](8000) NULL,
    feedback_issue_count            [int] NULL,
    account_team_field_lead         [varchar](8000) NULL,
    account_team_manager            [varchar](8000) NULL,
    account_team_manager_alias      [varchar](8000) NULL,
    account_team_manager_email      [varchar](8000) NULL,
    account_type                    [varchar](8000) NULL,
    s500_flag                       [bit] NULL,
    industry_group                  [varchar](8000) NULL,
    industry                        [varchar](8000) NULL,
    segment                         [varchar](8000) NULL,
    sales_unit                      [varchar](8000) NULL,
    territory_area                  [varchar](8000) NULL,
    territory_region                [varchar](8000) NULL,
    territory_atu                   [varchar](8000) NULL,
    territory                       [varchar](8000) NULL,
    synapse_migration_target_flag   [bit]           NULL,
    synapse_migration_context       [varchar](8000) NULL,
    synapse_primary_workload        [varchar](8000) NULL,
    synapse_migration_status        [varchar](8000) NULL,
    created_date                    [datetime2](6)  NULL
)
GO

CREATE TABLE history.cat_account_comment (
    snapshot_date           [date]          NULL,
    annotation_id           [varchar](8000) NULL,
    account_id              [varchar](8000) NULL,
    created_on_date_time    [datetime2](6)  NULL,
    created_by              [varchar](8000) NULL,
    comment_subject         [varchar](8000) NULL,
    comment_text            [varchar](8000) NULL,
    created_date            [datetime2](6)  NULL
)
GO

CREATE TABLE history.factory_engagement (
    snapshot_date                       [varchar](max)  NULL,
    tpid                                [varchar](8000) NULL,
    msx_opportunity_id                  [varchar](max)  NULL,
    msx_milestone_number                [varchar](max)  NULL,
    project_name                        [varchar](max)  NULL,
    nomination_created_by               [varchar](max)  NULL,
    cftl_primary                        [varchar](max)  NULL,
    cftl_secondary                      [varchar](max)  NULL,
    csa_name                            [varchar](max)  NULL,
    csa_email                           [varchar](max)  NULL,
    specialist_name                     [varchar](max)  NULL,
    specialist_email                    [varchar](max)  NULL,
    partner_name                        [varchar](max)  NULL,
    partner_nominated                   [varchar](max)  NULL,
    nomination_created_date             [datetime2](6)  NULL,
    nomination_decline_date             [datetime2](6)  NULL,
    moved_to_block_date                 [datetime2](6)  NULL,
    nomination_declined_on_hold_reason  [varchar](max)  NULL,
    planned_end_date                    [datetime2](6)  NULL,
    planned_start_sate                  [datetime2](6)  NULL,
    actual_start_date                   [datetime2](6)  NULL,
    actual_end_date                     [datetime2](6)  NULL,
    migration_status                    [varchar](max)  NULL,
    solution_play                       [varchar](max)  NULL,
    factory_offering                    [varchar](max)  NULL,
    primary_migration_path              [varchar](max)  NULL,
    nomination_status                   [varchar](max)  NULL,
    current_state                       [varchar](max)  NULL,
    task_id                             [bigint]        NULL,
    phase                               [varchar](max)  NULL,
    total_acr                           [bigint]        NULL,
    mode_of_access                      [varchar](max)  NULL,
    status_summary                      [varchar](max)  NULL,
    created_date                        [datetime2](6)  NOT NULL
)
GO

CREATE TABLE history.partner_engagement (
    snapshot_date       [varchar](max)  NULL,
    tpid                [varchar](8000) NULL,
    customer            [varchar](max)  NULL,
    current_stage       [varchar](max)  NULL,
    current_stage_text  [varchar](max)  NULL,
    partnerone_name     [varchar](max)  NULL,
    notes               [varchar](max)  NULL,
    created_date        [datetime2](6)  NOT NULL
)
GO

DROP PROCEDURE IF EXISTS history.usp_copy_stage_to_history
GO

CREATE PROCEDURE history.usp_copy_stage_to_history
AS
BEGIN

    /* Remove the existing snaphot records from the history table if they exist */
    DELETE FROM history.account_acr WHERE snapshot_date IN (SELECT DISTINCT snapshot_date FROM stage.account_acr)
    DELETE FROM history.cat_account WHERE snapshot_date IN (SELECT DISTINCT snapshot_date FROM stage.cat_account)
    DELETE FROM history.cat_account_comment WHERE snapshot_date IN (SELECT DISTINCT snapshot_date FROM stage.cat_account_comment)
    DELETE FROM history.factory_engagement WHERE snapshot_date IN (SELECT DISTINCT snapshot_date FROM stage.factory_engagement)
    DELETE FROM history.partner_engagement WHERE snapshot_date IN (SELECT DISTINCT snapshot_date FROM stage.partner_engagement)

    /* Copy the data from stage to history */
    INSERT INTO history.account_acr SELECT * FROM stage.account_acr
    INSERT INTO history.cat_account SELECT * FROM stage.cat_account
    INSERT INTO history.cat_account_comment SELECT * FROM stage.cat_account_comment
    INSERT INTO history.factory_engagement SELECT * FROM stage.factory_engagement
    INSERT INTO history.partner_engagement SELECT * FROM stage.partner_engagement

END
GO

