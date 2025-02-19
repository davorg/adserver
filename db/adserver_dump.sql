/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.10-MariaDB, for Linux (x86_64)
--
-- Host: 172.24.192.1    Database: adserver
-- ------------------------------------------------------
-- Server version	11.5.2-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ad`
--

DROP TABLE IF EXISTS `ad`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ad` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `url` varchar(2048) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `heading` varchar(255) NOT NULL,
  `body_text` text NOT NULL,
  `hash` char(32) NOT NULL,
  `campaign_id` int(11) DEFAULT NULL,
  `is_live` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `hash` (`hash`),
  UNIQUE KEY `campaign_id` (`campaign_id`,`code`),
  CONSTRAINT `ad_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `campaign` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ad`
--

LOCK TABLES `ad` WRITE;
/*!40000 ALTER TABLE `ad` DISABLE KEYS */;
INSERT INTO `ad` VALUES (4,'ghae1','GitHub Actions Essentials - Ad 1','https://actions.davecross.co.uk/','github-actions.png','GitHub Actions Essentials','Solve all your CI/CD problems','a58250b8063261d3854cbc0f929d416a',2,1);
INSERT INTO `ad` VALUES (5,'ghae2','GitHub Actions Essentials - Ad 2','https://actions.davecross.co.uk/','github-actions.png','GitHub Actions Essentials','Automate the boring bits of your software projects','420af519d82911a1615899e1c7faf642',2,1);
INSERT INTO `ad` VALUES (6,'george1','George - Ad 1','https://george.davecross.co.uk/','george.png','George and the Smart Home','Watch George solve his smart home problems.','014a15e57d7809c6daddc56a3bdb909d',3,1);
INSERT INTO `ad` VALUES (7,'george2','George - Ad 2','https://george.davecross.co.uk/','george.png','George and the Smart Home','George has a problem with his smart home.','30b6fc20dcfa810372f29bde8d4af043',3,1);
INSERT INTO `ad` VALUES (8,'prompt1','Prompt Engineering - Ad 2','https://will.sowman.org/#prompt','prompt_engineering_for_everyone.jpg','Prompt Engineering for Everyone','Don\'t get left behind by the AI revolution.','5efc0ae0870d82601834e17db8c8d83c',4,1);
INSERT INTO `ad` VALUES (9,'freedom1','Freedom - Ad 1','https://will.sowman.org/#commuting','from_commuting_to_freedom.jpg','From Commuting to Freedom','Why work for the Man?','aff77003315342e84b2545be223ae2ed',5,1);
INSERT INTO `ad` VALUES (10,'github1','GitHub Training - Ad 1','https://learn.davecross.co.uk/','github-training.png','Master Github skills','Online sessions on GitHub Actions, GitHub Pages and GitHub Copilot','2498bb827b433623a93be873a5c2474e',7,1);
/*!40000 ALTER TABLE `ad` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `campaign`
--

DROP TABLE IF EXISTS `campaign`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `campaign` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `client_id` int(11) DEFAULT NULL,
  `is_live` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `client_id` (`client_id`,`code`),
  CONSTRAINT `campaign_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `client` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `campaign`
--

LOCK TABLES `campaign` WRITE;
/*!40000 ALTER TABLE `campaign` DISABLE KEYS */;
INSERT INTO `campaign` VALUES (2,'ghae','GitHub Actions Essentials',2,1);
INSERT INTO `campaign` VALUES (3,'george','George and the Smart Home',2,1);
INSERT INTO `campaign` VALUES (4,'prompt','Prompt Engineering',3,1);
INSERT INTO `campaign` VALUES (5,'freedom','Commuting to Freedom',3,1);
INSERT INTO `campaign` VALUES (6,'learn-with-dave-cross','Learn with Dave Cross',2,0);
INSERT INTO `campaign` VALUES (7,'github-training','GitHub Training',2,0);
/*!40000 ALTER TABLE `campaign` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `click`
--

DROP TABLE IF EXISTS `click`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `click` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ad_id` int(11) DEFAULT NULL,
  `referer` varchar(2048) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `medium` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ad_id` (`ad_id`),
  CONSTRAINT `click_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `ad` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `click`
--

LOCK TABLES `click` WRITE;
/*!40000 ALTER TABLE `click` DISABLE KEYS */;
INSERT INTO `click` VALUES (10,10,'http://localhost:5000/test.html','2024-08-12 10:21:18',NULL);
/*!40000 ALTER TABLE `click` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `client`
--

DROP TABLE IF EXISTS `client`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `client` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_live` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `client`
--

LOCK TABLES `client` WRITE;
/*!40000 ALTER TABLE `client` DISABLE KEYS */;
INSERT INTO `client` VALUES (2,'magsol','Magnum Solutions',1);
INSERT INTO `client` VALUES (3,'willsow','Will Sowman',1);
/*!40000 ALTER TABLE `client` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `impression`
--

DROP TABLE IF EXISTS `impression`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `impression` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ad_id` int(11) DEFAULT NULL,
  `referer` varchar(2048) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `medium` varchar(255) DEFAULT NULL,
  `ip_addr` char(40) DEFAULT NULL,
  `user_agent` varchar(2048) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ad_id` (`ad_id`),
  CONSTRAINT `impression_ibfk_1` FOREIGN KEY (`ad_id`) REFERENCES `ad` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=203 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `impression`
--

LOCK TABLES `impression` WRITE;
/*!40000 ALTER TABLE `impression` DISABLE KEYS */;
INSERT INTO `impression` VALUES (151,5,'http://localhost:5000/test.html','2024-04-15 14:32:31',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (152,7,'http://localhost:5000/test.html','2024-08-12 10:18:40',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (153,10,'http://localhost:5000/test.html','2024-08-12 10:18:45',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (154,5,'http://localhost:5000/test.html','2024-08-12 10:20:26',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (155,7,'http://localhost:5000/test.html','2024-08-12 10:20:32',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (156,6,'http://localhost:5000/test.html','2024-08-12 10:20:35',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (157,6,'http://localhost:5000/test.html','2024-08-12 10:20:36',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (158,6,'http://localhost:5000/test.html','2024-08-12 10:20:39',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (159,10,'http://localhost:5000/test.html','2024-08-12 10:20:43',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (160,6,'http://localhost:5000/test.html','2024-10-23 11:04:05',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (161,6,'Unknown referer','2024-10-23 11:04:16',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (162,7,'Unknown referer','2024-10-23 11:05:45',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (163,6,'Unknown referer','2024-10-23 11:06:13',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (164,5,'http://localhost:5000/test.html','2024-10-23 11:12:06',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (165,5,'http://localhost:5000/test.html','2024-10-23 11:12:13',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (166,4,'http://localhost:5000/test.html','2024-10-23 11:12:16',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (167,10,'http://localhost:5000/test.html','2024-10-23 11:12:19',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (168,10,'http://localhost:5000/test.html','2024-10-23 11:12:22',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (169,10,'http://localhost:5000/test.html','2024-10-23 11:12:24',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (170,4,'http://localhost:5000/test.html','2024-10-23 11:12:27',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (171,4,'http://localhost:5000/test.html','2024-10-23 11:12:29',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (172,5,'http://localhost:5000/test.html','2024-10-23 11:12:31',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (173,4,'http://localhost:5000/test.html','2024-10-23 11:12:50',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (174,6,'Unknown referer','2024-10-23 12:13:08',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (175,5,'Unknown referer','2024-10-23 12:13:43',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (176,6,'Unknown referer','2024-10-23 12:13:52',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (177,10,'Unknown referer','2024-10-23 12:13:53',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (178,5,'Unknown referer','2024-10-23 12:13:54',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (179,6,'Unknown referer','2024-10-23 12:13:57',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (180,6,'Unknown referer','2024-10-23 12:13:57',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (181,7,'Unknown referer','2024-10-23 12:13:58',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (182,5,'Unknown referer','2024-10-23 12:13:59',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (183,5,'Unknown referer','2024-10-23 12:13:59',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (184,7,'Unknown referer','2024-10-23 12:14:00',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (185,5,'Unknown referer','2024-10-23 12:14:00',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (186,7,'Unknown referer','2024-10-23 12:14:01',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (187,5,'Unknown referer','2024-10-23 12:14:02',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (188,5,'Unknown referer','2024-10-23 12:14:02',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (189,7,'Unknown referer','2024-10-23 12:14:03',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (190,6,'Unknown referer','2024-10-23 12:14:03',NULL,'::1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (191,6,'Unknown referer','2024-10-23 13:30:41',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (192,4,'Unknown referer','2024-10-23 13:47:27',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (193,6,'Unknown referer','2024-10-23 13:47:32',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (194,6,'Unknown referer','2024-10-23 13:47:34',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (195,6,'Unknown referer','2024-10-23 13:47:36',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (196,10,'Unknown referer','2024-10-23 13:47:37',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (197,4,'Unknown referer','2024-10-23 13:47:40',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (198,4,'Unknown referer','2024-10-23 13:47:41',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (199,10,'http://localhost:5000/test.html','2025-02-19 17:39:22',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (200,7,'http://localhost:5000/test.html','2025-02-19 17:39:26',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (201,6,'http://localhost:5000/test.html','2025-02-19 17:39:30',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36');
INSERT INTO `impression` VALUES (202,5,'http://localhost:5000/test.html','2025-02-19 17:39:32',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36');
/*!40000 ALTER TABLE `impression` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-02-19 18:27:33
