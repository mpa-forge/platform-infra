INSERT INTO bootstrap_records (record_key, record_value)
VALUES
    ('stack_version', 'phase-1'),
    ('seed_source', 'platform-infra/local/postgres-init')
ON CONFLICT (record_key) DO UPDATE
SET
    record_value = EXCLUDED.record_value;
