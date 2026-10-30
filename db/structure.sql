SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: compensations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.compensations (
    id bigint NOT NULL,
    employee_id bigint NOT NULL,
    amount_cents bigint NOT NULL,
    currency character varying(3) NOT NULL,
    amount_usd_cents bigint NOT NULL,
    effective_date date NOT NULL,
    change_reason character varying(100) DEFAULT 'Initial Hire'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT compensations_amount_cents_nonnegative CHECK ((amount_cents >= 0)),
    CONSTRAINT compensations_amount_usd_cents_nonnegative CHECK ((amount_usd_cents >= 0)),
    CONSTRAINT compensations_currency_format CHECK (((currency)::text ~ '^[A-Z]{3}$'::text))
);


--
-- Name: compensations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.compensations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: compensations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.compensations_id_seq OWNED BY public.compensations.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(20) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employees (
    id bigint NOT NULL,
    employee_code character varying(20) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    country_code character varying(2) NOT NULL,
    department_id bigint NOT NULL,
    job_title character varying(100) NOT NULL,
    job_level character varying(20) NOT NULL,
    date_of_joining date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT employees_country_code_format CHECK (((country_code)::text ~ '^[A-Z]{2}$'::text))
);


--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employees_id_seq OWNED BY public.employees.id;


--
-- Name: exchange_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rates (
    id bigint NOT NULL,
    currency_code character varying(3) NOT NULL,
    rate_to_usd numeric(12,6) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT exchange_rates_currency_code_format CHECK (((currency_code)::text ~ '^[A-Z]{3}$'::text)),
    CONSTRAINT exchange_rates_rate_to_usd_positive CHECK ((rate_to_usd > (0)::numeric))
);


--
-- Name: exchange_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exchange_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exchange_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exchange_rates_id_seq OWNED BY public.exchange_rates.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: compensations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compensations ALTER COLUMN id SET DEFAULT nextval('public.compensations_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees ALTER COLUMN id SET DEFAULT nextval('public.employees_id_seq'::regclass);


--
-- Name: exchange_rates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates ALTER COLUMN id SET DEFAULT nextval('public.exchange_rates_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: compensations compensations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compensations
    ADD CONSTRAINT compensations_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_compensations_on_active_employee; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_compensations_on_active_employee ON public.compensations USING btree (employee_id) WHERE (is_active = true);


--
-- Name: index_compensations_on_active_usd_amount; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_compensations_on_active_usd_amount ON public.compensations USING btree (amount_usd_cents) WHERE (is_active = true);


--
-- Name: index_compensations_on_effective_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_compensations_on_effective_date ON public.compensations USING btree (effective_date);


--
-- Name: index_compensations_on_employee_and_effective_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_compensations_on_employee_and_effective_date ON public.compensations USING btree (employee_id, effective_date);


--
-- Name: index_departments_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_departments_on_code ON public.departments USING btree (code);


--
-- Name: index_departments_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_departments_on_name ON public.departments USING btree (name);


--
-- Name: index_employees_on_country_and_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_country_and_department ON public.employees USING btree (country_code, department_id);


--
-- Name: index_employees_on_department_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_department_id ON public.employees USING btree (department_id);


--
-- Name: index_employees_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_employees_on_email ON public.employees USING btree (email);


--
-- Name: index_employees_on_employee_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_employees_on_employee_code ON public.employees USING btree (employee_code);


--
-- Name: index_employees_on_last_and_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_employees_on_last_and_first_name ON public.employees USING btree (last_name, first_name);


--
-- Name: index_exchange_rates_on_currency_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_exchange_rates_on_currency_code ON public.exchange_rates USING btree (currency_code);


--
-- Name: employees fk_rails_0025f65a97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT fk_rails_0025f65a97 FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE RESTRICT;


--
-- Name: compensations fk_rails_e6d05c8678; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compensations
    ADD CONSTRAINT fk_rails_e6d05c8678 FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261030000003'),
('20261030000002'),
('20261030000001');

