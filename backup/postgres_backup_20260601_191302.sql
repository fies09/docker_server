--
-- PostgreSQL database cluster dump
--

\restrict K7FMTXiUjUtbY25xBxcj4A0KQDYWubcDwsScOPd8drFK548wsk5q9TjTiGyOZ6P

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:p7w3o3YBbzJi8iASifIBJg==$gW5bPh9e1KUsgzpetFeswSxDbNcgWGpAqcElsBxFYig=:hCdvd9ysUzwS7mhNxVcvqKDXSWoFiKZ2VjR0wKdZM3o=';

--
-- User Configurations
--








\unrestrict K7FMTXiUjUtbY25xBxcj4A0KQDYWubcDwsScOPd8drFK548wsk5q9TjTiGyOZ6P

--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

\restrict eC59acUKPtdnheCLAE6X913h06Z4cV4uaFz38oWO909SSI96yZ5ciOfohaRxwA5

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg13+1)
-- Dumped by pg_dump version 18.3 (Debian 18.3-1.pgdg13+1)

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

--
-- PostgreSQL database dump complete
--

\unrestrict eC59acUKPtdnheCLAE6X913h06Z4cV4uaFz38oWO909SSI96yZ5ciOfohaRxwA5

--
-- Database "mydb" dump
--

--
-- PostgreSQL database dump
--

\restrict saLRdv47NohDuN5vQGT99sH4SWaL1vr4wdFvN8KeRXJMUsE0VJWWmZrBdGWqHih

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg13+1)
-- Dumped by pg_dump version 18.3 (Debian 18.3-1.pgdg13+1)

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

--
-- Name: mydb; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE mydb WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE mydb OWNER TO postgres;

\unrestrict saLRdv47NohDuN5vQGT99sH4SWaL1vr4wdFvN8KeRXJMUsE0VJWWmZrBdGWqHih
\connect mydb
\restrict saLRdv47NohDuN5vQGT99sH4SWaL1vr4wdFvN8KeRXJMUsE0VJWWmZrBdGWqHih

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

--
-- PostgreSQL database dump complete
--

\unrestrict saLRdv47NohDuN5vQGT99sH4SWaL1vr4wdFvN8KeRXJMUsE0VJWWmZrBdGWqHih

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict 7DD8cd1uw5mwIlNlRPI20vQb3yUgb7uxRgepqdVFCYnDHqn14Fe4zUzFdfmyogY

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg13+1)
-- Dumped by pg_dump version 18.3 (Debian 18.3-1.pgdg13+1)

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

--
-- PostgreSQL database dump complete
--

\unrestrict 7DD8cd1uw5mwIlNlRPI20vQb3yUgb7uxRgepqdVFCYnDHqn14Fe4zUzFdfmyogY

--
-- PostgreSQL database cluster dump complete
--

