#  Tree Tracker

# Running the app
## Prerequisites

### Airtable setup
TBD...

### Cloudinary setup
Because Airtable doesn't support uploading images yet, we have to use an external provider to do so instead. We tried Imgur, but the API is really not user friendly due to its auth requisites. For now, we are using Cloudinary but it might change in the future.

1. Create a free account on [Cloudinary](https://cloudinary.com/users/register/free) (this will give you the needed Cloud name).
2. Now create an [upload preset](https://cloudinary.com/console/settings/upload) (this will give you the Upload Preset name).
3. Keep the keys as you'd need to add them to Secrets.xcconfig later on.

## Running from Xcode
1. Make sure you have downloaded Xcode 12.2+
2. Open the project in Xcode (you'll notice the dependencies will start to fetch in the background).
(In the meantime, Xcode will need to fetch dependencies for the project... 😴)
3. Now, to run the project, you'll need to create a file named `Secrets.xcconfig` in `__REPO_ROOT__/Tree Tracker/` directory (it should have the Info.plist file in there). This file needs to have a few of the secret api keys needed for this to work. Schema for the file looks like this:
```
AIRTABLE_API_KEY = yourKey123
AIRTABLE_BASE_ID = appNiceTree
AIRTABLE_TREES_TABLE_NAME = Trees Planted
CLOUDINARY_CLOUD_NAME = qqq2ek4mq
CLOUDINARY_UPLOAD_PRESET_NAME = iadfadff
```
The file is ignored in git since we do not want to store these in the repository itself.
4. You'll most likely need to change bundle identifier of the project. Basically because the project is set to auto-sign, each person that wants to run this on the device would need to update the bundle to be a unique id not registered before. E.g. from `com.sunshinejr.Tree-Tracker` to `com.mynickname.Tree-Tracker`.
5. When running on a device, you'll also need to trust the certificate in Settings -> General -> Profiles, otherwise you'll see an error after installing the build and before running it.

# Todo
- [x] Use Airtable's thumbnails for Uploaded Trees view
- [ ] Better UI for editing tree details form
- [ ] Better UI for tree cells
- [ ] Progress indicator for uploads
- [ ] Stop button for uploads
- [ ] Map picker when tapping on coordinates so we can adjust it

# License
[MIT](License.md)
