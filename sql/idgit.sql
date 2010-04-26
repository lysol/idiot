--
-- PostgreSQL database dump
--

-- Started on 2010-04-26 00:17:51 CDT

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 1860 (class 1262 OID 130474)
-- Name: idgit; Type: DATABASE; Schema: -; Owner: idgit
--

CREATE DATABASE idgit WITH TEMPLATE = template0 ENCODING = 'UTF8' COLLATE = 'C' CTYPE = 'C';


ALTER DATABASE idgit OWNER TO idgit;

\connect idgit

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 346 (class 2612 OID 16386)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

--
-- TOC entry 347 (class 2612 OID 130627)
-- Name: plpythonu; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpythonu;


ALTER PROCEDURAL LANGUAGE plpythonu OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 19 (class 1255 OID 130638)
-- Dependencies: 347 3
-- Name: create_issue(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_issue(project character varying, summary character varying, description character varying, author character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    INSERT INTO issue (
        project, summary, description, author
    ) VALUES (
        $1, $2, $3, $4
    );
""", ["text", "text", "text", "text"])

plpy.execute(plan, [project, summary, description, author])

$_$;


ALTER FUNCTION public.create_issue(project character varying, summary character varying, description character varying, author character varying) OWNER TO postgres;

--
-- TOC entry 20 (class 1255 OID 130628)
-- Dependencies: 3 347
-- Name: create_project(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_project(name character varying, description character varying, owner character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    INSERT INTO project (
      name, description, owner
    ) VALUES (
      $1, $2, $3
    );
""", ["text", "text", "text"])

plpy.execute(plan, [name, description, owner])

$_$;


ALTER FUNCTION public.create_project(name character varying, description character varying, owner character varying) OWNER TO postgres;

--
-- TOC entry 35 (class 1255 OID 130652)
-- Dependencies: 3 347
-- Name: create_thread(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_thread(project character varying, author character varying, comment character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    INSERT INTO comment (
        author, comment, project
    ) VALUES (
        $1, $2, $3
    );
""", ["text", "text", "text"])

plpy.execute(plan, [author, comment, project])

$_$;


ALTER FUNCTION public.create_thread(project character varying, author character varying, comment character varying) OWNER TO postgres;

--
-- TOC entry 38 (class 1255 OID 130662)
-- Dependencies: 3 347
-- Name: create_user(character varying, character varying, character varying, character varying, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) RETURNS void
    LANGUAGE plpythonu
    AS $_$

# Sanity checks
if password != password_again or len(password) < 6:
    raise Exception

plan = plpy.prepare("""
    INSERT INTO "user" (
      username, full_name, email, password, website, admin
    ) VALUES (
      $1, $2, $3, md5($4), $5, $6
    );
""", ["text", "text", "text", "text", "text", "bool"])

plpy.execute(plan, [username, full_name, email, password, website, admin])

$_$;


ALTER FUNCTION public.create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) OWNER TO postgres;

--
-- TOC entry 27 (class 1255 OID 130654)
-- Dependencies: 347 3
-- Name: delete_comment(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION delete_comment(seq integer) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    DELETE FROM comment
    WHERE seq = $1
""", ["int4"])

plpy.execute(plan, [seq])

$_$;


ALTER FUNCTION public.delete_comment(seq integer) OWNER TO postgres;

--
-- TOC entry 31 (class 1255 OID 130640)
-- Dependencies: 347 3
-- Name: delete_permission(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION delete_permission(seq integer) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    DELETE FROM permission
    WHERE seq = $1
""", ["int4"])

plpy.execute(plan, [seq])

$_$;


ALTER FUNCTION public.delete_permission(seq integer) OWNER TO postgres;

--
-- TOC entry 25 (class 1255 OID 130635)
-- Dependencies: 347 3
-- Name: delete_project(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION delete_project(name character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    DELETE FROM project
    WHERE name = $1
""", ["text"])

plpy.execute(plan, [name])

$_$;


ALTER FUNCTION public.delete_project(name character varying) OWNER TO postgres;

--
-- TOC entry 34 (class 1255 OID 130641)
-- Dependencies: 347 3
-- Name: delete_user(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION delete_user(username character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    DELETE FROM "user"
    WHERE username = $1
""", ["text"])

plpy.execute(plan, [username])

$_$;


ALTER FUNCTION public.delete_user(username character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 1541 (class 1259 OID 130584)
-- Dependencies: 1835 1836 3
-- Name: comment; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE comment (
    seq integer NOT NULL,
    author character varying DEFAULT ''::character varying NOT NULL,
    comment character varying NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    project character varying NOT NULL,
    parent_seq integer
);


ALTER TABLE public.comment OWNER TO postgres;

--
-- TOC entry 32 (class 1255 OID 130658)
-- Dependencies: 3 339 347
-- Name: get_all_comments(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_all_comments() RETURNS SETOF comment
    LANGUAGE plpythonu
    AS $$

RETURN plpy.execute("SELECT * FROM comment")

$$;


ALTER FUNCTION public.get_all_comments() OWNER TO postgres;

--
-- TOC entry 33 (class 1255 OID 130659)
-- Dependencies: 347 339 3
-- Name: get_comment(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_comment(seq integer) RETURNS comment
    LANGUAGE plpythonu STABLE
    AS $_$

plan = plpy.prepare("""
    SELECT * FROM comment
    WHERE seq = $1
""", ["int4"])

return plpy.execute(plan, [seq])

$_$;


ALTER FUNCTION public.get_comment(seq integer) OWNER TO postgres;

--
-- TOC entry 1536 (class 1259 OID 130485)
-- Dependencies: 1823 1824 3
-- Name: project; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE project (
    name character varying NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    owner character varying NOT NULL,
    created_timestamp timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.project OWNER TO postgres;

--
-- TOC entry 23 (class 1255 OID 130616)
-- Dependencies: 3 328 346
-- Name: get_project(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project(name character varying) RETURNS SETOF project
    LANGUAGE plpgsql STABLE
    AS $_$

  BEGIN

  RETURN QUERY
    SELECT * FROM project
    WHERE name = $1;

  END;



$_$;


ALTER FUNCTION public.get_project(name character varying) OWNER TO postgres;

--
-- TOC entry 1535 (class 1259 OID 130477)
-- Dependencies: 1821 1822 3
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
-- TOC entry 30 (class 1255 OID 130637)
-- Dependencies: 326 3 347
-- Name: get_project_issue_page(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) RETURNS SETOF issue
    LANGUAGE plpythonu STABLE
    AS $_$

offset = (page - 1) * per_page
limit = offset + per_page

if offset > 0:

    plan = plpy.prepare("""
        SELECT seq, project, summary, description, author
        FROM issue
        WHERE project = $1
        OFFSET $2 LIMIT $3
    """, ["text", "int4", "int4"])
    result = plpy.execute(plan, [name, offset, limit])
else:

    plan = plpy.prepare("""
        SELECT seq, project, summary, description, author
        FROM issue
        WHERE project = $1
        LIMIT $2
    """, ["text", "int4"])
    result = plpy.execute(plan, [name, limit])


if len(result) == 0:
    raise Exception
return result
    

$_$;


ALTER FUNCTION public.get_project_issue_page(name character varying, page integer, per_page integer) OWNER TO postgres;

--
-- TOC entry 22 (class 1255 OID 130636)
-- Dependencies: 347 326 3
-- Name: get_project_issues(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project_issues(name character varying) RETURNS SETOF issue
    LANGUAGE plpythonu STABLE
    AS $_$


plan = plpy.prepare("""
    SELECT seq, project, summary, description, author
    FROM issue
    WHERE project = $1
""", ["text"])

return plpy.execute(plan, [name])


$_$;


ALTER FUNCTION public.get_project_issues(name character varying) OWNER TO postgres;

--
-- TOC entry 26 (class 1255 OID 130615)
-- Dependencies: 328 3 346
-- Name: get_projects(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_projects() RETURNS SETOF project
    LANGUAGE plpgsql STABLE
    AS $$

  BEGIN

  RETURN QUERY SELECT * FROM project;

  END;



$$;


ALTER FUNCTION public.get_projects() OWNER TO postgres;

--
-- TOC entry 37 (class 1255 OID 130661)
-- Dependencies: 347 339 3
-- Name: get_thread(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_thread(seq integer) RETURNS SETOF comment
    LANGUAGE plpythonu STABLE
    AS $_$

plan = plpy.prepare("""
    WITH RECURSIVE thread AS
    (
        SELECT * FROM comment WHERE seq = $1
        UNION ALL
        SELECT c.*
        FROM
            comment AS c
        JOIN
            thread AS ct
            ON (c.parent_seq = ct.seq)
    )
    SELECT * FROM thread ORDER BY seq
""", ["int4"])

return plpy.execute(plan, [seq])

$_$;


ALTER FUNCTION public.get_thread(seq integer) OWNER TO postgres;

--
-- TOC entry 36 (class 1255 OID 130653)
-- Dependencies: 347 3
-- Name: modify_comment(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION modify_comment(seq integer, comment character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    UPDATE comment
    SET comment = $1
    WHERE seq = $2
""", ["text", "int4"])

plpy.execute(plan, [comment, seq])

$_$;


ALTER FUNCTION public.modify_comment(seq integer, comment character varying) OWNER TO postgres;

--
-- TOC entry 40 (class 1255 OID 130664)
-- Dependencies: 347 3
-- Name: modify_issue(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION modify_issue(seq integer, summary character varying, description character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    UPDATE issue
    SET summary = $1,
    description = $2
    WHERE seq = $3
""", ["text", "text", "int4"])

plpy.execute(plan, [summary, description, seq])

$_$;


ALTER FUNCTION public.modify_issue(seq integer, summary character varying, description character varying) OWNER TO postgres;

--
-- TOC entry 24 (class 1255 OID 130639)
-- Dependencies: 347 3
-- Name: modify_permission(character varying, character varying, boolean, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION modify_permission(project character varying, username character varying, post_issues boolean, post_comments boolean) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    SELECT TRUE AS present
    FROM permission
    WHERE project = $1
    AND username = $2
""", ["text", "text"])

if len(plpy.execute(plan, [project, username])) == 1:
    # Update
    plan = plpy.prepare("""
        UPDATE permission
        SET post_issues = $1,
            post_comments = $2
        WHERE username = $3
        AND project = $4
    """, ["bool", "bool", "text", "text"])
    
else:
    # New Permission
    plan = plpy.prepare("""
        INSERT INTO permission (
            post_issues, post_comments,
            username, project
        ) VALUES (
            $1, $2, $3, $4
        );
    """, ["bool", "bool", "text", "text"])


plpy.execute(plan, [post_issues, post_comments, username, project])

$_$;


ALTER FUNCTION public.modify_permission(project character varying, username character varying, post_issues boolean, post_comments boolean) OWNER TO postgres;

--
-- TOC entry 41 (class 1255 OID 130665)
-- Dependencies: 347 3
-- Name: modify_project(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION modify_project(name character varying, description character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    UPDATE project
    SET description = $1,
    WHERE name = $2
""", ["text", "text"])

plpy.execute(plan, [description, name])

$_$;


ALTER FUNCTION public.modify_project(name character varying, description character varying) OWNER TO postgres;

--
-- TOC entry 21 (class 1255 OID 130629)
-- Dependencies: 347 3
-- Name: modify_user(character varying, character varying, character varying, character varying, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) RETURNS void
    LANGUAGE plpythonu
    AS $_$

# Sanity checks
if password != password_again or len(password) < 6:
    raise Exception

plan = plpy.prepare("""
    INSERT INTO "user" (
      username, full_name, email, password, website, admin
    ) VALUES (
      $1, $2, $3, md5($4), $5, $6
    );
""", ["text", "text", "text", "text", "text", "bool"])

plpy.execute(plan, [username, full_name, email, password, website, admin])

$_$;


ALTER FUNCTION public.modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) OWNER TO postgres;

--
-- TOC entry 39 (class 1255 OID 130663)
-- Dependencies: 3 347
-- Name: modify_user(integer, character varying, character varying, character varying, character varying, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION modify_user(seq integer, username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) RETURNS void
    LANGUAGE plpythonu
    AS $_$

# Sanity checks
if password != password_again and password != '' and password_again != '':
    raise Exception

if password == '':
    plan = plpy.prepare("""
        UPDATE "user"
        SET
          username = $1,
          full_name = $2,
          email = $3,
          website = $4,
          admin = $5
        WHERE seq = $6
    """, ["text", "text", "text", "text", "bool"])
    plpy.execute(plan, [username, full_name, email, website, admin])
else:
    plan = plpy.prepare("""
        UPDATE "user"
        SET
          username = $1,
          full_name = $2,
          email = $3,
          password = $4,
          website = $5,
          admin = $6
        WHERE seq = $7
    """, ["text", "text", "text", "text", "text", "bool"])
    plpy.execute(plan, [username, full_name, email, password, website, admin])

$_$;


ALTER FUNCTION public.modify_user(seq integer, username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) OWNER TO postgres;

--
-- TOC entry 28 (class 1255 OID 130655)
-- Dependencies: 3 347
-- Name: reply_comment(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION reply_comment(seq integer, author character varying, comment character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    INSERT INTO comment (
        project, author, comment, parent_seq
    ) VALUES (
        (SELECT project
         FROM comment
         WHERE seq = $1
        ), $2, $3, $1
    )
""", ["int4", "text", "text"])

plpy.execute(plan, [seq, author, comment])

$_$;


ALTER FUNCTION public.reply_comment(seq integer, author character varying, comment character varying) OWNER TO postgres;

--
-- TOC entry 29 (class 1255 OID 130656)
-- Dependencies: 347 3
-- Name: tr_no_cross_project_comments(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION tr_no_cross_project_comments() RETURNS trigger
    LANGUAGE plpythonu STABLE
    AS $_$

our_project = TD["new"]["project"]
parent_seq = TD["new"]["parent_seq"]

if parent_seq > 0:
    plan = plpy.prepare("""
        SELECT project
        FROM comment
        WHERE seq = $1
    """, ["int4"])
    parent_project = plpy.execute(plan, [parent_seq])
    if parent_project != our_project:
        return "SKIP"
return "OK"
$_$;


ALTER FUNCTION public.tr_no_cross_project_comments() OWNER TO postgres;

--
-- TOC entry 1540 (class 1259 OID 130582)
-- Dependencies: 1541 3
-- Name: comment_seq_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE comment_seq_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.comment_seq_seq OWNER TO postgres;

--
-- TOC entry 1875 (class 0 OID 0)
-- Dependencies: 1540
-- Name: comment_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE comment_seq_seq OWNED BY comment.seq;


--
-- TOC entry 1542 (class 1259 OID 130601)
-- Dependencies: 3
-- Name: exceptions; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE exceptions (
    name text NOT NULL,
    description text NOT NULL,
    parent text
);


ALTER TABLE public.exceptions OWNER TO postgres;

--
-- TOC entry 1534 (class 1259 OID 130475)
-- Dependencies: 3 1535
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
-- TOC entry 1878 (class 0 OID 0)
-- Dependencies: 1534
-- Name: issue_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE issue_seq_seq OWNED BY issue.seq;


--
-- TOC entry 1539 (class 1259 OID 130503)
-- Dependencies: 1832 1833 3
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
-- TOC entry 1538 (class 1259 OID 130501)
-- Dependencies: 1539 3
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
-- TOC entry 1881 (class 0 OID 0)
-- Dependencies: 1538
-- Name: permission_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE permission_seq_seq OWNED BY permission.seq;


--
-- TOC entry 1537 (class 1259 OID 130492)
-- Dependencies: 1825 1826 1827 1828 1829 1830 3
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
-- TOC entry 1834 (class 2604 OID 130587)
-- Dependencies: 1541 1540 1541
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE comment ALTER COLUMN seq SET DEFAULT nextval('comment_seq_seq'::regclass);


--
-- TOC entry 1820 (class 2604 OID 130480)
-- Dependencies: 1535 1534 1535
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE issue ALTER COLUMN seq SET DEFAULT nextval('issue_seq_seq'::regclass);


--
-- TOC entry 1831 (class 2604 OID 130506)
-- Dependencies: 1539 1538 1539
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE permission ALTER COLUMN seq SET DEFAULT nextval('permission_seq_seq'::regclass);


--
-- TOC entry 1848 (class 2606 OID 130593)
-- Dependencies: 1541 1541
-- Name: comment_seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1850 (class 2606 OID 130608)
-- Dependencies: 1542 1542
-- Name: exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY exceptions
    ADD CONSTRAINT exceptions_pkey PRIMARY KEY (name);


--
-- TOC entry 1838 (class 2606 OID 130558)
-- Dependencies: 1535 1535
-- Name: issue_seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT issue_seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1840 (class 2606 OID 130517)
-- Dependencies: 1536 1536
-- Name: project_name_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_name_primary_key PRIMARY KEY (name);


--
-- TOC entry 1844 (class 2606 OID 130515)
-- Dependencies: 1539 1539 1539
-- Name: project_user_permission_unique; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT project_user_permission_unique UNIQUE (project, username);


--
-- TOC entry 1846 (class 2606 OID 130513)
-- Dependencies: 1539 1539
-- Name: seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1842 (class 2606 OID 130547)
-- Dependencies: 1537 1537
-- Name: username_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT username_primary_key PRIMARY KEY (username);


--
-- TOC entry 1851 (class 2606 OID 130559)
-- Dependencies: 1537 1535 1841
-- Name: author_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT author_fk FOREIGN KEY (author) REFERENCES "user"(username) ON UPDATE RESTRICT ON DELETE SET DEFAULT;


--
-- TOC entry 1854 (class 2606 OID 130594)
-- Dependencies: 1537 1541 1841
-- Name: comment_author_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_author_fk FOREIGN KEY (author) REFERENCES "user"(username) ON UPDATE RESTRICT ON DELETE SET DEFAULT;


--
-- TOC entry 1856 (class 2606 OID 130647)
-- Dependencies: 1541 1541 1847
-- Name: comment_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_parent_fk FOREIGN KEY (parent_seq) REFERENCES comment(seq) ON UPDATE SET NULL ON DELETE CASCADE;


--
-- TOC entry 1857 (class 2606 OID 130609)
-- Dependencies: 1849 1542 1542
-- Name: exceptions_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY exceptions
    ADD CONSTRAINT exceptions_parent_fkey FOREIGN KEY (parent) REFERENCES exceptions(name);


--
-- TOC entry 1855 (class 2606 OID 130642)
-- Dependencies: 1541 1839 1536
-- Name: project_comment_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT project_comment_fk FOREIGN KEY (project) REFERENCES project(name) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 1852 (class 2606 OID 130564)
-- Dependencies: 1535 1536 1839
-- Name: project_issue_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT project_issue_fk FOREIGN KEY (project) REFERENCES project(name) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 1853 (class 2606 OID 130569)
-- Dependencies: 1841 1536 1537
-- Name: project_owner_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_owner_fk FOREIGN KEY (owner) REFERENCES "user"(username);


--
-- TOC entry 1862 (class 0 OID 0)
-- Dependencies: 3
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 1863 (class 0 OID 0)
-- Dependencies: 20
-- Name: create_project(character varying, character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION create_project(name character varying, description character varying, owner character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_project(name character varying, description character varying, owner character varying) FROM postgres;
GRANT ALL ON FUNCTION create_project(name character varying, description character varying, owner character varying) TO postgres;
GRANT ALL ON FUNCTION create_project(name character varying, description character varying, owner character varying) TO PUBLIC;
GRANT ALL ON FUNCTION create_project(name character varying, description character varying, owner character varying) TO idgit_group;


--
-- TOC entry 1864 (class 0 OID 0)
-- Dependencies: 38
-- Name: create_user(character varying, character varying, character varying, character varying, character varying, character varying, boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM postgres;
GRANT ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO postgres;
GRANT ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO PUBLIC;
GRANT ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO idgit_group;


--
-- TOC entry 1865 (class 0 OID 0)
-- Dependencies: 25
-- Name: delete_project(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION delete_project(name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_project(name character varying) FROM postgres;
GRANT ALL ON FUNCTION delete_project(name character varying) TO postgres;
GRANT ALL ON FUNCTION delete_project(name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION delete_project(name character varying) TO idgit_group;


--
-- TOC entry 1866 (class 0 OID 0)
-- Dependencies: 34
-- Name: delete_user(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION delete_user(username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_user(username character varying) FROM postgres;
GRANT ALL ON FUNCTION delete_user(username character varying) TO postgres;
GRANT ALL ON FUNCTION delete_user(username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION delete_user(username character varying) TO idgit_group;


--
-- TOC entry 1867 (class 0 OID 0)
-- Dependencies: 1541
-- Name: comment; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE comment FROM PUBLIC;
REVOKE ALL ON TABLE comment FROM postgres;
GRANT ALL ON TABLE comment TO postgres;
GRANT ALL ON TABLE comment TO idgit_group;


--
-- TOC entry 1868 (class 0 OID 0)
-- Dependencies: 1536
-- Name: project; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE project FROM PUBLIC;
REVOKE ALL ON TABLE project FROM postgres;
GRANT ALL ON TABLE project TO postgres;
GRANT ALL ON TABLE project TO idgit_group;


--
-- TOC entry 1869 (class 0 OID 0)
-- Dependencies: 23
-- Name: get_project(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project(name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project(name character varying) FROM postgres;
GRANT ALL ON FUNCTION get_project(name character varying) TO postgres;
GRANT ALL ON FUNCTION get_project(name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_project(name character varying) TO idgit_group;


--
-- TOC entry 1870 (class 0 OID 0)
-- Dependencies: 1535
-- Name: issue; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE issue FROM PUBLIC;
REVOKE ALL ON TABLE issue FROM postgres;
GRANT ALL ON TABLE issue TO postgres;
GRANT ALL ON TABLE issue TO idgit_group;


--
-- TOC entry 1871 (class 0 OID 0)
-- Dependencies: 30
-- Name: get_project_issue_page(character varying, integer, integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) FROM postgres;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO postgres;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO idgit_group;


--
-- TOC entry 1872 (class 0 OID 0)
-- Dependencies: 22
-- Name: get_project_issues(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project_issues(name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project_issues(name character varying) FROM postgres;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO postgres;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO idgit_group;


--
-- TOC entry 1873 (class 0 OID 0)
-- Dependencies: 26
-- Name: get_projects(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_projects() FROM PUBLIC;
REVOKE ALL ON FUNCTION get_projects() FROM postgres;
GRANT ALL ON FUNCTION get_projects() TO postgres;
GRANT ALL ON FUNCTION get_projects() TO PUBLIC;
GRANT ALL ON FUNCTION get_projects() TO idgit_group;


--
-- TOC entry 1874 (class 0 OID 0)
-- Dependencies: 21
-- Name: modify_user(character varying, character varying, character varying, character varying, character varying, character varying, boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM postgres;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO postgres;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO PUBLIC;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO idgit_group;


--
-- TOC entry 1876 (class 0 OID 0)
-- Dependencies: 1540
-- Name: comment_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE comment_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE comment_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE comment_seq_seq TO postgres;
GRANT ALL ON SEQUENCE comment_seq_seq TO idgit_group;


--
-- TOC entry 1877 (class 0 OID 0)
-- Dependencies: 1542
-- Name: exceptions; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE exceptions FROM PUBLIC;
REVOKE ALL ON TABLE exceptions FROM postgres;
GRANT ALL ON TABLE exceptions TO postgres;
GRANT ALL ON TABLE exceptions TO idgit_group;


--
-- TOC entry 1879 (class 0 OID 0)
-- Dependencies: 1534
-- Name: issue_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE issue_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE issue_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE issue_seq_seq TO postgres;
GRANT ALL ON SEQUENCE issue_seq_seq TO idgit_group;


--
-- TOC entry 1880 (class 0 OID 0)
-- Dependencies: 1539
-- Name: permission; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE permission FROM PUBLIC;
REVOKE ALL ON TABLE permission FROM postgres;
GRANT ALL ON TABLE permission TO postgres;
GRANT ALL ON TABLE permission TO idgit_group;


--
-- TOC entry 1882 (class 0 OID 0)
-- Dependencies: 1538
-- Name: permission_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE permission_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE permission_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE permission_seq_seq TO postgres;
GRANT ALL ON SEQUENCE permission_seq_seq TO idgit_group;


--
-- TOC entry 1883 (class 0 OID 0)
-- Dependencies: 1537
-- Name: user; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE "user" FROM PUBLIC;
REVOKE ALL ON TABLE "user" FROM postgres;
GRANT ALL ON TABLE "user" TO postgres;
GRANT ALL ON TABLE "user" TO idgit_group;


-- Completed on 2010-04-26 00:17:51 CDT

--
-- PostgreSQL database dump complete
--

