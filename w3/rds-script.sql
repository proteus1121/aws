CREATE TABLE account(
   user_id serial PRIMARY KEY,
   username VARCHAR (50) UNIQUE NOT NULL,
   password VARCHAR (50) NOT NULL
);
INSERT INTO account (username, password) VALUES
    ('User1', 'user1_pass'),
    ('User2', 'user2_pass');
SELECT * FROM account;
