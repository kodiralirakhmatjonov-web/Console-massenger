# Console GitHub unpack bots

Upload these YAML files manually to:

`.github/workflows/`

## 1. console-auto-unpack.yml

Main workflow.

Upload exactly one update ZIP to the repository root with a name such as:

`console-update-001.zip`

The workflow will:

1. detect the ZIP;
2. safely extract it;
3. automatically remove one wrapper folder if present;
4. overlay the update onto the repository;
5. protect `.git` and `.github/workflows/`;
6. optionally process `.console-delete`;
7. delete the uploaded ZIP from repository root;
8. commit the extracted files;
9. push the commit back to the same branch.

### Optional deletion support

If an update needs to remove old files, include a text file named:

`.console-delete`

at the root of the ZIP contents.

Example:

```text
lib/old_screen.dart
assets/old_logo.png
server/obsolete
```

Protected Git/workflow paths cannot be deleted.

## 2. console-manual-unpack.yml

Backup/manual workflow.

Use GitHub:

`Actions → Console — Manual Unpack Update → Run workflow`

Enter the exact ZIP filename already present in the repository root.

This is useful if an update ZIP has a custom name or the automatic workflow needs to be rerun manually.

## Important

These workflows ONLY unpack and commit updates.

Cloudflare deployment and TestFlight deployment should be separate workflows so an unpacking failure cannot accidentally trigger a broken production/mobile deployment.
