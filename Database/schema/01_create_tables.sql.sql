DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS payroll_summary CASCADE;
DROP TABLE IF EXISTS breaks CASCADE;
DROP TABLE IF EXISTS break_reasons CASCADE;
DROP TABLE IF EXISTS time_events CASCADE;
DROP TABLE IF EXISTS compliance_rules CASCADE;
DROP TABLE IF EXISTS roster CASCADE;
DROP TABLE IF EXISTS stations CASCADE;
DROP TABLE IF EXISTS staff CASCADE;

CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN ('Casual','Full Time','Part Time')),
    standard_hours DECIMAL(5,2) NOT NULL DEFAULT 38,
    role VARCHAR(50),
    standard_rate DECIMAL(8,2) NOT NULL,
    overtime_rate DECIMAL(8,2) NOT NULL,
    credential_ref VARCHAR(100),
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE stations (
    station_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    id_type VARCHAR(20) CHECK (id_type IN ('QR','PIN','Face','Fingerprint'))
);

CREATE TABLE roster (
    roster_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL REFERENCES staff(staff_id),
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    expected_hours DECIMAL(4,2) NOT NULL,
    station_id INT REFERENCES stations(station_id)
);

CREATE TABLE compliance_rules (
    rule_id SERIAL PRIMARY KEY,
    rule_name VARCHAR(50) NOT NULL,
    max_hours_without_break DECIMAL(4,2),
    daily_overtime_threshold DECIMAL(4,2),
    weekly_overtime_threshold DECIMAL(4,2)
);

CREATE TABLE time_events (
    event_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL REFERENCES staff(staff_id),
    station_id INT REFERENCES stations(station_id),
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('clock_in','clock_out','break_start','break_end')),
    event_timestamp TIMESTAMP NOT NULL,
    captured_at TIMESTAMP NOT NULL DEFAULT now(),
    synced_at TIMESTAMP,
    is_override BOOLEAN DEFAULT FALSE,
    override_reason VARCHAR(200),
    created_by VARCHAR(50),
    rule_id INT REFERENCES compliance_rules(rule_id)
);

CREATE TABLE break_reasons (
    reason_id SERIAL PRIMARY KEY,
    label VARCHAR(30) NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE
);

CREATE TABLE breaks (
    break_id SERIAL PRIMARY KEY,
    event_id INT NOT NULL REFERENCES time_events(event_id),
    reason_id INT REFERENCES break_reasons(reason_id),
    note VARCHAR(200)
);

CREATE TABLE payroll_summary (
    payroll_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL REFERENCES staff(staff_id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    ordinary_hours DECIMAL(6,2),
    overtime_hours DECIMAL(6,2),
    total_pay DECIMAL(10,2)
);

CREATE TABLE audit_logs (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    reason VARCHAR(200) NOT NULL,
    changed_by VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP DEFAULT now()
);