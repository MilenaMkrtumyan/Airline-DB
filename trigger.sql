-- Order of execution

-- 1. DDL 
-- ... creates tables, adds departure_time/arrival_time as empty columns ...

-- 2. DML  
-- ... Airport, Aircraft, Crew, Passenger, Reservation, Flight, Ticket, Baggage, Flight_Crew ...
 
-- 3. Trigger (for future writes only)
CREATE OR REPLACE FUNCTION sync_ticket_flight_times() RETURNS TRIGGER AS $$
BEGIN
    SELECT f.departure_time, f.arrival_time
      INTO NEW.departure_time, NEW.arrival_time
    FROM Flight f
    WHERE f.flight_id = NEW.flight_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_ticket_flight_times
BEFORE INSERT OR UPDATE OF flight_id ON Ticket
FOR EACH ROW EXECUTE FUNCTION sync_ticket_flight_times();


-- 4 (in the DDL file)

---------

-- Passengers should not be able to buy tickets for cancelled flights.
CREATE OR REPLACE FUNCTION check_flight_availability()
RETURNS TRIGGER AS $$
DECLARE
    status VARCHAR(20);
BEGIN
    SELECT flight_status
    INTO status
    FROM Flight
    WHERE flight_id = NEW.flight_id;
    IF status = 'Cancelled' THEN
        RAISE EXCEPTION 'Cannot create ticket: flight % is cancelled',
        NEW.flight_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_flight_availability
BEFORE INSERT ON Ticket
FOR EACH ROW
EXECUTE FUNCTION check_flight_availability();


-- Automatically update baggage status after check-in
CREATE OR REPLACE FUNCTION update_baggage_checkin()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.checked_in = TRUE 
       AND OLD.checked_in = FALSE THEN
        UPDATE Baggage
        SET baggage_status = 'Checked-In',
            checked_in_time = NOW()
        WHERE ticket_id = NEW.ticket_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_update_baggage_checkin
AFTER UPDATE OF checked_in ON Ticket
FOR EACH ROW
EXECUTE FUNCTION update_baggage_checkin();


-- If maintenance date arrives, aircraft status becomes Active.

CREATE OR REPLACE FUNCTION check_aircraft_maintenance()
RETURNS TRIGGER AS $$
BEGIN
IF NEW.next_maintenance_date <= CURRENT_DATE THEN NEW.aircraft_status := 'Maintenance';
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_aircraft_maintenance
BEFORE INSERT OR UPDATE ON Aircraft
FOR EACH ROW
EXECUTE FUNCTION check_aircraft_maintenance();


-- Automatically recalculates reservation total price based on associated ticket fares whenever ticket data changes.

CREATE OR REPLACE FUNCTION update_reservation_price()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Reservation
    SET total_price =
    (SELECT COALESCE(SUM(fare),0)
        FROM Ticket
        WHERE reservation_id = NEW.reservation_id)
    WHERE reservation_id = NEW.reservation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_update_reservation_price
AFTER INSERT OR UPDATE OF fare OR DELETE ON Ticket
FOR EACH ROW
EXECUTE FUNCTION update_reservation_price();
