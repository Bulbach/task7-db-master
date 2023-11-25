-- 1.Вывести к каждому самолету класс обслуживания и количество мест этого класса
select a.aircraft_code, s.fare_conditions, count(s.seat_no) as seat_count
from aircrafts a
         join seats s
              on a.aircraft_code = s.aircraft_code
group by a.aircraft_code, s.fare_conditions

--  2.Найти 3 самых вместительных самолета (модель + кол-во мест)
select a.aircraft_code, count(s.seat_no) as seats
from aircrafts a
         join seats s
              on a.aircraft_code = s.aircraft_code
group by a.aircraft_code
order by seats desc limit 3

-- 3.Найти все рейсы, которые задерживались более 2 часов
SELECT f.flight_id,
       f.flight_no,
       f.scheduled_departure,
       f.scheduled_arrival,
       f.departure_airport,
       f.arrival_airport,
       f.status,
       f.aircraft_code,
       f.actual_departure,
       f.actual_arrival
FROM flights f
WHERE (f.actual_departure - f.scheduled_departure) > INTERVAL '2 hours'

--  4.Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business')
--    , с указанием имени пассажира и контактных данных
select t.ticket_no, t.passenger_name, t.contact_data, tf.fare_conditions
from tickets t
         join ticket_flights tf
              on t.ticket_no = tf.ticket_no
where tf.fare_conditions = 'Business'
order by t.ticket_no desc limit 10

--  5.Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
select distinct tf.flight_id, tf.fare_conditions, f.status
from ticket_flights tf
         left join flights f
                   on tf.flight_id = f.flight_id
where tf.flight_id
    not in (select distinct tf.flight_id from ticket_flights tf where tf.fare_conditions = 'Business')
  and f.status in ('Scheduled', 'On Time')
order by tf.flight_id

--  6. Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой по вылету
select distinct ad.airport_name, ad.city
from flights f
         left join airports_data ad
                   on f.departure_airport = ad.airport_code or f.arrival_airport = ad.airport_code
WHERE f.actual_departure > f.scheduled_departure

--  7. Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта,
--  отсортированный по убыванию количества рейсов
select distinct ad.airport_name, count(f.flight_id) as flight_count
from flights f
         left join airports_data ad
                   on f.departure_airport = ad.airport_code or f.arrival_airport = ad.airport_code
group by ad.airport_name
order by flight_count desc

--  8.Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено
--  и новое время прибытия (actual_arrival) не совпадает с запланированным
select f.flight_id, f.flight_no, f.scheduled_arrival, f.actual_arrival
from flights f
where (f.scheduled_arrival != f.actual_arrival)

--  9. Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
select ad.aircraft_code, ad.model, s.seat_no, s.fare_conditions
from aircrafts_data ad
         left join seats s
                   on ad.aircraft_code = s.aircraft_code
where (ad.model ->>'ru') = 'Аэробус A321-200'
  and s.fare_conditions!='Economy'
order by s.seat_no

--  10. Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
select ad.airport_code, ad.airport_name, ad.city
from airports_data ad
where city in (SELECT city
               FROM airports_data ad2
               GROUP BY ad2.city
               HAVING count(city) > 1)

--  11. Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
select distinct t.passenger_id, t.passenger_name, AVG(total_amount)
from bookings b
         left join tickets t
                   on b.book_ref = t.book_ref
group by t.passenger_id, t.passenger_name
HAVING SUM(b.total_amount) > (
    SELECT AVG(total_amount)
    FROM bookings
);

-- 12.Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT f.flight_id,
       f.flight_no,
       f.scheduled_departure,
       f.status,
       f.departure_airport,
       ad_dep.airport_name,
       ad_dep.city,
       f.arrival_airport,
       ad_arr.airport_name,
       ad_arr.city
FROM flights f
         LEFT JOIN airports_data ad_dep ON f.departure_airport = ad_dep.airport_code
         LEFT JOIN airports_data ad_arr ON f.arrival_airport = ad_arr.airport_code
WHERE f.status
    NOT IN ('Departed', 'Arrived', 'Cancelled')
  AND ((ad_dep.city ->> 'ru' = 'Екатеринбург' AND ad_arr.city ->> 'ru' = 'Москва'))
ORDER BY f.scheduled_departure ASC LIMIT 1;

-- 13. Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
(select ticket_no , flight_id , fare_conditions, amount
 from ticket_flights
 order by amount desc
 limit 1
 )
union
(select ticket_no , flight_id , fare_conditions, amount
 from ticket_flights
 order by amount asc
 limit 1
 );

-- 14. Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
CREATE TABLE IF NOT EXISTS customers(
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firstName VARCHAR (255) NOT NULL,
    lastName VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE CHECK(email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    phone VARCHAR(20) CHECK(phone ~ '^[0-9]+$')
    );


-- 15.  Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE IF NOT EXISTS orders(
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customerId UUID NOT NULL,
    quantity INTEGER NOT NULL,
    CONSTRAINT fk_customer
    FOREIGN KEY(customerId)
    REFERENCES customers(id)
    ON DELETE CASCADE
    );


-- 16. Написать 5 insert в эти таблицы
INSERT INTO customers (id, firstName, lastName, email, phone) VALUES
('00000000-0000-0000-0000-000000000001', 'Иван', 'Иванов', 'ivanov@example.com', '1234567890'),
('00000000-0000-0000-0000-000000000002', 'Петр', 'Петров', 'petrov@example.com', '9876543210'),
('00000000-0000-0000-0000-000000000003', 'Анна', 'Сидорова', 'sidorova@example.com', '5555555555'),
('00000000-0000-0000-0000-000000000004', 'Ольга', 'Аппель', 'appel@example.com', '5555444555'),
('00000000-0000-0000-0000-000000000005', 'Алексей', 'Верезубов', 'verezubov@example.com', '3333555555');

INSERT INTO orders (id, customerId, quantity)
VALUES ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 5),
       ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000002', 10),
       ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000003', 3),
       ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000004', 7),
       ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000005', 11);

-- 17. Удалить таблицы
drop table if exists wagons;
drop table if exists orders;