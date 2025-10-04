-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create user_checkins table
CREATE TABLE IF NOT EXISTS user_checkins (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users (id),
    check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    check_out_time TIMESTAMP,
    location VARCHAR(100)
);

-- Create tokens table
CREATE TABLE IF NOT EXISTS tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users (id),
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users
INSERT INTO
    users (username, email)
VALUES (
        'john_doe',
        'john@example.com'
    ),
    (
        'jane_smith',
        'jane@example.com'
    ),
    (
        'bob_wilson',
        'bob@example.com'
    ),
    (
        'alice_brown',
        'alice@example.com'
    ),
    (
        'charlie_davis',
        'charlie@example.com'
    ) ON CONFLICT (username) DO NOTHING;

-- Insert sample check-ins
INSERT INTO
    user_checkins (
        user_id,
        check_in_time,
        check_out_time,
        location
    )
VALUES (
        1,
        '2024-01-15 09:00:00',
        '2024-01-15 17:00:00',
        'Main Office'
    ),
    (
        1,
        '2024-01-16 08:30:00',
        '2024-01-16 16:30:00',
        'Main Office'
    ),
    (
        2,
        '2024-01-15 10:00:00',
        '2024-01-15 18:00:00',
        'Branch Office'
    ),
    (
        2,
        '2024-01-16 09:15:00',
        '2024-01-16 17:15:00',
        'Branch Office'
    ),
    (
        3,
        '2024-01-15 08:45:00',
        '2024-01-15 16:45:00',
        'Main Office'
    ),
    (
        3,
        '2024-01-17 09:30:00',
        '2024-01-17 17:30:00',
        'Main Office'
    ),
    (
        4,
        '2024-01-16 10:30:00',
        '2024-01-16 18:30:00',
        'Branch Office'
    ),
    (
        5,
        '2024-01-17 08:00:00',
        '2024-01-17 16:00:00',
        'Main Office'
    ) ON CONFLICT DO NOTHING;

-- Insert sample tokens
INSERT INTO
    tokens (user_id, token, expires_at)
VALUES (
        1,
        'token_12345',
        '2024-12-31 23:59:59'
    ),
    (
        2,
        'token_67890',
        '2024-12-31 23:59:59'
    ),
    (
        3,
        'token_abcde',
        '2024-12-31 23:59:59'
    ),
    (
        4,
        'token_fghij',
        '2024-12-31 23:59:59'
    ),
    (
        5,
        'token_klmno',
        '2024-12-31 23:59:59'
    ) ON CONFLICT (token) DO NOTHING;