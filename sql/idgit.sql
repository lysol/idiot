--
-- PostgreSQL database dump
--

-- Started on 2010-04-23 07:24:24 CDT

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 316 (class 2612 OID 16386)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 1504 (class 1259 OID 130477)
-- Dependencies: 1787 1788 3
-- Name: issue; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE issue (
    seq integer NOT NULL,
    project character varying DEFAULT ''::character varying NOT NULL,
    summary character varying NOT NULL,
    description character varying NOT NULL,
    author character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.issue OWNER TO postgres;

--
-- TOC entry 1503 (class 1259 OID 130475)
-- Dependencies: 1504 3
-- Name: issue_seq_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE issue_seq_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.issue_seq_seq OWNER TO postgres;

--
-- TOC entry 1821 (class 0 OID 0)
-- Dependencies: 1503
-- Name: issue_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE issue_seq_seq OWNED BY issue.seq;


--
-- TOC entry 1822 (class 0 OID 0)
-- Dependencies: 1503
-- Name: issue_seq_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('issue_seq_seq', 1, false);


--
-- TOC entry 1508 (class 1259 OID 130503)
-- Dependencies: 1797 1798 3
-- Name: permission; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE permission (
    seq integer NOT NULL,
    project character varying NOT NULL,
    username character varying NOT NULL,
    post_issues boolean DEFAULT false NOT NULL,
    post_comments boolean DEFAULT false NOT NULL
);


ALTER TABLE public.permission OWNER TO postgres;

--
-- TOC entry 1507 (class 1259 OID 130501)
-- Dependencies: 3 1508
-- Name: permission_seq_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE permission_seq_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.permission_seq_seq OWNER TO postgres;

--
-- TOC entry 1823 (class 0 OID 0)
-- Dependencies: 1507
-- Name: permission_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE permission_seq_seq OWNED BY permission.seq;


--
-- TOC entry 1824 (class 0 OID 0)
-- Dependencies: 1507
-- Name: permission_seq_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('permission_seq_seq', 1, false);


--
-- TOC entry 1505 (class 1259 OID 130485)
-- Dependencies: 1789 3
-- Name: project; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE project (
    name character varying NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    owner character varying NOT NULL
);


ALTER TABLE public.project OWNER TO postgres;

--
-- TOC entry 1506 (class 1259 OID 130492)
-- Dependencies: 1790 1791 1792 1793 1794 1795 3
-- Name: user; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "user" (
    username character varying NOT NULL,
    full_name character varying DEFAULT ''::character varying NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    password character varying NOT NULL,
    website character varying DEFAULT ''::character varying NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    CONSTRAINT email_proper CHECK ((((email)::text ~ '@'::text) OR ((email)::text = ''::text))),
    CONSTRAINT website_proper CHECK ((((website)::text ~ '^http'::text) OR ((website)::text = ''::text)))
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- TOC entry 1786 (class 2604 OID 130480)
-- Dependencies: 1503 1504 1504
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE issue ALTER COLUMN seq SET DEFAULT nextval('issue_seq_seq'::regclass);


--
-- TOC entry 1796 (class 2604 OID 130506)
-- Dependencies: 1507 1508 1508
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE permission ALTER COLUMN seq SET DEFAULT nextval('permission_seq_seq'::regclass);


--
-- TOC entry 1812 (class 0 OID 130477)
-- Dependencies: 1504
-- Data for Name: issue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY issue (seq, project, summary, description, author) FROM stdin;
\.


--
-- TOC entry 1815 (class 0 OID 130503)
-- Dependencies: 1508
-- Data for Name: permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY permission (seq, project, username, post_issues, post_comments) FROM stdin;
\.


--
-- TOC entry 1813 (class 0 OID 130485)
-- Dependencies: 1505
-- Data for Name: project; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY project (name, description, owner) FROM stdin;
\.


--
-- TOC entry 1814 (class 0 OID 130492)
-- Dependencies: 1506
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "user" (username, full_name, email, password, website, admin) FROM stdin;
\.


--
-- TOC entry 1800 (class 2606 OID 130558)
-- Dependencies: 1504 1504
-- Name: issue_seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT issue_seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1802 (class 2606 OID 130517)
-- Dependencies: 1505 1505
-- Name: project_name_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_name_primary_key PRIMARY KEY (name);


--
-- TOC entry 1806 (class 2606 OID 130515)
-- Dependencies: 1508 1508 1508
-- Name: project_user_permission_unique; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT project_user_permission_unique UNIQUE (project, username);


--
-- TOC entry 1808 (class 2606 OID 130513)
-- Dependencies: 1508 1508
-- Name: seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1804 (class 2606 OID 130547)
-- Dependencies: 1506 1506
-- Name: username_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT username_primary_key PRIMARY KEY (username);


--
-- TOC entry 1809 (class 2606 OID 130559)
-- Dependencies: 1506 1803 1504
-- Name: author_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT author_fk FOREIGN KEY (author) REFERENCES "user"(username) ON UPDATE RESTRICT ON DELETE SET DEFAULT;


--
-- TOC entry 1810 (class 2606 OID 130564)
-- Dependencies: 1801 1504 1505
-- Name: project_issue_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT project_issue_fk FOREIGN KEY (project) REFERENCES project(name) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 1811 (class 2606 OID 130569)
-- Dependencies: 1505 1506 1803
-- Name: project_owner_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_owner_fk FOREIGN KEY (owner) REFERENCES "user"(username);


--
-- TOC entry 1820 (class 0 OID 0)
-- Dependencies: 3
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2010-04-23 07:24:24 CDT

--
-- PostgreSQL database dump complete
--

