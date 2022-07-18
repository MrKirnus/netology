--ЗАДАНИЕ №1
-- В каких городах больше одного аэропорта?
 
select city ->> 'ru' as city_name -- выводим наименование городов согласно условиям
from airports_data ad -- получаем данные из таблицы с аэропортами
group by city ->> 'ru' -- группируем данные по наименованию города 
having count (airport_code) > 1 -- фильтруем количество аэропортов по условию больше одного 


--ЗАДАНИЕ №2
--В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
--Подзапрос

select distinct ad.airport_name ->> 'ru' as "airport_name" -- выводим наименование аэропортов
from ( -- формируем подзапрос
	select aircraft_code, "range" -- выводим код самолета и его максимальную дальность полета
	from aircrafts_data ad -- получаем данные из таблицы самолетов 
	order by "range" desc -- фильтруем отображение кодов самолетов по максимальной дальности (по уменьшению) 
	limit 1) x -- ограничиваем вывод данных по первой строчке (максимальная дальность)
join flights f on f.aircraft_code = x.aircraft_code -- присоединяем таблицу с перелетами для последующего присоединения таблицы с аэропортами
join airports_data ad on ad.airport_code = f.departure_airport -- присоединяем таблицу с аэропортами для получения наименования аэропорта
-- можно было не выводить наименование аэропорт ограничившись лишь их кодами, в таком случае не пришлось бы присоединять таблицу с аэропортами


--ЗАДАНИЕ №3
--Вывести 10 рейсов с максимальным временем задержки вылета
--Оператор LIMIT

select x.flight_no -- выводим номера рейсов
from ( -- формируем подзапрос
	select flight_no, actual_departure - scheduled_departure as "difference_departure" -- выводим номер рейса и рассчитываем задержку вылета
	from flights f -- получаем данные из таблицы перелетов
	where actual_departure is not null) x -- убираем пустые строки 
order by x.difference_departure desc -- фильтруем отображение задержки по уменьшению
limit 10 -- ограничиваем вывод данных десятью рейсами


--ЗАДАНИЕ №4
--Были ли брони, по которым не были получены посадочные талоны?
--Верный тип JOIN

select distinct t.book_ref -- выводим номера брони
from tickets t -- получаем данные из таблицы билетов
left join boarding_passes bp on bp.ticket_no = t.ticket_no -- присоединяем таблицу с посадочными талонами через оператор "left join" чтобы не потерять данные по брони без посадочного
where bp.boarding_no is null -- фильтруем отображение данных по условию отсутствия посадочного талона


--ЗАДАНИЕ №5
--Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних 
--рейсах в течении дня.
--Оконная функция
--Подзапросы или/и cte


select f.flight_no, z.nos - x.nop as "free", -- выводим номер рейса и получаем кол-во свободных мест
round(((z.nos::numeric - x.nop::numeric)/z.nos::numeric * 100), 2) as "%", -- выводим процентное соотношение свободных мест к общему количеству мест в самолете
f.scheduled_departure::date, f.departure_airport, x.nop, -- выводим дату вылета рейса и кол-во пассажиров на этом рейсе
sum(x.nop) over (partition by f.scheduled_departure::date, f.departure_airport order by f.scheduled_departure) as "cumulative total" -- формируем накопительный итог
from( -- формируем подзапрос для расчета кол-ва пассажиров на каждом рейсе
	select bp.flight_id, count(bp.boarding_no) as "nop" -- (number of passengers) сколько пассажиров на каждом рейсе
	from boarding_passes bp
	group by bp.flight_id) x 
join flights f on f.flight_id = x.flight_id -- присоединяем таблицу с перелетами через оператор "right join" чтобы не потерять данные
right join ( --присоединяем таблицу с посадкой в самолете для расчета кол-ва мест в каждом самолете
	select s.aircraft_code, count(s.seat_no) as "nos" -- (number of seats) сколько мест всего в самолете
	from seats s
	group by s.aircraft_code) z on z.aircraft_code = f.aircraft_code 
where f.actual_departure is not null and f.actual_arrival is not null -- оставляем только реальные перелеты


--ЗАДАНИЕ №6
--Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- Подзапрос или окно
-- Оператор ROUND

select f.aircraft_code, count(f.flight_id) as "num", round(count(f.flight_id)/ -- (num - numbers of flight) выводим коды самолетов и кол-во их рейсов. Высчитываем % соотношение
	(select count(flight_id)::numeric from flights f where f.actual_departure is not null) *100, 2) as "%" --формируем подзапрос для вычисления обшего кол-ва рейсов. Округляем % до двух знаков
from flights f
where f.actual_departure is not null -- фильтруем именно перелеты, а не просто планируемые и несостоявшиеся рейсы 
group by f.aircraft_code -- группируем по коду самолета


--ЗАДАНИЕ №7
--Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
--CTE

with Business as ( -- формируем СТЕ, где будут только билеты из класса "Бизнес"
	select f.flight_id, ad1.city ->> 'ru' as city_name, ad2.city ->> 'ru' as city_name, tf.amount -- выводим номер рейса, маршрут и стоимость билета
	from ticket_flights tf 
	join flights f on f.flight_id = tf.flight_id -- присоединяем таблицу с перелетами для отслеживания маршрута
	join airports_data ad1 on ad1.airport_code = f.departure_airport -- присоединяем таблицу с наименованием городов по коду аэропорта вылета
	join airports_data ad2 on ad2.airport_code = f.arrival_airport -- присоединяем таблицу с наименованием городов по коду аэропорта прилета
	where tf.fare_conditions = 'Business' -- оставляем только стоимость билетов в бизнес - класс
	group by f.flight_id, ad1.city, ad2.city, tf.amount), -- группируем для группировки
	Economy as ( --формируем СТЕ, где будут только билеты из класса "Эконом" аналогично бизнесу 
	select f.flight_id, ad1.city ->> 'ru' as city_name, ad2.city ->> 'ru' as city_name, tf.amount
	from ticket_flights tf
	join flights f on f.flight_id = tf.flight_id
	join airports_data ad1 on ad1.airport_code = f.departure_airport 
	join airports_data ad2 on ad2.airport_code = f.arrival_airport 
	where tf.fare_conditions = 'Economy'
	group by f.flight_id, ad1.city, ad2.city, tf.amount)
select ad2.city ->> 'ru' as "departure_airport", ad3.city ->> 'ru' as "arrival_airport", -- выводим маршрут
min(Business.amount) as "min_business", max(Economy.amount) as "max_economy" -- выводим минимальную стоимость билета в бизнес класс и эконом для данного направления
from flights f2 
join airports_data ad2 on ad2.airport_code = f2.departure_airport -- присоединяем таблицу с наименованием городов по коду аэропорта вылета
join airports_data ad3 on ad3.airport_code = f2.arrival_airport -- присоединяем таблицу с наименованием городов по коду аэропорта прилета
join Business on Business.flight_id = f2.flight_id -- присоединяем таблицу с бизнес - классом
join Economy on Economy.flight_id = f2.flight_id -- присоединяем таблицу с экономом
group by ad2.city, ad3.city -- группируем по маршруту
having min(Business.amount) < max(Economy.amount) -- фильтруем по условию, что стоимость бизнес - класса должна быть меньше эконома

--ЗАДАНИЕ №8
--Между какими городами нет прямых рейсов?
-- Декартово произведение в предложении FROM
-- Самостоятельно созданные представления (если облачное подключение, то без представления)
-- Оператор EXCEPT
 
select ad1.city ->> 'ru' as city_name, ad2.city ->> 'ru' as city_name -- выводим наименования городов по маршрутам
from airports_data ad1, airports_data ad2 -- формируем декартово произведение
where ad1.city ->> 'ru' != ad2.city ->> 'ru' -- фильтруем по условию несоответсвия наименований городов
except -- используем оператор except для выборки уникальных значений 
select ad1.city ->> 'ru' as city_name, ad2.city ->> 'ru' as city_name --выводим наименования городов по маршрутам
from flights f 
join airports_data ad1 on ad1.airport_code = f.departure_airport --присоединяем таблицу с наименованием городов по коду аэропорта вылета
join airports_data ad2 on ad2.airport_code = f.arrival_airport --присоединяем таблицу с наименованием городов по коду аэропорта прилета
 

--ЗАДАНИЕ №9
--Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью
--перелетов  в самолетах, обслуживающих эти рейсы * 
-- Оператор RADIANS или использование sind/cosd
-- CASE 
-- * - В облачной базе координаты находятся в столбце airports_data.coordinates - работаете, как с массивом. В локальной базе координаты 
-- находятся в столбцах airports.longitude и airports.latitude.
--Кратчайшее расстояние между двумя точками A и B на земной поверхности (если принять ее за сферу) определяется зависимостью:
-- d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}, 
-- где latitude_a и latitude_b — широты, longitude_a, longitude_b — долготы данных пунктов, 
--d — расстояние между пунктами измеряется в радианах длиной дуги большого круга земного шара.
--Расстояние между пунктами, измеряемое в километрах, определяется по формуле:
--L = d·R, где R = 6371 км — средний радиус земного шара.


with ac as ( -- формируем СТЕ с координатами, ac - airport coordinates
	select distinct ad.airport_name ->> 'ru' as airport_name, ad.airport_code , ad.coordinates [0] as "latitude", ad.coordinates [1] as "longitude" -- выводим наименование аэропорта, его код и широту и долготу отдельно 
	from airports_data ad)
select distinct dac.airport_name as "departure_airport", -- выводим уникальные значения аэропортов
round((acos(sind(dac.longitude) * sind(aac.longitude) + cosd(dac.longitude) * cosd(aac.longitude) * cosd(dac.latitude - aac.latitude)) * 6371)::numeric, 2) as "distance", -- расчитываем растояние между городами с округлением до двух знаков
aac.airport_name as "arrival_airport", ad2.aircraft_code, ad2.model ->> 'ru' as "model", ad2."range", -- выводим данные по аэропорту прилета, коду и наименованию самолета, а также его максимальную дальность полета
case when -- проверяем долетит ли самолет из одного города в другой по условию, если запас хода самолета больше расстояния между городами 
ad2."range" > round((acos(sind(dac.longitude) * sind(aac.longitude) + cosd(dac.longitude) * cosd(aac.longitude) * cosd(dac.latitude - aac.latitude)) * 6371)::numeric, 2)
then 'YES'
else 'NO'
end "success"
from flights f2
join ac dac on dac.airport_code = f2.departure_airport -- присоединяем таблицу с координатами по коду аэропорта вылета dac - departure airport coordinates
join ac aac on aac.airport_code = f2.arrival_airport -- присоединяем таблицу с координатами по коду аэропорта прилета aac - arrival airport coordinates
join aircrafts_data ad2 on ad2.aircraft_code  = f2.aircraft_code -- присоединяем таблицу с самолетами
