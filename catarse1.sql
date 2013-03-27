--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: authorizations; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE authorizations (
    id integer NOT NULL,
    oauth_provider_id integer NOT NULL,
    user_id integer NOT NULL,
    uid text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.authorizations OWNER TO catarse;

--
-- Name: authorizations_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE authorizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.authorizations_id_seq OWNER TO catarse;

--
-- Name: authorizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE authorizations_id_seq OWNED BY authorizations.id;


--
-- Name: backers; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE backers (
    id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL,
    reward_id integer,
    value numeric NOT NULL,
    confirmed boolean DEFAULT false NOT NULL,
    confirmed_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    anonymous boolean DEFAULT false,
    key text,
    requested_refund boolean DEFAULT false,
    refunded boolean DEFAULT false,
    credits boolean DEFAULT false,
    notified_finish boolean DEFAULT false,
    payment_method text,
    payment_token text,
    payment_id character varying(255),
    payer_name text,
    payer_email text,
    payer_document text,
    address_street text,
    address_number text,
    address_complement text,
    address_neighbourhood text,
    address_zip_code text,
    address_city text,
    address_state text,
    address_phone_number text,
    payment_choice text,
    payment_service_fee numeric,
    CONSTRAINT backers_value_positive CHECK ((value >= (0)::numeric))
);


ALTER TABLE public.backers OWNER TO catarse;

--
-- Name: rewards; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE rewards (
    id integer NOT NULL,
    project_id integer NOT NULL,
    minimum_value numeric NOT NULL,
    maximum_backers integer,
    description text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT rewards_maximum_backers_positive CHECK ((maximum_backers >= 0)),
    CONSTRAINT rewards_minimum_value_positive CHECK ((minimum_value >= (0)::numeric))
);


ALTER TABLE public.rewards OWNER TO catarse;

--
-- Name: users; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    primary_user_id integer,
    provider text,
    uid text,
    email text,
    name text,
    nickname text,
    bio text,
    image_url text,
    newsletter boolean DEFAULT false,
    project_updates boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    admin boolean DEFAULT false,
    full_name text,
    address_street text,
    address_number text,
    address_complement text,
    address_neighbourhood text,
    address_city text,
    address_state text,
    address_zip_code text,
    phone_number text,
    locale text DEFAULT 'pt'::text NOT NULL,
    cpf text,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    twitter character varying(255),
    facebook_link character varying(255),
    other_link character varying(255),
    uploaded_image text,
    moip_login character varying(255),
    state_inscription character varying(255),
    CONSTRAINT users_bio_length_within CHECK (((length(bio) >= 0) AND (length(bio) <= 140))),
    CONSTRAINT users_provider_not_blank CHECK ((length(btrim(provider)) > 0)),
    CONSTRAINT users_uid_not_blank CHECK ((length(btrim(uid)) > 0))
);


ALTER TABLE public.users OWNER TO catarse;

--
-- Name: backer_reports; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW backer_reports AS
    SELECT b.project_id, u.name, b.value, r.minimum_value, r.description, b.payment_method, b.payment_choice, b.payment_service_fee, b.key, (b.created_at)::date AS created_at, (b.confirmed_at)::date AS confirmed_at, u.email, b.payer_email, b.payer_name, COALESCE(b.payer_document, u.cpf) AS cpf, u.address_street, u.address_complement, u.address_number, u.address_neighbourhood, u.address_city, u.address_state, u.address_zip_code, b.requested_refund, b.refunded FROM ((backers b JOIN users u ON ((u.id = b.user_id))) LEFT JOIN rewards r ON ((r.id = b.reward_id))) WHERE b.confirmed;


ALTER TABLE public.backer_reports OWNER TO catarse;

--
-- Name: configurations; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE configurations (
    id integer NOT NULL,
    name text NOT NULL,
    value text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT configurations_name_not_blank CHECK ((length(btrim(name)) > 0))
);


ALTER TABLE public.configurations OWNER TO catarse;

--
-- Name: backer_reports_for_project_owners; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW backer_reports_for_project_owners AS
    SELECT b.project_id, COALESCE(r.id, 0) AS reward_id, r.description AS reward_description, (b.confirmed_at)::date AS confirmed_at, b.value AS back_value, (b.value * (SELECT (configurations.value)::numeric AS value FROM configurations WHERE (configurations.name = 'catarse_fee'::text))) AS service_fee, u.email AS user_email, b.payer_email, b.payment_method, COALESCE(b.address_street, u.address_street) AS street, COALESCE(b.address_complement, u.address_complement) AS complement, COALESCE(b.address_number, u.address_number) AS address_number, COALESCE(b.address_neighbourhood, u.address_neighbourhood) AS neighbourhood, COALESCE(b.address_city, u.address_city) AS city, COALESCE(b.address_state, u.address_state) AS state, COALESCE(b.address_zip_code, u.address_zip_code) AS zip_code FROM ((backers b JOIN users u ON ((u.id = b.user_id))) LEFT JOIN rewards r ON ((r.id = b.reward_id))) WHERE b.confirmed;


ALTER TABLE public.backer_reports_for_project_owners OWNER TO catarse;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE categories (
    id integer NOT NULL,
    name_pt text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name_en character varying(255),
    name_hk character varying(255),
    CONSTRAINT categories_name_not_blank CHECK ((length(btrim(name_pt)) > 0))
);


ALTER TABLE public.categories OWNER TO catarse;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE projects (
    id integer NOT NULL,
    name text NOT NULL,
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    goal numeric NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    about text NOT NULL,
    headline text NOT NULL,
    video_url text,
    image_url text,
    short_url text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    can_finish boolean DEFAULT false,
    finished boolean DEFAULT false,
    about_html text,
    visible boolean DEFAULT false,
    rejected boolean DEFAULT false,
    recommended boolean DEFAULT false,
    home_page_comment text,
    successful boolean DEFAULT false,
    permalink text NOT NULL,
    video_thumbnail text,
    state character varying(255),
    online_days integer DEFAULT 0,
    online_date timestamp without time zone,
    how_know text,
    more_links text,
    first_backers text,
    uploaded_image character varying(255),
    CONSTRAINT projects_about_not_blank CHECK ((length(btrim(about)) > 0)),
    CONSTRAINT projects_headline_length_within CHECK (((length(headline) >= 1) AND (length(headline) <= 140))),
    CONSTRAINT projects_headline_not_blank CHECK ((length(btrim(headline)) > 0))
);


ALTER TABLE public.projects OWNER TO catarse;

--
-- Name: backers_by_category; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW backers_by_category AS
    SELECT to_char(p.expires_at, 'yyyy'::text) AS year, c.name_pt AS category, sum(b.value) AS total_backed, count(DISTINCT b.user_id) AS total_backers FROM ((backers b JOIN projects p ON ((p.id = b.project_id))) JOIN categories c ON ((c.id = p.category_id))) WHERE b.confirmed GROUP BY to_char(p.expires_at, 'yyyy'::text), c.name_pt ORDER BY to_char(p.expires_at, 'yyyy'::text), c.name_pt;


ALTER TABLE public.backers_by_category OWNER TO catarse;

--
-- Name: backers_by_payment_choice; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW backers_by_payment_choice AS
    SELECT to_char(p.expires_at, 'yyyy-mm'::text) AS month, backers.payment_method, backers.payment_choice, sum(backers.value) AS total_backed, (sum(backers.value) / bbm.total_month_backed) AS payment_choice_ratio, sum(CASE WHEN backers.refunded THEN backers.value ELSE NULL::numeric END) AS total_refunded, (sum(CASE WHEN backers.refunded THEN backers.value ELSE NULL::numeric END) / bbm.total_month_backed) AS refunded_ratio FROM ((projects p JOIN backers ON ((backers.project_id = p.id))) JOIN (SELECT to_char(b2.created_at, 'yyyy-mm'::text) AS b2month, sum(b2.value) AS total_month_backed FROM backers b2 WHERE b2.confirmed GROUP BY to_char(b2.created_at, 'yyyy-mm'::text)) bbm ON ((bbm.b2month = to_char(backers.created_at, 'yyyy-mm'::text)))) WHERE backers.confirmed GROUP BY to_char(p.expires_at, 'yyyy-mm'::text), bbm.total_month_backed, backers.payment_method, backers.payment_choice ORDER BY to_char(p.expires_at, 'yyyy-mm'::text), backers.payment_method, backers.payment_choice;


ALTER TABLE public.backers_by_payment_choice OWNER TO catarse;

--
-- Name: backers_by_project; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW backers_by_project AS
    SELECT backers.project_id, sum(backers.value) AS total_backed, max(backers.value) AS max_backed, count(DISTINCT backers.user_id) AS total_backers FROM backers WHERE backers.confirmed GROUP BY backers.project_id;


ALTER TABLE public.backers_by_project OWNER TO catarse;

--
-- Name: backers_by_state; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW backers_by_state AS
    SELECT to_char(p.expires_at, 'yyyy'::text) AS year, NULLIF(u.address_state, ''::text) AS state, sum(b.value) AS total_backed, count(DISTINCT b.user_id) AS total_backers FROM ((backers b JOIN projects p ON ((b.project_id = p.id))) JOIN users u ON ((u.id = b.user_id))) WHERE b.confirmed GROUP BY to_char(p.expires_at, 'yyyy'::text), NULLIF(u.address_state, ''::text) ORDER BY to_char(p.expires_at, 'yyyy'::text), NULLIF(u.address_state, ''::text);


ALTER TABLE public.backers_by_state OWNER TO catarse;

--
-- Name: backers_by_year; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW backers_by_year AS
    SELECT to_char(p.expires_at, 'yyyy'::text) AS year, sum(backers.value) AS total_backed, count(DISTINCT backers.user_id) AS total_backers, count(DISTINCT CASE WHEN (backers.reward_id IS NULL) THEN backers.user_id ELSE NULL::integer END) AS total_backers_without_reward, ((count(DISTINCT CASE WHEN (backers.reward_id IS NULL) THEN backers.user_id ELSE NULL::integer END))::numeric / (count(DISTINCT backers.user_id))::numeric) AS backers_without_reward_ratio, max(backers.value) AS maximum_back FROM (backers JOIN projects p ON ((backers.project_id = p.id))) WHERE backers.confirmed GROUP BY to_char(p.expires_at, 'yyyy'::text);


ALTER TABLE public.backers_by_year OWNER TO catarse;

--
-- Name: backers_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE backers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.backers_id_seq OWNER TO catarse;

--
-- Name: backers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE backers_id_seq OWNED BY backers.id;


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categories_id_seq OWNER TO catarse;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;


--
-- Name: configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.configurations_id_seq OWNER TO catarse;

--
-- Name: configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE configurations_id_seq OWNED BY configurations.id;


--
-- Name: notification_types; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE notification_types (
    id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.notification_types OWNER TO catarse;

--
-- Name: notification_types_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE notification_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notification_types_id_seq OWNER TO catarse;

--
-- Name: notification_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE notification_types_id_seq OWNED BY notification_types.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE notifications (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer,
    dismissed boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notification_type_id integer NOT NULL,
    backer_id integer,
    update_id integer
);


ALTER TABLE public.notifications OWNER TO catarse;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO catarse;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: oauth_providers; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE oauth_providers (
    id integer NOT NULL,
    name text NOT NULL,
    key text NOT NULL,
    secret text NOT NULL,
    scope text,
    "order" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    strategy text,
    path text,
    CONSTRAINT oauth_providers_key_not_blank CHECK ((length(btrim(key)) > 0)),
    CONSTRAINT oauth_providers_name_not_blank CHECK ((length(btrim(name)) > 0)),
    CONSTRAINT oauth_providers_secret_not_blank CHECK ((length(btrim(secret)) > 0))
);


ALTER TABLE public.oauth_providers OWNER TO catarse;

--
-- Name: oauth_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE oauth_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oauth_providers_id_seq OWNER TO catarse;

--
-- Name: oauth_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE oauth_providers_id_seq OWNED BY oauth_providers.id;


--
-- Name: payment_logs; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE payment_logs (
    id integer NOT NULL,
    backer_id integer,
    status integer,
    amount double precision,
    payment_status integer,
    moip_id integer,
    payment_method integer,
    payment_type character varying(255),
    consumer_email character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.payment_logs OWNER TO catarse;

--
-- Name: payment_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE payment_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_logs_id_seq OWNER TO catarse;

--
-- Name: payment_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE payment_logs_id_seq OWNED BY payment_logs.id;


--
-- Name: payment_notifications; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE payment_notifications (
    id integer NOT NULL,
    backer_id integer NOT NULL,
    extra_data text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.payment_notifications OWNER TO catarse;

--
-- Name: payment_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE payment_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_notifications_id_seq OWNER TO catarse;

--
-- Name: payment_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE payment_notifications_id_seq OWNED BY payment_notifications.id;


--
-- Name: paypal_payments; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE paypal_payments (
    data text,
    hora text,
    fusohorario text,
    nome text,
    tipo text,
    status text,
    moeda text,
    valorbruto text,
    tarifa text,
    liquido text,
    doe_mail text,
    parae_mail text,
    iddatransacao text,
    statusdoequivalente text,
    statusdoendereco text,
    titulodoitem text,
    iddoitem text,
    valordoenvioemanuseio text,
    valordoseguro text,
    impostosobrevendas text,
    opcao1nome text,
    opcao1valor text,
    opcao2nome text,
    opcao2valor text,
    sitedoleilao text,
    iddocomprador text,
    urldoitem text,
    datadetermino text,
    iddaescritura text,
    iddafatura text,
    "idtxn_dereferência" text,
    numerodafatura text,
    numeropersonalizado text,
    iddorecibo text,
    saldo text,
    enderecolinha1 text,
    enderecolinha2_distrito_bairro text,
    cidade text,
    "estado_regiao_território_prefeitura_republica" text,
    cep text,
    pais text,
    numerodotelefoneparacontato text,
    extra text
);


ALTER TABLE public.paypal_payments OWNER TO catarse;

--
-- Name: paypal_pending; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW paypal_pending AS
    SELECT string_agg((b.id)::text, ','::text) AS string_agg FROM (backers b JOIN paypal_payments p ON ((lower(p.doe_mail) = b.payer_email))) WHERE ((((b.payment_method = 'PayPal'::text) AND (p.status = 'Concluído'::text)) AND (NOT b.confirmed)) AND (to_number(p.valorbruto, '9,99'::text) = b.value));


ALTER TABLE public.paypal_pending OWNER TO catarse;

--
-- Name: project_totals; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW project_totals AS
    SELECT backers.project_id, sum(backers.value) AS pledged, count(*) AS total_backers FROM backers WHERE (backers.confirmed = true) GROUP BY backers.project_id;


ALTER TABLE public.project_totals OWNER TO catarse;

--
-- Name: projects_by_category; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW projects_by_category AS
    SELECT to_char(p.expires_at, 'yyyy'::text) AS year, c.name_pt AS category, count(*) AS total_projects, count(NULLIF(p.successful, false)) AS successful_projects FROM (projects p JOIN categories c ON ((c.id = p.category_id))) WHERE p.finished GROUP BY to_char(p.expires_at, 'yyyy'::text), c.name_pt ORDER BY to_char(p.expires_at, 'yyyy'::text), c.name_pt;


ALTER TABLE public.projects_by_category OWNER TO catarse;

--
-- Name: projects_by_state; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW projects_by_state AS
    SELECT to_char(p.expires_at, 'yyyy'::text) AS year, NULLIF(btrim(u.address_state), ''::text) AS uf, count(*) AS total_projects, count(NULLIF(p.successful, false)) AS successful_projects FROM (projects p JOIN users u ON ((u.id = p.user_id))) WHERE p.finished GROUP BY to_char(p.expires_at, 'yyyy'::text), NULLIF(btrim(u.address_state), ''::text) ORDER BY to_char(p.expires_at, 'yyyy'::text), NULLIF(btrim(u.address_state), ''::text);


ALTER TABLE public.projects_by_state OWNER TO catarse;

--
-- Name: total_backed_ranges; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE total_backed_ranges (
    name text NOT NULL,
    lower numeric,
    upper numeric
);


ALTER TABLE public.total_backed_ranges OWNER TO catarse;

--
-- Name: projects_by_total_backed_ranges; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW projects_by_total_backed_ranges AS
    SELECT tbr.lower, tbr.upper, count(*) AS count, ((count(*))::numeric / ((SELECT count(*) AS count FROM backers_by_project))::numeric) AS ratio FROM (backers_by_project bp JOIN total_backed_ranges tbr ON (((bp.total_backed >= tbr.lower) AND (bp.total_backed <= tbr.upper)))) GROUP BY tbr.lower, tbr.upper ORDER BY tbr.lower;


ALTER TABLE public.projects_by_total_backed_ranges OWNER TO catarse;

--
-- Name: projects_by_year; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW projects_by_year AS
    SELECT to_char(p.expires_at, 'yyyy'::text) AS year, count(*) AS total_projects, count(NULLIF(p.successful, false)) AS successful_projects, sum(CASE WHEN p.successful THEN b.total_backed ELSE NULL::numeric END) AS successful_total_backed, max(b.total_backed) AS max_total_backed, max(b.max_backed) AS max_backed, max(b.total_backers) AS max_total_backers FROM (projects p LEFT JOIN backers_by_project b ON ((b.project_id = p.id))) WHERE p.finished GROUP BY to_char(p.expires_at, 'yyyy'::text) ORDER BY to_char(p.expires_at, 'yyyy'::text);


ALTER TABLE public.projects_by_year OWNER TO catarse;

--
-- Name: projects_curated_pages; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE projects_curated_pages (
    id integer NOT NULL,
    project_id integer,
    curated_page_id integer,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description_html text
);


ALTER TABLE public.projects_curated_pages OWNER TO catarse;

--
-- Name: projects_curated_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE projects_curated_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_curated_pages_id_seq OWNER TO catarse;

--
-- Name: projects_curated_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE projects_curated_pages_id_seq OWNED BY projects_curated_pages.id;


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO catarse;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: recurring_backers_by_year; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW recurring_backers_by_year AS
    SELECT bby.year, trb.total_recurring_backed, bby.total_backed, (trb.total_recurring_backed / bby.total_backed) AS recurring_backed_ratio, trb.total_recurring_backers, bby.total_backers, (trb.total_recurring_backers / (bby.total_backers)::numeric) AS recurring_backers_ratio FROM ((SELECT rb.year, sum(rb.total_recurring_backed) AS total_recurring_backed, sum(rb.total_recurring_backers) AS total_recurring_backers FROM (SELECT to_char(backers.created_at, 'yyyy'::text) AS year, sum(backers.value) AS total_recurring_backed, count(DISTINCT backers.user_id) AS total_recurring_backers FROM backers WHERE backers.confirmed GROUP BY to_char(backers.created_at, 'yyyy'::text), backers.user_id HAVING (count(*) > 1)) rb GROUP BY rb.year) trb JOIN backers_by_year bby USING (year));


ALTER TABLE public.recurring_backers_by_year OWNER TO catarse;

--
-- Name: reward_ranges; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE reward_ranges (
    name text NOT NULL,
    lower numeric,
    upper numeric
);


ALTER TABLE public.reward_ranges OWNER TO catarse;

--
-- Name: rewards_by_range; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW rewards_by_range AS
    SELECT rr.name AS range, count(*) AS count, ((count(*))::numeric / ((SELECT count(*) AS count FROM backers WHERE (backers.confirmed AND (backers.reward_id IS NOT NULL))))::numeric) AS ratio FROM ((reward_ranges rr JOIN rewards r ON (((r.minimum_value >= rr.lower) AND (r.minimum_value <= rr.upper)))) JOIN backers b ON ((b.reward_id = r.id))) WHERE b.confirmed GROUP BY rr.name, rr.lower ORDER BY rr.lower;


ALTER TABLE public.rewards_by_range OWNER TO catarse;

--
-- Name: rewards_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE rewards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rewards_id_seq OWNER TO catarse;

--
-- Name: rewards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE rewards_id_seq OWNED BY rewards.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO catarse;

--
-- Name: states; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE states (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    acronym character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    CONSTRAINT states_acronym_not_blank CHECK ((length(btrim((acronym)::text)) > 0)),
    CONSTRAINT states_name_not_blank CHECK ((length(btrim((name)::text)) > 0))
);


ALTER TABLE public.states OWNER TO catarse;

--
-- Name: states_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.states_id_seq OWNER TO catarse;

--
-- Name: states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE states_id_seq OWNED BY states.id;


--
-- Name: statistics; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW statistics AS
    SELECT (SELECT count(*) AS count FROM users) AS total_users, backers_totals.total_backs, backers_totals.total_backers, backers_totals.total_backed, projects_totals.total_projects, projects_totals.total_projects_success, projects_totals.total_projects_online FROM (SELECT count(*) AS total_backs, count(DISTINCT backers.user_id) AS total_backers, sum(backers.value) AS total_backed FROM backers WHERE backers.confirmed) backers_totals, (SELECT count(*) AS total_projects, count(CASE WHEN ((projects.state)::text = 'successful'::text) THEN 1 ELSE NULL::integer END) AS total_projects_success, count(CASE WHEN ((projects.state)::text = 'online'::text) THEN 1 ELSE NULL::integer END) AS total_projects_online FROM projects WHERE ((projects.state)::text <> ALL (ARRAY[('draft'::character varying)::text, ('rejected'::character varying)::text]))) projects_totals;


ALTER TABLE public.statistics OWNER TO catarse;

--
-- Name: unsubscribes; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE unsubscribes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    notification_type_id integer NOT NULL,
    project_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.unsubscribes OWNER TO catarse;

--
-- Name: unsubscribes_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE unsubscribes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.unsubscribes_id_seq OWNER TO catarse;

--
-- Name: unsubscribes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE unsubscribes_id_seq OWNED BY unsubscribes.id;


--
-- Name: updates; Type: TABLE; Schema: public; Owner: catarse; Tablespace: 
--

CREATE TABLE updates (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer NOT NULL,
    title text,
    comment text NOT NULL,
    comment_html text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.updates OWNER TO catarse;

--
-- Name: updates_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE updates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.updates_id_seq OWNER TO catarse;

--
-- Name: updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE updates_id_seq OWNED BY updates.id;


--
-- Name: user_totals; Type: VIEW; Schema: public; Owner: catarse
--

CREATE VIEW user_totals AS
    SELECT b.user_id AS id, b.user_id, sum(b.value) AS sum, count(*) AS count, sum(CASE WHEN (((p.state)::text <> 'failed'::text) AND (NOT b.credits)) THEN (0)::numeric WHEN (((p.state)::text = 'failed'::text) AND ((b.requested_refund AND (NOT b.credits)) OR (b.credits AND (NOT b.requested_refund)))) THEN (0)::numeric WHEN ((((p.state)::text = 'failed'::text) AND (NOT b.credits)) AND (NOT b.requested_refund)) THEN b.value ELSE (b.value * ((-1))::numeric) END) AS credits FROM (backers b JOIN projects p ON ((b.project_id = p.id))) WHERE (b.confirmed = true) GROUP BY b.user_id;


ALTER TABLE public.user_totals OWNER TO catarse;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: catarse
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO catarse;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: catarse
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY authorizations ALTER COLUMN id SET DEFAULT nextval('authorizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY backers ALTER COLUMN id SET DEFAULT nextval('backers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY categories ALTER COLUMN id SET DEFAULT nextval('categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY configurations ALTER COLUMN id SET DEFAULT nextval('configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY notification_types ALTER COLUMN id SET DEFAULT nextval('notification_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY oauth_providers ALTER COLUMN id SET DEFAULT nextval('oauth_providers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY payment_logs ALTER COLUMN id SET DEFAULT nextval('payment_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY payment_notifications ALTER COLUMN id SET DEFAULT nextval('payment_notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY projects_curated_pages ALTER COLUMN id SET DEFAULT nextval('projects_curated_pages_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY rewards ALTER COLUMN id SET DEFAULT nextval('rewards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY states ALTER COLUMN id SET DEFAULT nextval('states_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY unsubscribes ALTER COLUMN id SET DEFAULT nextval('unsubscribes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY updates ALTER COLUMN id SET DEFAULT nextval('updates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Data for Name: authorizations; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY authorizations (id, oauth_provider_id, user_id, uid, created_at, updated_at) FROM stdin;
4	1	9	100003512842149	2013-03-09 19:27:33.285691	2013-03-09 19:27:33.285691
5	1	13	100000266146023	2013-03-10 14:34:29.860762	2013-03-10 14:34:29.860762
\.


--
-- Name: authorizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('authorizations_id_seq', 5, true);


--
-- Data for Name: backers; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY backers (id, project_id, user_id, reward_id, value, confirmed, confirmed_at, created_at, updated_at, anonymous, key, requested_refund, refunded, credits, notified_finish, payment_method, payment_token, payment_id, payer_name, payer_email, payer_document, address_street, address_number, address_complement, address_neighbourhood, address_zip_code, address_city, address_state, address_phone_number, payment_choice, payment_service_fee) FROM stdin;
1	1	5	\N	50.0	t	2013-03-09 17:40:42.207813	2013-03-09 17:36:21.550193	2013-03-09 17:40:42.997166	f	f26bc9cd640c3fc6fc06288f8c484a1c	f	f	f	f	MoIP	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Name: backers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('backers_id_seq', 1, true);


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY categories (id, name_pt, created_at, updated_at, name_en, name_hk) FROM stdin;
1	Arte	2013-03-09 14:07:31.736854	2013-03-09 14:07:31.749655	Art	Art
2	Artes plásticas	2013-03-09 14:07:31.755312	2013-03-09 14:07:31.759305	Visual Arts	Visual Arts
3	Circo	2013-03-09 14:07:31.763556	2013-03-09 14:07:31.767334	Circus	Circus
4	Comunidade	2013-03-09 14:07:31.771939	2013-03-09 14:07:31.775578	Community	Community
5	Feito à mão	2013-03-09 14:07:31.779914	2013-03-09 14:07:31.783746	Handmade	Handmade
6	Humor	2013-03-09 14:07:31.788689	2013-03-09 14:07:31.79258	Humor	Humor
7	Quadrinhos	2013-03-09 14:07:31.796818	2013-03-09 14:07:31.800294	Comicbooks	Comicbooks
8	Dança	2013-03-09 14:07:31.804748	2013-03-09 14:07:31.808555	Dance	Dance
9	Design	2013-03-09 14:07:31.81266	2013-03-09 14:07:31.81608	Design	Design
10	Eventos	2013-03-09 14:07:31.820308	2013-03-09 14:07:31.823617	Events	Events
11	Moda	2013-03-09 14:07:31.827573	2013-03-09 14:07:31.830891	Fashion	Fashion
12	Comida	2013-03-09 14:07:31.83489	2013-03-09 14:07:31.838264	Food	Food
13	Cinema & Vídeo	2013-03-09 14:07:31.84253	2013-03-09 14:07:31.846287	Film & Video	Film & Video
14	Jogos	2013-03-09 14:07:31.850408	2013-03-09 14:07:31.853895	Games	Games
15	Jornalismo	2013-03-09 14:07:31.857984	2013-03-09 14:07:31.861711	Journalism	Journalism
16	Música	2013-03-09 14:07:31.866607	2013-03-09 14:07:31.87035	Music	Music
17	Fotografia	2013-03-09 14:07:31.874876	2013-03-09 14:07:31.878452	Photography	Photography
18	Tecnologia	2013-03-09 14:07:31.882498	2013-03-09 14:07:31.886057	Technology	Technology
19	Teatro	2013-03-09 14:07:31.890349	2013-03-09 14:07:31.893815	Theatre	Theatre
20	Esporte	2013-03-09 14:07:31.897798	2013-03-09 14:07:31.901229	Sport	Sport
21	Graffiti	2013-03-09 14:07:31.905439	2013-03-09 14:07:31.90875	Graffiti	Graffiti
22	Web	2013-03-09 14:07:31.912688	2013-03-09 14:07:31.916137	Web	Web
23	Carnaval	2013-03-09 14:07:31.92023	2013-03-09 14:07:31.923495	Carnival	Carnival
24	Arquitetura & Urbanismo	2013-03-09 14:07:31.927556	2013-03-09 14:07:31.930988	Architecture & Urbanism	Architecture & Urbanism
25	Literatura	2013-03-09 14:07:31.934922	2013-03-09 14:07:31.93858	Literature	Literature
\.


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('categories_id_seq', 25, true);


--
-- Data for Name: configurations; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY configurations (id, name, value, created_at, updated_at) FROM stdin;
1	company_name	Pullwater	2013-03-09 14:07:32.005318	2013-03-09 14:07:32.005318
2	host	pullwater.com	2013-03-09 14:07:32.01054	2013-03-09 14:07:32.01054
3	base_url	http://pullwater.com	2013-03-09 14:07:32.014657	2013-03-09 14:07:32.014657
4	blog_url	 http://pullwater.tumblr.com/	2013-03-09 14:07:32.017885	2013-03-09 14:07:32.017885
5	email_contact	contato@pullwater.com	2013-03-09 14:07:32.020984	2013-03-09 14:07:32.020984
6	email_payments	financeiro@pullwater.com	2013-03-09 14:07:32.024008	2013-03-09 14:07:32.024008
7	email_projects	projetos@pullwater.com	2013-03-09 14:07:32.027021	2013-03-09 14:07:32.027021
8	email_system	system@pullwater.com	2013-03-09 14:07:32.030224	2013-03-09 14:07:32.030224
9	email_no_reply	no-reply@pullwater.com	2013-03-09 14:07:32.033271	2013-03-09 14:07:32.033271
10	facebook_url	http://facebook.com/pullwater	2013-03-09 14:07:32.036434	2013-03-09 14:07:32.036434
11	facebook_app_id	427111090709356	2013-03-09 14:07:32.039418	2013-03-09 14:07:32.039418
12	twitter_username	pullwaterhk	2013-03-09 14:07:32.04241	2013-03-09 14:07:32.04241
13	bitly_api_login	pullwater	2013-03-09 14:07:32.045356	2013-03-09 14:07:32.045356
14	bitly_api_key	R_60f3630aebaf46c793c00e3048255724	2013-03-09 14:07:32.04828	2013-03-09 14:07:32.04828
15	mailchimp_url	http://pullwater.us6.list-manage.com/subscribe?u=394bd62853&id=60dfd14046&id=60dfd14046	2013-03-09 14:07:32.051337	2013-03-09 14:07:32.051337
16	catarse_fee	0.13	2013-03-09 14:07:32.054298	2013-03-09 14:07:32.054298
18	aws_access_key	AKIAIOAB2BJZOUBD23JQ	2013-03-09 19:53:56.445556	2013-03-09 19:53:56.445556
19	aws_secret_key	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	2013-03-09 19:54:16.855575	2013-03-09 19:54:16.855575
20	aws_bucket	pullwater	2013-03-09 19:54:57.847446	2013-03-09 19:54:57.847446
\.


--
-- Name: configurations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('configurations_id_seq', 20, true);


--
-- Data for Name: notification_types; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY notification_types (id, name, created_at, updated_at) FROM stdin;
1	confirm_backer	2013-03-09 14:07:31.956357	2013-03-09 14:07:31.956357
2	payment_slip	2013-03-09 14:07:31.961073	2013-03-09 14:07:31.961073
3	project_success	2013-03-09 14:07:31.964178	2013-03-09 14:07:31.964178
4	backer_project_successful	2013-03-09 14:07:31.967409	2013-03-09 14:07:31.967409
5	backer_project_unsuccessful	2013-03-09 14:07:31.970789	2013-03-09 14:07:31.970789
6	project_received	2013-03-09 14:07:31.973921	2013-03-09 14:07:31.973921
7	updates	2013-03-09 14:07:31.976857	2013-03-09 14:07:31.976857
8	project_unsuccessful	2013-03-09 14:07:31.979779	2013-03-09 14:07:31.979779
9	project_visible	2013-03-09 14:07:31.982712	2013-03-09 14:07:31.982712
10	processing_payment	2013-03-09 14:07:31.985607	2013-03-09 14:07:31.985607
11	new_draft_project	2013-03-09 14:07:31.988644	2013-03-09 14:07:31.988644
12	project_rejected	2013-03-09 14:07:31.991746	2013-03-09 14:07:31.991746
\.


--
-- Name: notification_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('notification_types_id_seq', 12, true);


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY notifications (id, user_id, project_id, dismissed, created_at, updated_at, notification_type_id, backer_id, update_id) FROM stdin;
1	3	1	t	2013-03-09 15:34:42.876131	2013-03-09 15:34:42.876131	6	\N	\N
2	4	2	t	2013-03-09 15:37:55.048765	2013-03-09 15:37:55.048765	6	\N	\N
3	3	1	t	2013-03-09 15:39:51.943778	2013-03-09 15:39:51.943778	9	\N	\N
4	5	\N	t	2013-03-09 17:40:42.277826	2013-03-09 17:40:42.277826	1	1	\N
5	4	2	t	2013-03-10 05:18:35.92192	2013-03-10 05:18:35.92192	9	\N	\N
8	12	4	t	2013-03-10 13:21:18.7977	2013-03-10 13:21:18.7977	6	\N	\N
9	12	4	t	2013-03-10 13:22:51.464797	2013-03-10 13:22:51.464797	9	\N	\N
10	12	5	t	2013-03-10 13:30:39.738601	2013-03-10 13:30:39.738601	6	\N	\N
11	12	5	t	2013-03-10 13:30:59.295586	2013-03-10 13:30:59.295586	12	\N	\N
12	12	5	t	2013-03-10 13:35:16.052885	2013-03-10 13:35:16.052885	9	\N	\N
\.


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('notifications_id_seq', 12, true);


--
-- Data for Name: oauth_providers; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY oauth_providers (id, name, key, secret, scope, "order", created_at, updated_at, strategy, path) FROM stdin;
1	facebook	427111090709356	e9127ca3234a9955b2608784c1cd80a3	\N	\N	2013-03-09 14:25:16.09995	2013-03-09 14:25:16.09995	Facebook	facebook
\.


--
-- Name: oauth_providers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('oauth_providers_id_seq', 1, true);


--
-- Data for Name: payment_logs; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY payment_logs (id, backer_id, status, amount, payment_status, moip_id, payment_method, payment_type, consumer_email, created_at, updated_at) FROM stdin;
\.


--
-- Name: payment_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('payment_logs_id_seq', 1, false);


--
-- Data for Name: payment_notifications; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY payment_notifications (id, backer_id, extra_data, created_at, updated_at) FROM stdin;
\.


--
-- Name: payment_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('payment_notifications_id_seq', 1, false);


--
-- Data for Name: paypal_payments; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY paypal_payments (data, hora, fusohorario, nome, tipo, status, moeda, valorbruto, tarifa, liquido, doe_mail, parae_mail, iddatransacao, statusdoequivalente, statusdoendereco, titulodoitem, iddoitem, valordoenvioemanuseio, valordoseguro, impostosobrevendas, opcao1nome, opcao1valor, opcao2nome, opcao2valor, sitedoleilao, iddocomprador, urldoitem, datadetermino, iddaescritura, iddafatura, "idtxn_dereferência", numerodafatura, numeropersonalizado, iddorecibo, saldo, enderecolinha1, enderecolinha2_distrito_bairro, cidade, "estado_regiao_território_prefeitura_republica", cep, pais, numerodotelefoneparacontato, extra) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY projects (id, name, user_id, category_id, goal, expires_at, about, headline, video_url, image_url, short_url, created_at, updated_at, can_finish, finished, about_html, visible, rejected, recommended, home_page_comment, successful, permalink, video_thumbnail, state, online_days, online_date, how_know, more_links, first_backers, uploaded_image) FROM stdin;
5	another	12	9	80.0	2013-04-03 13:35:15	asd	asdf	http://vimeo.com/4749536	\N	\N	2013-03-10 13:30:39.586883	2013-03-10 13:35:15.984737	f	f	<p>asd</p>	f	f	t	\N	f	another	\N	online	24	2013-03-10 13:35:15	sd	asd	sd	\N
2	project2	4	8	200.0	2013-03-30 05:18:35	about project2	punchline project2	http://vimeo.com/52422837	\N	\N	2013-03-09 15:37:54.981808	2013-03-10 10:26:40.110131	f	f	<p>about project2</p>	f	f	t	\N	f	proj2	\N	online	20	2013-03-10 05:18:35	How know	More links	First Backers	\N
1	project1	3	20	500.0	2013-04-08 15:39:51	About project1	punchline project1	http://vimeo.com/60043114	\N	\N	2013-03-09 15:34:42.798857	2013-03-10 11:29:58.914652	f	f	<p>About project1</p>	f	f	t	\N	f	proj1	\N	online	30	2013-03-09 15:39:51	How know	More links herer	First Backer	\N
4	test3	12	24	23.0	2013-04-19 13:22:51	test3	tes	http://vimeo.com/28355660	\N	\N	2013-03-10 13:21:18.666029	2013-03-10 13:22:55.684839	f	f	<p>test3</p>	f	f	t	\N	f	skd	\N	online	40	2013-03-10 13:22:51	excelletn	later	las, asdfm	\N
\.


--
-- Data for Name: projects_curated_pages; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY projects_curated_pages (id, project_id, curated_page_id, description, created_at, updated_at, description_html) FROM stdin;
\.


--
-- Name: projects_curated_pages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('projects_curated_pages_id_seq', 1, false);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('projects_id_seq', 5, true);


--
-- Data for Name: reward_ranges; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY reward_ranges (name, lower, upper) FROM stdin;
\.


--
-- Data for Name: rewards; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY rewards (id, project_id, minimum_value, maximum_backers, description, created_at, updated_at) FROM stdin;
1	2	3.0	6	description	2013-03-09 15:38:45.510408	2013-03-09 15:38:45.510408
2	4	6.0	3	set	2013-03-10 13:26:00.391806	2013-03-10 13:26:00.391806
3	4	3.0	6	est	2013-03-10 13:26:13.844581	2013-03-10 13:26:13.844581
4	5	1.0	\N	asd	2013-03-10 13:33:31.897211	2013-03-10 13:33:31.897211
5	5	1.0	\N	asd	2013-03-10 13:33:32.229407	2013-03-10 13:33:32.229407
\.


--
-- Name: rewards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('rewards_id_seq', 5, true);


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY schema_migrations (version) FROM stdin;
20121226120921
20121227012003
20121227012324
20121230111351
20130102180139
20130104005632
20130104104501
20130105123546
20130110191750
20130117205659
20130118193907
20130121162447
20130121204224
20130121212325
20130131121553
20130201200604
20130201202648
20130201202829
20130201205659
20130204192704
20130205143533
20130206121758
20130211174609
20130212145115
20130213184141
20130218201312
20130218201751
20130221171018
20130221172840
20130221175717
20130221184144
20130221185532
20130221201732
20130222163633
20130225135512
20130225141802
20130228141234
20130309140350
\.


--
-- Data for Name: states; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY states (id, name, acronym, created_at, updated_at) FROM stdin;
\.


--
-- Name: states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('states_id_seq', 1, false);


--
-- Data for Name: total_backed_ranges; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY total_backed_ranges (name, lower, upper) FROM stdin;
\.


--
-- Data for Name: unsubscribes; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY unsubscribes (id, user_id, notification_type_id, project_id, created_at, updated_at) FROM stdin;
\.


--
-- Name: unsubscribes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('unsubscribes_id_seq', 1, false);


--
-- Data for Name: updates; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY updates (id, user_id, project_id, title, comment, comment_html, created_at, updated_at) FROM stdin;
\.


--
-- Name: updates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('updates_id_seq', 4, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: catarse
--

COPY users (id, primary_user_id, provider, uid, email, name, nickname, bio, image_url, newsletter, project_updates, created_at, updated_at, admin, full_name, address_street, address_number, address_complement, address_neighbourhood, address_city, address_state, address_zip_code, phone_number, locale, cpf, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at, sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, twitter, facebook_link, other_link, uploaded_image, moip_login, state_inscription) FROM stdin;
3	\N	\N	\N	test1@gmail.com	test1	\N		\N	f	f	2013-03-09 14:44:28.119585	2013-03-10 11:28:21.568658	f										en		$2a$10$T9Dkqyk7fxmlce8dpRy0A.s1K/Q87ubvcT18lxajkiZEL96XgoQgC	\N	\N	\N	4	2013-03-10 11:26:16.782637	2013-03-09 15:31:20.137343	116.203.230.5	180.215.134.125				\N		
9	\N	\N	\N	msoni@tekpalette.com	Mahendra Soni	mahendra.soni.3990	\N	https://graph.facebook.com/100003512842149/picture?type=large	f	f	2013-03-09 19:27:33.279395	2013-03-09 19:27:33.289529	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	en	\N	$2a$10$DWu4WHpCeu7uc3jvbkD5beGUDlXba8N9r1uLs5PZEd8GxGF8kuhYO	\N	\N	\N	1	2013-03-09 19:27:33.28815	2013-03-09 19:27:33.28815	180.215.134.125	180.215.134.125	\N	\N	\N	\N	\N	\N
11	\N	\N	\N	test5@gmail.com	test5	\N	\N	\N	t	f	2013-03-10 10:13:30.411644	2013-03-10 11:31:15.455162	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	hk	\N	$2a$10$vsmuTRuylxlmtsFxJ4fyFO7DvKBwy2VVXdRnRQPd.YyA5ZtG/vyQC	\N	\N	\N	2	2013-03-10 11:31:15.446789	2013-03-10 10:13:30.446183	116.203.230.5	116.203.230.5	\N	\N	\N	\N	\N	\N
10	\N	\N	\N	hkadrian@gmail.com	adrian	\N	\N	\N	t	f	2013-03-10 06:05:28.930953	2013-03-10 06:09:25.353533	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	hk	\N	$2a$10$gG88v6dw/ku1cdtfTYfNd.rMQa0tFa.026YIQVgtJ.IPm/Rv4NSNm	\N	\N	\N	2	2013-03-10 06:08:09.408816	2013-03-10 06:05:28.954081	203.80.103.161	203.80.103.161	\N	\N	\N	\N	\N	\N
1	\N	\N	\N	mmahendra.soni@gmail.com	admin	\N	\N	\N	t	f	2013-03-09 14:35:19.128434	2013-03-10 13:22:26.683477	t	\N	\N	\N	\N	\N	\N	\N	\N	\N	hk	\N	$2a$10$VBZ7DUlNEpu7qXnI10QePujog6P1VmygsDcFlU5iKvXtwbYMUmQrC	\N	\N	\N	6	2013-03-10 13:22:26.679636	2013-03-10 11:29:20.761703	203.80.103.161	116.203.230.5	\N	\N	\N	\N	\N	\N
6	\N	\N	\N	test4@gmail.com	test4	\N		\N	t	f	2013-03-09 15:24:33.242246	2013-03-09 15:30:20.437445	f	My Company									hk		$2a$10$fS1vfEBDN0gRixBZA27ym.YVHUKigkzAq1oBHtKj7.58Sxha.Bmj.	\N	\N	\N	2	2013-03-09 15:25:11.30126	2013-03-09 15:24:33.248491	180.215.134.125	180.215.134.125				\N		
12	\N	\N	\N	pullwaterhk@gmail.com	\N	\N	\N	\N	f	f	2013-03-10 13:11:06.231587	2013-03-10 13:50:26.922054	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	en	\N	$2a$10$7cvlI9m44flasEm7ziTReelZ0quJJbCSVmoV1asKiXoOaX83yq5Z.	\N	\N	\N	4	2013-03-10 13:40:35.411216	2013-03-10 13:16:19.181105	203.80.103.161	203.80.103.161	\N	\N	\N	\N	\N	\N
4	\N	\N	\N	test2@gmail.com	test2	\N	\N	\N	t	f	2013-03-09 15:19:41.137719	2013-03-09 15:35:52.231752	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	hk	\N	$2a$10$8e1eOdhEyVla0UpIWfhYS.sPb1TJx/VINJ.AjaJ/6G/e.OhyqCOKW	\N	\N	\N	2	2013-03-09 15:35:52.22939	2013-03-09 15:19:41.149837	180.215.134.125	180.215.134.125	\N	\N	\N	\N	\N	\N
13	\N	\N	\N	mahendra20nov@gmail.com	Mahendra Soni	Mahendra.Soni11	\N	https://graph.facebook.com/100000266146023/picture?type=large	f	f	2013-03-10 14:34:29.843801	2013-03-10 15:00:50.158663	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	hk	\N	$2a$10$9d2iVokiWVyt25lthJeej./VnvU0xzNOYMafb8deJ.KEPNH2he4Ai	\N	\N	\N	2	2013-03-10 15:00:50.150849	2013-03-10 14:34:29.875546	116.203.98.227	116.203.98.227	\N	\N	\N	\N	\N	\N
5	\N	\N	\N	test3@gmail.com	test3	\N	\N	\N	t	f	2013-03-09 15:23:34.115933	2013-03-10 16:04:18.420833	f	\N	\N	\N	\N	\N	\N	\N	\N	\N	hk	\N	$2a$10$RQZrxQsK.EarfBsu.JWc7ufgoe1u/QF64z5SOIQrjYF2c2KVHe6Uq	\N	\N	\N	4	2013-03-10 16:04:18.418346	2013-03-10 10:11:52.650877	180.215.164.73	116.203.230.5	\N	\N	\N	\N	\N	\N
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: catarse
--

SELECT pg_catalog.setval('users_id_seq', 13, true);


--
-- Name: authorizations_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT authorizations_pkey PRIMARY KEY (id);


--
-- Name: backers_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY backers
    ADD CONSTRAINT backers_pkey PRIMARY KEY (id);


--
-- Name: categories_name_unique; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_name_unique UNIQUE (name_pt);


--
-- Name: categories_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY configurations
    ADD CONSTRAINT configurations_pkey PRIMARY KEY (id);


--
-- Name: notification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY notification_types
    ADD CONSTRAINT notification_types_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: oauth_providers_name_unique; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY oauth_providers
    ADD CONSTRAINT oauth_providers_name_unique UNIQUE (name);


--
-- Name: oauth_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY oauth_providers
    ADD CONSTRAINT oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: payment_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY payment_logs
    ADD CONSTRAINT payment_logs_pkey PRIMARY KEY (id);


--
-- Name: payment_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY payment_notifications
    ADD CONSTRAINT payment_notifications_pkey PRIMARY KEY (id);


--
-- Name: projects_curated_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY projects_curated_pages
    ADD CONSTRAINT projects_curated_pages_pkey PRIMARY KEY (id);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: reward_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY reward_ranges
    ADD CONSTRAINT reward_ranges_pkey PRIMARY KEY (name);


--
-- Name: rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (id);


--
-- Name: states_acronym_unique; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_acronym_unique UNIQUE (acronym);


--
-- Name: states_name_unique; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_name_unique UNIQUE (name);


--
-- Name: states_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: total_backed_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY total_backed_ranges
    ADD CONSTRAINT total_backed_ranges_pkey PRIMARY KEY (name);


--
-- Name: unsubscribes_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY unsubscribes
    ADD CONSTRAINT unsubscribes_pkey PRIMARY KEY (id);


--
-- Name: updates_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY updates
    ADD CONSTRAINT updates_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_provider_uid_unique; Type: CONSTRAINT; Schema: public; Owner: catarse; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_provider_uid_unique UNIQUE (provider, uid);


--
-- Name: fk__authorizations_oauth_provider_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX fk__authorizations_oauth_provider_id ON authorizations USING btree (oauth_provider_id);


--
-- Name: fk__authorizations_user_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX fk__authorizations_user_id ON authorizations USING btree (user_id);


--
-- Name: index_authorizations_on_uid_and_oauth_provider_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE UNIQUE INDEX index_authorizations_on_uid_and_oauth_provider_id ON authorizations USING btree (uid, oauth_provider_id);


--
-- Name: index_backers_on_confirmed; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_backers_on_confirmed ON backers USING btree (confirmed);


--
-- Name: index_backers_on_key; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_backers_on_key ON backers USING btree (key);


--
-- Name: index_backers_on_project_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_backers_on_project_id ON backers USING btree (project_id);


--
-- Name: index_backers_on_reward_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_backers_on_reward_id ON backers USING btree (reward_id);


--
-- Name: index_backers_on_user_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_backers_on_user_id ON backers USING btree (user_id);


--
-- Name: index_categories_on_name; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_categories_on_name ON categories USING btree (name_pt);


--
-- Name: index_configurations_on_name; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE UNIQUE INDEX index_configurations_on_name ON configurations USING btree (name);


--
-- Name: index_confirmed_backers_on_project_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_confirmed_backers_on_project_id ON backers USING btree (project_id) WHERE confirmed;


--
-- Name: index_notification_types_on_name; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE UNIQUE INDEX index_notification_types_on_name ON notification_types USING btree (name);


--
-- Name: index_notifications_on_update_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_notifications_on_update_id ON notifications USING btree (update_id);


--
-- Name: index_projects_on_category_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_projects_on_category_id ON projects USING btree (category_id);


--
-- Name: index_projects_on_name; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_projects_on_name ON projects USING btree (name);


--
-- Name: index_projects_on_permalink; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE UNIQUE INDEX index_projects_on_permalink ON projects USING btree (permalink);


--
-- Name: index_projects_on_user_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_projects_on_user_id ON projects USING btree (user_id);


--
-- Name: index_rewards_on_project_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_rewards_on_project_id ON rewards USING btree (project_id);


--
-- Name: index_unsubscribes_on_notification_type_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_unsubscribes_on_notification_type_id ON unsubscribes USING btree (notification_type_id);


--
-- Name: index_unsubscribes_on_project_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_unsubscribes_on_project_id ON unsubscribes USING btree (project_id);


--
-- Name: index_unsubscribes_on_user_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_unsubscribes_on_user_id ON unsubscribes USING btree (user_id);


--
-- Name: index_updates_on_project_id; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_updates_on_project_id ON updates USING btree (project_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_name; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_users_on_name ON users USING btree (name);


--
-- Name: index_users_on_primary_user_id_and_provider; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_users_on_primary_user_id_and_provider ON users USING btree (primary_user_id, provider);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_uid; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE INDEX index_users_on_uid ON users USING btree (uid);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: users_email; Type: INDEX; Schema: public; Owner: catarse; Tablespace: 
--

CREATE UNIQUE INDEX users_email ON users USING btree (email) WHERE (provider = 'devise'::text);


--
-- Name: backers_project_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY backers
    ADD CONSTRAINT backers_project_id_reference FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: backers_reward_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY backers
    ADD CONSTRAINT backers_reward_id_reference FOREIGN KEY (reward_id) REFERENCES rewards(id);


--
-- Name: backers_user_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY backers
    ADD CONSTRAINT backers_user_id_reference FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_authorizations_oauth_provider_id; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT fk_authorizations_oauth_provider_id FOREIGN KEY (oauth_provider_id) REFERENCES oauth_providers(id);


--
-- Name: fk_authorizations_user_id; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY authorizations
    ADD CONSTRAINT fk_authorizations_user_id FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: notifications_backer_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_backer_id_fk FOREIGN KEY (backer_id) REFERENCES backers(id);


--
-- Name: notifications_notification_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_notification_type_id_fk FOREIGN KEY (notification_type_id) REFERENCES notification_types(id);


--
-- Name: notifications_project_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_project_id_reference FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: notifications_update_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_update_id_fk FOREIGN KEY (update_id) REFERENCES updates(id);


--
-- Name: notifications_user_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_user_id_reference FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: payment_notifications_backer_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY payment_notifications
    ADD CONSTRAINT payment_notifications_backer_id_fk FOREIGN KEY (backer_id) REFERENCES backers(id);


--
-- Name: projects_category_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_category_id_reference FOREIGN KEY (category_id) REFERENCES categories(id);


--
-- Name: projects_user_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_user_id_reference FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: rewards_project_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY rewards
    ADD CONSTRAINT rewards_project_id_reference FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: unsubscribes_notification_type_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY unsubscribes
    ADD CONSTRAINT unsubscribes_notification_type_id_fk FOREIGN KEY (notification_type_id) REFERENCES notification_types(id);


--
-- Name: unsubscribes_project_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY unsubscribes
    ADD CONSTRAINT unsubscribes_project_id_fk FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: unsubscribes_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY unsubscribes
    ADD CONSTRAINT unsubscribes_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: updates_project_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY updates
    ADD CONSTRAINT updates_project_id_fk FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: updates_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY updates
    ADD CONSTRAINT updates_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: users_primary_user_id_reference; Type: FK CONSTRAINT; Schema: public; Owner: catarse
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_primary_user_id_reference FOREIGN KEY (primary_user_id) REFERENCES users(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

