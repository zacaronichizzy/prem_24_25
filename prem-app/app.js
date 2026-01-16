require('dotenv').config();

const express = require('express');
const { Pool } = require('pg');
const app = express();
const port = 3000;

// Set up EJS for rendering HTML
app.set('view engine', 'ejs');

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Database connection error:', err);
  } else {
    console.log('Database connected successfully');
  }
});

// Home route
app.get('/', (req, res) => {
  res.send('Premier League Table Viewer - Go to /table?date=2024-12-01 to view standings');
});

// Table route - shows standings at a specific date
app.get('/table', async (req, res) => {
  try {
    const date = req.query.date || '2025-01-14'; // Default to today if no date provided

    const full_table_query = `
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
            WHERE fixture_time <= $1

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
            WHERE fixture_time <= $1
        ) AS team_games ON teams.team_id = team_games.team_id
        GROUP BY teams.team_id
        ORDER BY points DESC, goal_difference DESC, goals_for DESC;
    `;

    const london_table_query = `
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
            WHERE fixture_time <= $1
                AND home_id IN (1, 4, 6, 7, 9, 18, 19)
                AND away_id IN (1, 4, 6, 7, 9, 18, 19)

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
            WHERE fixture_time <= $1
                AND home_id IN (1, 4, 6, 7, 9, 18, 19)
                AND away_id IN (1, 4, 6, 7, 9, 18, 19)
        ) AS team_games ON teams.team_id = team_games.team_id
        GROUP BY teams.team_id
        ORDER BY points DESC, goal_difference DESC, goals_for DESC;
    `;
    
    const full_table_result = await pool.query(full_table_query, [date]);
    const london_table_result = await pool.query(london_table_query, [date]);
    
    // Render the table
    res.render('table', { 
      full_standings: full_table_result.rows,
      london_standings: london_table_result.rows,
      date: date
    });
    
  } catch (err) {
    console.error('Error fetching table:', err);
    res.status(500).send('Error loading table');
  }
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});