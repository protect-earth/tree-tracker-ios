#  Tree Tracker

## 0.2.0
- Added count of trees to upload on the list.
- Added ability to remove trees from the upload list (edit tree -> trash icon)
- Supervisors and Species now open a selection picker as a keyboard since we're using identifiers to other tables instead of pure strings for these fields.
- Added fetching of Supervisors/Species/Sites from Airtable tables once the app launches and it's refreshing with trees once Refresh button is tapped on List view. 
- Added Site to the edit/add tree modal (with selection picker and caching, similar to Supervisors/Species).
- Fixed progress bar & button state when image upload errored out.
- Fixed Save button glitch that would show loading spinner underneath the title.

## 0.1.0
- Upload queue that uploads an image on an image server (currently Cloudinary) and then creates a record on Airtable
- Adding of images and filling the details like coordinates from the asset metadata (with option to add typed Supervisor/Species)
- List of all trees on the server (Uploaded Trees)
