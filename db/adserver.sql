DROP TABLE IF EXISTS click;
DROP TABLE IF EXISTS impression;
DROP TABLE IF EXISTS ad;
DROP TABLE IF EXISTS campaign;
DROP TABLE IF EXISTS client;

CREATE TABLE client (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE campaign (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    client_id INT,
    FOREIGN KEY (client_id) REFERENCES client(id),
    UNIQUE (client_id, code)
);

CREATE TABLE ad (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    url VARCHAR(2048) NOT NULL,
    image VARCHAR(255),
    heading VARCHAR(255) NOT NULL,
    body_text TEXT NOT NULL,
    hash CHAR(32) NOT NULL UNIQUE,
    campaign_id INT,
    FOREIGN KEY (campaign_id) REFERENCES campaign(id),
    UNIQUE (campaign_id, code)
);

CREATE TABLE click (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ad_id INT,
    referer VARCHAR(2048),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    medium VARCHAR(255),
    FOREIGN KEY (ad_id) REFERENCES ad(id)
);

CREATE TABLE impression (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ad_id INT,
    referer VARCHAR(2048),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    medium VARCHAR(255),
    ip_addr CHAR(40),
    user_agent VARCHAR(2048),
    FOREIGN KEY (ad_id) REFERENCES ad(id)
);
