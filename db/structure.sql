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
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: check_player_labels(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_player_labels() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  arr2 VARCHAR[];
BEGIN
  arr2 := (SELECT player_labels FROM tournaments WHERE id = NEW.tournament_id);
  IF (SELECT NEW.labels <@ arr2) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'tournaments_players.label IS NOT a member of tournament.player_labels';
  END IF;
END;
$$;


--
-- Name: check_result(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_result() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.result = 'draw' OR NEW.result = 'noshow' OR NEW.result IS NULL) THEN
    IF (NEW.walkover IS TRUE) THEN
      RAISE EXCEPTION 'walkover can only be set for white/black result';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: dec_wo_count_on_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dec_wo_count_on_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  wo_player INTEGER;
BEGIN
  RAISE NOTICE 'TG_NAME: %, OP: %, WHEN: %', TG_NAME, TG_OP, TG_WHEN;
  IF (OLD.result = 'white') THEN
    wo_player := OLD.black_id;
  ELSIF (OLD.result = 'black') THEN
    wo_player := OLD.white_id;
  END IF;
  UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = wo_player AND wo_count > 0;
  RETURN NULL;
END;
$$;


--
-- Name: dec_wo_count_on_noshow(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dec_wo_count_on_noshow() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE NOTICE 'TG_NAME: %, OP: %, WHEN: %', TG_NAME, TG_OP, TG_WHEN;
  UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = OLD.black_id AND wo_count > 0;
  UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = OLD.white_id AND wo_count > 0;
  RETURN NULL;
END;
$$;


--
-- Name: dec_wo_count_on_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dec_wo_count_on_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  wo_player INTEGER;
BEGIN
  RAISE NOTICE 'TG_NAME: %, OP: %, WHEN: %', TG_NAME, TG_OP, TG_WHEN;
  IF (OLD.result = 'white') THEN
    wo_player := OLD.black_id;
  ELSIF (OLD.result = 'black') THEN
    wo_player := OLD.white_id;
  END IF;
  UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = wo_player AND wo_count > 0;
  RETURN NULL;
END;
$$;


--
-- Name: inc_wo_count(integer, integer, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inc_wo_count(t_id integer, new_round integer, wo_player bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  prev_black INTEGER;
  prev_white INTEGER;
  prev_noshow INTEGER;
BEGIN
  --- check if also WO on the previous round
  prev_black  := (SELECT COUNT(1) FROM boards WHERE tournament_id = t_id AND round = new_round - 1 AND walkover IS true AND result = 'white' AND black_id = wo_player);
  prev_white  := (SELECT COUNT(1) FROM boards WHERE tournament_id = t_id AND round = new_round - 1 AND walkover IS true AND result = 'black' AND white_id = wo_player);
  prev_noshow := (SELECT COUNT(1) FROM boards WHERE tournament_id = t_id AND round = new_round - 1 AND result = 'noshow' AND (black_id = wo_player OR white_id = wo_player));

  IF (prev_black > 0 OR prev_white > 0 OR prev_noshow > 0) THEN
    UPDATE tournaments_players SET wo_count = wo_count + 1 WHERE id = wo_player;
  ELSE
    UPDATE tournaments_players SET wo_count = 1 WHERE id = wo_player;
  END IF;
END;
$$;


--
-- Name: inc_wo_count_on_noshow(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inc_wo_count_on_noshow() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  PERFORM inc_wo_count(NEW.tournament_id, NEW.round, NEW.black_id);
  PERFORM inc_wo_count(NEW.tournament_id, NEW.round, NEW.white_id);
  RETURN NULL;
END;
$$;


--
-- Name: inc_wo_count_on_walkover(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inc_wo_count_on_walkover() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  wo_player BIGINT;
BEGIN
  IF (NEW.result = 'white') THEN
    wo_player := NEW.black_id;
  ELSIF (NEW.result = 'black') THEN
    wo_player := NEW.white_id;
  END IF;
  PERFORM inc_wo_count(NEW.tournament_id, NEW.round, wo_player);
  RETURN NULL;
END;
$$;


--
-- Name: update_fp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_fp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.fp = TRUE) THEN
    UPDATE tournaments SET fp = FALSE WHERE id != NEW.id AND fp = TRUE;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: update_fp_global(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_fp_global() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.fp = TRUE) THEN
    IF (TG_TABLE_NAME = 'simuls') THEN
      UPDATE simuls SET fp = FALSE WHERE id != NEW.id AND fp = TRUE;
      UPDATE tournaments SET fp = FALSE WHERE fp = TRUE;
    ELSIF (TG_TABLE_NAME = 'tournaments') THEN
      UPDATE tournaments SET fp = FALSE WHERE id != NEW.id AND fp = TRUE;
      UPDATE simuls SET fp = FALSE WHERE fp = TRUE;
    END IF;    
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: update_fp_simuls(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_fp_simuls() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (NEW.fp = TRUE) THEN
    UPDATE simuls SET fp = FALSE WHERE id != NEW.id AND fp = TRUE;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: update_points(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_points() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    --- substract old results
    IF (OLD.result = 'white') THEN
        UPDATE tournaments_players SET points = points - 1   WHERE id = OLD.white_id;
    ELSIF (OLD.result = 'black') THEN
        UPDATE tournaments_players SET points = points - 1   WHERE id = OLD.black_id;
    ELSIF (OLD.result = 'draw') THEN
        UPDATE tournaments_players SET points = points - 0.5 WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
    --- update new results
    IF (NEW.result = 'white') THEN
        UPDATE tournaments_players SET points = points + 1   WHERE id = OLD.white_id;
    ELSIF (NEW.result = 'black') THEN
        UPDATE tournaments_players SET points = points + 1   WHERE id = OLD.black_id;
    ELSIF (NEW.result = 'draw') THEN
        UPDATE tournaments_players SET points = points + 0.5 WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (OLD.result = 'white') THEN
        UPDATE tournaments_players SET points = points - 1   WHERE id = OLD.white_id;
    ELSIF (OLD.result = 'black') THEN
        UPDATE tournaments_players SET points = points - 1   WHERE id = OLD.black_id;
    ELSIF (OLD.result = 'draw') THEN
        UPDATE tournaments_players SET points = points - 0.5 WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: update_points_configurable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_points_configurable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  win_pts DECIMAL(3,1);
  draw_pts DECIMAL(3,1);
  bye_pts DECIMAL(3,1);
BEGIN
  win_pts := (SELECT win_point FROM groups WHERE id = OLD.group_id);
  draw_pts := (SELECT draw_point FROM groups WHERE id = OLD.group_id);
  bye_pts := (SELECT bye_point FROM groups WHERE id = OLD.group_id);

  IF (TG_OP = 'UPDATE') THEN
  --- substract old results
    IF (OLD.result = 'white') THEN
      IF OLD.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_pts WHERE id = OLD.white_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_pts WHERE id = OLD.white_id;
      END IF;
    ELSIF (OLD.result = 'black') THEN
      IF OLD.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_pts WHERE id = OLD.black_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_pts   WHERE id = OLD.black_id;
      END IF;
    ELSIF (OLD.result = 'draw') THEN
      UPDATE tournaments_players SET points = points - draw_pts WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
    --- update new results
    IF (NEW.result = 'white') THEN
      IF NEW.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points + bye_pts WHERE id = NEW.white_id;
      ELSE
        UPDATE tournaments_players SET points = points + win_pts WHERE id = NEW.white_id;
      END IF;
    ELSIF (NEW.result = 'black') THEN
      IF NEW.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points + bye_pts WHERE id = NEW.black_id;
      ELSE
        UPDATE tournaments_players SET points = points + win_pts   WHERE id = NEW.black_id;
      END IF;
    ELSIF (NEW.result = 'draw') THEN
      UPDATE tournaments_players SET points = points + draw_pts WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (OLD.result = 'white') THEN
      IF OLD.black_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_pts WHERE id = OLD.white_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_pts WHERE id = OLD.white_id;
      END IF;
    ELSIF (OLD.result = 'black') THEN
      IF OLD.white_id IS NULL THEN
        UPDATE tournaments_players SET points = points - bye_pts WHERE id = OLD.black_id;
      ELSE
        UPDATE tournaments_players SET points = points - win_pts   WHERE id = OLD.black_id;
      END IF;
    ELSIF (OLD.result = 'draw') THEN
        UPDATE tournaments_players SET points = points - draw_pts WHERE id IN (OLD.white_id, OLD.black_id);
    END IF;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: update_wo_count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_wo_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  prev_black INTEGER;
  prev_white INTEGER;
  wo_player INTEGER;
  winning_player INTEGER;
BEGIN
  RAISE NOTICE 'Executing update_wo_count()';
  IF (NEW.result = 'white') THEN
    wo_player := NEW.black_id;
    winning_player := NEW.white_id;
  ELSIF (NEW.result = 'black') THEN
    wo_player := NEW.white_id;
    winning_player := NEW.black_id;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    PERFORM inc_wo_count(NEW.tournament_id, NEW.round, wo_player);
    --- update winning player
    UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = winning_player AND wo_count > 0;
  ELSIF TG_OP = 'DELETE' THEN
    IF (OLD.result = 'white') THEN
      wo_player := OLD.black_id;
    ELSIF (OLD.result = 'black') THEN
      wo_player := OLD.white_id;
    END IF;
    UPDATE tournaments_players SET wo_count = wo_count - 1 WHERE id = wo_player AND wo_count > 0;
  END IF;
  RETURN NULL;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


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
-- Name: boards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.boards (
    id integer NOT NULL,
    tournament_id integer NOT NULL,
    round integer DEFAULT 1 NOT NULL,
    result text,
    number integer NOT NULL,
    white_id bigint,
    black_id bigint,
    walkover boolean DEFAULT false NOT NULL,
    group_id bigint,
    CONSTRAINT boards_result_check CHECK ((result = ANY (ARRAY['white'::text, 'black'::text, 'draw'::text, 'noshow'::text])))
);


--
-- Name: boards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.boards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.boards_id_seq OWNED BY public.boards.id;


--
-- Name: events_sponsors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_sponsors (
    id bigint NOT NULL,
    sponsor_id bigint,
    eventable_type character varying,
    eventable_id bigint
);


--
-- Name: events_sponsors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_sponsors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_sponsors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_sponsors_id_seq OWNED BY public.events_sponsors.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id bigint NOT NULL,
    name text NOT NULL,
    tournament_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    bipartite_matching integer[] DEFAULT '{}'::integer[],
    max_walkover integer DEFAULT 1 NOT NULL,
    type character varying NOT NULL,
    rounds integer,
    win_point numeric(3,1) DEFAULT 1.0,
    draw_point numeric(3,1) DEFAULT 0.5,
    bye_point numeric(3,1) DEFAULT 1.0,
    merged_standings_config_id bigint,
    h2h_tb boolean DEFAULT false
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: listed_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listed_events (
    id bigint NOT NULL,
    eventable_type character varying,
    eventable_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: listed_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.listed_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: listed_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.listed_events_id_seq OWNED BY public.listed_events.id;


--
-- Name: merged_standings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merged_standings (
    id integer NOT NULL,
    merged_standings_config_id integer NOT NULL,
    player_id integer NOT NULL,
    points numeric(9,1) DEFAULT 0 NOT NULL,
    median numeric(9,1) DEFAULT 0,
    solkoff numeric(9,1) DEFAULT 0,
    cumulative numeric(9,1) DEFAULT 0,
    opposition_cumulative numeric(9,1) DEFAULT 0,
    playing_black integer DEFAULT 0,
    sb numeric(9,2) DEFAULT 0,
    wins integer DEFAULT 0,
    labels character varying[] DEFAULT '{}'::character varying[],
    blacklisted boolean DEFAULT false NOT NULL,
    h2h_points numeric(9,1),
    h2h_cluster integer
);


--
-- Name: merged_standings_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.merged_standings_configs (
    id bigint NOT NULL,
    name character varying,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    player_labels character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: merged_standings_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.merged_standings_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: merged_standings_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.merged_standings_configs_id_seq OWNED BY public.merged_standings_configs.id;


--
-- Name: merged_standings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.merged_standings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: merged_standings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.merged_standings_id_seq OWNED BY public.merged_standings.id;


--
-- Name: players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.players (
    id integer NOT NULL,
    name text NOT NULL,
    rating integer DEFAULT 1500 NOT NULL,
    modified_by text,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    updated_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    rating_deviation double precision DEFAULT 350.0 NOT NULL,
    rating_volatility double precision DEFAULT 0.06 NOT NULL,
    games_played integer DEFAULT 0 NOT NULL,
    rated_games_played integer DEFAULT 0 NOT NULL,
    fide_id character varying,
    fide_data text,
    phone character varying DEFAULT ''::character varying NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    graduation_year integer,
    affiliation character varying,
    remarks text,
    ccm_awarded_at_id bigint,
    CONSTRAINT affiliation_check CHECK (((affiliation)::text = ANY (ARRAY[('alumni_relatives'::character varying)::text, ('alumni'::character varying)::text, ('student'::character varying)::text, ('invitee'::character varying)::text, ('staff'::character varying)::text, ('N/A'::character varying)::text])))
);


--
-- Name: players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.players_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.players_id_seq OWNED BY public.players.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    session_id character varying NOT NULL,
    data text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: simuls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.simuls (
    id integer NOT NULL,
    fp boolean DEFAULT false NOT NULL,
    name text NOT NULL,
    description text,
    location text,
    date date,
    modified_by text,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    updated_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    simulgivers text,
    status integer DEFAULT 0,
    listed boolean DEFAULT false NOT NULL,
    alternate_color integer,
    playing_color text
);


--
-- Name: simuls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.simuls_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: simuls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.simuls_id_seq OWNED BY public.simuls.id;


--
-- Name: simuls_players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.simuls_players (
    id integer NOT NULL,
    simul_id integer NOT NULL,
    player_id integer NOT NULL,
    result text,
    color text DEFAULT 'black'::text NOT NULL,
    number integer DEFAULT 0,
    CONSTRAINT color_check CHECK ((color = ANY (ARRAY['white'::text, 'black'::text]))),
    CONSTRAINT result_check CHECK ((result = ANY (ARRAY['white'::text, 'black'::text, 'draw'::text, 'noshow'::text])))
);


--
-- Name: simuls_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.simuls_players_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: simuls_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.simuls_players_id_seq OWNED BY public.simuls_players.id;


--
-- Name: sponsors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sponsors (
    id bigint NOT NULL,
    name character varying NOT NULL,
    url text,
    remark text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sponsors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sponsors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sponsors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sponsors_id_seq OWNED BY public.sponsors.id;


--
-- Name: standings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.standings (
    id integer NOT NULL,
    tournaments_player_id integer NOT NULL,
    round integer NOT NULL,
    points numeric(9,1) NOT NULL,
    median numeric(9,1),
    solkoff numeric(9,1),
    cumulative numeric(9,1),
    opposition_cumulative numeric(9,1),
    playing_black integer DEFAULT 0 NOT NULL,
    tournament_id integer NOT NULL,
    blacklisted boolean DEFAULT false NOT NULL,
    sb numeric(9,2),
    h2h_rank integer,
    wins integer DEFAULT 0,
    h2h_points numeric(9,1),
    h2h_cluster integer
);


--
-- Name: standings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.standings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: standings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.standings_id_seq OWNED BY public.standings.id;


--
-- Name: titles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.titles (
    id bigint NOT NULL,
    cert_number character varying DEFAULT ''::character varying NOT NULL,
    name character varying DEFAULT 'CCM'::character varying NOT NULL,
    remarks text,
    awarded_on date,
    player_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: titles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.titles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: titles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.titles_id_seq OWNED BY public.titles.id;


--
-- Name: tournaments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournaments (
    id integer NOT NULL,
    name text NOT NULL,
    modified_by text,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    updated_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    fp boolean DEFAULT false NOT NULL,
    location character varying,
    date date,
    description text,
    rated boolean DEFAULT false NOT NULL,
    max_walkover integer DEFAULT 1 NOT NULL,
    player_labels character varying[] DEFAULT '{}'::character varying[],
    listed boolean DEFAULT false NOT NULL
);


--
-- Name: tournaments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tournaments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tournaments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tournaments_id_seq OWNED BY public.tournaments.id;


--
-- Name: tournaments_players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournaments_players (
    id integer NOT NULL,
    tournament_id integer NOT NULL,
    player_id integer NOT NULL,
    points numeric(9,1) DEFAULT 0 NOT NULL,
    blacklisted boolean DEFAULT false NOT NULL,
    start_rating integer,
    end_rating integer,
    wo_count integer DEFAULT 0 NOT NULL,
    labels character varying[] DEFAULT '{}'::character varying[],
    group_id bigint
);


--
-- Name: tournaments_players_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tournaments_players_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tournaments_players_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tournaments_players_id_seq OWNED BY public.tournaments_players.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    fullname character varying DEFAULT ''::character varying NOT NULL,
    username character varying NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: boards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards ALTER COLUMN id SET DEFAULT nextval('public.boards_id_seq'::regclass);


--
-- Name: events_sponsors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_sponsors ALTER COLUMN id SET DEFAULT nextval('public.events_sponsors_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: listed_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listed_events ALTER COLUMN id SET DEFAULT nextval('public.listed_events_id_seq'::regclass);


--
-- Name: merged_standings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merged_standings ALTER COLUMN id SET DEFAULT nextval('public.merged_standings_id_seq'::regclass);


--
-- Name: merged_standings_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merged_standings_configs ALTER COLUMN id SET DEFAULT nextval('public.merged_standings_configs_id_seq'::regclass);


--
-- Name: players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players ALTER COLUMN id SET DEFAULT nextval('public.players_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: simuls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simuls ALTER COLUMN id SET DEFAULT nextval('public.simuls_id_seq'::regclass);


--
-- Name: simuls_players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simuls_players ALTER COLUMN id SET DEFAULT nextval('public.simuls_players_id_seq'::regclass);


--
-- Name: sponsors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsors ALTER COLUMN id SET DEFAULT nextval('public.sponsors_id_seq'::regclass);


--
-- Name: standings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.standings ALTER COLUMN id SET DEFAULT nextval('public.standings_id_seq'::regclass);


--
-- Name: titles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.titles ALTER COLUMN id SET DEFAULT nextval('public.titles_id_seq'::regclass);


--
-- Name: tournaments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments ALTER COLUMN id SET DEFAULT nextval('public.tournaments_id_seq'::regclass);


--
-- Name: tournaments_players id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments_players ALTER COLUMN id SET DEFAULT nextval('public.tournaments_players_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: boards boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);


--
-- Name: events_sponsors events_sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_sponsors
    ADD CONSTRAINT events_sponsors_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: listed_events listed_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listed_events
    ADD CONSTRAINT listed_events_pkey PRIMARY KEY (id);


--
-- Name: merged_standings_configs merged_standings_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merged_standings_configs
    ADD CONSTRAINT merged_standings_configs_pkey PRIMARY KEY (id);


--
-- Name: merged_standings merged_standings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merged_standings
    ADD CONSTRAINT merged_standings_pkey PRIMARY KEY (id);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: simuls simuls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simuls
    ADD CONSTRAINT simuls_pkey PRIMARY KEY (id);


--
-- Name: simuls_players simuls_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simuls_players
    ADD CONSTRAINT simuls_players_pkey PRIMARY KEY (id);


--
-- Name: sponsors sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_pkey PRIMARY KEY (id);


--
-- Name: standings standings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.standings
    ADD CONSTRAINT standings_pkey PRIMARY KEY (id);


--
-- Name: titles titles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.titles
    ADD CONSTRAINT titles_pkey PRIMARY KEY (id);


--
-- Name: tournaments tournaments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments
    ADD CONSTRAINT tournaments_pkey PRIMARY KEY (id);


--
-- Name: tournaments_players tournaments_players_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments_players
    ADD CONSTRAINT tournaments_players_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_boards_on_black_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_boards_on_black_id ON public.boards USING btree (black_id);


--
-- Name: index_boards_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_boards_on_group_id ON public.boards USING btree (group_id);


--
-- Name: index_boards_on_tournament_id_and_round_and_number_and_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_boards_on_tournament_id_and_round_and_number_and_group ON public.boards USING btree (tournament_id, round, number, group_id);


--
-- Name: index_boards_on_white_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_boards_on_white_id ON public.boards USING btree (white_id);


--
-- Name: index_events_sponsors_on_eventable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_sponsors_on_eventable ON public.events_sponsors USING btree (eventable_type, eventable_id);


--
-- Name: index_events_sponsors_on_sponsor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_sponsors_on_sponsor_id ON public.events_sponsors USING btree (sponsor_id);


--
-- Name: index_groups_on_merged_standings_config_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_merged_standings_config_id ON public.groups USING btree (merged_standings_config_id);


--
-- Name: index_groups_on_tournament_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_tournament_id ON public.groups USING btree (tournament_id);


--
-- Name: index_groups_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_type ON public.groups USING btree (type);


--
-- Name: index_past_events_on_eventable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_past_events_on_eventable ON public.listed_events USING btree (eventable_type, eventable_id);


--
-- Name: index_players_on_ccm_awarded_at_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_players_on_ccm_awarded_at_id ON public.players USING btree (ccm_awarded_at_id);


--
-- Name: index_players_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_players_on_name ON public.players USING gist (name public.gist_trgm_ops);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_session_id ON public.sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON public.sessions USING btree (updated_at);


--
-- Name: index_standings_on_tournaments_player_id_and_round; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_standings_on_tournaments_player_id_and_round ON public.standings USING btree (tournaments_player_id, round);


--
-- Name: index_titles_on_player_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_titles_on_player_id ON public.titles USING btree (player_id);


--
-- Name: index_tournaments_on_id_and_fp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tournaments_on_id_and_fp ON public.tournaments USING btree (id, fp);


--
-- Name: index_tournaments_on_player_labels; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tournaments_on_player_labels ON public.tournaments USING gin (player_labels);


--
-- Name: index_tournaments_players_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tournaments_players_on_group_id ON public.tournaments_players USING btree (group_id);


--
-- Name: index_tournaments_players_on_labels; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tournaments_players_on_labels ON public.tournaments_players USING gin (labels);


--
-- Name: index_tournaments_players_on_tournament_id_and_player_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tournaments_players_on_tournament_id_and_player_id ON public.tournaments_players USING btree (tournament_id, player_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: boards a00_boards_if_walkover_true; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER a00_boards_if_walkover_true AFTER UPDATE OF walkover ON public.boards FOR EACH ROW WHEN ((new.walkover IS TRUE)) EXECUTE FUNCTION public.inc_wo_count_on_walkover();


--
-- Name: boards a05_boards_if_noshow; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER a05_boards_if_noshow AFTER UPDATE OF result ON public.boards FOR EACH ROW WHEN ((new.result = 'noshow'::text)) EXECUTE FUNCTION public.inc_wo_count_on_noshow();


--
-- Name: boards a10_boards_if_walkover_false; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER a10_boards_if_walkover_false AFTER UPDATE OF walkover ON public.boards FOR EACH ROW WHEN ((new.walkover IS FALSE)) EXECUTE FUNCTION public.dec_wo_count_on_update();


--
-- Name: boards a20_boards_result_if_walkover_true; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER a20_boards_result_if_walkover_true AFTER DELETE OR UPDATE OF result ON public.boards FOR EACH ROW WHEN ((old.walkover IS TRUE)) EXECUTE FUNCTION public.update_wo_count();


--
-- Name: boards a30_boards_after_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER a30_boards_after_delete AFTER DELETE ON public.boards FOR EACH ROW WHEN ((old.walkover IS TRUE)) EXECUTE FUNCTION public.dec_wo_count_on_delete();


--
-- Name: boards a40_boards_from_noshow; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER a40_boards_from_noshow AFTER UPDATE OF result ON public.boards FOR EACH ROW WHEN ((old.result = 'noshow'::text)) EXECUTE FUNCTION public.dec_wo_count_on_noshow();


--
-- Name: boards boards_check_result; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER boards_check_result BEFORE INSERT OR UPDATE ON public.boards FOR EACH ROW EXECUTE FUNCTION public.check_result();


--
-- Name: boards boards_if_modified; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER boards_if_modified AFTER DELETE OR UPDATE ON public.boards FOR EACH ROW EXECUTE FUNCTION public.update_points_configurable();


--
-- Name: simuls simuls_fp_modified; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER simuls_fp_modified AFTER INSERT OR UPDATE ON public.simuls FOR EACH ROW EXECUTE FUNCTION public.update_fp_global();


--
-- Name: tournaments tournaments_fp_modified; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tournaments_fp_modified AFTER INSERT OR UPDATE ON public.tournaments FOR EACH ROW EXECUTE FUNCTION public.update_fp_global();


--
-- Name: tournaments_players tournaments_players_check_player_labels; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tournaments_players_check_player_labels BEFORE INSERT OR UPDATE ON public.tournaments_players FOR EACH ROW EXECUTE FUNCTION public.check_player_labels();


--
-- Name: boards boards_tournament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id);


--
-- Name: groups fk_rails_1a66c2460d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_1a66c2460d FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id);


--
-- Name: boards fk_rails_1e9a074a35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT fk_rails_1e9a074a35 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: titles fk_rails_33ac63cdde; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.titles
    ADD CONSTRAINT fk_rails_33ac63cdde FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: boards fk_rails_7b8b8b8ac1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT fk_rails_7b8b8b8ac1 FOREIGN KEY (black_id) REFERENCES public.tournaments_players(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: tournaments_players fk_rails_9bd0e4dc6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments_players
    ADD CONSTRAINT fk_rails_9bd0e4dc6a FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: players fk_rails_aa53663708; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT fk_rails_aa53663708 FOREIGN KEY (ccm_awarded_at_id) REFERENCES public.listed_events(id);


--
-- Name: groups fk_rails_b8667a7556; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_rails_b8667a7556 FOREIGN KEY (merged_standings_config_id) REFERENCES public.merged_standings_configs(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: boards fk_rails_d80ebfe319; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT fk_rails_d80ebfe319 FOREIGN KEY (white_id) REFERENCES public.tournaments_players(id);


--
-- Name: merged_standings merged_standings_merged_standings_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merged_standings
    ADD CONSTRAINT merged_standings_merged_standings_config_id_fkey FOREIGN KEY (merged_standings_config_id) REFERENCES public.merged_standings_configs(id);


--
-- Name: merged_standings merged_standings_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.merged_standings
    ADD CONSTRAINT merged_standings_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: simuls_players simuls_players_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simuls_players
    ADD CONSTRAINT simuls_players_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: simuls_players simuls_players_simul_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simuls_players
    ADD CONSTRAINT simuls_players_simul_id_fkey FOREIGN KEY (simul_id) REFERENCES public.simuls(id);


--
-- Name: standings standings_tournament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.standings
    ADD CONSTRAINT standings_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE;


--
-- Name: standings standings_tournaments_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.standings
    ADD CONSTRAINT standings_tournaments_player_id_fkey FOREIGN KEY (tournaments_player_id) REFERENCES public.tournaments_players(id);


--
-- Name: tournaments_players tournaments_players_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments_players
    ADD CONSTRAINT tournaments_players_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id);


--
-- Name: tournaments_players tournaments_players_tournament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments_players
    ADD CONSTRAINT tournaments_players_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20230411135232'),
('20230412071621'),
('20230412073212'),
('20230412074311'),
('20230412091106'),
('20230416033508'),
('20230416033817'),
('20230420011822'),
('20230424145325'),
('20230426011757'),
('20230427040557'),
('20230503232236'),
('20230507162402'),
('20230509222724'),
('20230510210827'),
('20230523152226'),
('20230529012743'),
('20230530013119'),
('20230530021922'),
('20240302215303'),
('20240302223709'),
('20240306001128'),
('20240306003540'),
('20240315154542'),
('20240316121523'),
('20240318143740'),
('20240323165424'),
('20240323172446'),
('20240327015703'),
('20240330164843'),
('20240401124526'),
('20240403043743'),
('20240413031921'),
('20240415034104'),
('20240504212534'),
('20240512233336'),
('20240513235904'),
('20240516234039'),
('20240518072454'),
('20240523010843'),
('20250507170800'),
('20250508123207'),
('20250513093137'),
('20250513094800'),
('20250529073354'),
('20250711135553'),
('20250730073503'),
('20250731170248'),
('20250805181045'),
('20250808152612'),
('20250816125344'),
('20250821083414'),
('20250821173712'),
('20250826164806'),
('20250828034929'),
('20251119144427'),
('20251121014937'),
('20251123172044'),
('20251127162919'),
('20251130081520'),
('20251202011634'),
('20251202125038'),
('20251202155828'),
('20251202180941'),
('20251210142910'),
('20251218002259'),
('20251219050623'),
('20251219051135'),
('20251219062429'),
('20251220155525'),
('20251222000534'),
('20251230062633'),
('20260101054146'),
('20260101225351'),
('20260103032410'),
('20260115092219'),
('20260115123318');


