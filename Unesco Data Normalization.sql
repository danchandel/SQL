-- UNESCO DATA


DROP TABLE unesco_raw;

CREATE TABLE unesco_raw
 (name TEXT, description TEXT, justification TEXT, year INTEGER,
    longitude FLOAT, latitude FLOAT, area_hectares FLOAT,
    category TEXT, category_id INTEGER, state TEXT, state_id INTEGER,
    region TEXT, region_id INTEGER, iso TEXT, iso_id INTEGER);

CREATE TABLE category (
  id SERIAL,
  name VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);


CREATE TABLE state (
  id SERIAL,
  name VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);

CREATE TABLE region (
  id SERIAL,
  name VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);

CREATE TABLE iso (
  id SERIAL,
  name VARCHAR(128) UNIQUE,
  PRIMARY KEY(id)
);



CREATE TABLE unesco
(name TEXT, description TEXT, justification TEXT, year INTEGER,
    longitude FLOAT, latitude FLOAT, area_hectares FLOAT, 
    category_id INTEGER,
    state_id INTEGER,
    region_id INTEGER,
    iso_id INTEGER,
    CONSTRAINT category_id_fk FOREIGN KEY(category_id) REFERENCES category(id), 
    CONSTRAINT state_id_fk FOREIGN KEY(state_id) REFERENCES state(id),
    CONSTRAINT region_id_fk FOREIGN KEY(region_id) REFERENCES region(id),
    CONSTRAINT iso_id_fk FOREIGN KEY(iso_id) REFERENCES iso(id));


\copy unesco_raw(name,description,justification,year,longitude,latitude,area_hectares,category,state,region,iso) FROM '/Users/danbalictar/Desktop/whc-sites-2018-small.csv' WITH DELIMITER ',' CSV HEADER; -- copy csv file 


--INSERTING DATA TO EACH TABLE (normalizing them)

INSERT INTO category (name) SELECT DISTINCT category FROM unesco_raw; -- insert categories
INSERT INTO state (name) SELECT DISTINCT state FROM unesco_raw; -- insert state
INSERT INTO region (name) SELECT DISTINCT region FROM unesco_raw; -- insert region
INSERT INTO iso (name) SELECT DISTINCT iso FROM unesco_raw; -- insert iso



--UPDATING THE CATEGORIES IN unesco_raw

UPDATE unesco_raw SET category_id = (SELECT category.id from category WHERE category.name = unesco_raw.category); -- update category ids

UPDATE unesco_raw SET state_id = (SELECT state.id from state WHERE state.name = unesco_raw.state); -- update state ids

UPDATE unesco_raw SET region_id = (SELECT region.id from region WHERE region.name = unesco_raw.region); -- update region ids

UPDATE unesco_raw SET iso_id = (SELECT iso.id from iso WHERE iso.name = unesco_raw.iso); -- update iso ids


--INSERTING DATA IN unesco TABLE

INSERT INTO unesco (name, description, justification, year, longitude, latitude, area_hectares, category_id, region_id, state_id, iso_id) SELECT DISTINCT name, description, justification, year, longitude, latitude, area_hectares, category_id, region_id, state_id, iso_id FROM unesco_raw;

--JOINING THE TABLES TO RETRIEVE DATE

SELECT unesco.name, year, category.name, state.name, region.name, iso.name
  FROM unesco
  JOIN category ON unesco.category_id = category.id
  JOIN iso ON unesco.iso_id = iso.id
  JOIN state ON unesco.state_id = state.id
  JOIN region ON unesco.region_id = region.id
  ORDER BY iso.name, unesco.name
  LIMIT 3;
