const jwt = require('jsonwebtoken');
const User = require('../models/User');
const logger = require('../utils/logger');

const auth = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('Authorization')?.replace('Bearer ', '') || 
                  req.cookies?.token ||
                  req.query?.token;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'No token, authorization denied'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'gspy-secret');
    
    // Get user from database
    const user = await User.findById(decoded.userId).select('-password');
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Token is not valid'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Check if subscription is active (for premium features)
    if (!user.isSubscriptionActive) {
      // Allow access but add subscription status to request
      req.subscriptionActive = false;
    } else {
      req.subscriptionActive = true;
    }

    // Add user to request object
    req.user = user;
    next();

  } catch (error) {
    logger.error('Auth middleware error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Token is not valid'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token has expired'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error during authentication'
    });
  }
};

// Middleware to require active subscription
const requireSubscription = (req, res, next) => {
  if (!req.subscriptionActive) {
    return res.status(403).json({
      success: false,
      message: 'Active subscription required for this feature'
    });
  }
  next();
};

// Middleware to require specific role
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }

    next();
  };
};

// Middleware to require admin role
const requireAdmin = requireRole(['admin', 'super_admin']);

// Middleware to require super admin role
const requireSuperAdmin = requireRole(['super_admin']);

module.exports = {
  auth,
  requireSubscription,
  requireRole,
  requireAdmin,
  requireSuperAdmin
}; 