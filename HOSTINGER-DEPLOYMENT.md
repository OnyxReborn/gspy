# gSpy Hostinger Deployment Guide

This guide will help you deploy gSpy to your Hostinger VPS or dedicated server.

## 🚀 **Prerequisites**

### **Hostinger Server Requirements**
- **VPS or Dedicated Server** (Shared hosting won't work)
- **Ubuntu 20.04+** or **CentOS 8+**
- **Root access** or **sudo privileges**
- **At least 2GB RAM** (4GB recommended)
- **At least 20GB storage**
- **Domain name** pointing to your server

### **Domain Setup**
1. **Point your domain** to your Hostinger server IP
2. **Create a subdomain** (e.g., `gspy.yourdomain.com`)
3. **Wait for DNS propagation** (can take up to 24 hours)

## 📋 **Step-by-Step Deployment**

### **Step 1: Access Your Hostinger Server**

1. **Connect via SSH**:
   ```bash
   ssh root@your-server-ip
   ```

2. **Update system**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

### **Step 2: Install Required Software**

1. **Install Node.js 18+**:
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. **Install Git**:
   ```bash
   sudo apt install git -y
   ```

3. **Install PM2** (Process Manager):
   ```bash
   sudo npm install -g pm2
   ```

4. **Install Nginx**:
   ```bash
   sudo apt install nginx -y
   ```

5. **Install Certbot** (for SSL):
   ```bash
   sudo apt install certbot python3-certbot-nginx -y
   ```

### **Step 3: Download and Run Deployment Script**

1. **Download the deployment script**:
   ```bash
   wget https://raw.githubusercontent.com/your-username/gspy/main/deploy-hostinger.sh
   ```

2. **Make it executable**:
   ```bash
   chmod +x deploy-hostinger.sh
   ```

3. **Run the deployment script**:
   ```bash
   ./deploy-hostinger.sh
   ```

### **Step 4: Follow the Interactive Setup**

The script will ask you for:

- **Domain name** (e.g., `gspy.yourdomain.com`)
- **Email address** (for SSL certificate)
- **Database name** (default: `gspy_db`)
- **Database username** (default: `gspy_user`)
- **Database password** (auto-generated if left empty)
- **Admin email** (for dashboard access)
- **Admin password** (auto-generated if left empty)

### **Step 5: Wait for Installation**

The script will automatically:

1. ✅ **Install MongoDB** and create database
2. ✅ **Install Redis** for caching
3. ✅ **Setup Nginx** with SSL configuration
4. ✅ **Configure PM2** for process management
5. ✅ **Create admin user** for dashboard access
6. ✅ **Setup firewall** and security
7. ✅ **Configure monitoring** and backups
8. ✅ **Start all services**

## 🔧 **Post-Deployment Configuration**

### **Step 1: Access Your Dashboard**

1. **Open your browser** and go to: `https://your-domain.com`
2. **Login** with the admin credentials provided by the script
3. **Change the default password** immediately

### **Step 2: Configure Email Settings**

1. **Edit the backend environment file**:
   ```bash
   sudo nano /var/www/gspy/backend/.env
   ```

2. **Update email settings**:
   ```env
   EMAIL_SERVICE=gmail
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASS=your-app-password
   ```

3. **Restart the application**:
   ```bash
   pm2 restart gspy-backend
   ```

### **Step 3: Configure Additional Services**

#### **Google Maps API** (for location tracking):
```env
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

#### **Stripe** (for payments):
```env
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
```

#### **Firebase** (for push notifications):
```env
FIREBASE_SERVER_KEY=your-firebase-server-key
FIREBASE_PROJECT_ID=your-firebase-project-id
```

## 🛠️ **Management Commands**

### **Application Management**
```bash
# View application status
pm2 status

# View logs
pm2 logs gspy-backend

# Restart application
pm2 restart gspy-backend

# Stop application
pm2 stop gspy-backend

# Start application
pm2 start gspy-backend
```

### **Server Monitoring**
```bash
# Check server status
/var/www/gspy/monitor.sh

# View system resources
htop

# Check disk usage
df -h

# Check memory usage
free -h
```

### **Database Management**
```bash
# Access MongoDB
mongo gspy_db -u gspy_user -p

# Backup database
/var/www/gspy/backup.sh

# Restore database
mongorestore --uri="mongodb://gspy_user:password@localhost:27017/gspy_db" backup_folder/
```

### **Nginx Management**
```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart Nginx
sudo systemctl restart nginx

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 🔒 **Security Configuration**

### **Step 1: Update Passwords**
```bash
# Change database password
mongo --eval "db.changeUserPassword('gspy_user', 'new-password')"

# Update .env file
sudo nano /var/www/gspy/backend/.env
```

### **Step 2: Configure Firewall**
```bash
# Allow only necessary ports
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw deny 22  # If using different SSH port
sudo ufw enable
```

### **Step 3: Regular Updates**
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Node.js packages
cd /var/www/gspy
npm update
```

## 📊 **Monitoring and Maintenance**

### **Automated Backups**
- **Daily backups** are automatically created at 2 AM
- **Backup location**: `/var/www/gspy/backups/`
- **Retention**: 7 days
- **Manual backup**: `/var/www/gspy/backup.sh`

### **Log Monitoring**
```bash
# Application logs
tail -f /var/www/gspy/logs/combined.log

# Error logs
tail -f /var/www/gspy/logs/err.log

# Nginx logs
tail -f /var/log/nginx/access.log
```

### **Performance Monitoring**
```bash
# Check PM2 status
pm2 monit

# Check system resources
htop

# Check disk usage
df -h
```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. Application Won't Start**
```bash
# Check logs
pm2 logs gspy-backend

# Check if port is in use
sudo netstat -tlnp | grep :5000

# Restart application
pm2 restart gspy-backend
```

#### **2. Database Connection Issues**
```bash
# Check MongoDB status
sudo systemctl status mongod

# Restart MongoDB
sudo systemctl restart mongod

# Check connection
mongo --eval "db.runCommand('ping')"
```

#### **3. SSL Certificate Issues**
```bash
# Check certificate status
sudo certbot certificates

# Renew certificate
sudo certbot renew

# Check Nginx configuration
sudo nginx -t
```

#### **4. Domain Not Loading**
```bash
# Check DNS propagation
nslookup your-domain.com

# Check Nginx status
sudo systemctl status nginx

# Check firewall
sudo ufw status
```

### **Getting Help**

1. **Check logs** for error messages
2. **Verify configuration** files
3. **Test services** individually
4. **Check system resources**
5. **Review firewall settings**

## 📱 **Mobile App Configuration**

### **Step 1: Update Mobile App Settings**

1. **Edit mobile environment**:
   ```bash
   sudo nano /var/www/gspy/mobile/.env
   ```

2. **Update API URL**:
   ```env
   EXPO_PUBLIC_API_URL=https://your-domain.com/api
   EXPO_PUBLIC_SOCKET_URL=https://your-domain.com
   ```

### **Step 2: Build Mobile App**

```bash
cd /var/www/gspy/mobile
npx expo build:android
```

### **Step 3: Download and Install APK**

1. **Download the APK** from the provided link
2. **Transfer to your Android phone**
3. **Enable "Install from Unknown Sources"**
4. **Install the APK**

## 🔄 **Updates and Maintenance**

### **Regular Maintenance Tasks**

1. **Weekly**:
   - Check server resources
   - Review application logs
   - Update system packages

2. **Monthly**:
   - Review security settings
   - Check SSL certificate expiration
   - Update application dependencies

3. **Quarterly**:
   - Review backup integrity
   - Check performance metrics
   - Update monitoring scripts

### **Application Updates**

```bash
# Pull latest changes
cd /var/www/gspy
git pull origin main

# Install new dependencies
cd backend && npm install
cd ../frontend && npm install && npm run build

# Restart application
pm2 restart gspy-backend
```

## 📞 **Support Information**

### **Important Files and Locations**
- **Application**: `/var/www/gspy/`
- **Logs**: `/var/www/gspy/logs/`
- **Backups**: `/var/www/gspy/backups/`
- **Nginx Config**: `/etc/nginx/sites-available/gspy`
- **PM2 Config**: `/var/www/gspy/ecosystem.config.js`

### **Contact Information**
- **Documentation**: Check the `/docs/` folder
- **Issues**: Review logs in `/var/www/gspy/logs/`
- **Backups**: Located in `/var/www/gspy/backups/`

---

**🎉 Congratulations! Your gSpy monitoring dashboard is now live on Hostinger!**

Remember to:
- ✅ Change default passwords
- ✅ Configure email settings
- ✅ Set up monitoring alerts
- ✅ Regular backups and updates
- ✅ Comply with local laws and regulations 