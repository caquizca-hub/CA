# ca

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Vercel Deployment

### Environment Variables

When deploying to Vercel, go to **Settings > Environment Variables** and add the following keys:

| Key | Value | Description |
|-----|-------|-------------|
| `TEXT_API_KEY` | `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` | API Key for text generation (OpenRouter) |
| `IMAGE_API_KEY` | `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` | API Key for image generation (OpenRouter) |
| `FIREBASE_API_KEY` | `AIzaSyAzVUzRTU-EBlZcN43-FzWVQc-L7rhJzIA` | Firebase API Key |
| `FIREBASE_AUTH_DOMAIN` | `ca-quizz-104ab.firebaseapp.com` | Firebase Auth Domain |
| `FIREBASE_PROJECT_ID` | `ca-quizz-104ab` | Firebase Project ID |
| `FIREBASE_STORAGE_BUCKET` | `ca-quizz-104ab.firebasestorage.app` | Firebase Storage Bucket |
| `FIREBASE_MESSAGING_SENDER_ID` | `552806970314` | Firebase Messaging Sender ID |
| `FIREBASE_APP_ID` | `1:552806970314:web:3e765feb650fa7a811d533` | Firebase App ID |
| `FIREBASE_MEASUREMENT_ID` | `G-E1VC1RR529` | Firebase Measurement ID |

These keys are required for the AI features to work correctly in the production build.
