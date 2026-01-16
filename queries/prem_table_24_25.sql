-- Premier League 2024-25 table
SELECT
    teams.team_name AS team,
    COUNT(*) AS played,
    SUM(wins) AS wins,
    SUM(draws) AS draws,
    SUM(losses) AS losses,
    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,
    SUM(goals_for) - SUM(goals_against) AS goal_difference,
    SUM(points) AS points,
    ROUND(SUM(points)::DECIMAL / COUNT(*), 2) AS ppg
FROM teams
INNER JOIN (
    SELECT
        home_id AS team_id,
        CASE
            WHEN home_score > away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses,
        home_score AS goals_for,
        away_score AS goals_against
    FROM fixtures
    WHERE fixture_time <= '2025-05-01 00:00:00'

    UNION ALL

    SELECT
        away_id AS team_id,
        CASE
            WHEN home_score < away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN away_score = home_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS losses,
        away_score AS goals_for,
        home_score AS goals_against
    FROM fixtures
    WHERE fixture_time <= '2025-05-01 00:00:00'
) AS team_games ON teams.team_id = team_games.team_id
GROUP BY teams.team_id
ORDER BY points DESC, goal_difference DESC, goals_for DESC;

-- Home table
SELECT
    teams.team_name AS team,
    COUNT(*) AS played,
    SUM(wins) AS wins,
    SUM(draws) AS draws,
    SUM(losses) AS losses,
    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,
    SUM(goals_for) - SUM(goals_against) AS goal_difference,
    SUM(points) AS points
FROM teams
INNER JOIN (
    SELECT
        home_id AS team_id,
        CASE
            WHEN home_score > away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses,
        home_score AS goals_for,
        away_score AS goals_against
    FROM fixtures
    -- WHERE fixture_time <= '2024-12-25 00:00:00'
) AS team_games ON teams.team_id = team_games.team_id
GROUP BY teams.team_id
ORDER BY points DESC, goal_difference DESC, goals_for DESC;

-- Away table
SELECT
    teams.team_name AS team,
    COUNT(*) AS played,
    SUM(wins) AS wins,
    SUM(draws) AS draws,
    SUM(losses) AS losses,
    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,
    SUM(goals_for) - SUM(goals_against) AS goal_difference,
    SUM(points) AS points
FROM teams
INNER JOIN (
    SELECT
        away_id AS team_id,
        CASE
            WHEN home_score < away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN away_score = home_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS losses,
        away_score AS goals_for,
        home_score AS goals_against
    FROM fixtures
    -- WHERE fixture_time <= '2024-12-25 00:00:00'
) AS team_games ON teams.team_id = team_games.team_id
GROUP BY teams.team_id
ORDER BY points DESC, goal_difference DESC, goals_for DESC;

-- Goals by matchweek
SELECT mw, SUM(home_score) + SUM(away_score) AS total_goals
FROM mw_fixtures
GROUP BY mw
ORDER BY mw;

-- Matches decided by 3+ goals
SELECT f.*, t_home.team_name AS home_team, t_away.team_name AS away_team
FROM fixtures f
JOIN teams t_home
    ON f.home_id = t_home.team_id
JOIN teams t_away
    ON f.away_id = t_away.team_id
WHERE ABS(home_score - away_score) >= 3;

-- Matches involving 3+ goals
SELECT f.*, t_home.team_name AS home_team, t_away.team_name AS away_team
FROM fixtures f
JOIN teams t_home
    ON f.home_id = t_home.team_id
JOIN teams t_away
    ON f.away_id = t_away.team_id
WHERE home_score + away_score >= 3;

-- Teams' goal difference per month
SELECT
    t.team_name AS team,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 8 THEN goal_difference ELSE 0 END) AS august,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 9 THEN goal_difference ELSE 0 END) AS september,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 10 THEN goal_difference ELSE 0 END) AS october,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 11 THEN goal_difference ELSE 0 END) AS november,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 12 THEN goal_difference ELSE 0 END) AS december,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 1 THEN goal_difference ELSE 0 END) AS january,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 2 THEN goal_difference ELSE 0 END) AS february,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 3 THEN goal_difference ELSE 0 END) AS march,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 4 THEN goal_difference ELSE 0 END) AS april,
    SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 5 THEN goal_difference ELSE 0 END) AS may,
    SUM(goal_difference) AS gd
FROM teams t
INNER JOIN (
    SELECT
        home_id AS team_id,
        home_score - away_score AS goal_difference,
        fixture_time
    FROM fixtures

    UNION ALL

    SELECT
        away_id AS team_id,
        away_score - home_score AS goal_difference,
        fixture_time
    FROM fixtures
) f ON t.team_id = f.team_id
GROUP BY t.team_name
ORDER BY gd DESC;

-- Teams' PPG per month
SELECT
    t.team_name AS team,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 8 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 8 THEN 1 ELSE 0 END), 2) AS august,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 9 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 9 THEN 1 ELSE 0 END), 2) AS september,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 10 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 10 THEN 1 ELSE 0 END), 2) AS october,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 11 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 11 THEN 1 ELSE 0 END), 2) AS november,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 12 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 12 THEN 1 ELSE 0 END), 2) AS december,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 1 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 1 THEN 1 ELSE 0 END), 2) AS january,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 2 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 2 THEN 1 ELSE 0 END), 2) AS february,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 3 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 3 THEN 1 ELSE 0 END), 2) AS march,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 4 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 4 THEN 1 ELSE 0 END), 2) AS april,
    ROUND(SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 5 THEN points ELSE 0 END)::DECIMAL / SUM(CASE WHEN EXTRACT(MONTH FROM fixture_time) = 5 THEN 1 ELSE 0 END), 2) AS may,
    ROUND(SUM(points)::DECIMAL / 38, 2) AS ppg
FROM teams t
INNER JOIN (
    SELECT
        home_id AS team_id,
        CASE
            WHEN home_score > away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        fixture_time
    FROM fixtures

    UNION ALL

    SELECT
        away_id AS team_id,
        CASE
            WHEN away_score > home_score THEN 3
            WHEN away_score = home_score THEN 1
            ELSE 0
        END AS points,
        fixture_time
    FROM fixtures
) f ON t.team_id = f.team_id
GROUP BY t.team_name
ORDER BY ppg DESC;

-- London table
SELECT
    teams.team_name AS london_team,
    COUNT(*) AS played,
    SUM(wins) AS wins,
    SUM(draws) AS draws,
    SUM(losses) AS losses,
    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,
    SUM(goals_for) - SUM(goals_against) AS goal_difference,
    SUM(points) AS points
FROM teams
INNER JOIN (
    SELECT
        home_id AS team_id,
        CASE
            WHEN home_score > away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses,
        home_score AS goals_for,
        away_score AS goals_against
    FROM fixtures
    WHERE home_id IN (1, 4, 6, 7, 9, 18, 19) AND away_id IN (1, 4, 6, 7, 9, 18, 19)

    UNION ALL

    SELECT
        away_id AS team_id,
        CASE
            WHEN home_score < away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN away_score = home_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS losses,
        away_score AS goals_for,
        home_score AS goals_against
    FROM fixtures
    WHERE home_id IN (1, 4, 6, 7, 9, 18, 19) AND away_id IN (1, 4, 6, 7, 9, 18, 19)
) AS team_games ON teams.team_id = team_games.team_id
GROUP BY teams.team_id
ORDER BY points DESC, goal_difference DESC, goals_for DESC;

-- Points per game before and after the halfway point of the season
-- Table after matchweek 19 (but some games may have been postponed)
SELECT
    teams.team_name AS team,
    COUNT(*) AS played,
    SUM(wins) AS wins,
    SUM(draws) AS draws,
    SUM(losses) AS losses,
    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,
    SUM(goals_for) - SUM(goals_against) AS goal_difference,
    SUM(points) AS points
FROM teams
INNER JOIN (
    SELECT
        home_id AS team_id,
        CASE
            WHEN home_score > away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses,
        home_score AS goals_for,
        away_score AS goals_against
    FROM mw_fixtures
    WHERE mw <= 19

    UNION ALL

    SELECT
        away_id AS team_id,
        CASE
            WHEN home_score < away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN away_score = home_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS losses,
        away_score AS goals_for,
        home_score AS goals_against
    FROM mw_fixtures
    WHERE mw <= 19
) AS team_games ON teams.team_id = team_games.team_id
GROUP BY teams.team_id
ORDER BY points DESC, goal_difference DESC, goals_for DESC;

-- What was the latest game in matchweek 19?
SELECT fixture_time, mw
FROM mw_fixtures
WHERE mw = 19
ORDER BY fixture_time DESC
LIMIT 1;

-- Had every team played 19 games once this game finished?
SELECT
    teams.team_name AS team,
    COUNT(*) AS played,
    SUM(wins) AS wins,
    SUM(draws) AS draws,
    SUM(losses) AS losses,
    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,
    SUM(goals_for) - SUM(goals_against) AS goal_difference,
    SUM(points) AS points
FROM teams
INNER JOIN (
    SELECT
        home_id AS team_id,
        CASE
            WHEN home_score > away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses,
        home_score AS goals_for,
        away_score AS goals_against
    FROM mw_fixtures
    WHERE fixture_time <= '2025-01-02 00:00:00'

    UNION ALL

    SELECT
        away_id AS team_id,
        CASE
            WHEN home_score < away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN away_score = home_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS losses,
        away_score AS goals_for,
        home_score AS goals_against
    FROM mw_fixtures
    WHERE fixture_time <= '2025-01-02 00:00:00'
) AS team_games ON teams.team_id = team_games.team_id
GROUP BY teams.team_id
ORDER BY points DESC, goal_difference DESC, goals_for DESC;

-- Did Liverpool and Everton play immediately after?
SELECT f.*, f.fixture_time,t_home.team_name AS home_team, t_away.team_name AS away_team
FROM fixtures f
JOIN teams t_home
    ON f.home_id = t_home.team_id
JOIN teams t_away
    ON f.away_id = t_away.team_id
WHERE home_id in (8, 12) AND away_id in (8, 12);
-- No, so a fair halfway-point table isn't possible in terms of date

-- PPG before and after end of matchweek 19 fixtures
SELECT
    teams.team_name AS team,
    COUNT(*) AS played,
    SUM(wins) AS wins,
    SUM(draws) AS draws,
    SUM(losses) AS losses,
    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,
    SUM(goals_for) - SUM(goals_against) AS goal_difference,
    SUM(points) AS points,
    ROUND(SUM(CASE WHEN mw <= 19 THEN points ELSE 0 END)::DECIMAL / 19, 2) AS ppg1,
    ROUND(SUM(CASE WHEN mw > 19 THEN points ELSE 0 END)::DECIMAL / 19, 2) AS ppg2,
    ROUND(SUM(points)::DECIMAL / COUNT(*), 2) AS ppg
FROM teams
INNER JOIN (
    SELECT
        home_id AS team_id,
        CASE
            WHEN home_score > away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses,
        home_score AS goals_for,
        away_score AS goals_against,
        mw
    FROM mw_fixtures

    UNION ALL

    SELECT
        away_id AS team_id,
        CASE
            WHEN home_score < away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN away_score = home_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS losses,
        away_score AS goals_for,
        home_score AS goals_against,
        mw
    FROM mw_fixtures
) AS team_games ON teams.team_id = team_games.team_id
GROUP BY teams.team_id
ORDER BY points DESC, goal_difference DESC, goals_for DESC;

-- Points by matchweek (for visualisation; see 24_25_race.R)
SELECT
    teams.team_name AS team,
    SUM(points) OVER (PARTITION BY team_games.team_id ORDER BY mw) AS running_total
FROM teams
INNER JOIN (
    SELECT
        home_id AS team_id,
        CASE
            WHEN home_score > away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses,
        home_score AS goals_for,
        away_score AS goals_against,
        mw
    FROM mw_fixtures

    UNION ALL

    SELECT
        away_id AS team_id,
        CASE
            WHEN home_score < away_score THEN 3
            WHEN home_score = away_score THEN 1
            ELSE 0
        END AS points,
        CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS wins,
        CASE WHEN away_score = home_score THEN 1 ELSE 0 END AS draws,
        CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS losses,
        away_score AS goals_for,
        home_score AS goals_against,
        mw
    FROM mw_fixtures
) AS team_games ON teams.team_id = team_games.team_id;