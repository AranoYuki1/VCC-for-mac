# Release Checklist

This is the procedure for doing a release.



## Update the project 

1. Update the project version from Xcode's project pane.

   Update both Version and Build (Sparkle seems to be referring to the `build`.)



## Archive

1. Archive the app in Xcode.
2. Notarize the app. (Use Distribute App > Developer ID)
3. Export notarized app, and archive it into zip.



## appcast

In this section you should use terminal.

1. Change directory to project root.
2. Remove existing appcasts and archives in  `docs/sparkle`.
3. Place the app archive in  `docs/sparkle`.
4. Run `generate_appcast docs/sparkle`  to create appcast.



## GitHub (appcast)

In this section you should use terminal.

1. `git add .` to add files
2. `git commit -m [version]` to create commit.
3. `git push` to upload it.
4. If needed, create `release-note.html` for Sparkle update.



## GitHub (relase)

1. Create a tag for the release and push that tag.

   ```
   git tag [version]
   git push origin [version]
   ```

   

2. Create a Github release page.

3. Upload app archive as attached files.



END!!!









****
