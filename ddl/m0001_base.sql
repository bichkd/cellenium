
-- CREATE TABLE _config (
--   param  text PRIMARY KEY,
--   value  text
-- );
-- INSERT INTO _config VALUES (...);

CREATE OR REPLACE FUNCTION update_timestamp() RETURNS trigger
AS $$
BEGIN
  new.updated := current_timestamp;
  RETURN new;
END;
$$ LANGUAGE plpgsql VOLATILE;
