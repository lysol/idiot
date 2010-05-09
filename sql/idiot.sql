--
-- PostgreSQL database dump
--

-- Started on 2010-05-09 09:48:04 CDT

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 1883 (class 1262 OID 130474)
-- Name: idiot; Type: DATABASE; Schema: -; Owner: idiot
--

CREATE DATABASE idiot WITH TEMPLATE = template0 ENCODING = 'UTF8' COLLATE = 'C' CTYPE = 'C';


ALTER DATABASE idiot OWNER TO idiot;

\connect idiot

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 363 (class 2612 OID 16386)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

--
-- TOC entry 364 (class 2612 OID 130627)
-- Name: plpythonu; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpythonu;


ALTER PROCEDURAL LANGUAGE plpythonu OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 360 (class 1247 OID 130887)
-- Dependencies: 3
-- Name: issue_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE issue_status AS ENUM (
    'open',
    'assigned',
    'rejected',
    'completed'
);


ALTER TYPE public.issue_status OWNER TO postgres;

--
-- TOC entry 358 (class 1247 OID 130882)
-- Dependencies: 3
-- Name: issue_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE issue_type AS ENUM (
    'defect',
    'enhancement',
    'task'
);


ALTER TYPE public.issue_type OWNER TO postgres;

--
-- TOC entry 356 (class 1247 OID 130877)
-- Dependencies: 3
-- Name: severity; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE severity AS ENUM (
    'trivial',
    'normal',
    'critical'
);


ALTER TYPE public.severity OWNER TO postgres;

--
-- TOC entry 19 (class 1255 OID 130638)
-- Dependencies: 3 364
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
-- TOC entry 29 (class 1255 OID 130858)
-- Dependencies: 3 364
-- Name: create_project(character varying, character varying, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_project(name character varying, full_name character varying, description character varying, owner character varying, public boolean) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    INSERT INTO project (
      name, full_name, description, owner, public
    ) VALUES (
      $1, $2, $3, $4, $5
    );
""", ["text", "text", "text", "text", "bool"])

plpy.execute(plan, [name, full_name, description, owner, public])

$_$;


ALTER FUNCTION public.create_project(name character varying, full_name character varying, description character varying, owner character varying, public boolean) OWNER TO postgres;

--
-- TOC entry 34 (class 1255 OID 130652)
-- Dependencies: 364 3
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

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 1554 (class 1259 OID 130492)
-- Dependencies: 1847 1848 1849 1850 1851 1852 1853 3
-- Name: user; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "user" (
    username character varying NOT NULL,
    full_name character varying DEFAULT ''::character varying NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    password character varying NOT NULL,
    website character varying DEFAULT ''::character varying NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    about character varying DEFAULT ''::character varying NOT NULL,
    CONSTRAINT email_proper CHECK ((((email)::text ~ '@'::text) OR ((email)::text = ''::text))),
    CONSTRAINT website_proper CHECK ((((website)::text ~ '^http'::text) OR ((website)::text = ''::text)))
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- TOC entry 51 (class 1255 OID 130875)
-- Dependencies: 3 364 341
-- Name: create_user(character varying, character varying, character varying, character varying, character varying, character varying, boolean, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean, about character varying) RETURNS SETOF "user"
    LANGUAGE plpythonu
    AS $_$

# Sanity checks
if password != password_again or len(password) < 6:
    raise Exception

plan = plpy.prepare("""
    INSERT INTO "user" (
      username, full_name, email, password, website, admin, about
    ) VALUES (
      $1, $2, $3, md5($4), $5, $6, $7
    );
""", ["text", "text", "text", "text", "text", "bool", "text"])

plpy.execute(plan, [username, full_name, email, password, website, admin, about])

plan = plpy.prepare("""
    SELECT * FROM "user"
    WHERE username = $1
""", ["text"])

return plpy.execute(plan, [username])

$_$;


ALTER FUNCTION public.create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean, about character varying) OWNER TO postgres;

--
-- TOC entry 26 (class 1255 OID 130654)
-- Dependencies: 364 3
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
-- TOC entry 30 (class 1255 OID 130640)
-- Dependencies: 3 364
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
-- TOC entry 22 (class 1255 OID 130635)
-- Dependencies: 364 3
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
-- TOC entry 33 (class 1255 OID 130641)
-- Dependencies: 3 364
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

--
-- TOC entry 1558 (class 1259 OID 130584)
-- Dependencies: 1858 1859 3
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
-- TOC entry 31 (class 1255 OID 130658)
-- Dependencies: 349 3 364
-- Name: get_all_comments(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_all_comments() RETURNS SETOF comment
    LANGUAGE plpythonu
    AS $$

RETURN plpy.execute("SELECT * FROM comment")

$$;


ALTER FUNCTION public.get_all_comments() OWNER TO postgres;

--
-- TOC entry 32 (class 1255 OID 130659)
-- Dependencies: 364 3 349
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
-- TOC entry 1553 (class 1259 OID 130485)
-- Dependencies: 1844 1845 1846 3
-- Name: project; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE project (
    name character varying NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    owner character varying NOT NULL,
    created_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    public boolean DEFAULT false NOT NULL,
    full_name character varying NOT NULL
);


ALTER TABLE public.project OWNER TO postgres;

--
-- TOC entry 24 (class 1255 OID 130616)
-- Dependencies: 3 339 363
-- Name: get_project(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project(project_name character varying) RETURNS SETOF project
    LANGUAGE plpgsql STABLE
    AS $$

  BEGIN

  RETURN QUERY
    SELECT * FROM project
    WHERE name = project_name;

  END;



$$;


ALTER FUNCTION public.get_project(project_name character varying) OWNER TO postgres;

--
-- TOC entry 1552 (class 1259 OID 130477)
-- Dependencies: 1838 1839 1840 1841 1842 1843 360 3 358 356
-- Name: issue; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE issue (
    seq integer NOT NULL,
    project character varying DEFAULT ''::character varying NOT NULL,
    summary character varying NOT NULL,
    description character varying NOT NULL,
    author character varying DEFAULT ''::character varying NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    severity severity DEFAULT 'normal'::severity NOT NULL,
    type issue_type DEFAULT 'defect'::issue_type NOT NULL,
    status issue_status DEFAULT 'open'::issue_status NOT NULL
);


ALTER TABLE public.issue OWNER TO postgres;

--
-- TOC entry 47 (class 1255 OID 130637)
-- Dependencies: 3 364 337
-- Name: get_project_issue_page(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) RETURNS SETOF issue
    LANGUAGE plpythonu STABLE
    AS $_$

offset = (page - 1) * per_page
limit = offset + per_page

if offset > 0:

    plan = plpy.prepare("""
        SELECT seq, project, summary, description, author, created
        FROM issue
        WHERE project = $1
        ORDER BY created DESC
        OFFSET $2 LIMIT $3
    """, ["text", "int4", "int4"])
    result = plpy.execute(plan, [name, offset, limit])
else:

    plan = plpy.prepare("""
        SELECT seq, project, summary, description, author, created
        FROM issue
        WHERE project = $1
        ORDER BY created DESC
        LIMIT $2
    """, ["text", "int4"])
    result = plpy.execute(plan, [name, limit])


if len(result) == 0:
    return []
return result
    

$_$;


ALTER FUNCTION public.get_project_issue_page(name character varying, page integer, per_page integer) OWNER TO postgres;

--
-- TOC entry 25 (class 1255 OID 130636)
-- Dependencies: 3 364 337
-- Name: get_project_issues(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project_issues(name character varying) RETURNS SETOF issue
    LANGUAGE plpythonu STABLE
    AS $_$


plan = plpy.prepare("""
    SELECT seq, project, summary, description, author, created
    FROM issue
    WHERE project = $1
    ORDER BY created DESC
""", ["text"])

return plpy.execute(plan, [name])


$_$;


ALTER FUNCTION public.get_project_issues(name character varying) OWNER TO postgres;

--
-- TOC entry 50 (class 1255 OID 130871)
-- Dependencies: 364 3
-- Name: get_project_max_issue_page(character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project_max_issue_page(name character varying, per_page integer) RETURNS integer
    LANGUAGE plpythonu STABLE
    AS $_$

plan = plpy.prepare("""
     SELECT CASE
            WHEN count(*) % $2 = 0
            THEN count(*) % $2
            ELSE (count(*) / $2) + 1
        END AS max_page
        FROM issue
        WHERE project = $1
    """, ["text", "int4"])

return plpy.execute(plan, [name, per_page])[0]['max_page']

$_$;


ALTER FUNCTION public.get_project_max_issue_page(name character varying, per_page integer) OWNER TO postgres;

--
-- TOC entry 23 (class 1255 OID 130615)
-- Dependencies: 363 339 3
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
-- TOC entry 41 (class 1255 OID 130851)
-- Dependencies: 3 363 339
-- Name: get_projects(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_projects(public_only boolean) RETURNS SETOF project
    LANGUAGE plpgsql STABLE
    AS $_$

  BEGIN

  RETURN QUERY SELECT * FROM project
               WHERE CASE
                   WHEN $1 IS TRUE THEN public
                   ELSE TRUE
               END;

  END;



$_$;


ALTER FUNCTION public.get_projects(public_only boolean) OWNER TO postgres;

--
-- TOC entry 40 (class 1255 OID 130850)
-- Dependencies: 3 339 364
-- Name: get_public_project_page(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_public_project_page(page integer, per_page integer) RETURNS SETOF project
    LANGUAGE plpythonu STABLE
    AS $_$

offset = (page - 1) * per_page
limit = offset + per_page

if offset > 0:

    plan = plpy.prepare("""
        SELECT name, full_name, description, owner, created_timestamp, public
        FROM project
        WHERE "public" IS TRUE
        OFFSET $1 LIMIT $2
    """, ["int4", "int4"])
    result = plpy.execute(plan, [offset, limit])
else:

    plan = plpy.prepare("""
        SELECT name, full_name, description, owner, created_timestamp, public
        FROM project
        WHERE "public" IS TRUE     
        LIMIT $1
    """, ["int4"])
    result = plpy.execute(plan, [limit])


if len(result) == 0:
    return []
return result
    

$_$;


ALTER FUNCTION public.get_public_project_page(page integer, per_page integer) OWNER TO postgres;

--
-- TOC entry 36 (class 1255 OID 130661)
-- Dependencies: 364 3 349
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
-- TOC entry 49 (class 1255 OID 130868)
-- Dependencies: 3 363 341
-- Name: get_user(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_user(in_username character varying) RETURNS SETOF "user"
    LANGUAGE plpgsql STABLE
    AS $$

  BEGIN

  RETURN QUERY
    SELECT * FROM "user"
    WHERE username = in_username;

  END;



$$;


ALTER FUNCTION public.get_user(in_username character varying) OWNER TO postgres;

--
-- TOC entry 45 (class 1255 OID 130847)
-- Dependencies: 3 364 339
-- Name: get_user_project_page(integer, integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_user_project_page(page integer, per_page integer, username character varying) RETURNS SETOF project
    LANGUAGE plpythonu STABLE
    AS $_$

offset = (page - 1) * per_page
limit = offset + per_page

if offset > 0:

    plan = plpy.prepare("""
        SELECT name, full_name, description, owner, created_timestamp, public
        FROM project
        WHERE owner = $1
        OR name IN (SELECT project FROM permission
         WHERE username = $1)
        OR (SELECT "user"."admin" FROM "user"
         WHERE username = $1)
        OR "public" IS TRUE
        OFFSET $2 LIMIT $3
    """, ["text", "int4", "int4"])
    result = plpy.execute(plan, [username, offset, limit])
else:

    plan = plpy.prepare("""
        SELECT name, full_name, description, owner, created_timestamp, public
        FROM project
        WHERE owner = $1
        OR name IN (SELECT project FROM permission
         WHERE username = $1)
        OR (SELECT "user"."admin" FROM "user"
         WHERE username = $1)
        OR "public" IS TRUE     
        LIMIT $2
    """, ["text", "int4"])
    result = plpy.execute(plan, [username, limit])


if len(result) == 0:
    return []
return result
    

$_$;


ALTER FUNCTION public.get_user_project_page(page integer, per_page integer, username character varying) OWNER TO postgres;

--
-- TOC entry 48 (class 1255 OID 130916)
-- Dependencies: 3 364 349
-- Name: get_user_recent_comments(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) RETURNS SETOF comment
    LANGUAGE plpythonu STABLE
    AS $_$
plan = plpy.prepare("""
    SELECT *
    FROM comment
    WHERE project IN (
        SELECT name
        FROM project
        WHERE has_project_access(name, $1)
    )
    AND author = $2
    ORDER BY timestamp DESC
    LIMIT $3
""", ["text", "text", "int4"])

return plpy.execute(plan, [viewing_user, viewed_user, count])
$_$;


ALTER FUNCTION public.get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) OWNER TO postgres;

--
-- TOC entry 52 (class 1255 OID 130918)
-- Dependencies: 364 337 3
-- Name: get_user_recent_issues(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_user_recent_issues(viewed_user character varying, viewing_user character varying, count integer) RETURNS SETOF issue
    LANGUAGE plpythonu STABLE
    AS $_$
plan = plpy.prepare("""
    SELECT *
    FROM issue
    WHERE project IN (
        SELECT name
        FROM project
        WHERE has_project_access(name, $1)
    )
    AND author = $2
    ORDER BY created DESC
    LIMIT $3
""", ["text", "text", "int4"])

return plpy.execute(plan, [viewing_user, viewed_user, count])
$_$;


ALTER FUNCTION public.get_user_recent_issues(viewed_user character varying, viewing_user character varying, count integer) OWNER TO postgres;

--
-- TOC entry 44 (class 1255 OID 130853)
-- Dependencies: 3 363
-- Name: has_project_access(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION has_project_access(project_name character varying, username character varying) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $_$
BEGIN
RETURN $2 IN (
    SELECT username
    FROM permission
    WHERE project = $1
) OR $1 IN (
    SELECT name
    FROM project
    WHERE public IS TRUE
    OR owner = $2
);
END;
$_$;


ALTER FUNCTION public.has_project_access(project_name character varying, username character varying) OWNER TO postgres;

--
-- TOC entry 35 (class 1255 OID 130653)
-- Dependencies: 364 3
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
-- TOC entry 38 (class 1255 OID 130664)
-- Dependencies: 364 3
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
-- TOC entry 21 (class 1255 OID 130639)
-- Dependencies: 3 364
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
-- TOC entry 46 (class 1255 OID 130859)
-- Dependencies: 3 364
-- Name: modify_project(character varying, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION modify_project(name character varying, full_name character varying, description character varying, public boolean) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    UPDATE project
    SET description = $1, public = $3, full_name = $4
    WHERE name = $2
""", ["text", "text", "bool", "text"])

plpy.execute(plan, [description, name, public, full_name])

$_$;


ALTER FUNCTION public.modify_project(name character varying, full_name character varying, description character varying, public boolean) OWNER TO postgres;

--
-- TOC entry 20 (class 1255 OID 130629)
-- Dependencies: 3 364
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
-- TOC entry 37 (class 1255 OID 130663)
-- Dependencies: 3 364
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
-- TOC entry 39 (class 1255 OID 130855)
-- Dependencies: 3 363
-- Name: project_is_public(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION project_is_public(project_name character varying) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $_$
BEGIN
RETURN $1 IN (
    SELECT name
    FROM project
    WHERE public IS TRUE
) as is_public;
END;
$_$;


ALTER FUNCTION public.project_is_public(project_name character varying) OWNER TO postgres;

--
-- TOC entry 27 (class 1255 OID 130655)
-- Dependencies: 3 364
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
-- TOC entry 28 (class 1255 OID 130656)
-- Dependencies: 3 364
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
-- TOC entry 42 (class 1255 OID 130856)
-- Dependencies: 363 3
-- Name: user_login(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION user_login(login_username character varying, login_password character varying) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
RETURN COALESCE(
  (SELECT TRUE FROM "user"
   WHERE username = login_username
   AND password = md5(login_password)), FALSE
);
END;
$$;


ALTER FUNCTION public.user_login(login_username character varying, login_password character varying) OWNER TO postgres;

--
-- TOC entry 43 (class 1255 OID 130857)
-- Dependencies: 3 363
-- Name: user_verify(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION user_verify(login_username character varying, md5_password character varying) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
RETURN COALESCE(
  (SELECT TRUE FROM "user"
   WHERE username = login_username
   AND password = md5_password), FALSE
);
END;
$$;


ALTER FUNCTION public.user_verify(login_username character varying, md5_password character varying) OWNER TO postgres;

--
-- TOC entry 1557 (class 1259 OID 130582)
-- Dependencies: 3 1558
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
-- TOC entry 1898 (class 0 OID 0)
-- Dependencies: 1557
-- Name: comment_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE comment_seq_seq OWNED BY comment.seq;


--
-- TOC entry 1559 (class 1259 OID 130601)
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
-- TOC entry 1551 (class 1259 OID 130475)
-- Dependencies: 1552 3
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
-- TOC entry 1901 (class 0 OID 0)
-- Dependencies: 1551
-- Name: issue_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE issue_seq_seq OWNED BY issue.seq;


--
-- TOC entry 1556 (class 1259 OID 130503)
-- Dependencies: 1855 1856 3
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
-- TOC entry 1555 (class 1259 OID 130501)
-- Dependencies: 1556 3
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
-- TOC entry 1904 (class 0 OID 0)
-- Dependencies: 1555
-- Name: permission_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE permission_seq_seq OWNED BY permission.seq;


--
-- TOC entry 1857 (class 2604 OID 130587)
-- Dependencies: 1558 1557 1558
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE comment ALTER COLUMN seq SET DEFAULT nextval('comment_seq_seq'::regclass);


--
-- TOC entry 1837 (class 2604 OID 130480)
-- Dependencies: 1551 1552 1552
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE issue ALTER COLUMN seq SET DEFAULT nextval('issue_seq_seq'::regclass);


--
-- TOC entry 1854 (class 2604 OID 130506)
-- Dependencies: 1555 1556 1556
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE permission ALTER COLUMN seq SET DEFAULT nextval('permission_seq_seq'::regclass);


--
-- TOC entry 1871 (class 2606 OID 130593)
-- Dependencies: 1558 1558
-- Name: comment_seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1873 (class 2606 OID 130608)
-- Dependencies: 1559 1559
-- Name: exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY exceptions
    ADD CONSTRAINT exceptions_pkey PRIMARY KEY (name);


--
-- TOC entry 1861 (class 2606 OID 130558)
-- Dependencies: 1552 1552
-- Name: issue_seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT issue_seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1863 (class 2606 OID 130517)
-- Dependencies: 1553 1553
-- Name: project_name_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_name_primary_key PRIMARY KEY (name);


--
-- TOC entry 1867 (class 2606 OID 130515)
-- Dependencies: 1556 1556 1556
-- Name: project_user_permission_unique; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT project_user_permission_unique UNIQUE (project, username);


--
-- TOC entry 1869 (class 2606 OID 130513)
-- Dependencies: 1556 1556
-- Name: seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1865 (class 2606 OID 130547)
-- Dependencies: 1554 1554
-- Name: username_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT username_primary_key PRIMARY KEY (username);


--
-- TOC entry 1874 (class 2606 OID 130559)
-- Dependencies: 1554 1552 1864
-- Name: author_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT author_fk FOREIGN KEY (author) REFERENCES "user"(username) ON UPDATE RESTRICT ON DELETE SET DEFAULT;


--
-- TOC entry 1877 (class 2606 OID 130594)
-- Dependencies: 1554 1558 1864
-- Name: comment_author_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_author_fk FOREIGN KEY (author) REFERENCES "user"(username) ON UPDATE RESTRICT ON DELETE SET DEFAULT;


--
-- TOC entry 1879 (class 2606 OID 130647)
-- Dependencies: 1558 1870 1558
-- Name: comment_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_parent_fk FOREIGN KEY (parent_seq) REFERENCES comment(seq) ON UPDATE SET NULL ON DELETE CASCADE;


--
-- TOC entry 1880 (class 2606 OID 130609)
-- Dependencies: 1559 1872 1559
-- Name: exceptions_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY exceptions
    ADD CONSTRAINT exceptions_parent_fkey FOREIGN KEY (parent) REFERENCES exceptions(name);


--
-- TOC entry 1878 (class 2606 OID 130642)
-- Dependencies: 1553 1862 1558
-- Name: project_comment_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT project_comment_fk FOREIGN KEY (project) REFERENCES project(name) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 1875 (class 2606 OID 130564)
-- Dependencies: 1862 1553 1552
-- Name: project_issue_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT project_issue_fk FOREIGN KEY (project) REFERENCES project(name) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 1876 (class 2606 OID 130569)
-- Dependencies: 1864 1553 1554
-- Name: project_owner_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_owner_fk FOREIGN KEY (owner) REFERENCES "user"(username);


--
-- TOC entry 1885 (class 0 OID 0)
-- Dependencies: 3
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 1886 (class 0 OID 0)
-- Dependencies: 1554
-- Name: user; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE "user" FROM PUBLIC;
REVOKE ALL ON TABLE "user" FROM postgres;
GRANT ALL ON TABLE "user" TO postgres;
GRANT ALL ON TABLE "user" TO idiot_group;


--
-- TOC entry 1887 (class 0 OID 0)
-- Dependencies: 22
-- Name: delete_project(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION delete_project(name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_project(name character varying) FROM postgres;
GRANT ALL ON FUNCTION delete_project(name character varying) TO postgres;
GRANT ALL ON FUNCTION delete_project(name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION delete_project(name character varying) TO idiot_group;


--
-- TOC entry 1888 (class 0 OID 0)
-- Dependencies: 33
-- Name: delete_user(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION delete_user(username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_user(username character varying) FROM postgres;
GRANT ALL ON FUNCTION delete_user(username character varying) TO postgres;
GRANT ALL ON FUNCTION delete_user(username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION delete_user(username character varying) TO idiot_group;


--
-- TOC entry 1889 (class 0 OID 0)
-- Dependencies: 1558
-- Name: comment; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE comment FROM PUBLIC;
REVOKE ALL ON TABLE comment FROM postgres;
GRANT ALL ON TABLE comment TO postgres;
GRANT ALL ON TABLE comment TO idiot_group;


--
-- TOC entry 1890 (class 0 OID 0)
-- Dependencies: 1553
-- Name: project; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE project FROM PUBLIC;
REVOKE ALL ON TABLE project FROM postgres;
GRANT ALL ON TABLE project TO postgres;
GRANT ALL ON TABLE project TO idiot_group;


--
-- TOC entry 1891 (class 0 OID 0)
-- Dependencies: 24
-- Name: get_project(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project(project_name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project(project_name character varying) FROM postgres;
GRANT ALL ON FUNCTION get_project(project_name character varying) TO postgres;
GRANT ALL ON FUNCTION get_project(project_name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_project(project_name character varying) TO idiot_group;


--
-- TOC entry 1892 (class 0 OID 0)
-- Dependencies: 1552
-- Name: issue; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE issue FROM PUBLIC;
REVOKE ALL ON TABLE issue FROM postgres;
GRANT ALL ON TABLE issue TO postgres;
GRANT ALL ON TABLE issue TO idiot_group;


--
-- TOC entry 1893 (class 0 OID 0)
-- Dependencies: 47
-- Name: get_project_issue_page(character varying, integer, integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) FROM postgres;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO postgres;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO idiot_group;


--
-- TOC entry 1894 (class 0 OID 0)
-- Dependencies: 25
-- Name: get_project_issues(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project_issues(name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project_issues(name character varying) FROM postgres;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO postgres;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO idiot_group;


--
-- TOC entry 1895 (class 0 OID 0)
-- Dependencies: 23
-- Name: get_projects(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_projects() FROM PUBLIC;
REVOKE ALL ON FUNCTION get_projects() FROM postgres;
GRANT ALL ON FUNCTION get_projects() TO postgres;
GRANT ALL ON FUNCTION get_projects() TO PUBLIC;
GRANT ALL ON FUNCTION get_projects() TO idiot_group;


--
-- TOC entry 1896 (class 0 OID 0)
-- Dependencies: 49
-- Name: get_user(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_user(in_username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_user(in_username character varying) FROM postgres;
GRANT ALL ON FUNCTION get_user(in_username character varying) TO postgres;
GRANT ALL ON FUNCTION get_user(in_username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_user(in_username character varying) TO idiot_group;


--
-- TOC entry 1897 (class 0 OID 0)
-- Dependencies: 20
-- Name: modify_user(character varying, character varying, character varying, character varying, character varying, character varying, boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM postgres;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO postgres;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO PUBLIC;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO idiot_group;


--
-- TOC entry 1899 (class 0 OID 0)
-- Dependencies: 1557
-- Name: comment_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE comment_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE comment_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE comment_seq_seq TO postgres;
GRANT ALL ON SEQUENCE comment_seq_seq TO idiot_group;


--
-- TOC entry 1900 (class 0 OID 0)
-- Dependencies: 1559
-- Name: exceptions; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE exceptions FROM PUBLIC;
REVOKE ALL ON TABLE exceptions FROM postgres;
GRANT ALL ON TABLE exceptions TO postgres;
GRANT ALL ON TABLE exceptions TO idiot_group;


--
-- TOC entry 1902 (class 0 OID 0)
-- Dependencies: 1551
-- Name: issue_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE issue_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE issue_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE issue_seq_seq TO postgres;
GRANT ALL ON SEQUENCE issue_seq_seq TO idiot_group;


--
-- TOC entry 1903 (class 0 OID 0)
-- Dependencies: 1556
-- Name: permission; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE permission FROM PUBLIC;
REVOKE ALL ON TABLE permission FROM postgres;
GRANT ALL ON TABLE permission TO postgres;
GRANT ALL ON TABLE permission TO idiot_group;


--
-- TOC entry 1905 (class 0 OID 0)
-- Dependencies: 1555
-- Name: permission_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE permission_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE permission_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE permission_seq_seq TO postgres;
GRANT ALL ON SEQUENCE permission_seq_seq TO idiot_group;


-- Completed on 2010-05-09 09:48:04 CDT

--
-- PostgreSQL database dump complete
--

