#!/bin/bash
echo "Building Flutter Web..."

BUILD_ARGS=""

if [ -n "$TEXT_API_KEY" ]; then
  BUILD_ARGS="$BUILD_ARGS --dart-define=TEXT_API_KEY=$TEXT_API_KEY"
fi

if [ -n "$IMAGE_API_KEY" ]; then
  BUILD_ARGS="$BUILD_ARGS --dart-define=IMAGE_API_KEY=$IMAGE_API_KEY"
fi

./flutter/bin/flutter build web --release $BUILD_ARGS
