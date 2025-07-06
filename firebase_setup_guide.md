# Firebase Setup Guide for Technician Management

This guide will help you set up your Firebase Firestore database for storing and managing technician data in your FixIt app.

## Database Structure

The app uses the following collections and documents:

- `technicians` - Collection for storing technician information
  - Each document represents a technician with the following fields:
    - `name` (string) - The technician's full name
    - `email` (string) - The technician's email address
    - `phone` (string) - The technician's contact phone number
    - `specialty` (string) - The technician's specialty area (e.g., Plumbing, Electrical)
    - `jobs` (number) - Count of completed jobs
    - `rating` (number) - Average rating (0.0-5.0)
    - `available` (boolean) - Whether the technician is currently available for jobs

## Firestore Security Rules

Add the following security rules to your Firebase console (Firebase Console > Firestore Database > Rules):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Check if user is admin (admin1@gmail.com)
    function isAdmin() {
      return isAuthenticated() && 
             request.auth.token.email == 'admin1@gmail.com';
    }

    // Technicians collection rules
    match /technicians/{technicianId} {
      // Only admin can create, update, delete technicians
      allow create, update, delete: if isAdmin();
      
      // Admin can read all technician data
      // Regular users can only read basic technician info
      allow read: if isAuthenticated();
    }
  }
}
```

## Setting Up Firebase in the App

1. Make sure you have the following dependencies in your `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^2.24.2
     firebase_auth: ^4.15.3
     cloud_firestore: ^4.13.6
   ```

2. Run `flutter pub get` to install the dependencies.

3. Make sure your Firebase project is correctly set up in your app using the Firebase CLI or FlutterFire CLI.

## Testing the Technician Management

1. Log in with the admin email (admin1@gmail.com).
2. Navigate to the Technicians page.
3. Add a new technician using the "+" button.
4. Fill in the required fields and select a specialty from the dropdown.
5. The technician should appear in the list.
6. Try editing and deleting technicians to ensure CRUD operations work correctly.

## Troubleshooting

- If you see permission errors, check that you're logged in as the admin user.
- If technicians aren't loading, check your Firestore rules and ensure the collection path is correct.
- For other Firebase-related issues, check the debug console logs for detailed error messages. 