-- This structure.sql file is not maintained or updated by Rails.
-- It exists only to allow custom functions to be easily loaded.
-- The app.json file runs db:structure:load prior to running tests in Heroku CI,
-- which will add functions contained in this file to the test database.
--
-- Name: pg_search_dmetaphone(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION pg_search_dmetaphone(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E'\\s+')))), ' ')
$_$;


-- Credit to Jakub Trmota https://github.com/forrest79/PgSQL-TransliterateUTF8ToAscii
-- Altered to approximate Rails' String#parameterize method (but without transliteration)
-- Transliteration should be performed before data is saved to relevant fields

CREATE OR REPLACE FUNCTION parameterize(in_string character varying)
  RETURNS character varying AS
$BODY$
  SELECT trim(BOTH '-' FROM regexp_replace(lower($1), '[^a-z0-9_]+', '-', 'g'));
$BODY$
  LANGUAGE sql IMMUTABLE
  COST 1;
