// URL Shortener Frontend Application
// Modern, accessible, and robust JavaScript implementation

class UrlShortener {
  constructor() {
    this.config = window.UrlShortenerConfig;
    this.elements = {};
    this.state = {
      isLoading: false,
      lastShortenedUrl: null,
      retryCount: 0
    };
    
    this.init();
  }
  
  // Initialize the application
  init() {
    this.bindElements();
    this.bindEvents();
    this.setupAccessibility();
    
    if (this.config.debug) {
      console.log('🔗 URL Shortener initialized', this.config);
    }
  }
  
  // Bind DOM elements
  bindElements() {
    this.elements = {
      urlInput: document.getElementById('longUrl'),
      shortenBtn: document.getElementById('shortenBtn'),
      btnText: document.querySelector('.btn-text'),
      btnLoader: document.querySelector('.btn-loader'),
      resultContainer: document.getElementById('result'),
      errorContainer: document.getElementById('error')
    };
    
    // Validate required elements
    for (const [key, element] of Object.entries(this.elements)) {
      if (!element) {
        console.error(`Required element not found: ${key}`);
      }
    }
  }
  
  // Bind event listeners
  bindEvents() {
    // Button click
    this.elements.shortenBtn?.addEventListener('click', (e) => {
      e.preventDefault();
      this.handleShorten();
    });
    
    // Enter key in input
    this.elements.urlInput?.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !this.state.isLoading) {
        e.preventDefault();
        this.handleShorten();
      }
    });
    
    // Input validation
    this.elements.urlInput?.addEventListener('input', () => {
      this.validateInput();
      this.clearMessages();
    });
    
    // Paste event
    this.elements.urlInput?.addEventListener('paste', () => {
      // Use setTimeout to get the pasted value
      setTimeout(() => this.validateInput(), 0);
    });
  }
  
  // Setup accessibility features
  setupAccessibility() {
    // Add ARIA live regions if not present
    if (this.elements.resultContainer) {
      this.elements.resultContainer.setAttribute('aria-live', 'polite');
    }
    
    if (this.elements.errorContainer) {
      this.elements.errorContainer.setAttribute('aria-live', 'assertive');
    }
  }
  
  // Main shortening function
  async handleShorten() {
    if (this.state.isLoading) return;
    
    const url = this.elements.urlInput?.value?.trim();
    
    // Validate input
    const validation = this.validateUrl(url);
    if (!validation.isValid) {
      this.showError(validation.error);
      this.elements.urlInput?.focus();
      return;
    }
    
    try {
      this.setLoading(true);
      this.clearMessages();
      
      const result = await this.shortenUrl(url);
      this.showResult(result);
      this.state.lastShortenedUrl = result.short_url;
      this.state.retryCount = 0;
      
    } catch (error) {
      this.handleError(error);
    } finally {
      this.setLoading(false);
    }
  }
  
  // Validate URL input
  validateUrl(url) {
    if (!url) {
      return { isValid: false, error: 'Please enter a URL to shorten' };
    }
    
    if (url.length < this.config.validation.minUrlLength) {
      return { isValid: false, error: 'URL is too short to be valid' };
    }
    
    if (url.length > this.config.validation.maxUrlLength) {
      return { isValid: false, error: `URL is too long (maximum ${this.config.validation.maxUrlLength} characters)` };
    }
    
    // Basic URL validation
    try {
      const urlObj = new URL(url);
      
      // Check protocol
      if (!this.config.validation.allowedProtocols.includes(urlObj.protocol)) {
        return { 
          isValid: false, 
          error: `Only ${this.config.validation.allowedProtocols.join(', ')} URLs are allowed` 
        };
      }
      
      // Check blocked domains
      if (this.config.validation.blockedDomains.includes(urlObj.hostname)) {
        return { isValid: false, error: 'This domain is not allowed' };
      }
      
      return { isValid: true };
      
    } catch (e) {
      return { isValid: false, error: 'Please enter a valid URL (e.g., https://example.com)' };
    }
  }
  
  // Validate input in real-time
  validateInput() {
    const url = this.elements.urlInput?.value?.trim();
    const validation = this.validateUrl(url);
    
    // Update input styling
    if (this.elements.urlInput) {
      if (url && !validation.isValid) {
        this.elements.urlInput.classList.add('invalid');
        this.elements.urlInput.setAttribute('aria-invalid', 'true');
      } else {
        this.elements.urlInput.classList.remove('invalid');
        this.elements.urlInput.setAttribute('aria-invalid', 'false');
      }
    }
  }
  
  // Call the API to shorten URL
  async shortenUrl(url) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.config.api.timeout);
    
    try {
      const response = await fetch(`${this.config.api.baseUrl}/shorten`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ url }),
        signal: controller.signal
      });
      
      clearTimeout(timeoutId);
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `Server error: ${response.status}`);
      }
      
      const data = await response.json();
      
      if (!data.short_url) {
        throw new Error('Invalid response from server');
      }
      
      return data;
      
    } catch (error) {
      clearTimeout(timeoutId);
      
      if (error.name === 'AbortError') {
        throw new Error('Request timed out. Please try again.');
      }
      
      throw error;
    }
  }
  
  // Handle errors with retry logic
  async handleError(error) {
    if (this.config.debug) {
      console.error('Shortening error:', error);
    }
    
    // Retry logic for network errors
    if (this.state.retryCount < this.config.api.retries && 
        (error.message.includes('fetch') || error.message.includes('network'))) {
      
      this.state.retryCount++;
      this.showError(`Network error. Retrying... (${this.state.retryCount}/${this.config.api.retries})`);
      
      // Exponential backoff
      const delay = Math.pow(2, this.state.retryCount) * 1000;
      await new Promise(resolve => setTimeout(resolve, delay));
      
      return this.handleShorten();
    }
    
    // Show final error
    let errorMessage = 'An unexpected error occurred. Please try again.';
    
    if (error.message.includes('timeout') || error.message.includes('timed out')) {
      errorMessage = 'Request timed out. Please check your connection and try again.';
    } else if (error.message.includes('network') || error.message.includes('fetch')) {
      errorMessage = 'Network error. Please check your connection and try again.';
    } else if (error.message.includes('Server error')) {
      errorMessage = 'Server is temporarily unavailable. Please try again later.';
    } else if (error.message) {
      errorMessage = error.message;
    }
    
    this.showError(errorMessage);
  }
  
  // Set loading state
  setLoading(isLoading) {
    this.state.isLoading = isLoading;
    
    if (this.elements.shortenBtn) {
      if (isLoading) {
        this.elements.shortenBtn.classList.add('loading');
        this.elements.shortenBtn.disabled = true;
        this.elements.shortenBtn.setAttribute('aria-busy', 'true');
      } else {
        this.elements.shortenBtn.classList.remove('loading');
        this.elements.shortenBtn.disabled = false;
        this.elements.shortenBtn.setAttribute('aria-busy', 'false');
      }
    }
  }
  
  // Show success result
  showResult(data) {
    if (!this.elements.resultContainer) return;
    
    const resultHtml = `
      <div class="result-success">
        <h3>✅ URL shortened successfully!</h3>
        <div class="result-urls">
          <div class="url-row">
            <label for="original-url">Original URL:</label>
            <div id="original-url" class="url-display original-url">${this.escapeHtml(data.original_url || this.elements.urlInput?.value)}</div>
          </div>
          <div class="url-row">
            <label for="short-url">Short URL:</label>
            <div class="short-url-container">
              <a id="short-url" href="${this.escapeHtml(data.short_url)}" 
                 class="result-url" target="_blank" rel="noopener noreferrer"
                 aria-label="Shortened URL, opens in new tab">${this.escapeHtml(data.short_url)}</a>
              ${this.config.features.copyToClipboard ? 
                `<button class="copy-btn" onclick="app.copyToClipboard('${this.escapeHtml(data.short_url)}')" 
                         aria-label="Copy short URL to clipboard">📋 Copy</button>` : ''}
            </div>
          </div>
        </div>
        <p class="result-note">Click the short URL to test it, or copy it to share!</p>
      </div>
    `;
    
    this.elements.resultContainer.innerHTML = resultHtml;
    this.elements.resultContainer.classList.add('show');
    this.elements.resultContainer.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    
    // Auto-hide result after delay (optional)
    if (this.config.ui.hideResultsDelay > 0) {
      setTimeout(() => {
        this.elements.resultContainer?.classList.remove('show');
      }, this.config.ui.hideResultsDelay);
    }
  }
  
  // Show error message
  showError(message) {
    if (!this.elements.errorContainer) return;
    
    this.elements.errorContainer.innerHTML = `
      <div class="error-content">
        <h3>❌ Error</h3>
        <p>${this.escapeHtml(message)}</p>
        <button class="error-dismiss" onclick="app.clearMessages()">Dismiss</button>
      </div>
    `;
    this.elements.errorContainer.classList.add('show');
  }
  
  // Clear all messages
  clearMessages() {
    this.elements.resultContainer?.classList.remove('show');
    this.elements.errorContainer?.classList.remove('show');
  }
  
  // Copy to clipboard functionality
  async copyToClipboard(text) {
    try {
      await navigator.clipboard.writeText(text);
      this.showCopySuccess();
    } catch (error) {
      // Fallback for older browsers
      const textArea = document.createElement('textarea');
      textArea.value = text;
      textArea.style.position = 'fixed';
      textArea.style.opacity = '0';
      document.body.appendChild(textArea);
      textArea.select();
      
      try {
        document.execCommand('copy');
        this.showCopySuccess();
      } catch (fallbackError) {
        this.showError('Could not copy to clipboard. Please copy manually.');
      } finally {
        document.body.removeChild(textArea);
      }
    }
  }
  
  // Show copy success feedback
  showCopySuccess() {
    const copyBtn = document.querySelector('.copy-btn');
    if (copyBtn) {
      const originalText = copyBtn.textContent;
      copyBtn.textContent = '✅ Copied!';
      copyBtn.classList.add('copied');
      
      setTimeout(() => {
        copyBtn.textContent = originalText;
        copyBtn.classList.remove('copied');
      }, this.config.ui.copySuccessDelay);
    }
  }
  
  // Utility function to escape HTML
  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
  
  // Public method to reset the form
  reset() {
    if (this.elements.urlInput) {
      this.elements.urlInput.value = '';
      this.elements.urlInput.classList.remove('invalid');
      this.elements.urlInput.setAttribute('aria-invalid', 'false');
    }
    this.clearMessages();
    this.state.lastShortenedUrl = null;
    this.state.retryCount = 0;
  }
}

// Initialize the application when DOM is ready
let app;

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    app = new UrlShortener();
  });
} else {
  app = new UrlShortener();
}

// Global functions for HTML onclick handlers
window.app = {
  copyToClipboard: (text) => app?.copyToClipboard(text),
  clearMessages: () => app?.clearMessages(),
  reset: () => app?.reset()
};

// Service Worker registration (for future PWA features)
if (UrlShortenerConfig.features.offlineSupport && 'serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then(registration => {
        if (UrlShortenerConfig.debug) {
          console.log('SW registered: ', registration);
        }
      })
      .catch(registrationError => {
        if (UrlShortenerConfig.debug) {
          console.log('SW registration failed: ', registrationError);
        }
      });
  });
}
