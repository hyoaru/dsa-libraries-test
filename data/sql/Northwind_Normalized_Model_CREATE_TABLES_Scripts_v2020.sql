--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;



SET default_tablespace = '';

SET default_with_oids = false;


---
--- drop tables
---

DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS shippers;
DROP TABLE IF EXISTS territories;
DROP TABLE IF EXISTS employee_territories;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS order_details;


--------------------------------------------------------------------------------
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------

CREATE TABLE suppliers (
    supp_id smallint NOT NULL PRIMARY KEY,
    company_name varchar(60) NOT NULL,
    contact_name varchar(30),
    contact_title varchar(30),
    address varchar(60),
    city varchar(15),
    region varchar(15),
    postal_code varchar(10),
    country varchar(15),
    phone varchar(24),
    fax varchar(24),
    homepage text
);

--------------------------------------------------------------------------------
-- Name: product_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------
CREATE TABLE categories (
    category_id smallint NOT NULL PRIMARY KEY,
    category_name varchar(15) NOT NULL,
    description text,
    picture bytea
);


--------------------------------------------------------------------------------
-- Name: customers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------

CREATE TABLE customers (
    cust_id bpchar NOT NULL PRIMARY KEY,
    company_name varchar(40) NOT NULL,
    contact_name varchar(30),
    contact_title varchar(30),
    address varchar(60),
    city varchar(15),
    region varchar(15),
    postal_code varchar(10),
    country varchar(15),
    phone varchar(24),
    fax varchar(24)
);

--------------------------------------------------------------------------------
-- Name: regions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------
CREATE TABLE regions (
    region_id smallint NOT NULL PRIMARY KEY,
    region_description varchar NOT NULL
);


--------------------------------------------------------------------------------
-- Name: shippers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------
CREATE TABLE shippers (
    shipper_id smallint NOT NULL PRIMARY KEY,
    company_name varchar(40) NOT NULL,
    phone varchar(24)
);

--------------------------------------------------------------------------------
-- Name: territories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------

CREATE TABLE territories (
    territory_id character varying(20) NOT NULL PRIMARY KEY,
    territory_description bpchar NOT NULL,
    region_id smallint NOT NULL REFERENCES regions(region_id)
);


--------------------------------------------------------------------------------
-- Name: employee_territories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------
CREATE TABLE employee_territories (
    emp_id smallint NOT NULL,
    territory_id varchar(20) NOT NULL REFERENCES territories(territory_id),
	PRIMARY KEY (emp_id, territory_id)
);

--------------------------------------------------------------------------------
-- Name: employees; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------
CREATE TABLE employees (
    emp_id smallint NOT NULL PRIMARY KEY,
    last_name character varying(20) NOT NULL,
    first_name character varying(10) NOT NULL,
    title character varying(30),
    title_of_courtesy character varying(25),
    birth_date date,
    hire_date date,
    emp_curr_salary real,
    address character varying(60),
    city character varying(15),
    region character varying(15),
    postal_code character varying(10),
    country character varying(15),
    home_phone character varying(24),
    extension character varying(4),
    photo bytea,
    notes text,
    reports_to smallint,
    photo_path character varying(255)
);

--------------------------------------------------------------------------------
-- Name: products; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------

CREATE TABLE products (
    prod_id smallint NOT NULL PRIMARY KEY,
    prod_name character varying(40) NOT NULL,
    supp_id smallint REFERENCES suppliers(supp_id),
    category_id smallint REFERENCES categories(category_id),
    quantity_per_unit character varying(20),
    unit_price real,
    units_in_stock smallint,
    units_on_order smallint,
    reorder_level smallint,
    discontinued integer NOT NULL
);

--------------------------------------------------------------------------------
-- Name: orders; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------
CREATE TABLE orders (
    order_id smallint NOT NULL PRIMARY KEY,
    cust_id bpchar REFERENCES customers(cust_id),
    emp_id smallint REFERENCES employees(emp_id),
    order_date date,
    required_date date,
    shipped_date date,
    ship_via smallint REFERENCES shippers (shipper_id),
    freight real,
    ship_name character varying(40),
    ship_address character varying(60),
    ship_city character varying(15),
    ship_region character varying(15),
    ship_postal_code character varying(10),
    ship_country character varying(15)
);

--------------------------------------------------------------------------------
-- Name: order_details; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--------------------------------------------------------------------------------
CREATE TABLE order_details (
    order_id smallint NOT NULL REFERENCES orders(order_id),
    prod_id smallint NOT NULL REFERENCES products(prod_id),
    unit_price real NOT NULL,
    quantity smallint NOT NULL,
    discount real NOT NULL,
	PRIMARY KEY (order_id, prod_id)
);

--------------------------------------------------------------------------------
-- add remaining constraints
--------------------------------------------------------------------------------
ALTER TABLE employees 
ADD CONSTRAINT employees_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES employees (emp_id);
