-- ============================================================
-- CodeSense — Initial Database Schema
-- V1__initial_schema.sql
-- ============================================================

-- ─── Repositories ────────────────────────────────────────
CREATE TABLE repositories (
    id              BIGSERIAL       PRIMARY KEY,
    github_id       BIGINT          NOT NULL UNIQUE,
    full_name       VARCHAR(255)    NOT NULL UNIQUE,   -- e.g. "owner/repo"
    owner           VARCHAR(128)    NOT NULL,
    name            VARCHAR(128)    NOT NULL,
    default_branch  VARCHAR(128)    NOT NULL DEFAULT 'main',
    installation_id BIGINT,                             -- GitHub App installation ID
    webhook_secret  VARCHAR(255),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_repositories_full_name ON repositories (full_name);

-- ─── Pull Requests ───────────────────────────────────────
CREATE TABLE pull_requests (
    id              BIGSERIAL       PRIMARY KEY,
    repository_id   BIGINT          NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    github_pr_id    BIGINT          NOT NULL,
    pr_number       INT             NOT NULL,
    title           VARCHAR(512)    NOT NULL,
    author          VARCHAR(128)    NOT NULL,
    head_sha        VARCHAR(64)     NOT NULL,
    base_branch     VARCHAR(128)    NOT NULL,
    head_branch     VARCHAR(128)    NOT NULL,
    status          VARCHAR(32)     NOT NULL DEFAULT 'OPEN',  -- OPEN, MERGED, CLOSED
    opened_at       TIMESTAMPTZ     NOT NULL,
    merged_at       TIMESTAMPTZ,
    closed_at       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_pull_requests_repo_pr UNIQUE (repository_id, github_pr_id)
);

CREATE INDEX idx_pull_requests_repo_id ON pull_requests (repository_id);
CREATE INDEX idx_pull_requests_status  ON pull_requests (status);

-- ─── Analysis Results ────────────────────────────────────
CREATE TABLE analysis_results (
    id              BIGSERIAL       PRIMARY KEY,
    pull_request_id BIGINT          NOT NULL REFERENCES pull_requests(id) ON DELETE CASCADE,
    head_sha        VARCHAR(64)     NOT NULL,
    risk_score      INT             NOT NULL CHECK (risk_score BETWEEN 0 AND 100),
    summary         TEXT,
    lint_findings   JSONB           NOT NULL DEFAULT '[]'::JSONB,
    security_findings JSONB         NOT NULL DEFAULT '[]'::JSONB,
    best_practice_findings JSONB    NOT NULL DEFAULT '[]'::JSONB,
    escalated       BOOLEAN         NOT NULL DEFAULT FALSE,
    analysis_duration_ms BIGINT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_analysis_results_pr_id ON analysis_results (pull_request_id);
CREATE INDEX idx_analysis_results_created ON analysis_results (created_at);

-- ─── Tech Debt Snapshots ─────────────────────────────────
CREATE TABLE techdebt_snapshots (
    id              BIGSERIAL       PRIMARY KEY,
    repository_id   BIGINT          NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    snapshot_date   DATE            NOT NULL,
    avg_risk_score  NUMERIC(5,2)    NOT NULL,
    total_issues    INT             NOT NULL DEFAULT 0,
    critical_issues INT             NOT NULL DEFAULT 0,
    high_issues     INT             NOT NULL DEFAULT 0,
    medium_issues   INT             NOT NULL DEFAULT 0,
    low_issues      INT             NOT NULL DEFAULT 0,
    metadata        JSONB           DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_techdebt_repo_date UNIQUE (repository_id, snapshot_date)
);

CREATE INDEX idx_techdebt_repo_date ON techdebt_snapshots (repository_id, snapshot_date);

-- ─── Changelog Entries ───────────────────────────────────
CREATE TABLE changelog_entries (
    id              BIGSERIAL       PRIMARY KEY,
    repository_id   BIGINT          NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    pull_request_id BIGINT          REFERENCES pull_requests(id) ON DELETE SET NULL,
    category        VARCHAR(32)     NOT NULL,   -- Added, Fixed, Changed, Removed
    entry_text      TEXT            NOT NULL,
    version_tag     VARCHAR(64),
    generated_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_changelog_repo_id     ON changelog_entries (repository_id);
CREATE INDEX idx_changelog_generated   ON changelog_entries (generated_at DESC);
