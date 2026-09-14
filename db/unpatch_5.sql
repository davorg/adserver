ALTER TABLE click
DROP FOREIGN KEY click_impression_fk,
DROP COLUMN impression_id;

ALTER TABLE impression
DROP INDEX impression_token,
DROP COLUMN token;
