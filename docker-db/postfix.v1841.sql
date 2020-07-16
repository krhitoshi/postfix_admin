-- phpMyAdmin SQL Dump
-- version 4.9.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 30, 2020 at 04:28 PM
-- Server version: 10.3.17-MariaDB-log
-- PHP Version: 7.2.11

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `postfix`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `superadmin` tinyint(1) NOT NULL DEFAULT 0,
  `phone` varchar(30) NOT NULL DEFAULT '',
  `email_other` varchar(255) NOT NULL DEFAULT '',
  `token` varchar(255) NOT NULL DEFAULT '',
  `token_validity` datetime NOT NULL DEFAULT '2000-01-01 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Virtual Admins';

-- --------------------------------------------------------

--
-- Table structure for table `alias`
--

CREATE TABLE `alias` (
  `address` varchar(255) NOT NULL,
  `goto` text NOT NULL,
  `domain` varchar(255) NOT NULL,
  `created` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Virtual Aliases';

-- --------------------------------------------------------

--
-- Table structure for table `alias_domain`
--

CREATE TABLE `alias_domain` (
  `alias_domain` varchar(255) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `target_domain` varchar(255) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `created` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Domain Aliases';

-- --------------------------------------------------------

--
-- Table structure for table `config`
--

CREATE TABLE `config` (
  `id` int(11) NOT NULL,
  `name` varchar(20) NOT NULL DEFAULT '',
  `value` varchar(20) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='PostfixAdmin settings';

--
-- Dumping data for table `config`
--

INSERT INTO `config` (`id`, `name`, `value`) VALUES
(1, 'version', '1841');

-- --------------------------------------------------------

--
-- Table structure for table `domain`
--

CREATE TABLE `domain` (
  `domain` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `aliases` int(10) NOT NULL DEFAULT 0,
  `mailboxes` int(10) NOT NULL DEFAULT 0,
  `maxquota` bigint(20) NOT NULL DEFAULT 0,
  `quota` bigint(20) NOT NULL DEFAULT 0,
  `transport` varchar(255) NOT NULL,
  `backupmx` tinyint(1) NOT NULL DEFAULT 0,
  `created` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Virtual Domains';

--
-- Dumping data for table `domain`
--

INSERT INTO `domain` (`domain`, `description`, `aliases`, `mailboxes`, `maxquota`, `quota`, `transport`, `backupmx`, `created`, `modified`, `active`) VALUES
('ALL', '', 0, 0, 0, 0, '', 0, '0000-00-00 00:00:00', '0000-00-00 00:00:00', 1);

-- --------------------------------------------------------

--
-- Table structure for table `domain_admins`
--

CREATE TABLE `domain_admins` (
  `username` varchar(255) NOT NULL,
  `domain` varchar(255) NOT NULL,
  `created` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `active` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Domain Admins';

-- --------------------------------------------------------

--
-- Table structure for table `fetchmail`
--

CREATE TABLE `fetchmail` (
  `id` int(11) UNSIGNED NOT NULL,
  `mailbox` varchar(255) NOT NULL,
  `src_server` varchar(255) NOT NULL,
  `src_auth` enum('password','kerberos_v5','kerberos','kerberos_v4','gssapi','cram-md5','otp','ntlm','msn','ssh','any') DEFAULT NULL,
  `src_user` varchar(255) NOT NULL,
  `src_password` varchar(255) NOT NULL,
  `src_folder` varchar(255) NOT NULL,
  `poll_time` int(11) UNSIGNED NOT NULL DEFAULT 10,
  `fetchall` tinyint(1) UNSIGNED NOT NULL DEFAULT 0,
  `keep` tinyint(1) UNSIGNED NOT NULL DEFAULT 0,
  `protocol` enum('POP3','IMAP','POP2','ETRN','AUTO') DEFAULT NULL,
  `usessl` tinyint(1) UNSIGNED NOT NULL DEFAULT 0,
  `extra_options` text DEFAULT NULL,
  `returned_text` text DEFAULT NULL,
  `mda` varchar(255) NOT NULL,
  `date` timestamp NOT NULL DEFAULT '1999-12-31 15:00:00',
  `sslcertck` tinyint(1) NOT NULL DEFAULT 0,
  `sslcertpath` varchar(255) DEFAULT '',
  `sslfingerprint` varchar(255) CHARACTER SET latin1 DEFAULT '',
  `domain` varchar(255) CHARACTER SET latin1 DEFAULT '',
  `active` tinyint(1) NOT NULL DEFAULT 0,
  `created` timestamp NOT NULL DEFAULT '1999-12-31 15:00:00',
  `modified` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `log`
--

CREATE TABLE `log` (
  `timestamp` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `username` varchar(255) NOT NULL,
  `domain` varchar(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `data` text NOT NULL,
  `id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Log';

-- --------------------------------------------------------

--
-- Table structure for table `mailbox`
--

CREATE TABLE `mailbox` (
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `maildir` varchar(255) NOT NULL,
  `quota` bigint(20) NOT NULL DEFAULT 0,
  `local_part` varchar(255) NOT NULL,
  `domain` varchar(255) NOT NULL,
  `created` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `phone` varchar(30) NOT NULL DEFAULT '',
  `email_other` varchar(255) NOT NULL DEFAULT '',
  `token` varchar(255) NOT NULL DEFAULT '',
  `token_validity` datetime NOT NULL DEFAULT '2000-01-01 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Virtual Mailboxes';

-- --------------------------------------------------------

--
-- Table structure for table `quota`
--

CREATE TABLE `quota` (
  `username` varchar(255) NOT NULL,
  `path` varchar(100) NOT NULL,
  `current` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `quota2`
--

CREATE TABLE `quota2` (
  `username` varchar(100) NOT NULL,
  `bytes` bigint(20) NOT NULL DEFAULT 0,
  `messages` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `vacation`
--

CREATE TABLE `vacation` (
  `email` varchar(255) NOT NULL,
  `subject` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `cache` text NOT NULL,
  `domain` varchar(255) NOT NULL,
  `created` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `modified` timestamp NOT NULL DEFAULT current_timestamp(),
  `activefrom` timestamp NOT NULL DEFAULT '1999-12-31 15:00:00',
  `activeuntil` timestamp NOT NULL DEFAULT '2038-01-17 15:00:00',
  `interval_time` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Virtual Vacation';

-- --------------------------------------------------------

--
-- Table structure for table `vacation_notification`
--

CREATE TABLE `vacation_notification` (
  `on_vacation` varchar(150) NOT NULL,
  `notified` varchar(255) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `notified_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Postfix Admin - Virtual Vacation Notifications';

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `alias`
--
ALTER TABLE `alias`
  ADD PRIMARY KEY (`address`),
  ADD KEY `domain` (`domain`);

--
-- Indexes for table `alias_domain`
--
ALTER TABLE `alias_domain`
  ADD PRIMARY KEY (`alias_domain`),
  ADD KEY `active` (`active`),
  ADD KEY `target_domain` (`target_domain`);

--
-- Indexes for table `config`
--
ALTER TABLE `config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `domain`
--
ALTER TABLE `domain`
  ADD PRIMARY KEY (`domain`);

--
-- Indexes for table `domain_admins`
--
ALTER TABLE `domain_admins`
  ADD KEY `username` (`username`);

--
-- Indexes for table `fetchmail`
--
ALTER TABLE `fetchmail`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `log`
--
ALTER TABLE `log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `timestamp` (`timestamp`),
  ADD KEY `domain_timestamp` (`domain`,`timestamp`);

--
-- Indexes for table `mailbox`
--
ALTER TABLE `mailbox`
  ADD PRIMARY KEY (`username`),
  ADD KEY `domain` (`domain`);

--
-- Indexes for table `quota`
--
ALTER TABLE `quota`
  ADD PRIMARY KEY (`username`,`path`);

--
-- Indexes for table `quota2`
--
ALTER TABLE `quota2`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `vacation`
--
ALTER TABLE `vacation`
  ADD PRIMARY KEY (`email`),
  ADD KEY `email` (`email`);

--
-- Indexes for table `vacation_notification`
--
ALTER TABLE `vacation_notification`
  ADD PRIMARY KEY (`on_vacation`,`notified`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `config`
--
ALTER TABLE `config`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `fetchmail`
--
ALTER TABLE `fetchmail`
  MODIFY `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `log`
--
ALTER TABLE `log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `vacation_notification`
--
ALTER TABLE `vacation_notification`
  ADD CONSTRAINT `vacation_notification_pkey` FOREIGN KEY (`on_vacation`) REFERENCES `vacation` (`email`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
