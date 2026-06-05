-- TruePink — SQL
SELECT c.name, COUNT(*) AS total
FROM cats AS c
JOIN tags t ON t.cat_id = c.id
WHERE c.lives > 0 AND c.name LIKE 'M%'
GROUP BY c.name
HAVING COUNT(*) >= 2
ORDER BY total DESC
LIMIT 10;

INSERT INTO cats (name, lives) VALUES ('Mochi', 9);
UPDATE cats SET lives = lives - 1 WHERE id = 1;
