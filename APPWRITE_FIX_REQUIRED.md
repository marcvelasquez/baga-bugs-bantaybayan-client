# 🚨 ACTION REQUIRED: Configure Appwrite

Your app cannot connect to Appwrite because the project configuration is missing.

## Steps to Fix:

### 1. Get Your Appwrite Project Details

1. Go to **https://cloud.appwrite.io** and log in
2. Select your project (or create a new one if needed)
3. Go to **Settings** in the left sidebar
4. Copy your **Project ID** (it looks like: `6748a1b2c3d4e5f6g7h8`)
5. Note your **API Endpoint** (usually `https://cloud.appwrite.io/v1`)

### 2. Update the Configuration File

Open this file:
```
lib/core/config/appwrite_config.dart
```

Replace these lines:
```dart
static const String endpoint = 'https://cloud.appwrite.io/v1';
static const String projectId = 'YOUR_PROJECT_ID_HERE';
```

With your actual values:
```dart
static const String endpoint = 'https://cloud.appwrite.io/v1';  // Your endpoint
static const String projectId = '6748a1b2c3d4e5f6g7h8';  // Your actual project ID
```

### 3. Set Up Your Database (if not done)

In your Appwrite console:

1. Go to **Databases** → Create a database named `bagabugs_db`
2. Inside the database, create a collection named `users`
3. Add these attributes to the collection:

   | Attribute | Type | Size | Required |
   |-----------|------|------|----------|
   | user_id | String | 255 | ✓ |
   | full_name | String | 255 | ✓ |
   | phone_number | String | 50 | ✓ |
   | gender | String | 20 | ✓ |
   | birthday | String | 50 | ✓ |
   | age | Integer | - | ✓ |
   | created_at | String | 50 | ✓ |

4. Set collection permissions:
   - Read: `users` (any authenticated user)
   - Create: `users` (any authenticated user)
   - Update: `users` (any authenticated user)

### 4. Enable Authentication

In your Appwrite console:
1. Go to **Auth** → **Settings**
2. Enable **Anonymous Sessions** (required for the current auth flow)

### 5. Test

After updating the config:
```bash
flutter run
```

You should see in the console:
```
✓ Appwrite initialized with endpoint: https://cloud.appwrite.io/v1
✓ Project ID: your-project-id
```

---

## Current Error Explained

The error you're seeing:
```
AppwriteException: general_access_forbidden, Project is not accessible in this region
```

This means:
- ❌ The project ID is invalid or doesn't exist
- ❌ The endpoint URL doesn't match your project's region
- ❌ The project may have been deleted

Once you update the configuration with correct values, this error will be resolved.
