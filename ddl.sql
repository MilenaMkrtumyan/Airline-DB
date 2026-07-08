--DDL

DROP TABLE IF EXISTS Flight_Crew CASCADE;
DROP TABLE IF EXISTS Baggage CASCADE;
DROP TABLE IF EXISTS Ticket CASCADE;
DROP TABLE IF EXISTS Flight CASCADE;
DROP TABLE IF EXISTS Reservation CASCADE;
DROP TABLE IF EXISTS Crew CASCADE;
DROP TABLE IF EXISTS Passenger CASCADE;
DROP TABLE IF EXISTS Aircraft CASCADE;
DROP TABLE IF EXISTS Airport CASCADE;

-- TRUNCATE TABLE Flight_Crew RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE Baggage RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE Ticket RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE Flight RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE Reservation RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE Crew RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE Passenger RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE Aircraft RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE Airport RESTART IDENTITY CASCADE;

CREATE TABLE Airport (
    airport_id SERIAL PRIMARY KEY,
    iata_code CHAR(3) NOT NULL,
    airport_name VARCHAR(100) NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    CONSTRAINT uq_airport_iata_code UNIQUE (iata_code),
    CONSTRAINT chk_airport_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_airport_longitude CHECK (longitude BETWEEN -180 AND 180));

CREATE TABLE Aircraft (
    aircraft_id SERIAL PRIMARY KEY,
    registration_no VARCHAR(20) NOT NULL,
    model VARCHAR(50) NOT NULL,
    seat_capacity INT NOT NULL,
    manufacture_year INT,
    aircraft_status VARCHAR(20) DEFAULT 'Active',
    CONSTRAINT uq_aircraft_registration UNIQUE (registration_no),
    CONSTRAINT chk_aircraft_capacity CHECK (seat_capacity > 0),
    CONSTRAINT chk_aircraft_manufacture_year CHECK (manufacture_year >= 1900),
    CONSTRAINT chk_aircraft_status CHECK (aircraft_status IN ('Active', 'Maintenance', 'Stored')));
ALTER TABLE Aircraft ADD COLUMN last_maintenance_date DATE;
ALTER TABLE Aircraft ADD COLUMN next_maintenance_date DATE;
ALTER TABLE Aircraft ADD CONSTRAINT chk_maintenance_dates CHECK (next_maintenance_date >= last_maintenance_date);

CREATE TABLE Passenger (
    passenger_id SERIAL PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    lname VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone_number VARCHAR(30),
    passport_no VARCHAR(30) NOT NULL,
    passport_expiry DATE NOT NULL,
    date_of_birth DATE NOT NULL,
    nationality VARCHAR(100) NOT NULL,
    CONSTRAINT uq_passenger_email UNIQUE (email),
    CONSTRAINT uq_passenger_passport UNIQUE (passport_no),
    CONSTRAINT chk_passenger_email CHECK (email LIKE '_%@_%._%'));
ALTER TABLE Passenger RENAME CONSTRAINT chk_passenger_email TO chk_passenger_email_format;
 
CREATE TABLE Crew (
    crew_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    crew_role VARCHAR(30) NOT NULL,
    license_no VARCHAR(50),
    airport_id INT,
    phone_number VARCHAR(30),
    email VARCHAR(100),
    CONSTRAINT uq_crew_license UNIQUE (license_no),
    CONSTRAINT uq_crew_email UNIQUE (email),
    CONSTRAINT fk_crew_airport FOREIGN KEY (airport_id) REFERENCES Airport(airport_id),
    CONSTRAINT chk_crew_role CHECK (crew_role IN ('Captain', 'First Officer', 'Cabin Crew Lead', 'Cabin Crew')));
ALTER TABLE Crew ADD COLUMN crew_data JSONB;

CREATE TABLE Reservation (
    reservation_id SERIAL PRIMARY KEY,
    passenger_id INT,
    reference_code CHAR(6) NOT NULL,
    reservation_timestamp TIMESTAMPTZ DEFAULT now(),
    total_price DECIMAL(10,2) NOT NULL,
    channel VARCHAR(20),
    reservation_status VARCHAR(20) DEFAULT 'Confirmed',
    CONSTRAINT uq_reservation_reference UNIQUE (reference_code),
    CONSTRAINT chk_reservation_total_price CHECK (total_price >= 0),
    CONSTRAINT fk_reservation_passenger FOREIGN KEY (passenger_id) REFERENCES Passenger(passenger_id),
    CONSTRAINT chk_reservation_status CHECK (reservation_status IN ('Confirmed', 'Pending', 'Cancelled')));
ALTER TABLE Reservation ALTER COLUMN reference_code TYPE VARCHAR(10);

CREATE TABLE Flight (
    flight_id SERIAL PRIMARY KEY,
    flight_number VARCHAR(10) NOT NULL,
    aircraft_id INT,
    departure_airport_id INT,
    arrival_airport_id INT,
    departure_time TIMESTAMPTZ NOT NULL,
    arrival_time TIMESTAMPTZ NOT NULL,
    actual_departure TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    flight_status VARCHAR(20) DEFAULT 'Scheduled',
    CONSTRAINT fk_flight_aircraft FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id),
    CONSTRAINT fk_flight_departure_airport FOREIGN KEY (departure_airport_id) REFERENCES Airport(airport_id),
    CONSTRAINT fk_flight_arrival_airport FOREIGN KEY (arrival_airport_id) REFERENCES Airport(airport_id),
    CONSTRAINT chk_flight_route CHECK (departure_airport_id <> arrival_airport_id),
    CONSTRAINT chk_flight_times CHECK (arrival_time > departure_time),
    CONSTRAINT chk_flight_status CHECK (flight_status IN ('Scheduled', 'Delayed', 'Departed', 'Arrived', 'Cancelled')));
ALTER TABLE Flight ADD COLUMN flight_duration INTERVAL GENERATED ALWAYS AS (arrival_time - departure_time) STORED;

CREATE TABLE Ticket (
    ticket_id SERIAL PRIMARY KEY,
    reservation_id INT,
    passenger_id INT,
    flight_id INT,
    seat_number VARCHAR(10) NOT NULL,
    cabin_class VARCHAR(20) NOT NULL,
    fare DECIMAL(10,2) NOT NULL,
    ticket_status VARCHAR(20) DEFAULT 'Valid',
    checked_in BOOLEAN DEFAULT FALSE, 
    CONSTRAINT fk_ticket_reservation FOREIGN KEY (reservation_id) REFERENCES Reservation(reservation_id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_passenger FOREIGN KEY (passenger_id) REFERENCES Passenger(passenger_id),
    CONSTRAINT fk_ticket_flight FOREIGN KEY (flight_id) REFERENCES Flight(flight_id),
    CONSTRAINT chk_ticket_fare CHECK (fare >= 0),
    CONSTRAINT uq_ticket_passenger_flight UNIQUE (passenger_id, flight_id),
    CONSTRAINT chk_ticket_cabin_class CHECK (cabin_class IN ('Economy', 'Business', 'First')),
    CONSTRAINT chk_ticket_status CHECK (ticket_status IN ('Valid', 'Used', 'Refunded')));

CREATE TABLE Baggage (
    baggage_id SERIAL PRIMARY KEY,
    ticket_id INT,
    tag_number VARCHAR(20) NOT NULL,
    weight_kg DECIMAL(5,2) NOT NULL,
    is_oversized BOOLEAN,
    baggage_status VARCHAR(20) DEFAULT 'Checked-In', 
    CONSTRAINT uq_baggage_tag UNIQUE (tag_number),
    CONSTRAINT fk_baggage_ticket FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id) ON DELETE CASCADE,
    CONSTRAINT chk_baggage_weight CHECK (weight_kg > 0),
    CONSTRAINT chk_baggage_status CHECK (baggage_status IN ('Checked-In', 'Loaded', 'Transited', 'Claimed', 'Lost')));
ALTER TABLE Baggage ADD COLUMN checked_in_time TIMESTAMPTZ DEFAULT now(); 

CREATE TABLE Flight_Crew (
    flight_id INT,
    crew_id INT,
    PRIMARY KEY (flight_id, crew_id),
    CONSTRAINT fk_flightcrew_flight FOREIGN KEY (flight_id) REFERENCES Flight(flight_id) ON DELETE CASCADE,
    CONSTRAINT fk_flightcrew_crew FOREIGN KEY (crew_id) REFERENCES Crew(crew_id) ON DELETE CASCADE);

 
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE Ticket ADD COLUMN departure_time TIMESTAMPTZ;
ALTER TABLE Ticket ADD COLUMN arrival_time   TIMESTAMPTZ;


-- Order (see in the file trigger) 
-- 4. Constraint  

-- ALTER TABLE Ticket DROP CONSTRAINT excl_ticket_passenger_overlap;
ALTER TABLE Ticket ADD CONSTRAINT excl_ticket_passenger_overlap
EXCLUDE USING gist (
    passenger_id WITH =,
    tstzrange(departure_time, arrival_time, '[)') WITH &&
) WHERE (ticket_status <> 'Refunded');

 
 