# Parents Feature

This feature handles parent user profiles and data storage.

## Setup Instructions

1. You've already created the parents collection in Appwrite database with the following attributes:
   - `name` (string, required) - Stores the parent's name from the profile form
   - `username` (string, required)
   - `dob` (datetime, optional)
   - `email` (string, optional)
   - `avatar_url` (string, optional)
   - `kids` (string array, optional)

2. Update the `parentsCollectionId` constant in `parents_repository.dart` with the actual collection ID from your Appwrite.

3. The collection should have appropriate permissions:
   - Read: Any authenticated user
   - Write: Any authenticated user (for their own document)