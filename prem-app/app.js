const express = require('express');
const { Pool } = require('pg');
const app = express();
const port = 3000;

// Set up EJS for rendering HTML
app.set('view engine', 'ejs');

// PostgreSQL connection
const pool = new Pool({
  user: 'zacharychisholm',
  host: 'localhost',
  database: 'prem',
  password: 'your_password',
  port: 5432,
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
    
    // Your SQL query here - this is a basic example
    // You'll need to adapt this to match your database structure
    const query = `
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
    `;
    
    const result = await pool.query(query, [date]);
    
    // Render the table
    res.render('table', { 
      standings: result.rows,
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