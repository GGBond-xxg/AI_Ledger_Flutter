# Biometric unlock loop fix

This version prevents Android fingerprint / iOS Face ID dialogs from retriggering the app lock lifecycle repeatedly.

Key changes:
- Biometric prompt lifecycle transitions are ignored by the privacy snapshot lock.
- Successful unlock has a short grace window to avoid immediate relock on resume.
- `stickyAuth` is disabled to avoid repeated system prompt loops.
