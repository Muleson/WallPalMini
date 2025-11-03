# Apple App Site Association (AASA) Configuration

## What is AASA?
The Apple App Site Association file tells iOS which URLs should open your app instead of Safari. This file must be hosted on your web server.

## File Location
The file **must** be accessible at:
```
https://crahg.app/.well-known/apple-app-site-association
```

Alternative location (legacy):
```
https://crahg.app/apple-app-site-association
```

## File Requirements
- ✅ Must be served over **HTTPS**
- ✅ Must be valid JSON
- ✅ Must have content type: `application/json` or no content type
- ✅ Must be accessible without authentication
- ✅ Must be at root domain (not subdomain)
- ❌ No .json extension (just `apple-app-site-association`)
- ❌ No redirects

## AASA File Content

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.samquested.grigrimvp",
        "paths": [
          "/events/*",
          "/gyms/*",
          "/home",
          "/passes",
          "/whats-on"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "TEAMID.com.samquested.grigrimvp"
    ]
  }
}
```

## Configuration Steps

### 1. Replace TEAMID
Find your Team ID:
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Click on "Membership"
3. Copy your "Team ID"
4. Replace `TEAMID` in the AASA file

Example:
```json
"appID": "ABC123XYZ.com.samquested.grigrimvp"
```

### 2. Upload to Web Server

#### For Next.js (crahg-web):
Create file at: `public/.well-known/apple-app-site-association`

```javascript
// next.config.js
module.exports = {
  async headers() {
    return [
      {
        source: '/.well-known/apple-app-site-association',
        headers: [
          {
            key: 'Content-Type',
            value: 'application/json',
          },
        ],
      },
    ];
  },
};
```

#### For Static Hosting:
1. Create directory: `.well-known`
2. Create file: `apple-app-site-association` (no extension)
3. Upload to root of domain
4. Configure server to serve with JSON content type

### 3. Verify AASA File
Use online validator:
- [Branch AASA Validator](https://branch.io/resources/aasa-validator/)
- Enter: `https://crahg.app`

Or test manually:
```bash
curl -v https://crahg.app/.well-known/apple-app-site-association
```

Expected response:
- Status: 200 OK
- Content-Type: application/json (or empty)
- Body: Valid JSON

## Path Patterns

### Exact Match
```json
"paths": ["/home"]
```
Matches: `https://crahg.app/home`

### Wildcard Match
```json
"paths": ["/events/*"]
```
Matches:
- `https://crahg.app/events/123`
- `https://crahg.app/events/abc-def`
- `https://crahg.app/events/anything`

### NOT Match (Exclusion)
```json
"paths": ["/events/*", "NOT /events/admin"]
```
Matches: `https://crahg.app/events/123`
Excludes: `https://crahg.app/events/admin`

### Query Parameters
Query parameters are ignored:
```json
"paths": ["/events/*"]
```
Matches:
- `https://crahg.app/events/123`
- `https://crahg.app/events/123?utm_source=twitter`

## Testing

### 1. Deploy AASA File
Upload to your web server at the correct location.

### 2. Verify Accessibility
```bash
curl https://crahg.app/.well-known/apple-app-site-association
```

### 3. Reinstall App
iOS caches AASA during app installation:
1. Delete app from device
2. Rebuild and install
3. iOS will fetch AASA file

### 4. Test Deep Link
Method 1 - Notes:
1. Open Notes app
2. Type: `https://crahg.app/events/event-123`
3. Tap the link
4. App should open (not Safari)

Method 2 - Safari:
1. Open Safari
2. Navigate to: `https://crahg.app/events/event-123`
3. You may see "Open in App" banner
4. Or app opens automatically

### 5. Check Device Logs
```bash
# Connect device
# Open Console.app
# Filter: swcd
# Look for: "Associated Domains"
```

Successful output:
```
swcd: Allowing app com.samquested.grigrimvp to handle crahg.app
```

## Troubleshooting

### Issue: Links Open in Safari
**Cause**: AASA file not found or invalid

**Solutions**:
1. Verify AASA URL is accessible
2. Check JSON is valid
3. Ensure HTTPS (not HTTP)
4. Verify Team ID is correct
5. Reinstall app (delete first)
6. Wait up to 24 hours for CDN propagation

### Issue: 404 Not Found
**Cause**: File not at correct location

**Solutions**:
1. Check file path: `/.well-known/apple-app-site-association`
2. Verify file name (no extension)
3. Check server configuration
4. Test with curl

### Issue: Wrong Content Type
**Cause**: Server serving as text/plain

**Solutions**:
1. Configure server headers
2. Set Content-Type: `application/json`
3. Or remove Content-Type header entirely
4. Don't use `text/html` or `text/plain`

### Issue: Works in Simulator but Not Device
**Cause**: Device AASA cache

**Solutions**:
1. Delete app completely
2. Reinstall fresh
3. Wait a few minutes
4. Restart device
5. Check device has internet connection

### Issue: Team ID Mismatch
**Cause**: Wrong Team ID in AASA

**Solutions**:
1. Double-check Team ID from Apple Developer Portal
2. Format: `TEAMID.com.samquested.grigrimvp`
3. Update AASA file
4. Reinstall app

## Advanced Configuration

### Multiple Domains
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.samquested.grigrimvp",
        "paths": ["/events/*", "/gyms/*"]
      }
    ]
  }
}
```

Host AASA on:
- `https://crahg.app/.well-known/apple-app-site-association`
- `https://www.crahg.app/.well-known/apple-app-site-association`
- `https://beta.crahg.app/.well-known/apple-app-site-association`

Add to entitlements:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:crahg.app</string>
    <string>applinks:www.crahg.app</string>
    <string>applinks:beta.crahg.app</string>
</array>
```

### Environment-Specific
Development:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.samquested.grigrimvp.dev",
        "paths": ["/*"]
      }
    ]
  }
}
```

Production:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.samquested.grigrimvp",
        "paths": ["/events/*", "/gyms/*"]
      }
    ]
  }
}
```

## Maintenance

### When to Update AASA
- Adding new deep linkable content types
- Changing URL structure
- Adding/removing path patterns
- Changing bundle identifier
- Changing Team ID

### Update Process
1. Modify AASA file
2. Upload to web server
3. Verify accessibility
4. Test with validator
5. Users will get updates automatically (24-48hr cache)
6. For immediate update: reinstall app

## Security Notes

1. **HTTPS Only**: HTTP will not work
2. **No Authentication**: File must be public
3. **Validate Input**: Always validate IDs from URLs in app
4. **Rate Limiting**: Protect your APIs from abuse
5. **Sensitive Data**: Don't expose private info in URLs

## Resources

- [Apple Universal Links Docs](https://developer.apple.com/ios/universal-links/)
- [AASA Validator](https://branch.io/resources/aasa-validator/)
- [Search Console - Associated Domains](https://search.developer.apple.com/appsearch-validation-tool/)
- [Apple CDN Status](https://app-site-association.cdn-apple.com/)
