-- DROP SCHEMA IF EXISTS Venues_and_Geography CASCADE;
create Schema Venues_and_Geography;
SET search_path TO Venues_and_Geography;

create table countries
	(country_id		SMALLINT,
	name			varchar(200) NOT NULL UNIQUE,
	primary key(country_id)
	);

create table cities
	(city_id	Serial,
	name		varchar(200),
	country_id SMALLINT NOT NULL,
	primary key(city_id),
	foreign key (country_id) references countries(country_id)
	);

create table venues
	(venue_id 	Serial,
	name		varchar(200),
	city_id 	Int NOT NULL,
	capacity	Int NOT NULL CHECK (capacity > 0),
	contact_info	varchar(200),
	coordinates		point NOT NULL,
	indoor_outdoor VARCHAR(10) NOT NULL
        CHECK (UPPER(indoor_outdoor) IN ('INDOOR', 'OUTDOOR', 'BOTH')),
	primary key(venue_id),
	foreign key(city_id) references cities(city_id)
	);

create table routing
	(routing_id					BIGSERIAL,
	distance					Int NOT NULL CHECK (distance > 0),
	estimated_travel_time		Int NOT NULL CHECK (estimated_travel_time > 0),
	from_venue_id				Int NOT NULL,
	to_venue_id					INT NOT NULL,
	primary key(routing_id),
	foreign key(from_venue_id) references venues(venue_id),
	foreign key(to_venue_id) references venues(venue_id)
	);
	
create table show_sequence
	(sequence_id	SERIAL,
	 sequence_number INT UNSIGNED NOT NULL,
	 dist_from_previous_show	INT UNSIGNED NOT NULL,
	 drive_time					INT UNSIGNED NOT NULL,
	 rest_days					INT UNSIGNED NOT NULL,
	 tour_id					INT NOT NULL,
	 show_id					INT NOT NULL,
	 primary key(sequence_id),
	 foreign key(tour_id) references tours(tour_id),
	 foreign key(show_id) references shows(show_id)
	);

