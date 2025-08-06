const winston = require('winston');
const path = require('path');

// Define log levels
const levels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

// Define colors for each level
const colors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  debug: 'white',
};

// Tell winston that you want to link the colors
winston.addColors(colors);

// Define which level to log based on environment
const level = () => {
  const env = process.env.NODE_ENV || 'development';
  const isDevelopment = env === 'development';
  return isDevelopment ? 'debug' : 'warn';
};

// Define format for logs
const format = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
  winston.format.colorize({ all: true }),
  winston.format.printf(
    (info) => `${info.timestamp} ${info.level}: ${info.message}`,
  ),
);

// Define transports
const transports = [
  // Console transport
  new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }),
  
  // File transport for errors
  new winston.transports.File({
    filename: path.join(__dirname, '../../logs/error.log'),
    level: 'error',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.json()
    )
  }),
  
  // File transport for all logs
  new winston.transports.File({
    filename: path.join(__dirname, '../../logs/combined.log'),
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.json()
    )
  })
];

// Create the logger
const logger = winston.createLogger({
  level: level(),
  levels,
  format,
  transports,
  exitOnError: false
});

// Create a stream object for Morgan
logger.stream = {
  write: (message) => {
    logger.http(message.trim());
  },
};

// Helper methods for different log types
logger.logError = (error, context = '') => {
  const errorMessage = error instanceof Error ? error.message : error;
  const stack = error instanceof Error ? error.stack : '';
  
  logger.error(`${context ? `[${context}] ` : ''}${errorMessage}${stack ? `\n${stack}` : ''}`);
};

logger.logInfo = (message, data = null) => {
  const logMessage = data ? `${message} ${JSON.stringify(data)}` : message;
  logger.info(logMessage);
};

logger.logWarn = (message, data = null) => {
  const logMessage = data ? `${message} ${JSON.stringify(data)}` : message;
  logger.warn(logMessage);
};

logger.logDebug = (message, data = null) => {
  const logMessage = data ? `${message} ${JSON.stringify(data)}` : message;
  logger.debug(logMessage);
};

logger.logHttp = (req, res, responseTime) => {
  const logMessage = `${req.method} ${req.originalUrl} ${res.statusCode} ${responseTime}ms`;
  logger.http(logMessage);
};

// Request logging middleware
logger.logRequest = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.logHttp(req, res, duration);
  });
  
  next();
};

// Error logging middleware
logger.logErrorMiddleware = (error, req, res, next) => {
  logger.logError(error, `${req.method} ${req.originalUrl}`);
  next(error);
};

module.exports = logger; 