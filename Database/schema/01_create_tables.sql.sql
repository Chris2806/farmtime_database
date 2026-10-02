DROP TABLE IF EXISTS time_adjustments CASCADE;
DROP TABLE IF EXISTS exceptions CASCADE;
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
    system_role VARCHAR(20) NOT NULL DEFAULT 'Worker' CHECK (system_role IN ('Office Admin','Roster Admin','Manager/Supervisor','Worker')),
    hours_type VARCHAR(10) NOT NULL DEFAULT 'Weekly' CHECK (hours_type IN ('Weekly','Patterned')),
    pattern_days VARCHAR(30),
    pattern_start TIME,
    pattern_end TIME,
    registration_pin VARCHAR(10),
    pin_expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    CHECK (hours_type = 'Weekly' OR (pattern_days IS NOT NULL AND pattern_start IS NOT NULL AND pattern_end IS NOT NULL)),
    CHECK (registration_pin IS NULL OR pin_expires_at IS NOT NULL)
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
    team VARCHAR(50),
    site VARCHAR(50),
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
    override_method VARCHAR(20) CHECK (override_method IN ('Admin Portal','Supervisor PIN')),
    is_unrostered BOOLEAN DEFAULT FALSE,
    sync_status VARCHAR(20) NOT NULL DEFAULT 'Synced' CHECK (sync_status IN ('Pending','Synced','Failed')),
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


CREATE TABLE exceptions (
    exception_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL REFERENCES staff(staff_id),
    event_id INT REFERENCES time_events(event_id),
    rule_id INT REFERENCES compliance_rules(rule_id),
    exception_type VARCHAR(40) NOT NULL CHECK (exception_type IN (
        'Missing clock-out',
        'Break overdue',
        'Unrostered attempt',
        'Clocked in at wrong station'
    )),
    exception_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (status IN ('Open','Reviewed','Resolved')),
    manager_notified BOOLEAN DEFAULT FALSE,
    detected_at TIMESTAMP DEFAULT now(),
    notes VARCHAR(200)
);


CREATE TABLE time_adjustments (
    adjustment_id SERIAL PRIMARY KEY,
    staff_id INT NOT NULL REFERENCES staff(staff_id),
    event_id INT REFERENCES time_events(event_id),
    action VARCHAR(10) NOT NULL CHECK (action IN ('ADD','EDIT','DELETE')),
    old_timestamp TIMESTAMP,
    new_timestamp TIMESTAMP,
    reason VARCHAR(200) NOT NULL,
    override_method VARCHAR(20) CHECK (override_method IN ('Admin Portal','Supervisor PIN')),
    requested_by VARCHAR(50) NOT NULL,
    requested_at TIMESTAMP NOT NULL DEFAULT now(),
    approver VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Approved','Rejected')),
    decided_at TIMESTAMP,
    CHECK (status = 'Pending' OR (approver IS NOT NULL AND decided_at IS NOT NULL)),
    CHECK (approver IS NULL OR approver <> requested_by)
);


CREATE TABLE audit_logs (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    reason VARCHAR(200) NOT NULL,
    changed_by VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP DEFAULT now(),
    adjustment_id INT REFERENCES time_adjustments(adjustment_id)
);