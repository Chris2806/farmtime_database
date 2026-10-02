DROP VIEW IF EXISTS v_daily_exceptions;
DROP VIEW IF EXISTS v_attendance;
DROP VIEW IF EXISTS v_cost_analysis;


CREATE VIEW v_daily_exceptions AS
SELECT
    s.staff_id,
    s.first_name,
    s.last_name,
    r.shift_date,
    r.station_id AS rostered_station_id,
    MAX(CASE WHEN te.event_type = 'clock_in' THEN te.event_timestamp END) AS clock_in_time,
    MAX(CASE WHEN te.event_type = 'clock_out' THEN te.event_timestamp END) AS clock_out_time,
    MAX(CASE WHEN te.event_type = 'clock_in' THEN te.station_id END) AS actual_clock_in_station,
    CASE
        WHEN r.roster_id IS NULL
             AND MAX(CASE WHEN te.event_type = 'clock_in' THEN 1 ELSE 0 END) = 1
            THEN 'Unrostered attempt'
        WHEN r.station_id IS NOT NULL
             AND MAX(CASE WHEN te.event_type = 'clock_in' THEN te.station_id END) IS NOT NULL
             AND MAX(CASE WHEN te.event_type = 'clock_in' THEN te.station_id END) <> r.station_id
            THEN 'Clocked in at wrong station'
        WHEN MAX(CASE WHEN te.event_type = 'clock_in' THEN 1 ELSE 0 END) = 1
             AND MAX(CASE WHEN te.event_type = 'clock_out' THEN 1 ELSE 0 END) = 0
            THEN 'Missing clock-out'
        ELSE 'OK'
    END AS exception_type
FROM staff s
LEFT JOIN roster r ON r.staff_id = s.staff_id AND r.shift_date = CURRENT_DATE
LEFT JOIN time_events te ON te.staff_id = s.staff_id AND te.event_timestamp::date = CURRENT_DATE
GROUP BY s.staff_id, s.first_name, s.last_name, r.shift_date, r.roster_id, r.station_id;


CREATE VIEW v_attendance AS
WITH ev AS (
    SELECT staff_id,
           event_timestamp::date AS work_date,
           event_type,
           event_timestamp,
           LEAD(event_type) OVER (PARTITION BY staff_id, event_timestamp::date ORDER BY event_timestamp) AS next_type,
           LEAD(event_timestamp) OVER (PARTITION BY staff_id, event_timestamp::date ORDER BY event_timestamp) AS next_ts
    FROM time_events
),
daily AS (
    SELECT staff_id,
           work_date,
           MIN(event_timestamp) FILTER (WHERE event_type = 'clock_in') AS clock_in,
           MAX(event_timestamp) FILTER (WHERE event_type = 'clock_out') AS clock_out,
           COALESCE(SUM(EXTRACT(EPOCH FROM (next_ts - event_timestamp)) / 3600)
                    FILTER (WHERE event_type = 'break_start' AND next_type = 'break_end'), 0) AS break_hours
    FROM ev
    GROUP BY staff_id, work_date
)
SELECT COALESCE(d.staff_id, r.staff_id) AS staff_id,
       s.first_name || ' ' || s.last_name AS staff_name,
       COALESCE(d.work_date, r.shift_date) AS work_date,
       r.expected_hours AS rostered_hours,
       d.clock_in,
       d.clock_out,
       ROUND(d.break_hours::numeric, 2) AS break_hours,
       CASE WHEN d.clock_in IS NOT NULL AND d.clock_out IS NOT NULL
            THEN ROUND((EXTRACT(EPOCH FROM (d.clock_out - d.clock_in)) / 3600 - d.break_hours)::numeric, 2)
       END AS worked_hours,
       CASE WHEN d.clock_in IS NULL THEN 'Absent'
            WHEN d.clock_out IS NULL THEN 'Incomplete'
            ELSE 'Complete'
       END AS attendance_status
FROM daily d
FULL OUTER JOIN roster r ON r.staff_id = d.staff_id AND r.shift_date = d.work_date
JOIN staff s ON s.staff_id = COALESCE(d.staff_id, r.staff_id);


CREATE VIEW v_cost_analysis AS
SELECT p.payroll_id,
       p.period_start,
       p.period_end,
       s.staff_id,
       s.first_name || ' ' || s.last_name AS staff_name,
       s.role,
       s.contract_type,
       p.ordinary_hours,
       p.overtime_hours,
       p.weekend_hours,
       p.public_holiday_hours,
       ROUND(p.ordinary_hours * s.standard_rate, 2) AS ordinary_cost,
       ROUND(p.overtime_hours * s.overtime_rate, 2) AS overtime_cost,
       ROUND((p.weekend_hours + p.public_holiday_hours) * s.overtime_rate, 2) AS penalty_cost,
       p.total_pay,
       p.penalty_flag
FROM payroll_summary p
JOIN staff s ON s.staff_id = p.staff_id;


CREATE INDEX IF NOT EXISTS idx_roster_staff_date ON roster (staff_id, shift_date);
CREATE INDEX IF NOT EXISTS idx_time_events_not_synced ON time_events (staff_id, event_timestamp) WHERE sync_status <> 'Synced';
CREATE INDEX IF NOT EXISTS idx_time_events_unrostered ON time_events (staff_id, event_timestamp) WHERE is_unrostered = TRUE;
CREATE INDEX IF NOT EXISTS idx_exceptions_open ON exceptions (exception_date, staff_id) WHERE status = 'Open';
CREATE INDEX IF NOT EXISTS idx_time_adjustments_pending ON time_adjustments (requested_at) WHERE status = 'Pending';


SELECT * FROM v_daily_exceptions ORDER BY staff_id;