CREATE TABLE stations(
   ts             TIMESTAMP      PRIMARY KEY     NOT NULL,
   dtype          VARCHAR(32)    NOT NULL,
   counts         INT            NOT NULL,
   message        jsonb
);