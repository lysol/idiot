--
-- PostgreSQL database dump
--

-- Started on 2010-05-27 23:22:44 CDT

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 1905 (class 1262 OID 130474)
-- Name: idiot; Type: DATABASE; Schema: -; Owner: idiot
--

CREATE DATABASE idiot WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C';


ALTER DATABASE idiot OWNER TO idiot;

\connect idiot

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 375 (class 2612 OID 16386)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

--
-- TOC entry 376 (class 2612 OID 130627)
-- Name: plpythonu; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpythonu;


ALTER PROCEDURAL LANGUAGE plpythonu OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- TOC entry 367 (class 1247 OID 130887)
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
-- TOC entry 365 (class 1247 OID 130882)
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
-- TOC entry 363 (class 1247 OID 130877)
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
-- TOC entry 44 (class 1255 OID 146889)
-- Dependencies: 376 3
-- Name: confirm_email(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION confirm_email(in_auth_key uuid) RETURNS boolean
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    SELECT username 
    FROM email_confirmation
    WHERE auth_key = $1
    """, ["uuid"])

result = plpy.execute(plan, [in_auth_key])
if len(result) == 1:
    username = result[0]['username']
    plan = plpy.prepare("""
        DELETE FROM email_confirmation
        WHERE auth_key = $1
        """, ["uuid"])
    plpy.execute(plan, [in_auth_key])
    plan = plpy.prepare("""
        UPDATE "user"
        SET email_confirmed = TRUE
        WHERE username = $1
        """, ["text"])
    plpy.execute(plan, [username])
    return True
else:
    return False

$_$;


ALTER FUNCTION public.confirm_email(in_auth_key uuid) OWNER TO postgres;

--
-- TOC entry 45 (class 1255 OID 146881)
-- Dependencies: 376 3
-- Name: create_email_confirmation(character varying, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_email_confirmation(in_username character varying, in_auth_key uuid) RETURNS uuid
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
  SELECT TRUE
  FROM email_confirmation
  WHERE username = $1
  """, ["text"])

result = plpy.execute(plan, [in_username])

if len(result) > 0:
  plan = plpy.prepare("""
    DELETE
    FROM email_confirmation
    WHERE username = $1
    """, ["text"])
  plpy.execute(plan, [in_username])
  
plan = plpy.prepare("""
  INSERT INTO email_confirmation (
    username, auth_key
  ) VALUES (
    $1, $2
  )
  """, ["text", "uuid"])
  
plpy.execute(plan, [in_username, in_auth_key])
return in_auth_key
$_$;


ALTER FUNCTION public.create_email_confirmation(in_username character varying, in_auth_key uuid) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 1564 (class 1259 OID 130477)
-- Dependencies: 1851 1852 1853 1854 1855 1856 363 365 3 367
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
-- TOC entry 46 (class 1255 OID 138668)
-- Dependencies: 376 346 3
-- Name: create_issue(character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_issue(project character varying, summary character varying, description character varying, author character varying, severity character varying, issue_type character varying) RETURNS SETOF issue
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    INSERT INTO issue (
        project, summary, description, author, severity, "type"
    ) VALUES (
        $1, $2, $3, $4, $5, $6
    )
    RETURNING seq AS issue_seq
    ;
""", ["text", "text", "text", "text", "severity", "issue_type"])

seq = plpy.execute(plan, [project, summary, description, author, severity, issue_type])[0]['issue_seq']

plan = plpy.prepare("""
    SELECT *
    FROM issue
    WHERE seq = $1
""", ["int4"])
return plpy.execute(plan,[seq])

$_$;


ALTER FUNCTION public.create_issue(project character varying, summary character varying, description character varying, author character varying, severity character varying, issue_type character varying) OWNER TO postgres;

--
-- TOC entry 25 (class 1255 OID 130858)
-- Dependencies: 376 3
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
-- TOC entry 1570 (class 1259 OID 130584)
-- Dependencies: 1872 1873 3
-- Name: comment; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE comment (
    seq integer NOT NULL,
    author character varying DEFAULT ''::character varying NOT NULL,
    comment character varying NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    issue_seq integer NOT NULL,
    parent_seq integer
);


ALTER TABLE public.comment OWNER TO postgres;

--
-- TOC entry 47 (class 1255 OID 146857)
-- Dependencies: 3 357 376
-- Name: create_thread(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION create_thread(issue_seq integer, author character varying, comment character varying) RETURNS SETOF comment
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    INSERT INTO comment (
        author, comment, issue_seq
    ) VALUES (
        $1, $2, $3
    ) RETURNING seq as comment_seq;
""", ["text", "text", "int4"])

seq = plpy.execute(plan, [author, comment, issue_seq])[0]['comment_seq']

plan = plpy.prepare("""
    SELECT *
    FROM comment
    WHERE seq = $1
""", ["int4"])

return plpy.execute(plan, [seq])

$_$;


ALTER FUNCTION public.create_thread(issue_seq integer, author character varying, comment character varying) OWNER TO postgres;

--
-- TOC entry 1566 (class 1259 OID 130492)
-- Dependencies: 1860 1861 1862 1863 1864 1865 1866 1867 3
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
    email_confirmed boolean DEFAULT false NOT NULL,
    CONSTRAINT email_proper CHECK ((((email)::text ~ '@'::text) OR ((email)::text = ''::text))),
    CONSTRAINT website_proper CHECK ((((website)::text ~ '^http'::text) OR ((website)::text = ''::text)))
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- TOC entry 41 (class 1255 OID 130875)
-- Dependencies: 350 3 376
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
-- Dependencies: 3 376
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
-- TOC entry 27 (class 1255 OID 130640)
-- Dependencies: 3 376
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
-- TOC entry 23 (class 1255 OID 130635)
-- Dependencies: 3 376
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
-- TOC entry 28 (class 1255 OID 130641)
-- Dependencies: 3 376
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
-- TOC entry 29 (class 1255 OID 130658)
-- Dependencies: 3 357 376
-- Name: get_all_comments(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_all_comments() RETURNS SETOF comment
    LANGUAGE plpythonu
    AS $$

RETURN plpy.execute("SELECT * FROM comment")

$$;


ALTER FUNCTION public.get_all_comments() OWNER TO postgres;

--
-- TOC entry 30 (class 1255 OID 130659)
-- Dependencies: 3 357 376
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
-- TOC entry 48 (class 1255 OID 138669)
-- Dependencies: 376 3
-- Name: get_issue_statuses(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_issue_statuses() RETURNS SETOF character varying
    LANGUAGE plpythonu STABLE
    AS $$
result = plpy.execute("""
SELECT pg_enum.enumlabel::varchar
FROM pg_enum
JOIN pg_type ON pg_type.typname = 'issue_status'
AND pg_type.oid = pg_enum.enumtypid
""")

return [row['enumlabel'] for row in result]
$$;


ALTER FUNCTION public.get_issue_statuses() OWNER TO postgres;

--
-- TOC entry 49 (class 1255 OID 138693)
-- Dependencies: 376 3 357
-- Name: get_issue_threads(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_issue_threads(issue_seq integer) RETURNS SETOF comment
    LANGUAGE plpythonu STABLE
    AS $_$

plan = plpy.prepare("""
        SELECT * FROM comment WHERE issue_seq = $1
""", ["int4"])

return plpy.execute(plan, [issue_seq])

$_$;


ALTER FUNCTION public.get_issue_threads(issue_seq integer) OWNER TO postgres;

--
-- TOC entry 50 (class 1255 OID 138667)
-- Dependencies: 3 376
-- Name: get_issue_types(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_issue_types() RETURNS SETOF character varying
    LANGUAGE plpythonu STABLE
    AS $$
result = plpy.execute("""
SELECT pg_enum.enumlabel::varchar
FROM pg_enum
JOIN pg_type ON pg_type.typname = 'issue_type'
AND pg_type.oid = pg_enum.enumtypid
""")

return [row['enumlabel'] for row in result]
$$;


ALTER FUNCTION public.get_issue_types() OWNER TO postgres;

--
-- TOC entry 1565 (class 1259 OID 130485)
-- Dependencies: 1857 1858 1859 3
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
-- Dependencies: 3 375 348
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
-- TOC entry 51 (class 1255 OID 130637)
-- Dependencies: 346 3 376
-- Name: get_project_issue_page(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) RETURNS SETOF issue
    LANGUAGE plpythonu STABLE
    AS $_$

offset = (page - 1) * per_page
limit = offset + per_page

if offset > 0:

    plan = plpy.prepare("""
        SELECT *
        FROM issue
        WHERE project = $1
        ORDER BY created DESC
        OFFSET $2 LIMIT $3
    """, ["text", "int4", "int4"])
    result = plpy.execute(plan, [name, offset, limit])
else:

    plan = plpy.prepare("""
        SELECT *
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
-- TOC entry 19 (class 1255 OID 130636)
-- Dependencies: 346 376 3
-- Name: get_project_issues(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_project_issues(name character varying) RETURNS SETOF issue
    LANGUAGE plpythonu STABLE
    AS $_$


plan = plpy.prepare("""
    SELECT *
    FROM issue
    WHERE project = $1
    ORDER BY created DESC
""", ["text"])

return plpy.execute(plan, [name])


$_$;


ALTER FUNCTION public.get_project_issues(name character varying) OWNER TO postgres;

--
-- TOC entry 40 (class 1255 OID 130871)
-- Dependencies: 376 3
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
-- TOC entry 20 (class 1255 OID 130615)
-- Dependencies: 348 3 375
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
-- TOC entry 36 (class 1255 OID 130851)
-- Dependencies: 375 3 348
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
-- TOC entry 37 (class 1255 OID 130850)
-- Dependencies: 3 348 376
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
-- TOC entry 52 (class 1255 OID 138666)
-- Dependencies: 3 376
-- Name: get_severities(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_severities() RETURNS SETOF character varying
    LANGUAGE plpythonu STABLE
    AS $$
result = plpy.execute("""
SELECT pg_enum.enumlabel::varchar
FROM pg_enum
JOIN pg_type ON pg_type.typname = 'severity'
AND pg_type.oid = pg_enum.enumtypid
""")

return [row['enumlabel'] for row in result]
$$;


ALTER FUNCTION public.get_severities() OWNER TO postgres;

--
-- TOC entry 31 (class 1255 OID 130661)
-- Dependencies: 357 3 376
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
-- TOC entry 42 (class 1255 OID 130868)
-- Dependencies: 3 350 375
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
-- TOC entry 61 (class 1255 OID 146890)
-- Dependencies: 350 3 375
-- Name: get_user_by_email(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_user_by_email(in_email character varying) RETURNS SETOF "user"
    LANGUAGE plpgsql STABLE
    AS $$

  BEGIN

  RETURN QUERY
    SELECT * FROM "user"
    WHERE email = in_email;

  END;



$$;


ALTER FUNCTION public.get_user_by_email(in_email character varying) OWNER TO postgres;

--
-- TOC entry 43 (class 1255 OID 130847)
-- Dependencies: 3 376 348
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
-- TOC entry 53 (class 1255 OID 138665)
-- Dependencies: 376 3 348
-- Name: get_user_projects(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_user_projects(username character varying) RETURNS SETOF project
    LANGUAGE plpythonu STABLE
    AS $_$

plan = plpy.prepare("""
    SELECT *
    FROM project
    WHERE owner = $1
    OR name IN (SELECT project FROM permission
        WHERE username = $1)
    OR (SELECT "user"."admin" FROM "user"
        WHERE username = $1)
    OR "public" IS TRUE
    """, ["text"])
result = plpy.execute(plan, [username])

if len(result) == 0:
    return []
return result
    

$_$;


ALTER FUNCTION public.get_user_projects(username character varying) OWNER TO postgres;

--
-- TOC entry 54 (class 1255 OID 130916)
-- Dependencies: 357 3 376
-- Name: get_user_recent_comments(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) RETURNS SETOF comment
    LANGUAGE plpythonu STABLE
    AS $_$
plan = plpy.prepare("""
    SELECT comment.*
    FROM comment
    JOIN issue ON comment.issue_seq = issue.seq
    WHERE has_project_access(issue.project, $1)
    AND comment.author = $2
    ORDER BY timestamp DESC
    LIMIT $3
""", ["text", "text", "int4"])

return plpy.execute(plan, [viewing_user, viewed_user, count])
$_$;


ALTER FUNCTION public.get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) OWNER TO postgres;

--
-- TOC entry 55 (class 1255 OID 130918)
-- Dependencies: 3 346 376
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
-- TOC entry 56 (class 1255 OID 138670)
-- Dependencies: 3 375
-- Name: has_issue_write_access(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION has_issue_write_access(issue_seq integer, username character varying) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $_$
BEGIN
IF username = '' THEN
    RETURN FALSE;
END IF;

RETURN $2 IN (
    SELECT author
    FROM issue
    WHERE seq = $1
) OR (
    SELECT admin
    FROM "user"
    WHERE username = $2
) as access;
END;
$_$;


ALTER FUNCTION public.has_issue_write_access(issue_seq integer, username character varying) OWNER TO postgres;

--
-- TOC entry 34 (class 1255 OID 130853)
-- Dependencies: 375 3
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
-- TOC entry 32 (class 1255 OID 130653)
-- Dependencies: 376 3
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
-- TOC entry 57 (class 1255 OID 130921)
-- Dependencies: 3 376
-- Name: modify_issue(integer, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION modify_issue(seq integer, summary character varying, description character varying, severity character varying, issue_type character varying, status character varying) RETURNS void
    LANGUAGE plpythonu
    AS $_$

plan = plpy.prepare("""
    UPDATE issue
    SET summary = $1,
    description = $2,
    severity = $4,
    type = $5,
    status = $6
    WHERE seq = $3
""", ["text", "text", "int4", "severity", "issue_type", "issue_status"])

plpy.execute(plan, [summary, description, seq, severity, issue_type, status])

$_$;


ALTER FUNCTION public.modify_issue(seq integer, summary character varying, description character varying, severity character varying, issue_type character varying, status character varying) OWNER TO postgres;

--
-- TOC entry 21 (class 1255 OID 130639)
-- Dependencies: 3 376
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
-- TOC entry 33 (class 1255 OID 130859)
-- Dependencies: 376 3
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
-- TOC entry 22 (class 1255 OID 130629)
-- Dependencies: 376 3
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
-- TOC entry 35 (class 1255 OID 130663)
-- Dependencies: 376 3
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
-- TOC entry 38 (class 1255 OID 130855)
-- Dependencies: 375 3
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
-- TOC entry 58 (class 1255 OID 130655)
-- Dependencies: 3 376
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
-- TOC entry 60 (class 1255 OID 130656)
-- Dependencies: 3 376
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
-- TOC entry 39 (class 1255 OID 130856)
-- Dependencies: 375 3
-- Name: user_login(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION user_login(login_username character varying, login_password character varying) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
RETURN COALESCE(
  (SELECT TRUE FROM "user"
   WHERE username = login_username
   AND password = md5(login_password)
   AND email_confirmed IS TRUE), FALSE
);
END;
$$;


ALTER FUNCTION public.user_login(login_username character varying, login_password character varying) OWNER TO postgres;

--
-- TOC entry 59 (class 1255 OID 130857)
-- Dependencies: 375 3
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
-- TOC entry 1569 (class 1259 OID 130582)
-- Dependencies: 1570 3
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
-- TOC entry 1955 (class 0 OID 0)
-- Dependencies: 1569
-- Name: comment_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE comment_seq_seq OWNED BY comment.seq;


--
-- TOC entry 1572 (class 1259 OID 146865)
-- Dependencies: 3
-- Name: email_confirmation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE email_confirmation (
    auth_key uuid NOT NULL,
    username character varying NOT NULL
);


ALTER TABLE public.email_confirmation OWNER TO postgres;

--
-- TOC entry 1571 (class 1259 OID 130601)
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
-- TOC entry 1563 (class 1259 OID 130475)
-- Dependencies: 3 1564
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
-- TOC entry 1959 (class 0 OID 0)
-- Dependencies: 1563
-- Name: issue_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE issue_seq_seq OWNED BY issue.seq;


--
-- TOC entry 1568 (class 1259 OID 130503)
-- Dependencies: 1869 1870 3
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
-- TOC entry 1567 (class 1259 OID 130501)
-- Dependencies: 1568 3
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
-- TOC entry 1962 (class 0 OID 0)
-- Dependencies: 1567
-- Name: permission_seq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE permission_seq_seq OWNED BY permission.seq;


--
-- TOC entry 1871 (class 2604 OID 130587)
-- Dependencies: 1570 1569 1570
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE comment ALTER COLUMN seq SET DEFAULT nextval('comment_seq_seq'::regclass);


--
-- TOC entry 1850 (class 2604 OID 130480)
-- Dependencies: 1564 1563 1564
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE issue ALTER COLUMN seq SET DEFAULT nextval('issue_seq_seq'::regclass);


--
-- TOC entry 1868 (class 2604 OID 130506)
-- Dependencies: 1567 1568 1568
-- Name: seq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE permission ALTER COLUMN seq SET DEFAULT nextval('permission_seq_seq'::regclass);


--
-- TOC entry 1887 (class 2606 OID 130593)
-- Dependencies: 1570 1570
-- Name: comment_seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1892 (class 2606 OID 146872)
-- Dependencies: 1572 1572
-- Name: email_auth_key_uniq; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY email_confirmation
    ADD CONSTRAINT email_auth_key_uniq PRIMARY KEY (auth_key);


--
-- TOC entry 1894 (class 2606 OID 146888)
-- Dependencies: 1572 1572
-- Name: email_confirmation_username_unique; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY email_confirmation
    ADD CONSTRAINT email_confirmation_username_unique UNIQUE (username);


--
-- TOC entry 1890 (class 2606 OID 130608)
-- Dependencies: 1571 1571
-- Name: exceptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY exceptions
    ADD CONSTRAINT exceptions_pkey PRIMARY KEY (name);


--
-- TOC entry 1875 (class 2606 OID 130558)
-- Dependencies: 1564 1564
-- Name: issue_seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT issue_seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1877 (class 2606 OID 130517)
-- Dependencies: 1565 1565
-- Name: project_name_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_name_primary_key PRIMARY KEY (name);


--
-- TOC entry 1883 (class 2606 OID 130515)
-- Dependencies: 1568 1568 1568
-- Name: project_user_permission_unique; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT project_user_permission_unique UNIQUE (project, username);


--
-- TOC entry 1885 (class 2606 OID 130513)
-- Dependencies: 1568 1568
-- Name: seq_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY permission
    ADD CONSTRAINT seq_primary_key PRIMARY KEY (seq);


--
-- TOC entry 1879 (class 2606 OID 146894)
-- Dependencies: 1566 1566
-- Name: user_unique_email; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_unique_email UNIQUE (email);


--
-- TOC entry 1881 (class 2606 OID 130547)
-- Dependencies: 1566 1566
-- Name: username_primary_key; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT username_primary_key PRIMARY KEY (username);


--
-- TOC entry 1888 (class 1259 OID 138689)
-- Dependencies: 1570
-- Name: fki_comment_issue_seq_fk; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fki_comment_issue_seq_fk ON comment USING btree (issue_seq);


--
-- TOC entry 1895 (class 2606 OID 130559)
-- Dependencies: 1564 1566 1880
-- Name: author_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT author_fk FOREIGN KEY (author) REFERENCES "user"(username) ON UPDATE RESTRICT ON DELETE SET DEFAULT;


--
-- TOC entry 1898 (class 2606 OID 130594)
-- Dependencies: 1566 1880 1570
-- Name: comment_author_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_author_fk FOREIGN KEY (author) REFERENCES "user"(username) ON UPDATE RESTRICT ON DELETE SET DEFAULT;


--
-- TOC entry 1900 (class 2606 OID 138684)
-- Dependencies: 1874 1570 1564
-- Name: comment_issue_seq_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_issue_seq_fk FOREIGN KEY (issue_seq) REFERENCES issue(seq) ON UPDATE RESTRICT ON DELETE SET DEFAULT;


--
-- TOC entry 1899 (class 2606 OID 130647)
-- Dependencies: 1570 1886 1570
-- Name: comment_parent_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY comment
    ADD CONSTRAINT comment_parent_fk FOREIGN KEY (parent_seq) REFERENCES comment(seq) ON UPDATE SET NULL ON DELETE CASCADE;


--
-- TOC entry 1902 (class 2606 OID 146882)
-- Dependencies: 1880 1566 1572
-- Name: email_confirmation_username_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY email_confirmation
    ADD CONSTRAINT email_confirmation_username_fk FOREIGN KEY (username) REFERENCES "user"(username) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 1901 (class 2606 OID 130609)
-- Dependencies: 1571 1571 1889
-- Name: exceptions_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY exceptions
    ADD CONSTRAINT exceptions_parent_fkey FOREIGN KEY (parent) REFERENCES exceptions(name);


--
-- TOC entry 1896 (class 2606 OID 130564)
-- Dependencies: 1564 1565 1876
-- Name: project_issue_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issue
    ADD CONSTRAINT project_issue_fk FOREIGN KEY (project) REFERENCES project(name) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 1897 (class 2606 OID 130569)
-- Dependencies: 1566 1565 1880
-- Name: project_owner_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_owner_fk FOREIGN KEY (owner) REFERENCES "user"(username);


--
-- TOC entry 1907 (class 0 OID 0)
-- Dependencies: 3
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 1908 (class 0 OID 0)
-- Dependencies: 44
-- Name: confirm_email(uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION confirm_email(in_auth_key uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION confirm_email(in_auth_key uuid) FROM postgres;
GRANT ALL ON FUNCTION confirm_email(in_auth_key uuid) TO postgres;
GRANT ALL ON FUNCTION confirm_email(in_auth_key uuid) TO PUBLIC;
GRANT ALL ON FUNCTION confirm_email(in_auth_key uuid) TO idiot_group;


--
-- TOC entry 1909 (class 0 OID 0)
-- Dependencies: 45
-- Name: create_email_confirmation(character varying, uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION create_email_confirmation(in_username character varying, in_auth_key uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_email_confirmation(in_username character varying, in_auth_key uuid) FROM postgres;
GRANT ALL ON FUNCTION create_email_confirmation(in_username character varying, in_auth_key uuid) TO postgres;
GRANT ALL ON FUNCTION create_email_confirmation(in_username character varying, in_auth_key uuid) TO PUBLIC;
GRANT ALL ON FUNCTION create_email_confirmation(in_username character varying, in_auth_key uuid) TO idiot_group;


--
-- TOC entry 1910 (class 0 OID 0)
-- Dependencies: 1564
-- Name: issue; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE issue FROM PUBLIC;
REVOKE ALL ON TABLE issue FROM postgres;
GRANT ALL ON TABLE issue TO postgres;
GRANT ALL ON TABLE issue TO idiot_group;


--
-- TOC entry 1911 (class 0 OID 0)
-- Dependencies: 46
-- Name: create_issue(character varying, character varying, character varying, character varying, character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION create_issue(project character varying, summary character varying, description character varying, author character varying, severity character varying, issue_type character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_issue(project character varying, summary character varying, description character varying, author character varying, severity character varying, issue_type character varying) FROM postgres;
GRANT ALL ON FUNCTION create_issue(project character varying, summary character varying, description character varying, author character varying, severity character varying, issue_type character varying) TO postgres;
GRANT ALL ON FUNCTION create_issue(project character varying, summary character varying, description character varying, author character varying, severity character varying, issue_type character varying) TO PUBLIC;
GRANT ALL ON FUNCTION create_issue(project character varying, summary character varying, description character varying, author character varying, severity character varying, issue_type character varying) TO idiot_group;


--
-- TOC entry 1912 (class 0 OID 0)
-- Dependencies: 25
-- Name: create_project(character varying, character varying, character varying, character varying, boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION create_project(name character varying, full_name character varying, description character varying, owner character varying, public boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_project(name character varying, full_name character varying, description character varying, owner character varying, public boolean) FROM postgres;
GRANT ALL ON FUNCTION create_project(name character varying, full_name character varying, description character varying, owner character varying, public boolean) TO postgres;
GRANT ALL ON FUNCTION create_project(name character varying, full_name character varying, description character varying, owner character varying, public boolean) TO PUBLIC;
GRANT ALL ON FUNCTION create_project(name character varying, full_name character varying, description character varying, owner character varying, public boolean) TO idiot_group;


--
-- TOC entry 1913 (class 0 OID 0)
-- Dependencies: 1570
-- Name: comment; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE comment FROM PUBLIC;
REVOKE ALL ON TABLE comment FROM postgres;
GRANT ALL ON TABLE comment TO postgres;
GRANT ALL ON TABLE comment TO idiot_group;


--
-- TOC entry 1914 (class 0 OID 0)
-- Dependencies: 47
-- Name: create_thread(integer, character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION create_thread(issue_seq integer, author character varying, comment character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_thread(issue_seq integer, author character varying, comment character varying) FROM postgres;
GRANT ALL ON FUNCTION create_thread(issue_seq integer, author character varying, comment character varying) TO postgres;
GRANT ALL ON FUNCTION create_thread(issue_seq integer, author character varying, comment character varying) TO PUBLIC;
GRANT ALL ON FUNCTION create_thread(issue_seq integer, author character varying, comment character varying) TO idiot_group;


--
-- TOC entry 1915 (class 0 OID 0)
-- Dependencies: 1566
-- Name: user; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE "user" FROM PUBLIC;
REVOKE ALL ON TABLE "user" FROM postgres;
GRANT ALL ON TABLE "user" TO postgres;
GRANT ALL ON TABLE "user" TO idiot_group;


--
-- TOC entry 1916 (class 0 OID 0)
-- Dependencies: 41
-- Name: create_user(character varying, character varying, character varying, character varying, character varying, character varying, boolean, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean, about character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean, about character varying) FROM postgres;
GRANT ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean, about character varying) TO postgres;
GRANT ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean, about character varying) TO PUBLIC;
GRANT ALL ON FUNCTION create_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean, about character varying) TO idiot_group;


--
-- TOC entry 1917 (class 0 OID 0)
-- Dependencies: 26
-- Name: delete_comment(integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION delete_comment(seq integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_comment(seq integer) FROM postgres;
GRANT ALL ON FUNCTION delete_comment(seq integer) TO postgres;
GRANT ALL ON FUNCTION delete_comment(seq integer) TO PUBLIC;
GRANT ALL ON FUNCTION delete_comment(seq integer) TO idiot_group;


--
-- TOC entry 1918 (class 0 OID 0)
-- Dependencies: 27
-- Name: delete_permission(integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION delete_permission(seq integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_permission(seq integer) FROM postgres;
GRANT ALL ON FUNCTION delete_permission(seq integer) TO postgres;
GRANT ALL ON FUNCTION delete_permission(seq integer) TO PUBLIC;
GRANT ALL ON FUNCTION delete_permission(seq integer) TO idiot_group;


--
-- TOC entry 1919 (class 0 OID 0)
-- Dependencies: 23
-- Name: delete_project(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION delete_project(name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_project(name character varying) FROM postgres;
GRANT ALL ON FUNCTION delete_project(name character varying) TO postgres;
GRANT ALL ON FUNCTION delete_project(name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION delete_project(name character varying) TO idiot_group;


--
-- TOC entry 1920 (class 0 OID 0)
-- Dependencies: 28
-- Name: delete_user(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION delete_user(username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_user(username character varying) FROM postgres;
GRANT ALL ON FUNCTION delete_user(username character varying) TO postgres;
GRANT ALL ON FUNCTION delete_user(username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION delete_user(username character varying) TO idiot_group;


--
-- TOC entry 1921 (class 0 OID 0)
-- Dependencies: 29
-- Name: get_all_comments(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_all_comments() FROM PUBLIC;
REVOKE ALL ON FUNCTION get_all_comments() FROM postgres;
GRANT ALL ON FUNCTION get_all_comments() TO postgres;
GRANT ALL ON FUNCTION get_all_comments() TO PUBLIC;
GRANT ALL ON FUNCTION get_all_comments() TO idiot_group;


--
-- TOC entry 1922 (class 0 OID 0)
-- Dependencies: 30
-- Name: get_comment(integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_comment(seq integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_comment(seq integer) FROM postgres;
GRANT ALL ON FUNCTION get_comment(seq integer) TO postgres;
GRANT ALL ON FUNCTION get_comment(seq integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_comment(seq integer) TO idiot_group;


--
-- TOC entry 1923 (class 0 OID 0)
-- Dependencies: 48
-- Name: get_issue_statuses(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_issue_statuses() FROM PUBLIC;
REVOKE ALL ON FUNCTION get_issue_statuses() FROM postgres;
GRANT ALL ON FUNCTION get_issue_statuses() TO postgres;
GRANT ALL ON FUNCTION get_issue_statuses() TO PUBLIC;
GRANT ALL ON FUNCTION get_issue_statuses() TO idiot_group;


--
-- TOC entry 1924 (class 0 OID 0)
-- Dependencies: 49
-- Name: get_issue_threads(integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_issue_threads(issue_seq integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_issue_threads(issue_seq integer) FROM postgres;
GRANT ALL ON FUNCTION get_issue_threads(issue_seq integer) TO postgres;
GRANT ALL ON FUNCTION get_issue_threads(issue_seq integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_issue_threads(issue_seq integer) TO idiot_group;


--
-- TOC entry 1925 (class 0 OID 0)
-- Dependencies: 50
-- Name: get_issue_types(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_issue_types() FROM PUBLIC;
REVOKE ALL ON FUNCTION get_issue_types() FROM postgres;
GRANT ALL ON FUNCTION get_issue_types() TO postgres;
GRANT ALL ON FUNCTION get_issue_types() TO PUBLIC;
GRANT ALL ON FUNCTION get_issue_types() TO idiot_group;


--
-- TOC entry 1926 (class 0 OID 0)
-- Dependencies: 1565
-- Name: project; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE project FROM PUBLIC;
REVOKE ALL ON TABLE project FROM postgres;
GRANT ALL ON TABLE project TO postgres;
GRANT ALL ON TABLE project TO idiot_group;


--
-- TOC entry 1927 (class 0 OID 0)
-- Dependencies: 24
-- Name: get_project(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project(project_name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project(project_name character varying) FROM postgres;
GRANT ALL ON FUNCTION get_project(project_name character varying) TO postgres;
GRANT ALL ON FUNCTION get_project(project_name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_project(project_name character varying) TO idiot_group;


--
-- TOC entry 1928 (class 0 OID 0)
-- Dependencies: 51
-- Name: get_project_issue_page(character varying, integer, integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) FROM postgres;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO postgres;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_project_issue_page(name character varying, page integer, per_page integer) TO idiot_group;


--
-- TOC entry 1929 (class 0 OID 0)
-- Dependencies: 19
-- Name: get_project_issues(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project_issues(name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project_issues(name character varying) FROM postgres;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO postgres;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_project_issues(name character varying) TO idiot_group;


--
-- TOC entry 1930 (class 0 OID 0)
-- Dependencies: 40
-- Name: get_project_max_issue_page(character varying, integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_project_max_issue_page(name character varying, per_page integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_project_max_issue_page(name character varying, per_page integer) FROM postgres;
GRANT ALL ON FUNCTION get_project_max_issue_page(name character varying, per_page integer) TO postgres;
GRANT ALL ON FUNCTION get_project_max_issue_page(name character varying, per_page integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_project_max_issue_page(name character varying, per_page integer) TO idiot_group;


--
-- TOC entry 1931 (class 0 OID 0)
-- Dependencies: 20
-- Name: get_projects(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_projects() FROM PUBLIC;
REVOKE ALL ON FUNCTION get_projects() FROM postgres;
GRANT ALL ON FUNCTION get_projects() TO postgres;
GRANT ALL ON FUNCTION get_projects() TO PUBLIC;
GRANT ALL ON FUNCTION get_projects() TO idiot_group;


--
-- TOC entry 1932 (class 0 OID 0)
-- Dependencies: 36
-- Name: get_projects(boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_projects(public_only boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_projects(public_only boolean) FROM postgres;
GRANT ALL ON FUNCTION get_projects(public_only boolean) TO postgres;
GRANT ALL ON FUNCTION get_projects(public_only boolean) TO PUBLIC;
GRANT ALL ON FUNCTION get_projects(public_only boolean) TO idiot_group;


--
-- TOC entry 1933 (class 0 OID 0)
-- Dependencies: 37
-- Name: get_public_project_page(integer, integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_public_project_page(page integer, per_page integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_public_project_page(page integer, per_page integer) FROM postgres;
GRANT ALL ON FUNCTION get_public_project_page(page integer, per_page integer) TO postgres;
GRANT ALL ON FUNCTION get_public_project_page(page integer, per_page integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_public_project_page(page integer, per_page integer) TO idiot_group;


--
-- TOC entry 1934 (class 0 OID 0)
-- Dependencies: 52
-- Name: get_severities(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_severities() FROM PUBLIC;
REVOKE ALL ON FUNCTION get_severities() FROM postgres;
GRANT ALL ON FUNCTION get_severities() TO postgres;
GRANT ALL ON FUNCTION get_severities() TO PUBLIC;
GRANT ALL ON FUNCTION get_severities() TO idiot_group;


--
-- TOC entry 1935 (class 0 OID 0)
-- Dependencies: 31
-- Name: get_thread(integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_thread(seq integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_thread(seq integer) FROM postgres;
GRANT ALL ON FUNCTION get_thread(seq integer) TO postgres;
GRANT ALL ON FUNCTION get_thread(seq integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_thread(seq integer) TO idiot_group;


--
-- TOC entry 1936 (class 0 OID 0)
-- Dependencies: 42
-- Name: get_user(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_user(in_username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_user(in_username character varying) FROM postgres;
GRANT ALL ON FUNCTION get_user(in_username character varying) TO postgres;
GRANT ALL ON FUNCTION get_user(in_username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_user(in_username character varying) TO idiot_group;


--
-- TOC entry 1937 (class 0 OID 0)
-- Dependencies: 61
-- Name: get_user_by_email(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_user_by_email(in_email character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_user_by_email(in_email character varying) FROM postgres;
GRANT ALL ON FUNCTION get_user_by_email(in_email character varying) TO postgres;
GRANT ALL ON FUNCTION get_user_by_email(in_email character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_user_by_email(in_email character varying) TO idiot_group;


--
-- TOC entry 1938 (class 0 OID 0)
-- Dependencies: 43
-- Name: get_user_project_page(integer, integer, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_user_project_page(page integer, per_page integer, username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_user_project_page(page integer, per_page integer, username character varying) FROM postgres;
GRANT ALL ON FUNCTION get_user_project_page(page integer, per_page integer, username character varying) TO postgres;
GRANT ALL ON FUNCTION get_user_project_page(page integer, per_page integer, username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_user_project_page(page integer, per_page integer, username character varying) TO idiot_group;


--
-- TOC entry 1939 (class 0 OID 0)
-- Dependencies: 53
-- Name: get_user_projects(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_user_projects(username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_user_projects(username character varying) FROM postgres;
GRANT ALL ON FUNCTION get_user_projects(username character varying) TO postgres;
GRANT ALL ON FUNCTION get_user_projects(username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION get_user_projects(username character varying) TO idiot_group;


--
-- TOC entry 1940 (class 0 OID 0)
-- Dependencies: 54
-- Name: get_user_recent_comments(character varying, character varying, integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) FROM postgres;
GRANT ALL ON FUNCTION get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) TO postgres;
GRANT ALL ON FUNCTION get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_user_recent_comments(viewed_user character varying, viewing_user character varying, count integer) TO idiot_group;


--
-- TOC entry 1941 (class 0 OID 0)
-- Dependencies: 55
-- Name: get_user_recent_issues(character varying, character varying, integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION get_user_recent_issues(viewed_user character varying, viewing_user character varying, count integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_user_recent_issues(viewed_user character varying, viewing_user character varying, count integer) FROM postgres;
GRANT ALL ON FUNCTION get_user_recent_issues(viewed_user character varying, viewing_user character varying, count integer) TO postgres;
GRANT ALL ON FUNCTION get_user_recent_issues(viewed_user character varying, viewing_user character varying, count integer) TO PUBLIC;
GRANT ALL ON FUNCTION get_user_recent_issues(viewed_user character varying, viewing_user character varying, count integer) TO idiot_group;


--
-- TOC entry 1942 (class 0 OID 0)
-- Dependencies: 56
-- Name: has_issue_write_access(integer, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION has_issue_write_access(issue_seq integer, username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION has_issue_write_access(issue_seq integer, username character varying) FROM postgres;
GRANT ALL ON FUNCTION has_issue_write_access(issue_seq integer, username character varying) TO postgres;
GRANT ALL ON FUNCTION has_issue_write_access(issue_seq integer, username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION has_issue_write_access(issue_seq integer, username character varying) TO idiot_group;


--
-- TOC entry 1943 (class 0 OID 0)
-- Dependencies: 34
-- Name: has_project_access(character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION has_project_access(project_name character varying, username character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION has_project_access(project_name character varying, username character varying) FROM postgres;
GRANT ALL ON FUNCTION has_project_access(project_name character varying, username character varying) TO postgres;
GRANT ALL ON FUNCTION has_project_access(project_name character varying, username character varying) TO PUBLIC;
GRANT ALL ON FUNCTION has_project_access(project_name character varying, username character varying) TO idiot_group;


--
-- TOC entry 1944 (class 0 OID 0)
-- Dependencies: 32
-- Name: modify_comment(integer, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION modify_comment(seq integer, comment character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_comment(seq integer, comment character varying) FROM postgres;
GRANT ALL ON FUNCTION modify_comment(seq integer, comment character varying) TO postgres;
GRANT ALL ON FUNCTION modify_comment(seq integer, comment character varying) TO PUBLIC;
GRANT ALL ON FUNCTION modify_comment(seq integer, comment character varying) TO idiot_group;


--
-- TOC entry 1945 (class 0 OID 0)
-- Dependencies: 57
-- Name: modify_issue(integer, character varying, character varying, character varying, character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION modify_issue(seq integer, summary character varying, description character varying, severity character varying, issue_type character varying, status character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_issue(seq integer, summary character varying, description character varying, severity character varying, issue_type character varying, status character varying) FROM postgres;
GRANT ALL ON FUNCTION modify_issue(seq integer, summary character varying, description character varying, severity character varying, issue_type character varying, status character varying) TO postgres;
GRANT ALL ON FUNCTION modify_issue(seq integer, summary character varying, description character varying, severity character varying, issue_type character varying, status character varying) TO PUBLIC;
GRANT ALL ON FUNCTION modify_issue(seq integer, summary character varying, description character varying, severity character varying, issue_type character varying, status character varying) TO idiot_group;


--
-- TOC entry 1946 (class 0 OID 0)
-- Dependencies: 21
-- Name: modify_permission(character varying, character varying, boolean, boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION modify_permission(project character varying, username character varying, post_issues boolean, post_comments boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_permission(project character varying, username character varying, post_issues boolean, post_comments boolean) FROM postgres;
GRANT ALL ON FUNCTION modify_permission(project character varying, username character varying, post_issues boolean, post_comments boolean) TO postgres;
GRANT ALL ON FUNCTION modify_permission(project character varying, username character varying, post_issues boolean, post_comments boolean) TO PUBLIC;
GRANT ALL ON FUNCTION modify_permission(project character varying, username character varying, post_issues boolean, post_comments boolean) TO idiot_group;


--
-- TOC entry 1947 (class 0 OID 0)
-- Dependencies: 33
-- Name: modify_project(character varying, character varying, character varying, boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION modify_project(name character varying, full_name character varying, description character varying, public boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_project(name character varying, full_name character varying, description character varying, public boolean) FROM postgres;
GRANT ALL ON FUNCTION modify_project(name character varying, full_name character varying, description character varying, public boolean) TO postgres;
GRANT ALL ON FUNCTION modify_project(name character varying, full_name character varying, description character varying, public boolean) TO PUBLIC;
GRANT ALL ON FUNCTION modify_project(name character varying, full_name character varying, description character varying, public boolean) TO idiot_group;


--
-- TOC entry 1948 (class 0 OID 0)
-- Dependencies: 22
-- Name: modify_user(character varying, character varying, character varying, character varying, character varying, character varying, boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM postgres;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO postgres;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO PUBLIC;
GRANT ALL ON FUNCTION modify_user(username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO idiot_group;


--
-- TOC entry 1949 (class 0 OID 0)
-- Dependencies: 35
-- Name: modify_user(integer, character varying, character varying, character varying, character varying, character varying, character varying, boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION modify_user(seq integer, username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_user(seq integer, username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) FROM postgres;
GRANT ALL ON FUNCTION modify_user(seq integer, username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO postgres;
GRANT ALL ON FUNCTION modify_user(seq integer, username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO PUBLIC;
GRANT ALL ON FUNCTION modify_user(seq integer, username character varying, full_name character varying, email character varying, password character varying, password_again character varying, website character varying, admin boolean) TO idiot_group;


--
-- TOC entry 1950 (class 0 OID 0)
-- Dependencies: 38
-- Name: project_is_public(character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION project_is_public(project_name character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION project_is_public(project_name character varying) FROM postgres;
GRANT ALL ON FUNCTION project_is_public(project_name character varying) TO postgres;
GRANT ALL ON FUNCTION project_is_public(project_name character varying) TO PUBLIC;
GRANT ALL ON FUNCTION project_is_public(project_name character varying) TO idiot_group;


--
-- TOC entry 1951 (class 0 OID 0)
-- Dependencies: 58
-- Name: reply_comment(integer, character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION reply_comment(seq integer, author character varying, comment character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION reply_comment(seq integer, author character varying, comment character varying) FROM postgres;
GRANT ALL ON FUNCTION reply_comment(seq integer, author character varying, comment character varying) TO postgres;
GRANT ALL ON FUNCTION reply_comment(seq integer, author character varying, comment character varying) TO PUBLIC;
GRANT ALL ON FUNCTION reply_comment(seq integer, author character varying, comment character varying) TO idiot_group;


--
-- TOC entry 1952 (class 0 OID 0)
-- Dependencies: 60
-- Name: tr_no_cross_project_comments(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION tr_no_cross_project_comments() FROM PUBLIC;
REVOKE ALL ON FUNCTION tr_no_cross_project_comments() FROM postgres;
GRANT ALL ON FUNCTION tr_no_cross_project_comments() TO postgres;
GRANT ALL ON FUNCTION tr_no_cross_project_comments() TO PUBLIC;
GRANT ALL ON FUNCTION tr_no_cross_project_comments() TO idiot_group;


--
-- TOC entry 1953 (class 0 OID 0)
-- Dependencies: 39
-- Name: user_login(character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION user_login(login_username character varying, login_password character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION user_login(login_username character varying, login_password character varying) FROM postgres;
GRANT ALL ON FUNCTION user_login(login_username character varying, login_password character varying) TO postgres;
GRANT ALL ON FUNCTION user_login(login_username character varying, login_password character varying) TO PUBLIC;
GRANT ALL ON FUNCTION user_login(login_username character varying, login_password character varying) TO idiot_group;


--
-- TOC entry 1954 (class 0 OID 0)
-- Dependencies: 59
-- Name: user_verify(character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION user_verify(login_username character varying, md5_password character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION user_verify(login_username character varying, md5_password character varying) FROM postgres;
GRANT ALL ON FUNCTION user_verify(login_username character varying, md5_password character varying) TO postgres;
GRANT ALL ON FUNCTION user_verify(login_username character varying, md5_password character varying) TO PUBLIC;
GRANT ALL ON FUNCTION user_verify(login_username character varying, md5_password character varying) TO idiot_group;


--
-- TOC entry 1956 (class 0 OID 0)
-- Dependencies: 1569
-- Name: comment_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE comment_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE comment_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE comment_seq_seq TO postgres;
GRANT ALL ON SEQUENCE comment_seq_seq TO idiot_group;


--
-- TOC entry 1957 (class 0 OID 0)
-- Dependencies: 1572
-- Name: email_confirmation; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE email_confirmation FROM PUBLIC;
REVOKE ALL ON TABLE email_confirmation FROM postgres;
GRANT ALL ON TABLE email_confirmation TO postgres;
GRANT ALL ON TABLE email_confirmation TO idiot_group;


--
-- TOC entry 1958 (class 0 OID 0)
-- Dependencies: 1571
-- Name: exceptions; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE exceptions FROM PUBLIC;
REVOKE ALL ON TABLE exceptions FROM postgres;
GRANT ALL ON TABLE exceptions TO postgres;
GRANT ALL ON TABLE exceptions TO idiot_group;


--
-- TOC entry 1960 (class 0 OID 0)
-- Dependencies: 1563
-- Name: issue_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE issue_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE issue_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE issue_seq_seq TO postgres;
GRANT ALL ON SEQUENCE issue_seq_seq TO idiot_group;


--
-- TOC entry 1961 (class 0 OID 0)
-- Dependencies: 1568
-- Name: permission; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE permission FROM PUBLIC;
REVOKE ALL ON TABLE permission FROM postgres;
GRANT ALL ON TABLE permission TO postgres;
GRANT ALL ON TABLE permission TO idiot_group;


--
-- TOC entry 1963 (class 0 OID 0)
-- Dependencies: 1567
-- Name: permission_seq_seq; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON SEQUENCE permission_seq_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE permission_seq_seq FROM postgres;
GRANT ALL ON SEQUENCE permission_seq_seq TO postgres;
GRANT ALL ON SEQUENCE permission_seq_seq TO idiot_group;


-- Completed on 2010-05-27 23:22:44 CDT

--
-- PostgreSQL database dump complete
--

