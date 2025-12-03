#!/bin/bash
echo "Building Flutter Web..."

BUILD_ARGS=""

# Function to add env var if it exists
add_env_var() {
  local var_name=$1
  local var_value=${!1}
  if [ -n "$var_value" ]; then
    BUILD_ARGS="$BUILD_ARGS --dart-define=$var_name=$var_value"
  fi
}

# Add all necessary environment variables
add_env_var "TEXT_API_KEY"
add_env_var "IMAGE_API_KEY"
add_env_var "FIREBASE_API_KEY"
add_env_var "FIREBASE_AUTH_DOMAIN"
add_env_var "FIREBASE_PROJECT_ID"
add_env_var "FIREBASE_STORAGE_BUCKET"
add_env_var "FIREBASE_MESSAGING_SENDER_ID"
add_env_var "FIREBASE_APP_ID"
add_env_var "FIREBASE_MEASUREMENT_ID"

echo "Running build with args: $BUILD_ARGS"
./flutter/bin/flutter build web --release $BUILD_ARGS
