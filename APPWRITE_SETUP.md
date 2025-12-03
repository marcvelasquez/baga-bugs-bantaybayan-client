# BagaBugs - Appwrite Setup Guide

## Overview
This guide will help you set up Appwrite for the BantayBayan (BagaBugs) project to handle user authentication and data storage.

## Prerequisites
- Appwrite Cloud account (https://cloud.appwrite.io)
- Flutter project setup

## Step 1: Create Appwrite Project

1. **Sign up/Login to Appwrite Cloud**
   - Go to https://cloud.appwrite.io
   - Create an account or login
   - Create a new project named "BagaBugs"

2. **Get Project Details**
   - Copy your Project ID from the project dashboard
   - You'll need this for the app configuration

## Step 2: Configure Authentication

1. **Enable Email/Password Authentication**
   - Go to "Auth" section in your Appwrite console
   - Enable "Email/Password" provider
   - Configure settings as needed

## Step 3: Create Database and Collection

1. **Create Database**
   - Go to "Databases" section
   - Create a new database with ID: `bagabugs_db`
   - Name: "BagaBugs Database"

2. **Create Users Collection**
   - Inside the database, create a new collection
   - Collection ID: `users`
   - Name: "Users"

3. **Configure Collection Attributes**
   Add the following attributes to the `users` collection:

   | Attribute Name | Type | Size | Required | Array | Default |
   |---------------|------|------|----------|-------|---------|
   | user_id | String | 255 | Yes | No | - |
   | full_name | String | 255 | Yes | No | - |
   | phone_number | String | 50 | Yes | No | - |
   | gender | String | 20 | Yes | No | - |
   | birthday | String | 50 | Yes | No | - |
   | age | Integer | - | Yes | No | - |
   | created_at | String | 50 | Yes | No | - |

4. **Set Collection Permissions**
   - Add the following permissions:
   - **Create**: `users` (logged-in users can create)
   - **Read**: `users` (logged-in users can read)
   - **Update**: `users` (logged-in users can update)
   - **Delete**: `users` (logged-in users can delete)

## Step 4: Configure App

1. **Update AuthService Configuration**
   Open `lib/services/auth_service.dart` and replace:
   ```dart
   static const String _projectId = 'YOUR_PROJECT_ID';
   ```
   With your actual Appwrite project ID:
   ```dart
   static const String _projectId = 'your-actual-project-id-here';
   ```

2. **Update Platform Settings (Optional)**
   For production, you may want to configure platform-specific settings in Appwrite:
   - Go to "Settings" → "Platforms"
   - Add your app's package name for Android
   - Add your app's bundle ID for iOS

## Step 5: Test the Integration

1. **Run the App**
   ```bash
   flutter pub get
   flutter run
   ```

2. **Test User Registration**
   - Open the app
   - Try registering a new user
   - Check the Appwrite console to see if the user and data are created

3. **Test User Login**
   - Try logging in with the registered credentials
   - Verify that the profile dropdown shows user information

## Security Configuration

### Production Considerations

1. **API Keys**: Never expose API keys in client-side code
2. **Permissions**: Review and tighten collection permissions as needed
3. **Rate Limiting**: Configure rate limits in Appwrite settings
4. **SSL**: Ensure SSL is properly configured

### Environment Configuration

For different environments (development, staging, production), you can:

1. Create separate Appwrite projects
2. Use environment variables or configuration files
3. Update the project ID based on the build environment

## Database Schema

### Users Collection Structure
```json
{
  "user_id": "unique_user_id_from_appwrite_auth",
  "full_name": "John Doe",
  "phone_number": "+1234567890",
  "gender": "Male",
  "birthday": "1990-01-01T00:00:00.000Z",
  "age": 34,
  "created_at": "2024-12-03T10:30:00.000Z"
}
```

## API Usage

### User Registration
```dart
await authService.register(
  fullName: "John Doe",
  phone: "+1234567890",
  gender: "Male",
  birthday: DateTime(1990, 1, 1),
);
```

### User Login
```dart
await authService.login(phone: "+1234567890");
```

### Get User Data
```dart
final userData = await authService.getUserData();
```

### Logout
```dart
await authService.logout();
```

## Troubleshooting

### Common Issues

1. **"Project not found" error**
   - Check that your project ID is correct
   - Ensure the project exists in your Appwrite account

2. **Permission denied errors**
   - Verify collection permissions are set correctly
   - Check that the user is authenticated

3. **Network errors**
   - Ensure device has internet connection
   - Check Appwrite endpoint URL

4. **Authentication errors**
   - Verify email/password provider is enabled
   - Check user credentials

### Debug Mode

To enable debug mode, you can add logging to the AuthService:
```dart
// Add this to catch and log errors
catch (e) {
  print('Error details: $e');
  debugPrint('Full error: ${e.toString()}');
  rethrow;
}
```

## Support

For additional help:
- Appwrite Documentation: https://appwrite.io/docs
- Appwrite Community: https://discord.gg/appwrite
- Flutter Documentation: https://docs.flutter.dev