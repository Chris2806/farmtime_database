TRUNCATE TABLE exceptions, time_adjustments, breaks, payroll_summary, time_events, compliance_rules, roster, break_reasons, stations, staff, audit_logs RESTART IDENTITY CASCADE;

INSERT INTO stations (name, location, id_type) VALUES
('Main Gate', 'Farm Entrance', 'QR'),
('Packing Shed', 'Shed 2', 'PIN');

INSERT INTO staff (first_name, last_name, contract_type, standard_hours, role, standard_rate, overtime_rate, credential_ref) VALUES
('Sam', 'Lee', 'Casual', 38, 'Farm Hand', 28.50, 42.75, 'QR-1001'),
('Jess', 'Nguyen', 'Full Time', 38, 'Supervisor', 32.00, 48.00, 'QR-1002'),
('Priya', 'Patel', 'Part Time', 20, 'Packing', 27.00, 40.50, 'PIN-2001');

INSERT INTO roster (staff_id, shift_date, start_time, expected_hours, station_id) VALUES
(1, CURRENT_DATE, '07:00', 8, 1),
(2, CURRENT_DATE, '07:00', 8, 1),
(3, CURRENT_DATE, '09:00', 5, 2);

INSERT INTO break_reasons (label, is_paid) VALUES
('Meal', FALSE), ('Rest', TRUE), ('Personal', FALSE), ('Emergency', TRUE), ('Other', FALSE);

INSERT INTO compliance_rules (rule_name, max_hours_without_break, daily_overtime_threshold, weekly_overtime_threshold) VALUES
('Standard AU Rule', 5, 8, 38),
('PID Break Rule', 4, 8, 38);

-- Sam: clocks in, forgets to clock out (demonstrates a missing clock-out exception)
INSERT INTO time_events (staff_id, station_id, event_type, event_timestamp, captured_at, synced_at, created_by, rule_id) VALUES
(1, 1, 'clock_in', CURRENT_DATE + TIME '07:02', CURRENT_DATE + TIME '07:02', CURRENT_DATE + TIME '07:03', 'system', 1);

-- Jess: full day worked with a break, clocked out normally, last event not yet synced (demonstrates offline case)
INSERT INTO time_events (staff_id, station_id, event_type, event_timestamp, captured_at, synced_at, created_by, rule_id) VALUES
(2, 1, 'clock_in', CURRENT_DATE + TIME '06:58', CURRENT_DATE + TIME '06:58', CURRENT_DATE + TIME '06:59', 'system', 1),
(2, 1, 'break_start', CURRENT_DATE + TIME '11:00', CURRENT_DATE + TIME '11:00', CURRENT_DATE + TIME '11:01', 'system', 1),
(2, 1, 'break_end', CURRENT_DATE + TIME '11:30', CURRENT_DATE + TIME '11:30', CURRENT_DATE + TIME '11:31', 'system', 1),
(2, 1, 'clock_out', CURRENT_DATE + TIME '15:05', CURRENT_DATE + TIME '15:05', NULL, 'system', 1);

-- Priya: clocks in at Main Gate instead of her rostered Packing Shed (demonstrates an unrostered/wrong-station attempt)
INSERT INTO time_events (staff_id, station_id, event_type, event_timestamp, captured_at, synced_at, is_override, override_reason, created_by, rule_id) VALUES
(3, 1, 'clock_in', CURRENT_DATE + TIME '09:05', CURRENT_DATE + TIME '09:05', CURRENT_DATE + TIME '09:06', FALSE, NULL, 'system', 1);

-- Link Jess's break event to a reason (Meal)
INSERT INTO breaks (event_id, reason_id, note)
SELECT event_id, 1, 'Lunch' FROM time_events WHERE staff_id = 2 AND event_type = 'break_start';

-- Exceptions: stored records that a manager can review
INSERT INTO exceptions (staff_id, event_id, rule_id, exception_type, manager_notified, notes)
SELECT 1, event_id, NULL, 'Missing clock-out', FALSE, 'Clocked in 07:02, no clock-out recorded'
FROM time_events WHERE staff_id = 1 AND event_type = 'clock_in';

INSERT INTO exceptions (staff_id, event_id, rule_id, exception_type, manager_notified, notes)
SELECT 2, event_id, 2, 'Break overdue', TRUE, 'Break started 4h02m after clock-in, over the 4 hour limit'
FROM time_events WHERE staff_id = 2 AND event_type = 'break_start';

INSERT INTO exceptions (staff_id, event_id, rule_id, exception_type, manager_notified, notes)
SELECT 3, event_id, NULL, 'Clocked in at wrong station', TRUE, 'Rostered at Packing Shed, clocked in at Main Gate'
FROM time_events WHERE staff_id = 3 AND event_type = 'clock_in';

-- Mark events that never reached the server as pending sync
UPDATE time_events SET sync_status = 'Pending' WHERE synced_at IS NULL;

-- Pending request: Sam forgot to clock out, waiting for manager approval
INSERT INTO time_adjustments (staff_id, event_id, action, new_timestamp, reason, override_method, requested_by)
SELECT 1, event_id, 'ADD', CURRENT_DATE + TIME '15:30', 'Forgot to clock out, confirmed with supervisor', 'Admin Portal', 'Office Admin'
FROM time_events WHERE staff_id = 1 AND event_type = 'clock_in';

-- Approved request: Jess's clock-out time corrected
INSERT INTO time_adjustments (staff_id, event_id, action, old_timestamp, new_timestamp, reason, override_method, requested_by, approver, status, decided_at)
SELECT 2, event_id, 'EDIT', event_timestamp, CURRENT_DATE + TIME '15:00', 'Corrected clock-out time after supervisor check', 'Admin Portal', 'Office Admin', 'Farm Manager', 'Approved', CURRENT_DATE + TIME '15:30'
FROM time_events WHERE staff_id = 2 AND event_type = 'clock_out';

-- Apply the approved change to the clock event
UPDATE time_events
SET event_timestamp = CURRENT_DATE + TIME '15:00', is_override = TRUE,
    override_reason = 'Corrected clock-out time after supervisor check', override_method = 'Admin Portal'
WHERE staff_id = 2 AND event_type = 'clock_out';

-- Audit trail for every approved adjustment
INSERT INTO audit_logs (table_name, record_id, action, reason, changed_by, adjustment_id)
SELECT 'time_events', event_id, 'UPDATE', reason, approver, adjustment_id
FROM time_adjustments WHERE status = 'Approved';

-- Phase 1 Step 4: roles, patterned hours, registration PIN, roster team/site
INSERT INTO staff (first_name, last_name, contract_type, standard_hours, role, standard_rate, overtime_rate, credential_ref, system_role) VALUES
('Alex', 'Morgan', 'Full Time', 38, 'Office Admin', 35.00, 52.50, 'PIN-3001', 'Office Admin'),
('Taylor', 'Brooks', 'Full Time', 38, 'Roster Admin', 34.00, 51.00, 'PIN-3002', 'Roster Admin');

UPDATE staff SET system_role = 'Manager/Supervisor' WHERE staff_id = 2;

UPDATE staff SET hours_type = 'Patterned', pattern_days = 'Mon-Thu', pattern_start = '09:00', pattern_end = '14:00' WHERE staff_id = 3;

UPDATE staff SET registration_pin = '482916', pin_expires_at = now() + interval '72 hours' WHERE staff_id = 1;

UPDATE roster SET team = 'Orchard', site = 'Main Farm' WHERE staff_id IN (1, 2);
UPDATE roster SET team = 'Packing', site = 'Shed 2' WHERE staff_id = 3;

-- Verification: confirm row counts match expectations
SELECT 'staff' AS tbl, COUNT(*) FROM staff
UNION ALL
SELECT 'roster', COUNT(*) FROM roster
UNION ALL
SELECT 'time_events', COUNT(*) FROM time_events
UNION ALL
SELECT 'breaks', COUNT(*) FROM breaks
UNION ALL
SELECT 'stations', COUNT(*) FROM stations
UNION ALL
SELECT 'break_reasons', COUNT(*) FROM break_reasons
UNION ALL
SELECT 'compliance_rules', COUNT(*) FROM compliance_rules
UNION ALL
SELECT 'exceptions', COUNT(*) FROM exceptions
UNION ALL
SELECT 'time_adjustments', COUNT(*) FROM time_adjustments
UNION ALL
SELECT 'audit_logs', COUNT(*) FROM audit_logs;