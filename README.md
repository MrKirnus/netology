# Итоговая работа

1.	В работе использовался облачный тип подключения.

2.	Скриншот ER-диаграммы из DBeaver`a согласно Вашего подключения.

 
![ER](https://user-images.githubusercontent.com/109523023/179508323-2761ac99-f426-4479-b938-7c2c7ebdd3c6.png)

 
## 3.	Краткое описание БД - из каких таблиц и представлений состоит.

Основной сущностью является бронирование (bookings).

В одно бронирование можно включить несколько пассажиров, каждому из которых выписывается отдельный билет (tickets). 
Билет имеет уникальный номер и содержит информацию о пассажире. Как таковой пассажир не является отдельной сущностью. 
Как имя, так и номер документа пассажира могут меняться с течением времени, так что невозможно однозначно найти все билеты одного человека; 
для простоты можно считать, что все пассажиры уникальны.

Билет включает один или несколько перелетов (ticket_flights). 
Несколько перелетов могут включаться в билет в случаях, когда нет прямого рейса, соединяющего пункты отправления и назначения (полет с пересадками), 
либо когда билет взят «туда и обратно». 
В схеме данных нет жесткого ограничения, но предполагается, что все билеты в одном бронировании имеют одинаковый набор перелетов.

Каждый рейс (flights) следует из одного аэропорта (airports_data) в другой. 
Рейсы с одним номером имеют одинаковые пункты вылета и назначения, но будут отличаться датой отправления.
При регистрации на рейс пассажиру выдается посадочный талон (boarding_passes), в котором указано место в самолете. 
Пассажир может зарегистрироваться только на тот рейс, который есть у него в билете. 
Комбинация рейса и места в самолете должна быть уникальной, чтобы не допустить выдачу двух посадочных талонов на одно место.

Количество мест (seats) в самолете и их распределение по классам обслуживания зависит от модели самолета (aircrafts_data), выполняющего рейс. 
Предполагается, что каждая модель самолета имеет только одну компоновку салона. 
Схема данных не контролирует, что места в посадочных талонах соответствуют имеющимся в самолете.

Список таблиц и представлений.

* Имя |	Тип |	Описание
* aircrafts_data | таблица | Самолеты
* airports_data |	таблица |	Аэропорты
* boarding_passes |	таблица |	Посадочные талоны
* bookings |	таблица |	Бронирования
* flights |	таблица |	Рейcы
* seats |	таблица |	Места
* ticket_flights |	таблица |	Перелеты
* tickets |	таблица |	Билеты
* aircrafts |	представление |	Самолеты
* airports |	представление |	Аэропорты
* flights_v |	представление |	Рейcы
* routes |	представление |	Маршруты

 
## 4.	Развернутый анализ БД - описание таблиц, логики, связей и бизнес области (частично можно взять из описания базы данных, оформленной в виде анализа базы данных). 
Бизнес задачи, которые можно решить, используя БД.

Таблицы

Таблица bookings.aircraft_data
Каждая модель воздушного судна идентифицируется своим трехзначным кодом (aircraft_code). 
Указывается также название модели на русском или английском языках (model) и максимальная дальность полета в километрах (range).

* Столбец	| Тип |	Модификаторы | Описание
* aircraft_code |	bpchar(3) |	NOT NULL |	Код самолета, IATA
* model |	jsonb |	NOT NULL |	Модель самолета на русском или английском языках
* range |	int4 |	NOT NULL |	Максимальная дальность полета, км

Индексы:
*	PRIMARY KEY, btree (aircraft_data)
Ограничения-проверки:
*	CHECK (range > 0)
Ссылки извне:
*	TABLE "flights" FOREIGN KEY (aircraft_code) REFERENCES aircraft_data (aircraft_code)
*	TABLE "seats" FOREIGN KEY (aircraft_code) REFERENCES aircraft_data (aircraft_code) ON DELETE CASCADE

Таблица airports_data

Аэропорт идентифицируется трехбуквенным кодом (airport_code) и имеет свое имя на русском или английском языках (airport_name).
Для города не предусмотрено отдельной сущности, но название (city) на русском или английском языках, указывается и может служить для того, чтобы определить аэропорты одного города. Также указывается широта и долгота (coordinates) и часовой пояс (timezone).

* Столбец |	Тип |	Модификаторы |	Описание
* airport_code |	bpchar(3) |	NOT NULL |	Код аэропорта
* airport_name |	jsonb |	NOT NULL |	Название аэропорта на русском или английском языке
* city |	jsonb |	NOT NULL |	Город на русском или английском языке
* coordinates |	point	NOT NULL |	 Координаты аэропорта: долгота и широта
* timezone |	text |	NOT NULL |	Временная зона аэропорта

Индексы:
* PRIMARY KEY, btree (airports_data)
Ссылки извне:
* TABLE "flights" FOREIGN KEY (arrival_airport) REFERENCES airports_data (airport_code)
* TABLE "flights" FOREIGN KEY (departure_airport) REFERENCES airports_data (airport_code)
 

Таблица bookings.boarding_passes

При регистрации на рейс, которая возможна за сутки до плановой даты отправления, пассажиру выдается посадочный талон. Он идентифицируется также, как и перелет — номером билета и номером рейса.
Посадочным талонам присваиваются последовательные номера (boarding_no) в порядке регистрации пассажиров на рейс (этот номер будет уникальным только в пределах данного рейса). В посадочном талоне указывается номер места (seat_no).

* Столбец |	Тип |	Модификаторы |	Описание
* ticket_no |	bpchar(13) |	NOT NULL |	Номер билета
* flight_id |	int4 |	NOT NULL |	Идентификатор рейса
* boarding_no |	int4 |	NOT NULL |	Номер посадочного талона
* seat_no |	varchar(4) |	NOT NULL |	Номер места


Индексы:
* PRIMARY KEY, btree (ticket_no, flight_id)
* UNIQUE CONSTRAINT, btree (flight_id, boarding_no)
* UNIQUE CONSTRAINT, btree (flight_id, seat_no)

Ограничения внешнего ключа:
* FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)

Таблица bookings.bookings

Пассажир заранее (book_date, максимум за месяц до рейса) бронирует билет себе и, возможно, нескольким другим пассажирам. Бронирование идентифицируется номером (book_ref, шестизначная комбинация букв и цифр).
Поле total_amount хранит общую стоимость включенных в бронирование перелетов всех пассажиров.

* Столбец |	Тип |	Модификаторы |	Описание
* book_ref |	bpchar(6)	NOT NULL |	Номер бронирования
* book_date |	timestamptz	NOT NULL |	Дата бронирования
* total_amount |	numeric(10,2) |	NOT NULL |	Полная сумма бронирования

Индексы:
* PRIMARY KEY, btree (book_ref)
Ссылки извне:
* TABLE "tickets" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)


 
Таблица bookings.flights

Естественный ключ таблицы рейсов состоит из двух полей — номера рейса (flight_no) и даты отправления (scheduled_departure). Чтобы сделать внешние ключи на эту таблицу компактнее, в качестве первичного используется суррогатный ключ (flight_id).

Рейс всегда соединяет две точки — аэропорты вылета (departure_airport) и прибытия (arrival_airport). Такое понятие, как «рейс с пересадками» отсутствует: если из одного аэропорта до другого нет прямого рейса, в билет просто включаются несколько необходимых рейсов.
У каждого рейса есть запланированные дата и время вылета (scheduled_departure) и прибытия (scheduled_arrival). Реальные время вылета (actual_departure) и прибытия (actual_arrival) могут отличаться: обычно не сильно, но иногда и на несколько часов, если рейс задержан.

Статус рейса (status) может принимать одно из следующих значений:
Статус	Описание
Scheduled	Рейс доступен для бронирования. Это происходит за месяц до плановой даты вылета; до этого запись о рейсе не существует в базе данных.
On Time	Рейс доступен для регистрации (за сутки до плановой даты вылета) и не задержан.
Delayed	Рейс доступен для регистрации (за сутки до плановой даты вылета), но задержан.
Departed	Самолет уже вылетел и находится в воздухе.
Arrived	Самолет прибыл в пункт назначения.
Cancelled	Рейс отменен.

* Столбец |	Тип |	Модификаторы |	Описание
* flight_id |	serial4 |	NOT NULL |	Идентификатор рейса
* flight_no |	bpchar(6) |	NOT NULL |	Номер рейса
* scheduled_departure |	timestamptz |	NOT NULL |	Время вылета по расписанию
* scheduled_arrival |	timestamptz |	NOT NULL |	Время прилета по расписанию
* departure_airport |	bpchar(3) |	NOT NULL |	Аэропорт отправления
* arrival_airport |	bpchar(3) |	NOT NULL |	Аэропорт прибытия
* status |	varchar(20) |	NOT NULL |	Статус рейса
* aircraft_code |	bpchar(3) |	NOT NULL |	Код самолета, IATA
* actual_departure |	timestamptz |		Фактическое время вылета
* actual_arrival |	timestamptz |		Фактическое время прилета

Индексы:
* PRIMARY KEY, btree (flight_id)
* UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)

Ограничения -проверки:
- CHECK (scheduled_arrival > scheduled_departure)
- CHECK ((actual_arrival IS NULL) OR ((actual_departure IS NOT NULL AND actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure)))
- CHECK ((status)::text = ANY (ARRAY[('On Time'::character varying)::text, ('Delayed'::character varying)::text, ('Departed'::character varying)::text, ('Arrived'::character varying)::text, ('Scheduled'::character varying)::text, ('Cancelled'::character varying)::text]))

Ограничения внешнего ключа:
* FOREIGN KEY (aircraft_code) REFERENCES aircrafts_data (aircraft_code)
* FOREIGN KEY (arrival_airport) REFERENCES airports_data (airport_code)
* FOREIGN KEY (departure_airport) REFERENCES airports_data (airport_code)

Ссылки извне:
* TABLE "ticket_flights" FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
Таблица bookings.seats

Места определяют схему салона каждой модели. Каждое место определяется своим номером (seat_no) и имеет закрепленный за ним класс обслуживания (fare_conditions) — Economy, Comfort или Business.

* Столбец |	Тип |	Модификаторы |	Описание
* aircraft_code |	bpchar(3)	NOT NULL |	Код самолета, IATA
* seat_no |	varchar(4) |	NOT NULL |	Номер места
* fare_conditions |	varchar(10) |	NOT NULL |	Класс обслуживания

Индексы:
* PRIMARY KEY, btree (aircraft_code, seat_no)

Ограничения-проверки:
* CHECK ((fare_conditions)::text = ANY (ARRAY[('Economy'::character varying)::text, ('Comfort'::character varying)::text, ('Business'::character varying)::text]))

Ограничения внешнего ключа:
* FOREIGN KEY (aircraft_code) REFERENCES aircrafts_data(aircraft_code) ON DELETE CASCADE

Таблица bookings.ticket_flights
Перелет соединяет билет с рейсом и идентифицируется их номерами.
Для каждого перелета указываются его стоимость (amount) и класс обслуживания (fare_conditions).

* Столбец |	Тип |	Модификаторы |	Описание
* ticket_no |	bpchar(13) |	NOT NULL |	Номер билета
* flight_id |	int4 |	NOT NULL |	Идентификатор рейса
* fare_conditions |	varchar(10) |	NOT NULL |	Класс обслуживания
* amount |	numeric(10,2) |	NOT NULL |	Стоимость перелета

Индексы:
* PRIMARY KEY, btree (ticket_no, flight_id)

Ограничения-проверки:
* CHECK (amount >= 0)
* CHECK ((fare_conditions)::text = ANY (ARRAY[('Economy'::character varying)::text, ('Comfort'::character varying)::text, ('Business'::character varying)::text]))

Ограничения внешнего ключа:
* FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
* FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)

Ссылки извне:
* TABLE "boarding_passes" FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)


 
Таблица bookings.tickets 

Билет имеет уникальный номер (ticket_no), состоящий из 13 цифр. 
Билет содержит идентификатор пассажира (passenger_id) — номер документа, удостоверяющего личность, — его фамилию и имя (passenger_name) и контактную информацию (contact_data). 
Ни идентификатор пассажира, ни имя не являются постоянными (можно поменять паспорт, можно сменить фамилию), поэтому однозначно найти все билеты одного и того же пассажира невозможно. 

* Столбец        |	Тип         |	Модификаторы |	Описание
* ticket_no      |	bpchar(13)  |	NOT NULL     |	Номер билета
* book_ref       |	bpchar(6)   |	NOT NULL     |	Номер бронирования
* passenger_id   |	varchar(20) |	NOT NULL     |	Идентификатор пассажира
* passenger_name |	text        |	NOT NULL     |	Имя пассажира
* contact_data   |	jsonb       |		            | Контактные данные пассажира

Индексы:
* PRIMARY KEY, btree (ticket_no)
Ограничения внешнего ключа:
* FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)
Ссылки извне:
* TABLE "ticket_flights" FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)

Представления

Представление bookings.aircrafts

При работе с таблицей aircrafts_data приходилось взаимодействовать с типом данных json, в представлении aircrafts их преобразовали в тип text. Лишив при этом возможности работать с наименованием на английском языке.

* Столбец |	Тип |	Описание
* aircraft_code |	bpchar(3) |	Код самолета, IATA
* model |	text |	Модель самолета на русском языке
* range |	Int4	 |Максимальная дальность полета, км

Представление bookings.airports

При работе с таблицей airports _data приходилось взаимодействовать с типом данных json, в представлении airports их преобразовали в тип text. Лишив при этом возможности работать с наименованиями на английском языке.


* Столбец |	Тип |	Описание
* airport_code |	bpchar(3) |	Код аэропорта
* airport_name |	text |	Название аэропорта на русском или английском языке
* city |	text |	Город на русском или английском языке
* coordinates |	point |	 Координаты аэропорта: долгота и широта
* timezone |	text |	Временная зона аэропорта

 
Представление bookings.flights_v

Над таблицей flights создано представление flights_v, содержащее дополнительную информацию:
** расшифровку данных об аэропорте вылета (departure_airport, departure_airport_name, departure_city),
* расшифровку данных об аэропорте прибытия (arrival_airport, arrival_airport_name, arrival_city),
* местное время вылета (scheduled_departure_local, actual_departure_local),
* местное время прибытия (scheduled_arrival_local, actual_arrival_local),
* продолжительность полета (scheduled_duration, actual_duration).

* Столбец |	Тип |	Описание
* flight_id |	int4 |	Идентификатор рейса
* flight_no |	bpchar(6) |	Номер рейса
* scheduled_departure |	timestamptz |	Время вылета по расписанию
* scheduled_departure_local |	timestampt |	Время вылета по расписанию, местное время в пункте отправления
* scheduled_arrival |	timestamptz |	Время прилета по расписанию
* scheduled_arrival_local |	timestampt |	Время прилета по расписанию, местное время в пункте прибытия
* scheduled_duration |	interval |	Планируемая продолжительность полета
* departure_airport |	bpchar(3) |	Код аэропорта отправления
* departure_airport_name |	text |	Название аэропорта отправления
* departure_city |	text |	Город отправления
* arrival_airport |	bpchar(3) |	Код аэропорта прибытия
* arrival_airport_name |	text |	Название аэропорта прибытия
* arrival_city |	text |	Город прибытия
* status |	varchar(20) |	Статус рейса
* aircraft_code |	bpchar(3) |	Код самолета, IATA
* actual_departure |	timestamptz |	Фактическое время вылета
* actual_departure_local |	timestampt |	Фактическое время вылета, местное время в пункте отправления
* actual_arrival |	timestamptz |	Фактическое время прилета
* actual_arrival_local |	timestampt |	Фактическое время прилета, местное время в пункте прибытия
* actual_duration |	interval |	Фактическая продолжительность полета

 
Представление bookings.routes 

Таблица рейсов содержит избыточность: из нее можно было бы выделить информацию о маршруте (номер рейса, аэропорты отправления и назначения), которая не зависит
от конкретных дат рейсов. 
Именно такая информация и составляет материализованное представление routes. 

* Столбец |	Тип |	Описание
* flight_no |	bpchar(6) |	Номер рейса
* departure_airport |	bpchar(3) |	Код аэропорта отправления
* departure_airport_name |	text |	Название аэропорта отправления
* departure_city |	text |	Город отправления
* arrival_airport |	bpchar(3) |	Код аэропорта прибытия
* arrival_airport_name |	text |	Название аэропорта прибытия
* arrival_city |	text |	Город прибытия
* aircraft_code |	bpchar(3) |	Код самолета, IATA
* duration |	interval |	Продолжительность полета
* days_of_week |	Int4 |	Дни недели, когда выполняются рейсы

## Бизнес задачи, которые можно решить, используя БД.

* Выделить критические (больше 2-х часов) задержки вылетов для дальнейшего выяснений причин задержек;
* Найти рейсы, которые не пользуются спросом и сократить их или использовать самолеты с меньшим количеством мест;
* Найти направления, по которым пассажиры вынуждены летать с пересадками и рассмотреть возможность запуска прямых рейсов по данным направлениям;
* Найти клиентов, которые часто бронируют билеты и предложить им скидку; 
* Найти клиентов, которые оформили бронь, но не получили посадочные талоны и узнать причину;
* Выделить популярные и перегруженные (где заполняемость самолета больше 98%) направления и рассмотреть возможность запуска дополнительных рейсов по данным направлениям.

