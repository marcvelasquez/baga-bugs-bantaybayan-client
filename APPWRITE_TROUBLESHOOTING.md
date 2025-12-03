# Appwrite Connection Error - Troubleshooting Guide

## Current Error
```
AppwriteException: general_access_forbidden, Project is not accessible in this region (401)
```

## Your Current Configuration
- **Endpoint**: `https://sgp.cloud.appwrite.io/v1`
- **Project ID**: `baga-bugs`
- **Database ID**: `692fe40600109e7d2fd3`
- **Collection ID**: `users`

---

## Possible Causes & Solutions

### 1. ⚠️ Project ID Format Issue

Your project ID `baga-bugs` looks like a custom name, but Appwrite typically uses longer IDs like `676xxxxxxxxxxxxx`.

**Solution:**
1. Go to your Appwrite Console: https://cloud.appwrite.io
2. Select your project
3. Go to **Settings**
4. Look for **Project ID** - it should be a long alphanumeric string, NOT just "baga-bugs"
5. Copy the ACTUAL Project ID and update `lib/core/config/appwrite_config.dart`

### 2. 🌐 Wrong Endpoint Region

You're using `https://sgp.cloud.appwrite.io/v1` (Singapore region).

**Check if this is correct:**
1. In Appwrite Console → Settings
2. Look for the **API Endpoint** or **Region**
3. Common endpoints:
   - `https://cloud.appwrite.io/v1` (Global/US)
   - `https://eu.cloud.appwrite.io/v1` (Europe)
   - `https://sgp.cloud.appwrite.io/v1` (Singapore)

**If different, update the endpoint in the config file.**

### 3. 🔐 Platform Not Registered (Android)

Appwrite requires platform registration for Android apps.

**Solution:**
1. In Appwrite Console → your project
2. Go to **Settings** → **Platforms**
3. Click **Add Platform** → **Android**
4. Enter your package name: `com.bagabugs.bantaybayan`
5. You can leave other fields empty for development
6. **Save**

### 4. ❌ Database/Collection Doesn't Exist

Your database ID `692fe40600109e7d2fd3` might be wrong.

**Verify:**
1. In Appwrite Console → **Databases**
2. Check if a database exists with ID: `692fe40600109e7d2fd3`
3. Inside that database, verify there's a collection named `users`
4. If not, create them following the APPWRITE_SETUP.md guide

### 5. 🔒 Collection Permissions Not Set

Even if the collection exists, it needs proper permissions.

**Fix Permissions:**
1. Go to Databases → `bagabugs_db` (or your database)
2. Click on `users` collection
3. Go to **Settings** → **Permissions**
4. Add these permissions:
   ```
   Read: Any
   Create: Any
   Update: Users
   Delete: Users
   ```
   OR for development (less secure):
   ```
   All permissions: Any
   ```

### 6. 🔑 API Key Issue (Less Likely)

If using API keys (not recommended for client apps):
- Ensure the API key has proper scopes
- Client apps should use anonymous/email sessions, not API keys

---

## Quick Test Steps

1. **Verify Project ID is correct** (most common issue)
   - Should be long like `676fa1b2c3d4e5f6g7h8`
   - NOT just `baga-bugs`

2. **Add Android Platform**
   - Settings → Platforms → Add Android
   - Package: `com.bagabugs.bantaybayan`

3. **Check Database Exists**
   - Databases → Look for `692fe40600109e7d2fd3`
   - Or create a new one named `bagabugs_db`

4. **Set Permissions to "Any" (for testing)**
   - Collection Settings → Permissions
   - Set all to "Any" temporarily

5. **Restart the app**
   ```bash
   flutter run
   ```

---

## Still Not Working?

Run these commands to see detailed logs:
```bash
flutter run --verbose
```

Look for lines starting with:
- `✓ Appwrite initialized with endpoint:`
- `❌ Appwrite Error`

The detailed error will show exactly what's wrong.

---

## Example of Correct Configuration

```dart
class AppwriteConfig {
  static const String endpoint = 'https://cloud.appwrite.io/v1';  // ← Verify region
  static const String projectId = '676fa1b2c3d4e5f6g7h8';  // ← Long ID, not 'baga-bugs'
  static const String databaseId = '692fe40600109e7d2fd3';
  static const String usersCollectionId = 'users';
}
```
