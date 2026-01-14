-- Let's create a "raw data" table, i.e. what we would really expect a table with just the raw data to look like

-- Create table to store imported data
CREATE TABLE IF NOT EXISTS fixtures (
    fixture_id INTEGER PRIMARY KEY,
    fixture_time_raw VARCHAR,
    country VARCHAR,
    league VARCHAR,
    season VARCHAR,
    home_team VARCHAR,
    away_team VARCHAR,
    referee VARCHAR,
    home_score INTEGER,
    away_score INTEGER,
    result VARCHAR
);

-- Import data
COPY fixtures
FROM '/data/prem_24_25_fixtures.csv'
DELIMITER ',' CSV HEADER;

-- Get rid of unnecessary columns
ALTER TABLE fixtures
    DROP COLUMN country,
    DROP COLUMN league,
    DROP COLUMN season,
    DROP COLUMN result;

-- Create the table storing all teams (what if a team changes its name, or its name is disputed?)
CREATE TABLE IF NOT EXISTS teams (
    team_id SMALLSERIAL PRIMARY KEY,
    team_name VARCHAR NOT NULL
);

-- Populate teams table with team names
INSERT INTO teams
            (team_name)
SELECT DISTINCT home_team
FROM fixtures
ORDER BY home_team;

-- In fixtures table, create team ID columns (we want these instead of team names)
ALTER TABLE fixtures
    ADD COLUMN home_id INT,
    ADD COLUMN away_id INT;

-- Insert home team IDs
UPDATE fixtures
SET home_id = teams.team_id
FROM teams
WHERE fixtures.home_team = teams.team_name;

-- Insert away team IDs
UPDATE fixtures
SET away_id = teams.team_id
FROM teams
WHERE fixtures.away_team = teams.team_name;

-- Ensure the home and away team IDs are foreign keys; name these constraints
ALTER TABLE fixtures
    ADD CONSTRAINT fk_home_id
        FOREIGN KEY (home_id) REFERENCES teams (team_id),
    ADD CONSTRAINT fk_away_id
        FOREIGN KEY (away_id) REFERENCES teams (team_id);

-- Ensure there are two team IDs in every fixture; we don't need the team name columns anymore
ALTER TABLE fixtures
    ALTER COLUMN home_id SET NOT NULL,
    ALTER COLUMN away_id SET NOT NULL,
    DROP COLUMN home_team,
    DROP COLUMN away_team;

-- Actually, we don't like the abbreviated 'Utd' in the teams table
UPDATE teams
SET team_name = 'Manchester United'
WHERE team_id = 14;

-- Now we need to change the date formats from DMY to YMD
-- Create a new column for fixture date/time in proper format
ALTER TABLE fixtures
    ADD COLUMN fixture_time TIMESTAMP;

-- Populate new column with altered dates from original column
UPDATE fixtures
SET fixture_time = TO_TIMESTAMP(fixture_time_raw, 'DD-MM-YY HH24:MI');

-- The times are actually an hour ahead
UPDATE fixtures
SET fixture_time = fixture_time - INTERVAL '1 hour';

-- We can now drop the original column
ALTER TABLE fixtures
    DROP COLUMN fixture_time_raw;

-- Add matchweek data
-- Create table for matchweek data
CREATE TABLE IF NOT EXISTS matchweek (
    match_no INTEGER,
    mw INTEGER,
    date VARCHAR,
    location VARCHAR,
    home_team VARCHAR,
    away_team VARCHAR,
    result VARCHAR
);

-- Import matchweek data
COPY matchweek
FROM '/data/epl-2024-GMTStandardTime.csv'
DELIMITER ',' CSV HEADER;

-- Convert team names to team IDs (alphabetical order is in line with ID ordering)
ALTER TABLE matchweek
    ADD COLUMN home_id INTEGER,
    ADD COLUMN away_id INTEGER;

-- Create table to match matchweek team names to IDs
CREATE TABLE IF NOT EXISTS mw_teams (
    team_id SMALLSERIAL PRIMARY KEY,
    mw_team VARCHAR
);

-- IDs go up in alphabetical order
INSERT INTO mw_teams
            (mw_team)
SELECT DISTINCT home_team
FROM matchweek
ORDER BY home_team;

-- Insert home team IDs
UPDATE matchweek
SET home_id = mw_teams.team_id
FROM mw_teams
WHERE matchweek.home_team = mw_teams.mw_team;

-- Insert away team IDs
UPDATE matchweek
SET away_id = mw_teams.team_id
FROM mw_teams
WHERE matchweek.away_team = mw_teams.mw_team;

-- We don't need the team names anymore
ALTER TABLE matchweek
    DROP COLUMN home_team,
    DROP COLUMN away_team;

-- Don't need the new ID table either
DROP TABLE mw_teams;

-- Finally, add in the matchweek for each fixture
CREATE TABLE mw_fixtures AS
    SELECT fixtures.*, matchweek.mw
    FROM fixtures
    LEFT JOIN matchweek
        ON fixtures.home_id = matchweek.home_id
        AND fixtures.away_id = matchweek.away_id;


















