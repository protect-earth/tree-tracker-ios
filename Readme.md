#  Tree Tracker
App for managing trees.

## Prerequisites

### Airtable setup
TBD...

### Cloudinary setup
Because Airtable doesn't support uploading images yet, we have to use an external provider to do so instead. We tried Imgur, but the API is really not user friendly due to its auth requisites. For now, we are using Cloudinary but it might change in the future.

1. Create a free account on [Cloudinary](https://cloudinary.com/users/register/free) (this will give you the needed Cloud name).
2. Now create an [upload preset](https://cloudinary.com/console/settings/upload) (this will give you the Upload Preset name).
3. Keep the keys as you'd need to add them to Secrets.xcconfig later on.

### Running the app from Xcode
1. Make sure you have downloaded Xcode 12.2+
2. Open the project in Xcode (you'll notice the dependencies will start to fetch in the background).
(In the meantime, Xcode will need to fetch dependencies for the project... 😴)
3. Now, to run the project, we'll need to generate Secrets file. This means you need to run first install `pouch` (the easiest is using `brew install sunshinejr/formulae/pouch`). Now, you need to have these environment variables:
```
AIRTABLE_API_KEY
AIRTABLE_BASE_ID
AIRTABLE_TREES_TABLE_NAME
AIRTABLE_SPECIES_TABLE_NAME
AIRTABLE_SUPERVISORS_TABLE_NAME
AIRTABLE_SITES_TABLE_NAME
CLOUDINARY_CLOUD_NAME
CLOUDINARY_UPLOAD_PRESET_NAME
```
Finally in the root folder run `pouch`, which should generate a file at `./TreeTracker/Secrets.swift`.
4. You'll most likely need to change bundle identifier of the project. Basically because the project is set to auto-sign, each person that wants to run this on the device would need to update the bundle to be a unique id not registered before. E.g. from `com.protect.earth.Tree-Tracker` to `com.mynickname.Tree-Tracker`.
5. When running on a device, you'll also need to trust the certificate in Settings -> General -> Profiles, otherwise you'll see an error after installing the build and before running it.

## Todo
- [ ] Show errors for when image upload fails (details should show when tapped on a tree cell).
- [ ] List of all trees should be grouped. It can be grouped by Site, but eventually it would be great to have a Group By button that would change the default grouping option.
- [ ] Better UI for editing tree details form
- [ ] Better UI for tree cells
- [ ] Edit uploaded tree
- [ ] Map picker when tapping on coordinates so we can adjust it
- [ ] Settings screen (enable/disable network fetching, credits for OSS & Icons)

## License
[MIT](License.md)
