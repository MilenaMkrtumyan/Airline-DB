-- DML 

-- BEGIN;


ALTER TABLE Ticket DISABLE TRIGGER trg_update_reservation_price;
-- NOTE: ddl.sql creates trg_update_reservation_price, which fires
-- an individual UPDATE on Reservation for every row inserted into Ticket.
-- With 1.2M ticket rows that's 1.2M row-by-row updates, which will noticeably
-- slow this script down. We can disable it for the bulk load and re-enable it 
-- right after.
 
INSERT INTO Airport (iata_code, airport_name, latitude, longitude, city, country)
VALUES
('EVN','Zvartnots International Airport',40.1473,44.3959,'Yerevan','Armenia'),
('LAX','Los Angeles International Airport',33.9416,-118.4085,'Los Angeles','USA'),
('JFK','John F. Kennedy International Airport',40.6413,-73.7781,'New York','USA'),
('CDG','Charles de Gaulle Airport',49.0097,2.5479,'Paris','France'),
('LHR','Heathrow Airport',51.4700,-0.4543,'London','United Kingdom'),
('FRA','Frankfurt Airport',50.0379,8.5622,'Frankfurt','Germany'),
('DXB','Dubai International Airport',25.2532,55.3657,'Dubai','UAE'),
('DOH','Hamad International Airport',25.2736,51.6081,'Doha','Qatar'),
('AMS','Amsterdam Schiphol Airport',52.3105,4.7683,'Amsterdam','Netherlands'),
('FCO','Leonardo da Vinci Airport',41.8003,12.2389,'Rome','Italy');

 
INSERT INTO Aircraft (registration_no,model,seat_capacity,manufacture_year,aircraft_status,last_maintenance_date,next_maintenance_date)
SELECT
    'No-' || LPAD(gs::text,4,'0'),
    (ARRAY['Airbus A320', 'Airbus A321', 'Airbus A350', 'Boeing 737', 'Boeing 777', 'Boeing 787'])[1 + (gs % 6)],
    150 + (gs % 250),
    2005 + (gs % 20),
    'Active',
    CURRENT_DATE - ((gs % 180) || ' days')::interval,
    CURRENT_DATE + ((180 + gs % 180) || ' days')::interval
FROM generate_series(1,300) gs;

 
-- INSERT INTO Crew (full_name,crew_role,license_no,airport_id,phone_number,email,crew_data)
-- SELECT 'Crew Member ' || gs,
--     (ARRAY['Captain', 'First Officer', 'Cabin Crew', 'Cabin Crew Lead'])[1 + (gs % 4)],
--     'LIC' || LPAD(gs::text,6,'0'),
--     (gs % 10) + 1,
--     '+374771' || LPAD(gs::text,5,'0'),
--     'crew' || gs || '@airline.com',
--     jsonb_build_object('languages', ARRAY['English','Armenian'])
-- FROM generate_series(1,5000) gs;


INSERT INTO Crew (full_name,crew_role,license_no,airport_id,phone_number,email,crew_data)
SELECT full_name, crew_role, license_no, airport_id, phone_number, email,
    jsonb_build_object(
        'crew_id', gs,
        'full_name', full_name,
        'crew_role', crew_role,
        'license_no', license_no,
        'airport_id', airport_id,
        'phone_number', phone_number,
        'email', email)
FROM (SELECT gs,
        'Crew Member ' || gs AS full_name,
        (ARRAY['Captain', 'First Officer', 'Cabin Crew', 'Cabin Crew Lead'])[1 + (gs % 4)] AS crew_role,
        'LIC' || LPAD(gs::text,6,'0') AS license_no,
        (gs % 10) + 1 AS airport_id,
        '+374771' || LPAD(gs::text,5,'0') AS phone_number,
        'crew' || gs || '@airline.com' AS email
    FROM generate_series(1,5000) gs) c;
 
 
INSERT INTO Passenger (fname,lname,email,phone_number,passport_no,passport_expiry,date_of_birth,nationality)
SELECT  (ARRAY['John','Emma','Michael','Anna','David','Sophia','Daniel','Maria','James','Olivia'])[1 + (gs % 10)],
        (ARRAY['Smith','Johnson','Brown','Miller','Wilson','Taylor','Thomas','Clark','Lewis','Walker'])[1 + ((gs/10) % 10)],
        'passenger' || gs || '@gmail.com',
        '+37494' || LPAD((100000 + gs % 900000)::text,6,'0'),
        'P' || LPAD(gs::text,8,'0'),
        CURRENT_DATE + ((gs % 3000) || ' days')::interval,
        DATE '1960-01-01' + ((gs % 18000) || ' days')::interval,
        (ARRAY['Armenian', 'American', 'French', 'German', 'Italian', 'British'])[1 + (gs % 6)]
FROM generate_series(1,1200000) gs;

 
INSERT INTO Reservation(passenger_id,reference_code,reservation_timestamp,total_price,channel,reservation_status)
SELECT gs,
    'R' || LPAD(gs::text,7,'0'),
    NOW() - ((gs % 365) || ' days')::interval,
    ROUND((80 + random()*1200)::numeric,2),
    (ARRAY['Website','Mobile App','Travel Agency'])[1 + (gs % 3)],
    (ARRAY['Confirmed','Pending', 'Cancelled'])[1 + (gs % 3)]
FROM generate_series(1,1200000) gs;

 
INSERT INTO Flight(flight_number,aircraft_id,departure_airport_id,arrival_airport_id,departure_time,arrival_time,actual_departure,actual_arrival,flight_status)
SELECT 'FL' || LPAD(gs::text,5,'0'),
    (gs % 300)+1,
    (gs % 10)+1,
    ((gs+3)%10)+1,
    TIMESTAMPTZ '2025-01-01' + (gs || ' hours')::interval,
    TIMESTAMPTZ '2025-01-01' + (gs || ' hours')::interval + ((2 + gs % 8) || ' hours')::interval,
    NULL,
    NULL,
    'Scheduled'
FROM generate_series(1,50000) gs;

 
-- passenger_id = gs is unique per row here, so every seeded
-- ticket belongs to a different passenger. This is what keeps
-- excl_ticket_passenger_overlap from rejecting any row during this load.
 
INSERT INTO Ticket(reservation_id,passenger_id,flight_id,seat_number,cabin_class,fare,ticket_status,checked_in)
SELECT  gs,
        gs,
        (gs % 50000)+1,
        (1 + gs % 40) || CHR(65 + gs % 6),
        (ARRAY['Economy','Business','First'])[1 + (gs % 3)],
        ROUND((100 + random()*900)::numeric,2),
        'Valid',
        (gs % 2 = 0)
FROM generate_series(1,1200000) gs;

 
INSERT INTO Baggage(ticket_id,tag_number,weight_kg,is_oversized,baggage_status)
SELECT gs,
    'BG' || LPAD(gs::text,10,'0'),
    ROUND((5 + random()*28)::numeric,2),
    (random()<0.1),
    (ARRAY['Checked-In','Loaded','Transited','Claimed'])[1 + (gs % 4)]
FROM generate_series(1,1100000) gs;

 
INSERT INTO Flight_Crew(flight_id,crew_id)
SELECT   f,
        ((f + c) % 5000) + 1
FROM generate_series(1,50000) f
CROSS JOIN generate_series(1,5) c;

 
UPDATE Ticket t
SET departure_time = f.departure_time,
    arrival_time   = f.arrival_time
FROM Flight f
WHERE t.flight_id = f.flight_id;

ALTER TABLE Ticket ENABLE TRIGGER trg_update_reservation_price;


------------------------------------------------------------------ 
UPDATE Reservation
SET reservation_status = 'Cancelled',
    reservation_timestamp = NOW() - INTERVAL '2 years'
WHERE reservation_id <= 5000;

DELETE FROM Reservation
WHERE reservation_status = 'Cancelled'
  AND reservation_timestamp < NOW() - INTERVAL '2 years'
  AND total_price < 300;

INSERT INTO Aircraft (registration_no, model, seat_capacity, manufacture_year,aircraft_status, last_maintenance_date, next_maintenance_date)
VALUES ('No-0001', 'Airbus A321', 220, 2023,'Maintenance', CURRENT_DATE, CURRENT_DATE + INTERVAL '180 days')
ON CONFLICT (registration_no)
DO UPDATE
SET
    aircraft_status = EXCLUDED.aircraft_status,
    last_maintenance_date = EXCLUDED.last_maintenance_date,
    next_maintenance_date = EXCLUDED.next_maintenance_date;

INSERT INTO Passenger(fname, lname, email, phone_number, passport_no, passport_expiry, date_of_birth, nationality)
VALUES ('John', 'Smith', 'passenger1@gmail.com', '+37494000000','PX999999', '2032-12-31', '1995-05-10', 'Armenian')
ON CONFLICT (email) DO NOTHING;

UPDATE Reservation
SET reservation_status =
CASE
    WHEN reservation_id % 25 = 0 THEN 'Cancelled'
    WHEN reservation_id % 10 = 0 THEN 'Pending'
    ELSE 'Confirmed'
END
WHERE reservation_id > 5000;

UPDATE Flight
SET flight_status =
CASE
    WHEN flight_id % 50 = 0 THEN 'Cancelled'
    WHEN flight_id % 15 = 0 THEN 'Delayed'
    WHEN flight_id % 5 = 0 THEN 'Arrived'
    WHEN flight_id % 3 = 0 THEN 'Departed'
    ELSE 'Scheduled'
END;

UPDATE Ticket
SET fare =
CASE cabin_class
    WHEN 'Economy' THEN ROUND((100 + random()*300)::numeric,2)
    WHEN 'Business' THEN ROUND((500 + random()*700)::numeric,2)
    WHEN 'First' THEN ROUND((1200 + random()*1500)::numeric,2)
END;

UPDATE Baggage
SET baggage_status = 'Lost'
WHERE baggage_id % 1000 = 0;

UPDATE Baggage
SET is_oversized = TRUE,
    weight_kg = 35
WHERE baggage_id % 250 = 0;

INSERT INTO Flight (flight_number, aircraft_id, departure_airport_id, arrival_airport_id, departure_time, arrival_time, actual_departure, actual_arrival, flight_status)
VALUES
('LONG001',  1,  1,  2, '2025-06-01 08:00:00+00', '2025-06-01 18:30:00+00', '2025-06-01 08:10:00+00', '2025-06-01 18:40:00+00', 'Arrived'),
('LONG002',  2,  2,  4, '2025-06-02 10:00:00+00', '2025-06-02 21:45:00+00', NULL, NULL, 'Scheduled'),
('LONG003',  3,  3,  5, '2025-06-03 06:30:00+00', '2025-06-03 17:15:00+00', '2025-06-03 06:45:00+00', '2025-06-03 17:30:00+00', 'Arrived'),
('LONG004',  4,  4,  7, '2025-06-04 14:00:00+00', '2025-06-05 01:30:00+00', NULL, NULL, 'Scheduled'),
('LONG005',  5,  5,  9, '2025-06-05 09:00:00+00', '2025-06-05 19:20:00+00', '2025-06-05 09:05:00+00', '2025-06-05 19:35:00+00', 'Arrived'),
('LONG006',  6,  6,  3, '2025-06-06 12:00:00+00', '2025-06-06 22:45:00+00', NULL, NULL, 'Delayed'),
('LONG007',  7,  7, 10, '2025-06-07 07:30:00+00', '2025-06-07 18:15:00+00', '2025-06-07 08:00:00+00', '2025-06-07 18:40:00+00', 'Arrived'),
('LONG008',  8,  8,  1, '2025-06-08 16:00:00+00', '2025-06-09 03:30:00+00', NULL, NULL, 'Scheduled'),
('LONG009',  9,  9,  6, '2025-06-09 11:00:00+00', '2025-06-09 22:20:00+00', '2025-06-09 11:20:00+00', '2025-06-09 22:45:00+00', 'Arrived'),
('LONG010', 10, 10,  2, '2025-06-10 05:00:00+00', '2025-06-10 15:30:00+00', NULL, NULL, 'Scheduled');

UPDATE Flight SET arrival_airport_id =
CASE
    WHEN flight_id % 5 = 0 THEN 7   -- DXB
    WHEN flight_id % 5 = 1 THEN 5   -- LHR
    WHEN flight_id % 5 = 2 THEN 4   -- CDG
    WHEN flight_id % 5 = 3 THEN 6   -- FRA
    ELSE arrival_airport_id
END;
  

-- COMMIT;

-- ROLLBACK;
