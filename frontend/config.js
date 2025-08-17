// Configuration for the URL Shortener Frontend
// This file contains all configurable settings

window.UrlShortenerConfig = {
  // API Configuration
  api: {
    baseUrl: 'https://short.sctp-sandbox.com',
    timeout: 10000, // 10 seconds
    retries: 2
  },
  
  // UI Configuration
  ui: {
    showLoadingDelay: 200, // Show loading after 200ms
    hideResultsDelay: 30000, // Hide results after 30 seconds
    copySuccessDelay: 2000 // Show copy success for 2 seconds
  },
  
  // Validation
  validation: {
    maxUrlLength: 2048,
    minUrlLength: 10,
    allowedProtocols: ['http:', 'https:', 'ftp:'],
    blockedDomains: [] // Add domains to block if needed
  },
  
  // Analytics (if needed in future)
  analytics: {
    enabled: false,
    trackingId: null
  },
  
  // Feature flags
  features: {
    copyToClipboard: true,
    urlValidation: true,
    errorReporting: true,
    offlineSupport: false // For future PWA features
  },
  
  // Environment detection
  environment: window.location.hostname.includes('localhost') || window.location.hostname.includes('127.0.0.1') ? 'development' : 'production',
  
  // Debug mode
  debug: window.location.hostname.includes('localhost') || window.location.search.includes('debug=true')
};

// Development overrides
if (UrlShortenerConfig.environment === 'development') {
  UrlShortenerConfig.api.baseUrl = 'http://localhost:3000'; // Local development API
  UrlShortenerConfig.debug = true;
}

// Freeze configuration to prevent accidental modification
Object.freeze(UrlShortenerConfig);

// Export for modules (if using module system in future)
if (typeof module !== 'undefined' && module.exports) {
  module.exports = UrlShortenerConfig;
}
