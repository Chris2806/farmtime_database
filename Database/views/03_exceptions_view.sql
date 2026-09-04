DROP VIEW IF EXISTS v_daily_exceptions;

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

SELECT * FROM v_daily_exceptions ORDER BY staff_id;