-- ==============================================================================
-- CRS Balochistan — Complete MySQL / MariaDB Database Dump for XAMPP
-- Compatible with: XAMPP, phpMyAdmin, MySQL 5.7+, MySQL 8.0+, MariaDB 10+
-- Character Set: utf8mb4 (Supports Urdu Nastaliq text without corruption)
-- ==============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- Set proper character set to preserve Urdu text
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- ------------------------------------------------------------------------------
-- 1. Database Creation
-- ------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS `crs_balochistan` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `crs_balochistan`;

-- Disable foreign key checks during import
SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables if already exist
DROP TABLE IF EXISTS `site_settings`;
DROP TABLE IF EXISTS `audit_logs`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `data_import_errors`;
DROP TABLE IF EXISTS `data_import_jobs`;
DROP TABLE IF EXISTS `report_approvals`;
DROP TABLE IF EXISTS `crop_reports`;
DROP TABLE IF EXISTS `crops`;
DROP TABLE IF EXISTS `crop_categories`;
DROP TABLE IF EXISTS `agriculture_years`;
DROP TABLE IF EXISTS `tehsils`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `districts`;
DROP TABLE IF EXISTS `divisions`;
DROP TABLE IF EXISTS `provinces`;

-- ------------------------------------------------------------------------------
-- 2. Geographic Hierarchy Tables
-- ------------------------------------------------------------------------------

-- Provinces
CREATE TABLE `provinces` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `nameUrdu` VARCHAR(150) DEFAULT NULL,
  `code` VARCHAR(20) NOT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_province_name` (`name`),
  UNIQUE KEY `idx_province_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Divisions
CREATE TABLE `divisions` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `nameUrdu` VARCHAR(150) DEFAULT NULL,
  `code` VARCHAR(20) NOT NULL,
  `provinceId` VARCHAR(64) NOT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_division_code` (`code`),
  KEY `idx_divisions_provinceId` (`provinceId`),
  CONSTRAINT `fk_divisions_province` FOREIGN KEY (`provinceId`) REFERENCES `provinces` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Districts
CREATE TABLE `districts` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `nameUrdu` VARCHAR(150) DEFAULT NULL,
  `code` VARCHAR(20) NOT NULL,
  `divisionId` VARCHAR(64) NOT NULL,
  `latitude` DOUBLE DEFAULT NULL,
  `longitude` DOUBLE DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_district_code` (`code`),
  KEY `idx_districts_divisionId` (`divisionId`),
  CONSTRAINT `fk_districts_division` FOREIGN KEY (`divisionId`) REFERENCES `divisions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tehsils
CREATE TABLE `tehsils` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `nameUrdu` VARCHAR(150) DEFAULT NULL,
  `code` VARCHAR(20) NOT NULL,
  `districtId` VARCHAR(64) NOT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_tehsil_code` (`code`),
  KEY `idx_tehsils_districtId` (`districtId`),
  CONSTRAINT `fk_tehsils_district` FOREIGN KEY (`districtId`) REFERENCES `districts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 3. Users Table
-- ------------------------------------------------------------------------------
CREATE TABLE `users` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(150) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `passwordHash` VARCHAR(255) NOT NULL,
  `role` ENUM('SUPER_ADMIN','PROVINCIAL_ADMIN','DISTRICT_OFFICER','DATA_ENTRY_OPERATOR','APPROVER','PUBLIC_VIEWER') NOT NULL DEFAULT 'PUBLIC_VIEWER',
  `districtId` VARCHAR(64) DEFAULT NULL,
  `isActive` TINYINT(1) NOT NULL DEFAULT 1,
  `lastLoginAt` DATETIME DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deletedAt` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_users_email` (`email`),
  KEY `idx_users_role` (`role`),
  KEY `idx_users_district` (`districtId`),
  CONSTRAINT `fk_users_district` FOREIGN KEY (`districtId`) REFERENCES `districts` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 4. Agriculture Reference Tables
-- ------------------------------------------------------------------------------

-- Agriculture Years
CREATE TABLE `agriculture_years` (
  `id` VARCHAR(64) NOT NULL,
  `label` VARCHAR(50) NOT NULL,
  `startYear` INT NOT NULL,
  `endYear` INT NOT NULL,
  `isCurrent` TINYINT(1) NOT NULL DEFAULT 0,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_years_label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Crop Categories
CREATE TABLE `crop_categories` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `nameUrdu` VARCHAR(150) DEFAULT NULL,
  `description` TEXT DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_crop_category_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Crops
CREATE TABLE `crops` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `nameUrdu` VARCHAR(150) DEFAULT NULL,
  `code` VARCHAR(20) NOT NULL,
  `categoryId` VARCHAR(64) DEFAULT NULL,
  `season` ENUM('KHARIF','RABI','ANNUAL','PERENNIAL') DEFAULT NULL,
  `description` TEXT DEFAULT NULL,
  `isActive` TINYINT(1) NOT NULL DEFAULT 1,
  `imageUrl` VARCHAR(255) DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_crops_code` (`code`),
  KEY `idx_crops_categoryId` (`categoryId`),
  CONSTRAINT `fk_crops_category` FOREIGN KEY (`categoryId`) REFERENCES `crop_categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 5. Core Crop Reports Table
-- ------------------------------------------------------------------------------
CREATE TABLE `crop_reports` (
  `id` VARCHAR(64) NOT NULL,
  `cropId` VARCHAR(64) NOT NULL,
  `agricultureYearId` VARCHAR(64) NOT NULL,
  `season` ENUM('KHARIF','RABI','ANNUAL','PERENNIAL') NOT NULL,
  `provinceId` VARCHAR(64) DEFAULT NULL,
  `divisionId` VARCHAR(64) DEFAULT NULL,
  `districtId` VARCHAR(64) NOT NULL,
  `tehsilId` VARCHAR(64) DEFAULT NULL,
  `reportingOfficerId` VARCHAR(64) DEFAULT NULL,
  `reportingOrganization` VARCHAR(255) DEFAULT NULL,
  `cultivatedArea` DOUBLE DEFAULT NULL,
  `sownArea` DOUBLE DEFAULT NULL,
  `harvestedArea` DOUBLE DEFAULT NULL,
  `areaUnit` ENUM('ACRES','HECTARES','KILOGRAMS','METRIC_TONNES','MAUNDS') NOT NULL DEFAULT 'ACRES',
  `totalProduction` DOUBLE DEFAULT NULL,
  `productionUnit` ENUM('ACRES','HECTARES','KILOGRAMS','METRIC_TONNES','MAUNDS') NOT NULL DEFAULT 'METRIC_TONNES',
  `yield` DOUBLE DEFAULT NULL,
  `yieldUnit` VARCHAR(50) DEFAULT NULL,
  `sowingDate` DATETIME DEFAULT NULL,
  `harvestDate` DATETIME DEFAULT NULL,
  `reportingDate` DATETIME DEFAULT NULL,
  `sourceReference` VARCHAR(255) DEFAULT NULL,
  `remarks` TEXT DEFAULT NULL,
  `status` ENUM('DRAFT','SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `verifiedAt` DATETIME DEFAULT NULL,
  `publishedAt` DATETIME DEFAULT NULL,
  `createdById` VARCHAR(64) DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deletedAt` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_crop_reports_cropId` (`cropId`),
  KEY `idx_crop_reports_districtId` (`districtId`),
  KEY `idx_crop_reports_yearId` (`agricultureYearId`),
  KEY `idx_crop_reports_status` (`status`),
  KEY `idx_crop_reports_season` (`season`),
  CONSTRAINT `fk_reports_crop` FOREIGN KEY (`cropId`) REFERENCES `crops` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_reports_year` FOREIGN KEY (`agricultureYearId`) REFERENCES `agriculture_years` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_reports_district` FOREIGN KEY (`districtId`) REFERENCES `districts` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_reports_tehsil` FOREIGN KEY (`tehsilId`) REFERENCES `tehsils` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_reports_user` FOREIGN KEY (`createdById`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 6. Report Approvals Table
-- ------------------------------------------------------------------------------
CREATE TABLE `report_approvals` (
  `id` VARCHAR(64) NOT NULL,
  `reportId` VARCHAR(64) NOT NULL,
  `approverId` VARCHAR(64) NOT NULL,
  `status` ENUM('DRAFT','SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','PUBLISHED','ARCHIVED') NOT NULL,
  `comments` TEXT DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_report_approvals_reportId` (`reportId`),
  KEY `idx_report_approvals_approverId` (`approverId`),
  CONSTRAINT `fk_approvals_report` FOREIGN KEY (`reportId`) REFERENCES `crop_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_approvals_user` FOREIGN KEY (`approverId`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 7. Data Import Jobs & Errors
-- ------------------------------------------------------------------------------
CREATE TABLE `data_import_jobs` (
  `id` VARCHAR(64) NOT NULL,
  `filename` VARCHAR(255) NOT NULL,
  `fileSize` INT DEFAULT NULL,
  `mimeType` VARCHAR(100) DEFAULT NULL,
  `totalRows` INT NOT NULL DEFAULT 0,
  `validRows` INT NOT NULL DEFAULT 0,
  `errorRows` INT NOT NULL DEFAULT 0,
  `importedRows` INT NOT NULL DEFAULT 0,
  `status` ENUM('PENDING','PROCESSING','COMPLETED','FAILED','PARTIAL') NOT NULL DEFAULT 'PENDING',
  `uploadedById` VARCHAR(64) NOT NULL,
  `errorSummary` TEXT DEFAULT NULL,
  `completedAt` DATETIME DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_import_jobs_user` (`uploadedById`),
  KEY `idx_import_jobs_status` (`status`),
  CONSTRAINT `fk_import_user` FOREIGN KEY (`uploadedById`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `data_import_errors` (
  `id` VARCHAR(64) NOT NULL,
  `jobId` VARCHAR(64) NOT NULL,
  `rowNumber` INT NOT NULL,
  `field` VARCHAR(100) DEFAULT NULL,
  `message` TEXT NOT NULL,
  `rowData` JSON DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_import_errors_job` (`jobId`),
  CONSTRAINT `fk_import_error_job` FOREIGN KEY (`jobId`) REFERENCES `data_import_jobs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 8. Notifications, Audit Logs & Settings
-- ------------------------------------------------------------------------------
CREATE TABLE `notifications` (
  `id` VARCHAR(64) NOT NULL,
  `title` VARCHAR(200) NOT NULL,
  `message` TEXT NOT NULL,
  `type` VARCHAR(50) NOT NULL DEFAULT 'info',
  `isRead` TINYINT(1) NOT NULL DEFAULT 0,
  `userId` VARCHAR(64) DEFAULT NULL,
  `link` VARCHAR(255) DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notifications_user` (`userId`),
  KEY `idx_notifications_isRead` (`isRead`),
  CONSTRAINT `fk_notifications_user` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `audit_logs` (
  `id` VARCHAR(64) NOT NULL,
  `userId` VARCHAR(64) DEFAULT NULL,
  `action` ENUM('CREATE','UPDATE','DELETE','LOGIN','LOGOUT','IMPORT','EXPORT','APPROVE','REJECT','PUBLISH','ARCHIVE','RESTORE') NOT NULL,
  `entityType` VARCHAR(100) DEFAULT NULL,
  `entityId` VARCHAR(64) DEFAULT NULL,
  `previousData` JSON DEFAULT NULL,
  `newData` JSON DEFAULT NULL,
  `ipAddress` VARCHAR(50) DEFAULT NULL,
  `userAgent` TEXT DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_logs_user` (`userId`),
  KEY `idx_audit_logs_action` (`action`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `site_settings` (
  `id` VARCHAR(64) NOT NULL,
  `key` VARCHAR(100) NOT NULL,
  `value` TEXT NOT NULL,
  `description` TEXT DEFAULT NULL,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_site_settings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ==============================================================================
-- 9. SEED DATA INSERTIONS
-- ==============================================================================

-- 9.1 Province
INSERT INTO `provinces` (`id`, `name`, `nameUrdu`, `code`, `createdAt`, `updatedAt`) VALUES
('prov-balochistan', 'Balochistan', 'بلوچستان', 'BAL', NOW(), NOW());

-- 9.2 Divisions
INSERT INTO `divisions` (`id`, `name`, `nameUrdu`, `code`, `provinceId`, `createdAt`, `updatedAt`) VALUES
('div-quetta',     'Quetta',     'کوئٹہ',       'QTA', 'prov-balochistan', NOW(), NOW()),
('div-kalat',      'Kalat',      'کلات',        'KLT', 'prov-balochistan', NOW(), NOW()),
('div-makran',     'Makran',     'مکران',       'MKR', 'prov-balochistan', NOW(), NOW()),
('div-naseerabad', 'Naseerabad', 'نصیرآباد',    'NSR', 'prov-balochistan', NOW(), NOW()),
('div-sibi',       'Sibi',       'سبی',         'SBI', 'prov-balochistan', NOW(), NOW()),
('div-zhob',       'Zhob',       'ژوب',         'ZHB', 'prov-balochistan', NOW(), NOW()),
('div-loralai',    'Loralai',    'لورالائی',    'LRL', 'prov-balochistan', NOW(), NOW()),
('div-rakhshan',   'Rakhshan',   'رخشان',       'RKH', 'prov-balochistan', NOW(), NOW());

-- 9.3 Districts
INSERT INTO `districts` (`id`, `name`, `nameUrdu`, `code`, `divisionId`, `latitude`, `longitude`, `createdAt`, `updatedAt`) VALUES
-- Quetta Division
('dist-quetta',        'Quetta',         'کوئٹہ',         'QTA-01', 'div-quetta',     30.1798, 66.9750, NOW(), NOW()),
('dist-pishin',        'Pishin',         'پشین',          'QTA-02', 'div-quetta',     30.5805, 66.9946, NOW(), NOW()),
('dist-killa-abdullah','Killa Abdullah', 'کلہ عبداللہ',   'QTA-03', 'div-quetta',     30.6830, 66.5884, NOW(), NOW()),
('dist-chagai',        'Chagai',         'چاغی',          'QTA-04', 'div-quetta',     29.0933, 64.9088, NOW(), NOW()),
('dist-noshki',        'Noshki',         'نوشکی',         'QTA-05', 'div-quetta',     29.5500, 65.9222, NOW(), NOW()),
-- Kalat Division
('dist-kalat',         'Kalat',          'کلات',          'KLT-01', 'div-kalat',      29.0230, 66.5849, NOW(), NOW()),
('dist-khuzdar',       'Khuzdar',        'خضدار',         'KLT-02', 'div-kalat',      27.8123, 66.6172, NOW(), NOW()),
('dist-mastung',       'Mastung',        'مستونگ',        'KLT-03', 'div-kalat',      29.7987, 66.8437, NOW(), NOW()),
('dist-surab',         'Surab',          'سراب',          'KLT-04', 'div-kalat',      28.4880, 66.2558, NOW(), NOW()),
-- Makran Division
('dist-gwadar',        'Gwadar',         'گوادر',         'MKR-01', 'div-makran',     25.1216, 62.3254, NOW(), NOW()),
('dist-turbat',        'Turbat',         'تربت',          'MKR-02', 'div-makran',     25.9882, 63.0623, NOW(), NOW()),
('dist-panjgur',       'Panjgur',        'پنجگور',        'MKR-03', 'div-makran',     26.9688, 64.0988, NOW(), NOW()),
-- Naseerabad Division
('dist-naseerabad',    'Naseerabad',     'نصیرآباد',      'NSR-01', 'div-naseerabad', 28.4189, 68.3564, NOW(), NOW()),
('dist-jafarabad',     'Jafarabad',      'جعفرآباد',      'NSR-02', 'div-naseerabad', 28.3400, 68.0151, NOW(), NOW()),
('dist-sohbatpur',     'Sohbatpur',      'صحبت پور',      'NSR-03', 'div-naseerabad', 28.5225, 68.1145, NOW(), NOW()),
('dist-dera-bugti',    'Dera Bugti',     'ڈیرہ بگٹی',    'NSR-04', 'div-naseerabad', 28.9826, 69.1700, NOW(), NOW()),
-- Sibi Division
('dist-sibi',          'Sibi',           'سبی',           'SBI-01', 'div-sibi',       29.5432, 67.8770, NOW(), NOW()),
('dist-ziarat',        'Ziarat',         'زیارت',         'SBI-02', 'div-sibi',       30.3817, 67.7244, NOW(), NOW()),
('dist-kohlu',         'Kohlu',          'کوہلو',         'SBI-03', 'div-sibi',       29.8929, 69.2565, NOW(), NOW()),
-- Zhob Division
('dist-zhob',          'Zhob',           'ژوب',           'ZHB-01', 'div-zhob',       31.3424, 69.4466, NOW(), NOW()),
('dist-sherani',       'Sherani',        'شیرانی',        'ZHB-02', 'div-zhob',       31.5687, 70.0900, NOW(), NOW()),
('dist-musakhel',      'Musakhel',       'موسیٰ خیل',     'ZHB-03', 'div-zhob',       30.8175, 69.8232, NOW(), NOW()),
-- Loralai Division
('dist-loralai',       'Loralai',        'لورالائی',      'LRL-01', 'div-loralai',    30.3668, 68.6004, NOW(), NOW()),
('dist-barkhan',       'Barkhan',        'بارکھان',       'LRL-02', 'div-loralai',    29.8996, 69.5244, NOW(), NOW()),
('dist-killa-saifullah','Killa Saifullah','کلہ سیف اللہ', 'LRL-03', 'div-loralai',    30.8990, 68.1100, NOW(), NOW()),
-- Rakhshan Division
('dist-kharan',        'Kharan',         'خاران',         'RKH-01', 'div-rakhshan',   28.5836, 65.4161, NOW(), NOW()),
('dist-washuk',        'Washuk',         'واشک',          'RKH-02', 'div-rakhshan',   27.6952, 64.5958, NOW(), NOW());

-- 9.4 Crop Categories
INSERT INTO `crop_categories` (`id`, `name`, `nameUrdu`, `description`, `createdAt`, `updatedAt`) VALUES
('cat-cereals',    'Cereals',    'اناج',         'Major and minor grain crops', NOW(), NOW()),
('cat-cash',       'Cash Crops', 'نقد آور فصلیں','High value commercial crops', NOW(), NOW()),
('cat-fruits',     'Fruits',     'پھل',          'Horticultural fruit orchards', NOW(), NOW()),
('cat-vegetables', 'Vegetables', 'سبزیاں',       'Seasonal field vegetables', NOW(), NOW()),
('cat-pulses',     'Pulses',     'دالیں',        'Leguminous pulse crops', NOW(), NOW());

-- 9.5 Crops
INSERT INTO `crops` (`id`, `name`, `nameUrdu`, `code`, `categoryId`, `season`, `isActive`, `createdAt`, `updatedAt`) VALUES
('crop-wht', 'Wheat',       'گندم',    'WHT', 'cat-cereals',    'RABI',      1, NOW(), NOW()),
('crop-rce', 'Rice',        'چاول',    'RCE', 'cat-cereals',    'KHARIF',    1, NOW(), NOW()),
('crop-mze', 'Maize',       'مکئی',    'MZE', 'cat-cereals',    'KHARIF',    1, NOW(), NOW()),
('crop-sor', 'Sorghum',     'جوار',    'SOR', 'cat-cereals',    'KHARIF',    1, NOW(), NOW()),
('crop-brl', 'Barley',      'جَو',     'BRL', 'cat-cereals',    'RABI',      1, NOW(), NOW()),
('crop-ctn', 'Cotton',      'کپاس',    'CTN', 'cat-cash',       'KHARIF',    1, NOW(), NOW()),
('crop-sgc', 'Sugarcane',   'گنا',     'SGC', 'cat-cash',       'ANNUAL',    1, NOW(), NOW()),
('crop-app', 'Apple',       'سیب',     'APP', 'cat-fruits',     'PERENNIAL', 1, NOW(), NOW()),
('crop-grp', 'Grapes',      'انگور',   'GRP', 'cat-fruits',     'PERENNIAL', 1, NOW(), NOW()),
('crop-dat', 'Dates',       'کھجور',   'DAT', 'cat-fruits',     'PERENNIAL', 1, NOW(), NOW()),
('crop-pom', 'Pomegranate', 'انار',    'POM', 'cat-fruits',     'PERENNIAL', 1, NOW(), NOW()),
('crop-apr', 'Apricot',     'خوبانی',  'APR', 'cat-fruits',     'PERENNIAL', 1, NOW(), NOW()),
('crop-ono', 'Onion',       'پیاز',    'ONO', 'cat-vegetables', 'RABI',      1, NOW(), NOW()),
('crop-pot', 'Potato',      'آلو',     'POT', 'cat-vegetables', 'RABI',      1, NOW(), NOW()),
('crop-tom', 'Tomato',      'ٹماٹر',   'TOM', 'cat-vegetables', 'KHARIF',    1, NOW(), NOW()),
('crop-chi', 'Chillies',    'مرچ',     'CHI', 'cat-vegetables', 'KHARIF',    1, NOW(), NOW()),
('crop-chk', 'Chickpea',    'چنا',     'CHK', 'cat-pulses',     'RABI',      1, NOW(), NOW()),
('crop-lnt', 'Lentil',      'مسور',    'LNT', 'cat-pulses',     'RABI',      1, NOW(), NOW());

-- 9.6 Agriculture Years
INSERT INTO `agriculture_years` (`id`, `label`, `startYear`, `endYear`, `isCurrent`, `createdAt`, `updatedAt`) VALUES
('year-2019-20', '2019-20', 2019, 2020, 0, NOW(), NOW()),
('year-2020-21', '2020-21', 2020, 2021, 0, NOW(), NOW()),
('year-2021-22', '2021-22', 2021, 2022, 0, NOW(), NOW()),
('year-2022-23', '2022-23', 2022, 2023, 0, NOW(), NOW()),
('year-2023-24', '2023-24', 2023, 2024, 1, NOW(), NOW());

-- 9.7 Default Admin Users (Password: ChangeMe@123)
INSERT INTO `users` (`id`, `name`, `email`, `passwordHash`, `role`, `isActive`, `createdAt`, `updatedAt`) VALUES
('user-super-admin', 'CRS Super Admin', 'admin@crs.gob.pk', '$2a$12$ce92iDKnM578o0sX446ilOY2pPnIfxOfspY2lpUDSJ7F/NdrEjQ52', 'SUPER_ADMIN', 1, NOW(), NOW()),
('user-prov-admin',  'Provincial Director CRS', 'director@crs.gob.pk', '$2a$12$ce92iDKnM578o0sX446ilOY2pPnIfxOfspY2lpUDSJ7F/NdrEjQ52', 'PROVINCIAL_ADMIN', 1, NOW(), NOW()),
('user-officer-qta', 'District Officer Quetta', 'officer.qta@crs.gob.pk', '$2a$12$ce92iDKnM578o0sX446ilOY2pPnIfxOfspY2lpUDSJ7F/NdrEjQ52', 'DISTRICT_OFFICER', 1, NOW(), NOW());

-- 9.8 Sample Published Crop Reports (Year: 2023-24)
INSERT INTO `crop_reports` (
  `id`, `cropId`, `agricultureYearId`, `season`, `districtId`,
  `cultivatedArea`, `sownArea`, `harvestedArea`, `areaUnit`,
  `totalProduction`, `productionUnit`, `yield`, `yieldUnit`,
  `status`, `reportingOrganization`, `createdById`, `reportingDate`, `publishedAt`, `createdAt`, `updatedAt`
) VALUES
('rep-001', 'crop-wht', 'year-2023-24', 'RABI', 'dist-quetta',     12400, 12200, 11800, 'ACRES', 14500, 'METRIC_TONNES', 1.228, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-002', 'crop-wht', 'year-2023-24', 'RABI', 'dist-khuzdar',     8900,  8700,  8400, 'ACRES',  9200, 'METRIC_TONNES', 1.095, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-003', 'crop-wht', 'year-2023-24', 'RABI', 'dist-naseerabad', 22000, 21500, 20800, 'ACRES', 28000, 'METRIC_TONNES', 1.346, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-004', 'crop-wht', 'year-2023-24', 'RABI', 'dist-zhob',        9500,  9300,  9000, 'ACRES', 10800, 'METRIC_TONNES', 1.200, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-005', 'crop-wht', 'year-2023-24', 'RABI', 'dist-loralai',     7200,  7100,  6900, 'ACRES',  7800, 'METRIC_TONNES', 1.130, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-006', 'crop-rce', 'year-2023-24', 'KHARIF', 'dist-naseerabad',18500, 18200, 17900, 'ACRES', 42000, 'METRIC_TONNES', 2.346, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-007', 'crop-rce', 'year-2023-24', 'KHARIF', 'dist-jafarabad', 14200, 14000, 13700, 'ACRES', 33000, 'METRIC_TONNES', 2.408, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-008', 'crop-mze', 'year-2023-24', 'KHARIF', 'dist-zhob',       5200,  5100,  4900, 'ACRES',  8300, 'METRIC_TONNES', 1.693, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-009', 'crop-mze', 'year-2023-24', 'KHARIF', 'dist-loralai',    4100,  4000,  3800, 'ACRES',  6500, 'METRIC_TONNES', 1.710, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-010', 'crop-app', 'year-2023-24', 'PERENNIAL', 'dist-ziarat',  6800,  6800,  6500, 'ACRES', 21000, 'METRIC_TONNES', 3.230, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-011', 'crop-grp', 'year-2023-24', 'PERENNIAL', 'dist-kalat',   4200,  4200,  4000, 'ACRES', 15500, 'METRIC_TONNES', 3.875, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-012', 'crop-grp', 'year-2023-24', 'PERENNIAL', 'dist-pishin',  3100,  3100,  3000, 'ACRES', 11200, 'METRIC_TONNES', 3.733, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-013', 'crop-dat', 'year-2023-24', 'PERENNIAL', 'dist-gwadar',  8900,  8900,  8700, 'ACRES', 28500, 'METRIC_TONNES', 3.275, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-014', 'crop-dat', 'year-2023-24', 'PERENNIAL', 'dist-turbat',  7200,  7200,  7000, 'ACRES', 22000, 'METRIC_TONNES', 3.142, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-015', 'crop-pom', 'year-2023-24', 'PERENNIAL', 'dist-khuzdar', 3500,  3500,  3300, 'ACRES',  9800, 'METRIC_TONNES', 2.969, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-016', 'crop-ono', 'year-2023-24', 'RABI', 'dist-quetta',      2800,  2750,  2700, 'ACRES', 38500, 'METRIC_TONNES', 14.25, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW()),
('rep-017', 'crop-ono', 'year-2023-24', 'RABI', 'dist-naseerabad',  3200,  3150,  3100, 'ACRES', 44000, 'METRIC_TONNES', 14.19, 'Tonnes/Acre', 'PUBLISHED', 'CRS Balochistan', 'user-super-admin', NOW(), NOW(), NOW(), NOW());

-- 9.9 System Site Settings
INSERT INTO `site_settings` (`id`, `key`, `value`, `description`, `updatedAt`) VALUES
('set-org-name',     'org_name',         'Directorate General Crop Reporting Services Balochistan', 'Official organization title', NOW()),
('set-org-urdu',     'org_name_urdu',    'ڈائریکٹوریٹ جنرل فصل رپورٹنگ سروسز، محکمہ زراعت و امداد باہمی حکومت بلوچستان', 'Organization title in Urdu', NOW()),
('set-current-year', 'current_agri_year', '2023-24', 'Active agricultural enumeration year', NOW()),
('set-contact-email','contact_email',     'info@crs.balochistan.gov.pk', 'Public inquiries email', NOW()),
('set-contact-phone','contact_phone',     '+92 (081) 920-1234', 'Headquarters telephone line', NOW()),
('set-hq-address',   'hq_address',       'Directorate General CRS, Agriculture Complex, Sariab Road, Quetta, Balochistan, Pakistan', 'Official headquarters address', NOW());

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
