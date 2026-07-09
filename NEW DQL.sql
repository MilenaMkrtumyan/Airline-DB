-- DQL
 
SELECT * FROM Flight_Crew;
SELECT * FROM Baggage;
SELECT * FROM Ticket;
SELECT * FROM Flight;
SELECT * FROM Reservation ORDER BY reservation_id;
SELECT * FROM Crew;
SELECT * FROM Passenger;
SELECT * FROM Aircraft;
SELECT * FROM Airport;

-- Average ticket price by cabin class
SELECT cabin_class, ROUND(AVG(fare),2) AS average_fare, COUNT(*) AS number_of_tickets
FROM Ticket
GROUP BY cabin_class
ORDER BY average_fare DESC;

 -- Monthly revenue
SELECT DATE_TRUNC('month', reservation_timestamp) AS month, COUNT(*) AS reservations, SUM(total_price) AS revenue
FROM Reservation
GROUP BY month
ORDER BY month;

-- Most delayed airports (by departures)
SELECT a.airport_name, COUNT(*) AS delayed_flights
FROM Airport a
JOIN Flight f ON a.airport_id = f.departure_airport_id
WHERE f.flight_status = 'Delayed'
GROUP BY a.airport_name
ORDER BY delayed_flights DESC;

-- Which routes lose the most baggage
SELECT dep.city AS departure, arr.city AS arrival, COUNT(b.baggage_id) AS lost_bags
FROM Baggage b
JOIN Ticket t ON b.ticket_id = t.ticket_id
JOIN Flight f ON t.flight_id = f.flight_id
JOIN Airport dep ON f.departure_airport_id = dep.airport_id
JOIN Airport arr ON f.arrival_airport_id = arr.airport_id
WHERE b.baggage_status = 'Lost'
GROUP BY dep.city, arr.city
ORDER BY lost_bags DESC;

-- Which flights make the most revenue - top 10
SELECT f.flight_number, dep.city AS departure_city, arr.city AS arrival_city, COUNT(t.ticket_id) AS tickets_sold, ROUND(SUM(t.fare),2) AS total_revenue
FROM Flight f
JOIN Ticket t ON f.flight_id = t.flight_id
JOIN Airport dep ON f.departure_airport_id = dep.airport_id
JOIN Airport arr ON f.arrival_airport_id = arr.airport_id
WHERE t.ticket_status <> 'Refunded'
GROUP BY f.flight_id, f.flight_number, dep.city, arr.city
ORDER BY total_revenue DESC
LIMIT 10;

-- Number of flights by status
SELECT flight_status, COUNT(*) AS number_of_flights
FROM Flight
GROUP BY flight_status
ORDER BY number_of_flights DESC;

-- Average baggage weight by cabin class
SELECT t.cabin_class, ROUND(AVG(b.weight_kg),4) AS average_baggage_weight, COUNT(b.baggage_id) AS baggage_count
FROM Ticket t
JOIN Baggage b ON t.ticket_id = b.ticket_id
GROUP BY t.cabin_class
ORDER BY average_baggage_weight DESC;

-- Passengers with cancelled reservations - top 20
SELECT p.fname, p.lname, COUNT(r.reservation_id) AS cancelled_bookings
FROM Passenger p
JOIN Reservation r ON p.passenger_id = r.passenger_id
WHERE r.reservation_status = 'Cancelled'
GROUP BY p.passenger_id, p.fname, p.lname
ORDER BY cancelled_bookings DESC
LIMIT 20;

-- Flights longer than average
SELECT f.flight_number, dep.iata_code AS departure_airport, arr.iata_code AS arrival_airport, f.flight_duration
FROM Flight f
JOIN Airport dep ON f.departure_airport_id = dep.airport_id
JOIN Airport arr ON f.arrival_airport_id = arr.airport_id
WHERE f.flight_duration > (SELECT AVG(flight_duration) FROM Flight)
ORDER BY f.flight_duration DESC;

-- Aircraft maintenance (by model)
SELECT model, aircraft_status, COUNT(*) AS aircraft_count, MIN(next_maintenance_date) AS next_required_maintenance
FROM Aircraft
GROUP BY model, aircraft_status
ORDER BY next_required_maintenance;

-- Which airports receive the most flights
SELECT a.airport_name, a.city, a.country, COUNT(f.flight_id) AS incoming_flights
FROM Airport a
JOIN Flight f ON a.airport_id = f.arrival_airport_id
GROUP BY a.airport_id, a.airport_name, a.city, a.country
ORDER BY incoming_flights DESC;

 