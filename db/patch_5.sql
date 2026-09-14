ALTER TABLE impression
ADD COLUMN token CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NULL,
ADD UNIQUE KEY impression_token (token);

ALTER TABLE click
ADD COLUMN impression_id INT NULL,
ADD CONSTRAINT click_impression_fk FOREIGN KEY (impression_id) REFERENCES impression(id);
