-- DCL

BEGIN;

-- We check whether a row with that name already exists in pg_roles. 
-- If it doesn't, we create it; if it does, we skip it.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'airline_admin') THEN
        CREATE ROLE airline_admin NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'flight_ops') THEN
        CREATE ROLE flight_ops NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_agent') THEN
        CREATE ROLE service_agent NOLOGIN;
    END IF;
END
$$;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO airline_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO airline_admin; -- needed for any SERIAL column inserts
GRANT SELECT, INSERT, UPDATE ON Flight, Aircraft, Crew, Flight_Crew TO flight_ops;
GRANT USAGE, SELECT ON SEQUENCE Flight_flight_id_seq, Aircraft_aircraft_id_seq, Crew_crew_id_seq TO flight_ops;
GRANT SELECT, INSERT, UPDATE ON Ticket, Reservation, Passenger, Baggage TO service_agent;
GRANT USAGE, SELECT ON SEQUENCE Ticket_ticket_id_seq, Reservation_reservation_id_seq, assenger_passenger_id_seq, Baggage_baggage_id_seq TO service_agent;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

GRANT CONNECT ON DATABASE airline_db TO airline_admin, flight_ops, service_agent;
GRANT USAGE ON SCHEMA public TO airline_admin, flight_ops, service_agent;

 
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_user') THEN
        CREATE ROLE admin_user LOGIN PASSWORD 'password1';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ops_user') THEN
        CREATE ROLE ops_user LOGIN PASSWORD 'password2' CONNECTION LIMIT 10;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'agent_user') THEN
        CREATE ROLE agent_user LOGIN PASSWORD 'password3' CONNECTION LIMIT 20;
    END IF;
END
$$;

GRANT airline_admin  TO admin_user;
GRANT flight_ops     TO ops_user;
GRANT service_agent  TO agent_user;

COMMIT;

 