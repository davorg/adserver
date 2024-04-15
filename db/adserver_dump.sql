-- MariaDB dump 10.19  Distrib 10.5.23-MariaDB, for Linux (x86_64)
--
-- Host: 172.28.224.1    Database: adserver
-- ------------------------------------------------------
-- Server version	10.6.11-MariaDB

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
  PRIMARY KEY (`id`),
  UNIQUE KEY `hash` (`hash`),
  UNIQUE KEY `campaign_id` (`campaign_id`,`code`),
  CONSTRAINT `ad_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `campaign` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ad`
--

LOCK TABLES `ad` WRITE;
/*!40000 ALTER TABLE `ad` DISABLE KEYS */;
INSERT INTO `ad` VALUES (4,'ghae1','GitHub Actions Essentials - Ad 1','https://actions.davecross.co.uk/','github-actions.png','GitHub Actions Essentials','Solve all your CI/CD problems','a58250b8063261d3854cbc0f929d416a',2);
INSERT INTO `ad` VALUES (5,'ghae2','GitHub Actions Essentials - Ad 2','https://actions.davecross.co.uk/','github-actions.png','GitHub Actions Essentials','Automate the boring bits of your software projects','420af519d82911a1615899e1c7faf642',2);
INSERT INTO `ad` VALUES (6,'george1','George - Ad 1','https://george.davecross.co.uk/','george.png','George and the Smart Home','Watch George solve his smart home problems.','014a15e57d7809c6daddc56a3bdb909d',3);
INSERT INTO `ad` VALUES (7,'george2','George - Ad 2','https://george.davecross.co.uk/','george.png','George and the Smart Home','George has a problem with his smart home.','30b6fc20dcfa810372f29bde8d4af043',3);
INSERT INTO `ad` VALUES (8,'prompt1','Prompt Engineering - Ad 2','https://will.sowman.org/','prompt_engineering_for_everyone.jpg','Prompt Engineering for Everyone','Don\'t get left behind by the AI revolution.','5efc0ae0870d82601834e17db8c8d83c',4);
INSERT INTO `ad` VALUES (9,'freedom1','Freedom - Ad 1','https://will.sowman.org/','from_commuting_to_freedom.jpg','From Commuting to Freedom','Why work for the Man?','aff77003315342e84b2545be223ae2ed',5);
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `client_id` (`client_id`,`code`),
  CONSTRAINT `campaign_ibfk_1` FOREIGN KEY (`client_id`) REFERENCES `client` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `campaign`
--

LOCK TABLES `campaign` WRITE;
/*!40000 ALTER TABLE `campaign` DISABLE KEYS */;
INSERT INTO `campaign` VALUES (2,'ghae','GitHub Actions Essentials',2);
INSERT INTO `campaign` VALUES (3,'george','George and the Smart Home',2);
INSERT INTO `campaign` VALUES (4,'prompt','Prompt Engineering',3);
INSERT INTO `campaign` VALUES (5,'freedom','Commuting to Freedom',3);
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `click`
--

LOCK TABLES `click` WRITE;
/*!40000 ALTER TABLE `click` DISABLE KEYS */;
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
INSERT INTO `client` VALUES (2,'magsol','Magnum Solutions');
INSERT INTO `client` VALUES (3,'willsow','Will Sowman');
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
) ENGINE=InnoDB AUTO_INCREMENT=151 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `impression`
--

LOCK TABLES `impression` WRITE;
/*!40000 ALTER TABLE `impression` DISABLE KEYS */;
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

-- Dump completed on 2024-04-15 14:29:26
