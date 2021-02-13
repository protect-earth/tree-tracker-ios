#  Tree Tracker

## Next
- Fix changing/showing tabbar item name for queue (the idea was to hide names for now).
- Added new view for camera session flow (take a photo -> add details -> take another one...)
- Added rounding precision (5) for coordinates
- Upload list is now sorted by `createdDate` if possible (descending)

## 0.3.0
- When uploading, we will now disable screen lock timer and enable it back on after the upload finishes/errors out.
- Added delete all button to Upload Queue view - prompts with alert to confirm deleting all items from the queue and proceeds to do so when confirmed.

## 0.2.1
- Disabled longpress actions on textfields without caret (paste etc.)
- When adding a tree, add additional "--" field in keyboard picker when you don't want to select a Specie/Supervisor/Site yet.

## 0.2.0
- Added count of trees to upload on the list.
- Added ability to remove trees from the upload list (edit tree -> trash icon).
- Supervisors and Species now open a selection picker as a keyboard since we're using identifiers to other tables instead of pure strings for these fields.
- Added fetching of Supervisors/Species/Sites from Airtable tables once the app launches and it's refreshing with trees once Refresh button is tapped on List view. 
- Added Site to the edit/add tree modal (with selection picker and caching, similar to Supervisors/Species).
- Fixed progress bar & button state when image upload errored out.
- Fixed Save button glitch that would show loading spinner underneath the title.

## 0.1.0
- Upload queue that uploads an image on an image server (currently Cloudinary) and then creates a record on Airtable.
- Adding of images and filling the details like coordinates from the asset metadata (with option to add typed Supervisor/Species).
- List of all trees on the server (Uploaded Trees).
