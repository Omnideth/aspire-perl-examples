# Duplicate Resource Installer Name Collision

## Summary
If two separate Aspire resources use the same `.WithPackage()` value, the generated installer resources can collide on name.

When this happens, Aspire detects duplicate resource names and fails to start the AppHost.

## Symptom
- `aspire start` fails during AppHost startup.
- Error indicates a duplicate resource name or resource registration conflict.

## Cause
Aspire generates installer-related resources from package metadata. If two independent resources resolve to the same installer resource name, the second registration conflicts with the first.

## Workaround
- Ensure each resource uses a unique package identity where installer resource naming is derived.
- If multiple resources need similar dependencies, avoid duplicating the exact same `.WithPackage()` statement in a way that produces the same installer resource name.

## Recommendation
Treat package-based installer resource naming as globally unique within a single AppHost model. If two resources require similar package setup, make the installer resource names distinct so Aspire can build the full graph without collisions.
