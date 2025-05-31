--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: semester_work; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE semester_work WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';


ALTER DATABASE semester_work OWNER TO postgres;

\connect semester_work

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: prevent_self_comment(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_self_comment() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM sellers 
        WHERE seller_id = NEW.seller_id AND user_id = NEW.user_id
    ) THEN
        RAISE EXCEPTION 'User cannot comment on their own store';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.prevent_self_comment() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    category_id bigint NOT NULL,
    category_name text NOT NULL
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.categories ALTER COLUMN category_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.categories_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: clickstream; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clickstream (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    item_id bigint NOT NULL,
    event_id bigint NOT NULL,
    event_date timestamp without time zone NOT NULL,
    surface integer,
    platform integer,
    node bigint NOT NULL,
    CONSTRAINT check_clickstream_event_date CHECK (((event_date >= '2000-01-01 00:00:00'::timestamp without time zone) AND (event_date <= CURRENT_TIMESTAMP)))
);


ALTER TABLE public.clickstream OWNER TO postgres;

--
-- Name: clickstream_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.clickstream ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.clickstream_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comments (
    comment_id bigint NOT NULL,
    user_id bigint NOT NULL,
    rating smallint NOT NULL,
    seller_id bigint NOT NULL,
    text_id bigint,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT comments_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.comments OWNER TO postgres;

--
-- Name: comments_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.comments ALTER COLUMN comment_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.comments_comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: distribution; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.distribution (
    item_id bigint NOT NULL,
    location_id bigint NOT NULL
);


ALTER TABLE public.distribution OWNER TO postgres;

--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    event_id bigint NOT NULL,
    is_contact boolean NOT NULL
);


ALTER TABLE public.events OWNER TO postgres;

--
-- Name: item_features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_features (
    item_id bigint NOT NULL,
    category_id bigint NOT NULL,
    clean_params jsonb NOT NULL,
    node bigint NOT NULL,
    text_id bigint,
    seller_id bigint NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT item_features_created_date_check CHECK (((created_date >= '2000-01-01 00:00:00'::timestamp without time zone) AND (created_date <= CURRENT_TIMESTAMP)))
);


ALTER TABLE public.item_features OWNER TO postgres;

--
-- Name: item_features_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.item_features ALTER COLUMN item_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.item_features_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.locations (
    location_id bigint NOT NULL,
    location_name character varying(255) NOT NULL,
    postal_code integer NOT NULL,
    region character varying(255) NOT NULL,
    city character varying(255) NOT NULL,
    street character varying(255),
    house_num character varying(30),
    apart_num smallint,
    CONSTRAINT postal_code_check CHECK (((postal_code >= 100000) AND (postal_code <= 999999)))
);


ALTER TABLE public.locations OWNER TO postgres;

--
-- Name: sellers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sellers (
    seller_id bigint NOT NULL,
    user_id bigint NOT NULL,
    store_name character varying(128) NOT NULL,
    text_id bigint,
    location_id bigint,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT sellers_store_name_check CHECK ((length((store_name)::text) >= 2))
);


ALTER TABLE public.sellers OWNER TO postgres;

--
-- Name: user_features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_features (
    user_id bigint NOT NULL,
    gender boolean,
    registration_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    seller boolean DEFAULT false NOT NULL,
    user_nickname character varying(128) NOT NULL,
    age date NOT NULL,
    user_params jsonb,
    CONSTRAINT user_features_age_check CHECK ((age <= (CURRENT_DATE - '18 years'::interval))),
    CONSTRAINT user_nickname_min_lenght CHECK ((char_length((user_nickname)::text) >= 2))
);


ALTER TABLE public.user_features OWNER TO postgres;

--
-- Name: location_distribution; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.location_distribution AS
 SELECT l.location_id,
    l.location_name,
    count(DISTINCT s.seller_id) AS total_sellers,
    count(DISTINCT i.item_id) AS total_items,
    count(DISTINCT c.user_id) AS active_users,
    count(DISTINCT cl.id) AS total_clicks
   FROM (((((public.locations l
     LEFT JOIN public.sellers s ON ((l.location_id = s.location_id)))
     LEFT JOIN public.item_features i ON ((s.seller_id = i.seller_id)))
     LEFT JOIN public.distribution d ON ((l.location_id = d.location_id)))
     LEFT JOIN public.clickstream cl ON (((i.item_id = cl.item_id) OR (d.item_id = cl.item_id))))
     LEFT JOIN public.user_features c ON ((cl.user_id = c.user_id)))
  GROUP BY l.location_id, l.location_name;


ALTER VIEW public.location_distribution OWNER TO postgres;

--
-- Name: locations_location_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.locations ALTER COLUMN location_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.locations_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: seller_mean_ratings; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.seller_mean_ratings AS
 SELECT c.seller_id,
    s.store_name,
    avg(c.rating) AS mean_rating
   FROM (public.comments c
     JOIN public.sellers s ON ((c.seller_id = s.seller_id)))
  GROUP BY c.seller_id, s.store_name;


ALTER VIEW public.seller_mean_ratings OWNER TO postgres;

--
-- Name: sellers_seller_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.sellers ALTER COLUMN seller_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.sellers_seller_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: text_features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.text_features (
    text_id bigint NOT NULL,
    title_projection text NOT NULL
);


ALTER TABLE public.text_features OWNER TO postgres;

--
-- Name: text_features_text_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.text_features ALTER COLUMN text_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.text_features_text_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_activity_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.user_activity_summary AS
 SELECT u.user_id,
    u.user_nickname,
    u.age,
    count(DISTINCT c.id) AS total_clicks,
    count(DISTINCT
        CASE
            WHEN e.is_contact THEN c.id
            ELSE NULL::bigint
        END) AS contact_events,
    min(c.event_date) AS first_activity_date,
    max(c.event_date) AS last_activity_date
   FROM ((public.user_features u
     LEFT JOIN public.clickstream c ON ((u.user_id = c.user_id)))
     LEFT JOIN public.events e ON ((c.event_id = e.event_id)))
  GROUP BY u.user_id, u.user_nickname, u.age;


ALTER VIEW public.user_activity_summary OWNER TO postgres;

--
-- Name: user_features_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_features ALTER COLUMN user_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.user_features_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (category_id, category_name) FROM stdin;
1	Обувь
2	Куртки
3	Телефонов
4	Футболки
5	Сумки
\.


--
-- Data for Name: clickstream; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clickstream (id, user_id, item_id, event_id, event_date, surface, platform, node) FROM stdin;
1	1	1	1	2023-06-01 10:15:00	1	1	5001
2	2	2	2	2023-06-01 11:30:00	2	2	5002
3	3	3	3	2023-06-02 09:45:00	1	1	5003
4	4	4	4	2023-06-02 14:20:00	3	3	5004
5	5	5	5	2023-06-03 16:10:00	2	2	5005
6	1	3	1	2023-06-03 17:30:00	1	1	5006
7	2	1	2	2023-06-04 12:45:00	2	2	5007
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comments (comment_id, user_id, rating, seller_id, text_id, created_date) FROM stdin;
6	5	4	1	9	2025-04-27 20:51:39.902456
7	3	5	1	\N	2025-05-15 21:09:15.301968
\.


--
-- Data for Name: distribution; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.distribution (item_id, location_id) FROM stdin;
1	1
1	2
2	1
3	3
4	2
4	4
5	5
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.events (event_id, is_contact) FROM stdin;
1	t
2	f
3	t
4	f
5	t
\.


--
-- Data for Name: item_features; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item_features (item_id, category_id, clean_params, node, text_id, seller_id, created_date) FROM stdin;
1	1	{"size": "M", "color": "red", "weight": 0.5}	1001	1	2	2023-01-16 16:37:34
2	2	{"size": "L", "color": "blue", "material": "cotton"}	1002	2	2	2023-01-23 19:12:39
3	3	{"type": "electronic", "warranty": true}	1003	3	1	2023-07-18 12:18:05
4	4	{"size": "S", "color": "black"}	1004	4	1	2023-10-18 23:54:34
5	5	{"brand": "XYZ", "model": "2023"}	1005	5	1	2023-12-02 12:12:30
\.


--
-- Data for Name: locations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.locations (location_id, location_name, postal_code, region, city, street, house_num, apart_num) FROM stdin;
1	Москва	452000	Москва	Москва	Неглинная	\N	\N
2	Санкт-Петербург	435000	Санк-Петербург	Санкт-Петербург	\N	\N	\N
3	Новосибирск	123450	Новосибирская область	Новосибирск	\N	\N	\N
4	Екатеринбург	123450	Свердловская область	Екатеринбург	\N	\N	\N
5	Казань	123450	республика Татарстан	Казань	Аделя Кутуя	\N	\N
\.


--
-- Data for Name: sellers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sellers (seller_id, user_id, store_name, text_id, location_id, created_date) FROM stdin;
1	1	TechGadgets	6	1	2023-01-16 16:32:30
2	3	FashionHub	7	1	2023-07-18 12:15:00
\.


--
-- Data for Name: text_features; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.text_features (text_id, title_projection) FROM stdin;
1	Красная футболка с принтом
2	Синие джинсы классического кроя
3	Смартфон с большим экраном
4	Черное платье офисного стиля
5	Кофемашина профессиональная
6	Крутой магаз поверь брат
7	Честный магаз 100%
8	У нас все ок
9	Четкий магаз
10	У нас все супер
\.


--
-- Data for Name: user_features; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_features (user_id, gender, registration_date, seller, user_nickname, age, user_params) FROM stdin;
1	t	2023-01-15 10:30:00	f	Oleggg	2003-11-13	{"Адрес": "г. Москва, ул. Тверская, д. 10, кв. 25", "Почта": "oleggg@example.com", "Телефон": "+7 (900) 123-45-67", "Верификация": true, "Предпочтения": ["Электроника", "Спорт"]}
2	f	2023-02-20 14:45:00	t	Kseni	2001-02-10	{"Адрес": "г. Санкт-Петербург, Невский пр-т, д. 30", "Почта": "kseniya@example.com", "Телефон": "+7 (911) 234-56-78", "Верификация": false, "Бонусные баллы": 1500}
3	t	2023-03-10 09:15:00	f	Voloda	2007-02-23	{"Адрес": "г. Казань, ул. Баумана, д. 5", "Почта": "volodya@example.com", "Телефон": "+7 (902) 345-67-89", "Способ оплаты": "Карта", "История заказов": 3}
4	f	2023-04-05 16:20:00	t	Юля	1992-05-03	{"Адрес": "г. Екатеринбург, ул. Ленина, д. 42, кв. 13", "Почта": "yulya@example.com", "Телефон": "+7 (903) 456-78-90", "Избранные товары": [112, 205, 307], "Подписка на рассылку": true}
5	t	2023-05-12 11:10:00	f	Максимочка	1997-08-20	{"Адрес": "г. Новосибирск, ул. Кирова, д. 15", "Почта": "maxim@example.com", "Соцсети": ["vk", "telegram"], "Телефон": "+7 (904) 567-89-01", "Дата рождения": "1997-08-20"}
\.


--
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_category_id_seq', 5, true);


--
-- Name: clickstream_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clickstream_id_seq', 7, true);


--
-- Name: comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comments_comment_id_seq', 8, true);


--
-- Name: item_features_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_features_item_id_seq', 5, true);


--
-- Name: locations_location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.locations_location_id_seq', 5, true);


--
-- Name: sellers_seller_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sellers_seller_id_seq', 2, true);


--
-- Name: text_features_text_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.text_features_text_id_seq', 10, true);


--
-- Name: user_features_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_features_user_id_seq', 5, true);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: clickstream clickstream_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clickstream
    ADD CONSTRAINT clickstream_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (comment_id);


--
-- Name: distribution distribution_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distribution
    ADD CONSTRAINT distribution_pkey PRIMARY KEY (item_id, location_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id);


--
-- Name: item_features item_features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_features
    ADD CONSTRAINT item_features_pkey PRIMARY KEY (item_id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);


--
-- Name: sellers sellers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sellers
    ADD CONSTRAINT sellers_pkey PRIMARY KEY (seller_id);


--
-- Name: text_features text_features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.text_features
    ADD CONSTRAINT text_features_pkey PRIMARY KEY (text_id);


--
-- Name: user_features user_features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_features
    ADD CONSTRAINT user_features_pkey PRIMARY KEY (user_id);


--
-- Name: comments_user_id_ind; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX comments_user_id_ind ON public.comments USING btree (user_id);


--
-- Name: idx_clickstream_event_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clickstream_event_id ON public.clickstream USING btree (event_id);


--
-- Name: idx_clickstream_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clickstream_item_id ON public.clickstream USING btree (item_id);


--
-- Name: idx_clickstream_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clickstream_user_id ON public.clickstream USING btree (user_id);


--
-- Name: idx_item_features_category_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_item_features_category_id ON public.item_features USING btree (category_id);


--
-- Name: item_features_user_id_ind; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX item_features_user_id_ind ON public.item_features USING btree (category_id);


--
-- Name: sellers_user_id_ind; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sellers_user_id_ind ON public.sellers USING btree (user_id);


--
-- Name: comments tr_prevent_self_comment; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tr_prevent_self_comment BEFORE INSERT OR UPDATE ON public.comments FOR EACH ROW EXECUTE FUNCTION public.prevent_self_comment();


--
-- Name: clickstream clickstream_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clickstream
    ADD CONSTRAINT clickstream_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(event_id);


--
-- Name: clickstream clickstream_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clickstream
    ADD CONSTRAINT clickstream_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item_features(item_id);


--
-- Name: clickstream clickstream_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clickstream
    ADD CONSTRAINT clickstream_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_features(user_id);


--
-- Name: comments comments_seller_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_seller_id_fkey FOREIGN KEY (seller_id) REFERENCES public.sellers(seller_id);


--
-- Name: comments comments_text_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_text_id_fkey FOREIGN KEY (text_id) REFERENCES public.text_features(text_id);


--
-- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_features(user_id);


--
-- Name: distribution distribution_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distribution
    ADD CONSTRAINT distribution_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item_features(item_id);


--
-- Name: distribution distribution_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distribution
    ADD CONSTRAINT distribution_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(location_id);


--
-- Name: item_features fk_item_category; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_features
    ADD CONSTRAINT fk_item_category FOREIGN KEY (category_id) REFERENCES public.categories(category_id);


--
-- Name: item_features item_features_seller_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_features
    ADD CONSTRAINT item_features_seller_id FOREIGN KEY (seller_id) REFERENCES public.sellers(seller_id);


--
-- Name: item_features item_features_text_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_features
    ADD CONSTRAINT item_features_text_id_fkey FOREIGN KEY (text_id) REFERENCES public.text_features(text_id);


--
-- Name: sellers sellers_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sellers
    ADD CONSTRAINT sellers_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(location_id);


--
-- Name: sellers sellers_text_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sellers
    ADD CONSTRAINT sellers_text_id_fkey FOREIGN KEY (text_id) REFERENCES public.text_features(text_id);


--
-- Name: sellers sellers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sellers
    ADD CONSTRAINT sellers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_features(user_id);


--
-- PostgreSQL database dump complete
--

