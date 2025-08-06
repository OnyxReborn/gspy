# gSpy Cloudways Deployment Guide

This guide will help you deploy gSpy to Cloudways hosting platform with full feature support.

## 🚀 **Cloudways Advantages**

### **✅ Full Feature Support:**
- ✅ **MongoDB** (built-in support)
- ✅ **Redis** (built-in support)
- ✅ **Node.js** (multiple versions available)
- ✅ **PM2** (process management)
- ✅ **SSL certificates** (automatic)
- ✅ **CDN** (Cloudflare integration)
- ✅ **Backup system** (automated)
- ✅ **Monitoring** (built-in)
- ✅ **Real-time features** (full support)
- ✅ **Background processes** (cron jobs)
- ✅ **Custom domains** (unlimited)
- ✅ **Load balancing** (available)

## 📋 **Prerequisites**

### **Cloudways Account Requirements:**
- **Cloudways account** (free trial available)
- **Server plan** (DigitalOcean, AWS, Google Cloud, etc.)
- **Application** (Node.js)
- **Domain name** (optional, can use Cloudways subdomain)

### **Recommended Server Specs:**
- **RAM**: 2GB minimum (4GB recommended)
- **Storage**: 20GB minimum (50GB recommended)
- **CPU**: 1 core minimum (2 cores recommended)
- **Bandwidth**: 1TB minimum

## 🚀 **Step-by-Step Deployment**

### **Step 1: Create Cloudways Account**

1. **Sign up** at [cloudways.com](https://cloudways.com)
2. **Verify email** and complete account setup
3. **Add payment method** (required for server creation)

### **Step 2: Create Server**

1. **Login to Cloudways dashboard**
2. **Click "Add Server"**
3. **Choose cloud provider**:
   - **DigitalOcean** (recommended for beginners)
   - **AWS** (more features, higher cost)
   - **Google Cloud** (good performance)
   - **Vultr** (cost-effective)
4. **Select server size**:
   - **2GB RAM** (minimum for gSpy)
   - **4GB RAM** (recommended)
   - **8GB RAM** (for high traffic)
5. **Choose server location** (closest to your users)
6. **Click "Launch Server"**

### **Step 3: Create Application**

1. **Click "Add Application"**
2. **Select your server**
3. **Choose "Node.js"** as application type
4. **Select Node.js version** (16.x or higher)
5. **Enter application name** (e.g., "gspy-app")
6. **Click "Add Application"**

### **Step 4: Access Server**

#### **Option A: SSH Access (Recommended)**
1. **Go to Server Settings**
2. **Click "Master Credentials"**
3. **Copy SSH details**:
   ```bash
   ssh username@server-ip
   ```

#### **Option B: Cloudways Terminal**
1. **Go to Application Settings**
2. **Click "SSH Terminal"**
3. **Use built-in terminal**

### **Step 5: Run Deployment Script**

1. **Connect to server via SSH**
2. **Navigate to application directory**:
   ```bash
   cd applications/your-app-name/public_html
   ```

3. **Download and run script**:
   ```bash
   wget https://raw.githubusercontent.com/your-username/gspy/main/deploy-cloudways.sh
   chmod +x deploy-cloudways.sh
   ./deploy-cloudways.sh
   ```

4. **Follow interactive setup**:
   - Enter app name
   - Enter domain name
   - Enter admin credentials
   - Enter database details

### **Step 6: Configure Domain**

1. **Go to Application Settings**
2. **Click "Domain Management"**
3. **Add your domain**:
   - **Primary Domain**: yourdomain.com
   - **Point DNS** to Cloudways IP
4. **Enable SSL** (automatic with Let's Encrypt)

### **Step 7: Configure Database**

1. **Go to Application Settings**
2. **Click "Database Manager"**
3. **Create new database**:
   - **Database Name**: gspy_db
   - **Username**: gspy_user
   - **Password**: (use generated password)
4. **Note credentials** for configuration

## 🔧 **Alternative Deployment Methods**

### **Method 1: Git Deployment**

If you prefer Git-based deployment:

```bash
# Clone repository
git clone https://github.com/your-username/gspy.git

# Navigate to application directory
cd applications/your-app-name/public_html

# Copy files
cp -r gspy/* .

# Install dependencies
cd backend && npm install --production
cd ../frontend && npm install && npm run build

# Configure environment
cp backend/env.example backend/.env
# Edit backend/.env with your settings
```

### **Method 2: Manual Upload**

1. **Download gSpy files** to your computer
2. **Upload via SFTP** to Cloudways
3. **Use Cloudways terminal** for setup commands

### **Method 3: Cloudways Git Integration**

1. **Go to Application Settings**
2. **Click "Git Version Control"**
3. **Connect your GitHub repository**
4. **Deploy automatically** on push

## 🗄️ **Database Configuration**

### **MongoDB Setup (Recommended)**

Cloudways provides MongoDB support:

1. **Go to Application Settings**
2. **Click "Database Manager"**
3. **Create MongoDB database**
4. **Get connection string**
5. **Update backend/.env**:
   ```env
   MONGODB_URI=mongodb://username:password@localhost:27017/gspy
   ```

### **MySQL Setup (Alternative)**

If you prefer MySQL:

1. **Create MySQL database** in Cloudways
2. **Update backend** to use MySQL
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
# Check PM2 status
pm2 status

# View application logs
pm2 logs

# Restart application
pm2 restart gspy-backend

# Stop application
pm2 stop gspy-backend

# Start application
pm2 start gspy-backend
```

### **File Management**

```bash
# Check disk usage
df -h

# Check application size
du -sh applications/your-app-name/public_html

# Clean up old files
find . -name "*.log" -mtime +7 -delete

# Backup application
tar -czf backup_$(date +%Y%m%d).tar.gz applications/your-app-name/public_html
```

### **Database Management**

```bash
# Backup MongoDB
mongodump --db gspy --out backup/

# Restore MongoDB
mongorestore --db gspy backup/gspy/

# Backup MySQL
mysqldump -u username -p gspy_db > backup.sql

# Restore MySQL
mysql -u username -p gspy_db < backup.sql
```

## 🔒 **Security Configuration**

### **Cloudways Security Features**

1. **SSL Certificates**:
   - Automatic Let's Encrypt SSL
   - Custom SSL certificates supported

2. **Firewall**:
   - Built-in firewall protection
   - IP whitelisting available

3. **Backup Security**:
   - Encrypted backups
   - Off-site storage

### **Application Security**

1. **Environment Variables**:
   ```bash
   # Keep sensitive data in .env files
   chmod 600 backend/.env
   ```

2. **File Permissions**:
   ```bash
   # Set proper permissions
   chmod 755 applications/your-app-name/public_html
   chmod 644 applications/your-app-name/public_html/frontend/build/*
   ```

3. **Rate Limiting**:
   - Already configured in application
   - Adjust in backend/.env if needed

## 📊 **Monitoring and Performance**

### **Cloudways Monitoring**

1. **Server Monitoring**:
   - CPU usage
   - Memory usage
   - Disk usage
   - Network traffic

2. **Application Monitoring**:
   - Response times
   - Error rates
   - Request counts

### **Application Monitoring**

```bash
# Check application health
curl https://yourdomain.com/api/health

# Monitor PM2 processes
pm2 monit

# View real-time logs
pm2 logs --lines 100 --timestamp
```

### **Performance Optimization**

1. **Enable CDN**:
   - Go to Application Settings
   - Click "Cloudflare"
   - Enable CDN

2. **Optimize Images**:
   - Use WebP format
   - Implement lazy loading
   - Use image compression

3. **Database Optimization**:
   - Create indexes
   - Optimize queries
   - Regular maintenance

## 🔄 **Updates and Maintenance**

### **Regular Maintenance**

1. **Weekly**:
   - Check application logs
   - Monitor resource usage
   - Test backup restoration

2. **Monthly**:
   - Update dependencies
   - Review security settings
   - Performance analysis

3. **Quarterly**:
   - Full system audit
   - Update documentation
   - Plan capacity upgrades

### **Application Updates**

```bash
# Pull latest changes
git pull origin main

# Update dependencies
cd backend && npm update
cd ../frontend && npm update && npm run build

# Restart application
pm2 restart gspy-backend

# Test application
curl https://yourdomain.com/api/health
```

### **Cloudways Updates**

1. **Server Updates**:
   - Automatic security updates
   - Manual OS updates available

2. **Application Updates**:
   - Node.js version updates
   - PHP version updates (if applicable)

## 📞 **Support and Resources**

### **Cloudways Support**

- **24/7 Live Chat**: Available in dashboard
- **Knowledge Base**: Extensive documentation
- **Community Forum**: Active user community
- **Ticket System**: For complex issues

### **Application Support**

- **Logs**: Check PM2 logs for errors
- **Documentation**: Review deployment guides
- **GitHub Issues**: Report bugs and request features

### **External Services**

- **MongoDB Atlas**: [docs.atlas.mongodb.com](https://docs.atlas.mongodb.com)
- **Email Services**: Gmail, SendGrid, Mailgun
- **File Storage**: AWS S3, Google Cloud Storage

## 💰 **Cost Optimization**

### **Server Optimization**

1. **Right-size server**:
   - Start with 2GB RAM
   - Scale up as needed
   - Monitor usage patterns

2. **Use appropriate provider**:
   - **DigitalOcean**: Good for beginners
   - **AWS**: More features, higher cost
   - **Vultr**: Cost-effective option

3. **Enable auto-scaling** (if available)

### **Resource Optimization**

1. **Database optimization**:
   - Regular cleanup
   - Efficient queries
   - Proper indexing

2. **Application optimization**:
   - Code optimization
   - Asset compression
   - CDN usage

## 🎯 **Quick Start Checklist**

- [ ] **Create Cloudways account**
- [ ] **Launch server** (2GB RAM minimum)
- [ ] **Create Node.js application**
- [ ] **Access server via SSH**
- [ ] **Run deployment script**
- [ ] **Configure domain and SSL**
- [ ] **Set up database**
- [ ] **Test application health**
- [ ] **Configure email settings**
- [ ] **Set up monitoring**
- [ ] **Create backup strategy**
- [ ] **Test mobile app connection**

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. Application Won't Start**
```bash
# Check Node.js version
node --version

# Check PM2 status
pm2 status

# View error logs
pm2 logs --err
```

#### **2. Database Connection Issues**
```bash
# Test MongoDB connection
mongo --host localhost --port 27017

# Test MySQL connection
mysql -u username -p -h localhost
```

#### **3. Domain Issues**
- Check DNS settings
- Verify SSL certificate
- Test domain propagation

#### **4. Performance Issues**
- Monitor resource usage
- Check application logs
- Optimize database queries

---

## 🎉 **Success!**

**Your gSpy monitoring dashboard is now running on Cloudways with full feature support!**

### **Key Benefits:**
- ✅ **Full feature support** (no limitations)
- ✅ **Professional hosting** (99.9% uptime)
- ✅ **Automatic backups** (daily)
- ✅ **SSL certificates** (automatic)
- ✅ **CDN support** (Cloudflare)
- ✅ **24/7 support** (live chat)
- ✅ **Easy scaling** (upgrade anytime)
- ✅ **Monitoring tools** (built-in)

### **Next Steps:**
1. **Configure email settings** in backend/.env
2. **Set up external services** (AWS, Google Cloud)
3. **Customize dashboard** appearance
4. **Set up monitoring alerts**
5. **Create user accounts**
6. **Test all features**

### **Remember:**
- ✅ Monitor resource usage regularly
- ✅ Keep backups up to date
- ✅ Update dependencies monthly
- ✅ Test new features before deployment
- ✅ Comply with local laws and regulations

---

**🎯 Your gSpy monitoring solution is now enterprise-ready on Cloudways!** 