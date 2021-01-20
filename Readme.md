#  Tree Tracker

## Getting this to run
1. Make sure you have downloaded Xcode 12.2+
2. Open the project in Xcode (you'll notice the dependencies will start to fetch in the background).
3. Now to run the project you'll need to create a file named `Secrets.xcconfig` in `__REPO_ROOT__/Tree Tracker/` directory (it should have the Info.plist file in there). This file needs to have a few of the secret api keys needed for this to work. Schema for the file looks like this:
```
AIRTABLE_API_KEY = yourKey123
AIRTABLE_BASE_ID = appNiceTree
AIRTABLE_TREES_TABLE_NAME = Trees Planted
IMGUR_CLIENT_ID = 47blablabla325
```
The file is ignored in git since we do not want to store these in the repository itself.
4. You'll most likely need to change bundle identifier of the project. Basically because the project is set to auto-sign, each person that wants to run this on the device would need to update the bundle to be a unique id not registered before. E.g. from `com.sunshinejr.Tree-Tracker` to `com.mynickname.Tree-Tracker`.
5. When running on a device, you'll also need to trust the certificate in Settings -> General -> Profiles, otherwise you'll see an error after installing the build and before running it.

# License
[MIT](License.md)
