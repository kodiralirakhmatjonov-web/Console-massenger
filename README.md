Console App Store Connect propagation/retry patch

- Keeps Bundle ID: com.console.beta
- Verifies the exact App Store Connect app record via API before building
- Waits up to 10 minutes if the newly-created app record has not propagated yet
- Retries only the specific transient Xcode error: Error Downloading App Information
- Preserves cloud-managed signing and unique build numbers
- Upload diagnostics now includes export-upload.log
