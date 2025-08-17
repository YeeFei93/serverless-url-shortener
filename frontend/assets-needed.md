# Favicon and Static Assets

Since we can't generate actual image files in this environment, here are the assets you should add to complete the frontend:

## Required Assets:

### 1. favicon.ico
Create a simple favicon with a link/chain icon. You can use:
- Online favicon generators like favicon.io
- Or use an emoji-based favicon: 🔗

### 2. apple-touch-icon.png (180x180)
Apple touch icon for iOS devices showing the app icon on home screen

### 3. manifest.json (for PWA features)
```json
{
  "name": "URL Shortener",
  "short_name": "URL Short",
  "description": "A simple, fast URL shortener service",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#0066cc",
  "icons": [
    {
      "src": "icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icon-512.png", 
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

## Instructions:

1. **Favicon**: 
   - Go to https://favicon.io/emoji-favicons/link/
   - Download the generated favicon package
   - Place favicon.ico in the frontend/ folder

2. **Apple Touch Icon**:
   - Create a 180x180 PNG with your logo/icon
   - Name it apple-touch-icon.png

3. **Progressive Web App Icons**:
   - Create 192x192 and 512x512 PNG icons
   - Add manifest.json to enable PWA features

4. **Optional Enhancements**:
   - Add og:image meta tag with a social sharing image
   - Add structured data for better SEO
   - Add robots.txt if needed
