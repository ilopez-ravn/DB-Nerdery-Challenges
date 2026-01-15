-- Your answers here:
-- 1
SELECT type AS Account_yype, CAST(SUM(mount) AS numeric(10,2)) AS total_amount 
FROM accounts 
GROUP BY type;
-- 2
SELECT COUNT(a.id) AS users_count 
FROM users u
JOIN accounts a ON u.id = a.user_id
WHERE a.type = 'CURRENT_ACCOUNT'
GROUP BY a.type
HAVING COUNT(a.id) >= 2;
-- 3
SELECT u.name, a.type, a.mount AS amount 
FROM accounts a
JOIN users u ON u.id = a.user_id
ORDER BY a.mount DESC 
LIMIT 5; 
-- 4
SELECT u.name, CAST((a.mount + SUM(
    CASE m.type
        WHEN 'IN' THEN m.mount
        WHEN 'OUT' THEN -m.mount
        WHEN 'TRANSFER' THEN -m.mount
        WHEN 'OTHER' THEN -m.mount
    ELSE 
        0
    END
)) AS numeric(10,2)) AS final_amount
FROM accounts a
JOIN movements m ON m.account_from = a.id OR m.account_to = a.id
JOIN users u ON u.id = a.user_id
GROUP BY a.id, u.name
ORDER BY final_amount DESC 
LIMIT 3;

-- 5
DROP FUNCTION IF EXISTS get_account_final_amount(TEXT);
CREATE OR REPLACE FUNCTION get_account_final_amount(s_account_id TEXT) 
returns numeric(10,2) 
language plpgsql
AS
$$
declare
    final_amount numeric(10,2);
BEGIN
    SELECT CAST ((a.mount + SUM(
        CASE m.type
            WHEN 'IN' THEN m.mount
            WHEN 'OUT' THEN -m.mount
            WHEN 'TRANSFER' THEN -m.mount
            WHEN 'OTHER' THEN -m.mount
        ELSE 
            0
        END
    )) AS numeric(10,2) ) AS final_amount
    INTO final_amount
    FROM accounts a
    JOIN movements m ON m.account_from = a.id OR m.account_to = a.id
    JOIN users u ON u.id = a.user_id
    WHERE a.id = CAST(s_account_id AS UUID)
    GROUP BY a.id, u.name;

    return final_amount;
END;
$$;

BEGIN TRANSACTION;
-- A
SELECT u.name, a.account_id ,a.type, CAST ((a.mount + SUM(
    CASE m.type
        WHEN 'IN' THEN m.mount
        WHEN 'OUT' THEN -m.mount
        WHEN 'TRANSFER' THEN -m.mount
        WHEN 'OTHER' THEN -m.mount
    ELSE 
        0
    END
)) AS numeric(10,2) ) AS final_amount
FROM accounts a
JOIN movements m ON m.account_from = a.id OR m.account_to = a.id
JOIN users u ON u.id = a.user_id
WHERE a.id IN ('3b79e403-c788-495a-a8ca-86ad7643afaf','fd244313-36e5-4a17-a27c-f8265bc46590')
GROUP BY a.id, u.name
ORDER BY final_amount DESC;

-- B Insert new movement (TRANSFER)
INSERT INTO movements (id, type, account_from, account_to, mount)
VALUES (gen_random_uuid(), 'TRANSFER', '3b79e403-c788-495a-a8ca-86ad7643afaf', 'fd244313-36e5-4a17-a27c-f8265bc46590', 50.75);

-- C Insert new movement (OUT)
-- Create a function that inserts the movements and 
-- checks for sufficient funds and raise exception, if neccesary, triggering a rollback
do $$
DECLARE 
final_amount numeric(10,2);
BEGIN

INSERT INTO movements (id, type, account_from, mount)
VALUES (gen_random_uuid() ,'OUT', '3b79e403-c788-495a-a8ca-86ad7643afaf', 731823.56);

SELECT get_account_final_amount('3b79e403-c788-495a-a8ca-86ad7643afaf') 
INTO final_amount;  

IF final_amount < 0 THEN
    RAISE EXCEPTION 'INSUFFICIENT FUNDS';
END IF;
END
$$;
COMMIT;
-- D

-- E

-- F

-- G
SELECT get_account_final_amount('fd244313-36e5-4a17-a27c-f8265bc46590') as final_amount; 

-- 6
SELECT u.name || ' ' || u.last_name AS name, u.email, a.account_id,m.type AS transfer_type, m.mount as movement
FROM accounts a
JOIN movements m ON m.account_from = a.id OR m.account_to = a.id
JOIN users u ON u.id = a.user_id
WHERE a.id = '3b79e403-c788-495a-a8ca-86ad7643afaf';

-- 7
SELECT u.name, u.email, CAST((a.mount + SUM(
    CASE m.type
        WHEN 'IN' THEN m.mount
        WHEN 'OUT' THEN -m.mount
        WHEN 'TRANSFER' THEN -m.mount
        WHEN 'OTHER' THEN -m.mount
    ELSE 
        0
    END
)) AS numeric(10,2)) AS final_amount
FROM accounts a
JOIN movements m ON m.account_from = a.id OR m.account_to = a.id
JOIN users u ON u.id = a.user_id
GROUP BY a.id, u.name, u.email
ORDER BY final_amount DESC 
LIMIT 1;

-- 8
SELECT m.type AS movement_type, m.account_from, m.account_to, m.mount AS movement_amount
FROM users u
JOIN accounts a ON a.user_id = u.id
JOIN movements m ON m.account_from = a.id OR m.account_to = a.id
WHERE u.email ILIKE 'Kaden.Gusikowski@gmail.com';

