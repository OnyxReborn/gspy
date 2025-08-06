# gSpy Shared Hosting Deployment Guide

This guide will help you deploy gSpy to Hostinger shared hosting with limitations and workarounds.

## ⚠️ **Shared Hosting Limitations**

### **What Won't Work on Shared Hosting:**
- ❌ **MongoDB** (not supported)
- ❌ **Redis** (not available)
- ❌ **Background processes** (limited)
- ❌ **Custom ports** (restricted)
- ❌ **System-level access** (not available)
- ❌ **Advanced monitoring** (limited)
- ❌ **Real-time features** (restricted)

### **What Will Work:**
- ✅ **Basic monitoring dashboard**
- ✅ **User authentication**
- ✅ **Data storage** (via external database)
- ✅ **Email notifications**
- ✅ **Basic analytics**
- ✅ **Mobile app integration**

## 🚀 **Prerequisites**

### **Hostinger Shared Hosting Requirements:**
- **Shared hosting plan** with Node.js support
- **Domain name** pointing to your hosting
- **FTP/SFTP access** to upload files
- **cPanel access** for database management
- **At least 1GB storage** available

### **External Services Needed:**
- **MongoDB Atlas** (free tier) for database
- **Email service** (Gmail, SendGrid, etc.)
- **File storage** (AWS S3, Google Cloud Storage)

## 📋 **Step-by-Step Deployment**

### **Step 1: Check Hostinger Node.js Support**

1. **Login to cPanel**
2. **Look for "Node.js"** in the applications section
3. **Check Node.js version** (should be 16+)
4. **Note your Node.js app URL** (usually `yourdomain.com:3000`)

### **Step 2: Access Your Hosting**

#### **Option A: SSH Access (if available)**
```bash
ssh username@your-server-ip
```

#### **Option B: cPanel Terminal**
1. Login to cPanel
2. Find "Terminal" or "SSH Access"
3. Open terminal

#### **Option C: File Manager**
1. Login to cPanel
2. Open "File Manager"
3. Navigate to `public_html`

### **Step 3: Run the Deployment Script**

1. **Download the script**:
   ```bash
   wget https://raw.githubusercontent.com/your-username/gspy/main/deploy-hostinger-shared.sh
   ```

2. **Make it executable**:
   ```bash
   chmod +x deploy-hostinger-shared.sh
   ```

3. **Run the script**:
   ```bash
   ./deploy-hostinger-shared.sh
   ```

### **Step 4: Follow Interactive Setup**

The script will ask for:
- **Domain name** (e.g., `yourdomain.com`)
- **Email address**
- **Admin credentials**
- **Database information** (for MongoDB Atlas)

### **Step 5: Set Up MongoDB Atlas**

1. **Create MongoDB Atlas Account**:
   - Go to [mongodb.com/atlas](https://www.mongodb.com/atlas)
   - Sign up for free account
   - Create new cluster (free tier)

2. **Create Database User**:
   - Go to "Database Access"
   - Add new user
   - Set username and password

3. **Get Connection String**:
   - Go to "Clusters"
   - Click "Connect"
   - Choose "Connect your application"
   - Copy the connection string

4. **Update Configuration**:
   ```bash
   nano backend/.env
   ```
   
   Update the MONGODB_URI line:
   ```env
   MONGODB_URI=mongodb+srv://username:password@cluster0.mongodb.net/gspy?retryWrites=true&w=majority
   ```

## 🔧 **Alternative Deployment Methods**

### **Method 1: Manual File Upload**

If you can't use SSH:

1. **Download the files** to your computer
2. **Upload via FTP/SFTP** to `public_html/gspy/`
3. **Use cPanel Terminal** to run commands

### **Method 2: cPanel Node.js App**

1. **Create Node.js App** in cPanel:
   - Go to "Node.js" in cPanel
   - Create new application
   - Set startup file to `server.js`

2. **Upload files** to the app directory
3. **Configure environment variables**
4. **Start the application**

### **Method 3: Git Deployment**

If your hosting supports Git:

```bash
# Clone repository
git clone https://github.com/your-username/gspy.git

# Install dependencies
cd gspy/backend
npm install --production

cd ../frontend
npm install
npm run build
```

## 🗄️ **Database Setup**

### **MongoDB Atlas Configuration**

1. **Network Access**:
   - Go to "Network Access" in Atlas
   - Add IP address `0.0.0.0/0` (allow all)
   - Or add your hosting IP specifically

2. **Database Creation**:
   - The app will create collections automatically
   - No manual setup required

3. **Connection Testing**:
   ```bash
   # Test connection
   curl https://yourdomain.com/api/health
   ```

### **Alternative: MySQL (if available)**

If your shared hosting supports MySQL:

1. **Create MySQL database** in cPanel
2. **Update backend** to use MySQL instead of MongoDB
3. **Install MySQL dependencies**:
   ```bash
   npm install mysql2 sequelize
   ```

## 📱 **Mobile App Configuration**

### **Step 1: Update Mobile Settings**

1. **Edit mobile environment**:
   ```bash
   nano mobile/.env
   ```

2. **Update API URL**:
   ```env
   EXPO_PUBLIC_API_URL=https://yourdomain.com/api
   EXPO_PUBLIC_SOCKET_URL=https://yourdomain.com
   ```

### **Step 2: Build Mobile App**

```bash
cd mobile
npx expo build:android
```

### **Step 3: Install on Android**

1. **Download APK** from the provided link
2. **Transfer to Android phone**
3. **Enable "Install from Unknown Sources"**
4. **Install the APK**

## 🛠️ **Management and Maintenance**

### **Application Management**

```bash
# Check if app is running
ps aux | grep node

# View logs
tail -f logs/app.log

# Restart application
pkill node
cd backend && node server.js &
```

### **File Management**

```bash
# Check disk usage
du -sh *

# Clean up old files
find . -name "*.log" -mtime +7 -delete

# Backup important files
tar -czf backup_$(date +%Y%m%d).tar.gz backend frontend
```

### **Database Management**

```bash
# Backup MongoDB Atlas data
mongodump --uri="your-connection-string" --out=backup/

# Restore data
mongorestore --uri="your-connection-string" backup/
```

## 🔒 **Security Configuration**

### **Shared Hosting Security**

1. **Strong Passwords**:
   ```bash
   # Generate secure passwords
   openssl rand -base64 32
   ```

2. **Environment Variables**:
   - Keep sensitive data in `.env` files
   - Never commit `.env` to version control

3. **HTTPS Configuration**:
   - Enable SSL in cPanel
   - Force HTTPS redirects

4. **File Permissions**:
   ```bash
   # Set proper permissions
   chmod 644 backend/.env
   chmod 755 backend/
   chmod 644 frontend/build/*
   ```

## 📊 **Monitoring and Troubleshooting**

### **Health Checks**

1. **Application Health**:
   ```bash
   curl https://yourdomain.com/api/health
   ```

2. **Database Connection**:
   ```bash
   curl https://yourdomain.com/api/auth/test
   ```

3. **File System**:
   ```bash
   df -h
   du -sh public_html/gspy/*
   ```

### **Common Issues**

#### **1. Application Won't Start**
```bash
# Check Node.js version
node --version

# Check if port is available
netstat -tlnp | grep :3000

# Check logs
tail -f logs/app.log
```

#### **2. Database Connection Issues**
- Verify MongoDB Atlas connection string
- Check network access settings
- Test connection from hosting server

#### **3. Memory/Storage Issues**
```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Clean up old files
find . -name "*.log" -delete
```

#### **4. Performance Issues**
- Optimize images and assets
- Enable compression
- Use CDN for static files
- Monitor resource usage

## 🔄 **Updates and Maintenance**

### **Regular Maintenance**

1. **Weekly**:
   - Check application logs
   - Monitor disk usage
   - Test database connection

2. **Monthly**:
   - Update dependencies
   - Review security settings
   - Backup data

3. **Quarterly**:
   - Review performance
   - Update documentation
   - Check for new features

### **Application Updates**

```bash
# Pull latest changes
git pull origin main

# Update dependencies
cd backend && npm update
cd ../frontend && npm update && npm run build

# Restart application
pkill node
cd backend && node server.js &
```

## 📞 **Support and Resources**

### **Hostinger Support**
- **cPanel Documentation**: Check Hostinger's cPanel guide
- **Node.js Support**: Contact Hostinger support for Node.js issues
- **Database Support**: Use MongoDB Atlas support

### **Application Support**
- **Logs**: Check `logs/` directory for error messages
- **Documentation**: Review `DATABASE_SETUP.md`
- **Community**: Check GitHub issues and discussions

### **External Services**
- **MongoDB Atlas**: [docs.atlas.mongodb.com](https://docs.atlas.mongodb.com)
- **Email Services**: Gmail, SendGrid, Mailgun
- **File Storage**: AWS S3, Google Cloud Storage

## ⚠️ **Important Limitations**

### **Shared Hosting Restrictions**
- **No background processes** (cron jobs limited)
- **No custom ports** (must use provided ports)
- **Limited memory** (monitor usage carefully)
- **No system access** (can't install system packages)
- **No SSL certificates** (use hosting provider's SSL)

### **Workarounds**
- **Use external services** for heavy processing
- **Implement polling** instead of real-time updates
- **Optimize code** for limited resources
- **Use CDN** for static assets
- **Implement caching** strategies

---

## 🎯 **Quick Start Checklist**

- [ ] **Check Node.js support** in cPanel
- [ ] **Run deployment script** or upload files manually
- [ ] **Set up MongoDB Atlas** database
- [ ] **Configure environment variables**
- [ ] **Test application** health endpoints
- [ ] **Set up SSL certificate**
- [ ] **Configure email settings**
- [ ] **Test mobile app** connection
- [ ] **Set up monitoring** and alerts
- [ ] **Create backup** strategy

---

**🎉 Your gSpy monitoring dashboard is now running on shared hosting!**

Remember:
- ✅ Monitor resource usage carefully
- ✅ Use external services for heavy operations
- ✅ Regular backups are essential
- ✅ Keep dependencies updated
- ✅ Comply with local laws and regulations 