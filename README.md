#  Tree Tracker
App for managing trees.

## Prerequisites

### Airtable tables
Our current API type expects that you have 4 tables:

#### Trees Planted
| ID | Notes | Image | Species | Supervisor | Sites | Coordinates | What3Words | CreatedDate | UploadedDate | ImageSignature |
| - | - | - | - | - | - | - | - | - | - | - |
| Auto Number | Long text | Attachment | Link to Species table  | Link to Supervisors table | Link to Sites table | Text | Text | Date and time | Date and time | Text |
| number | string | array of attachment objects | array of record IDs (strings) | array of record IDs (strings) | array of record IDs (strings) | string | string | string (ISO 8601 formatted date) | string (ISO 8601 formatted date) | string |

#### Species
_(notice there is no "ID" field - this is because we use the auto-generated ID through Airtable, the "ID" in the column above is a custom Auto Number field added manually)_
| Name |
| - |
| Long text |
| Long text |

#### Supervisors
_(the same structure as above)_
| Name |
| - |
| Long text |
| Long text |

#### Sites
_(the same structure as above)_
| Name |
| - |
| Long text |
| Long text |

### Cloudinary setup
Because Airtable doesn't support uploading images yet, we have to use an external provider to do so instead. We tried Imgur, but the API is really not user friendly due to its auth requisites. For now, we are using Cloudinary but it might change in the future.

1. Create a free account on [Cloudinary](https://cloudinary.com/users/register/free) (this will give you the needed Cloud name).
2. Now create an [upload preset](https://cloudinary.com/console/settings/upload) (this will give you the Upload Preset name).
3. Keep the keys as you'd need to add them to Secrets.xcconfig later on.

### Running the app from Xcode
1. Make sure you have downloaded Xcode 12.2+
2. Open the project in Xcode (you'll notice the dependencies will start to fetch in the background).
(In the meantime, Xcode will need to fetch dependencies for the project... 😴)
3. Now, to run the project, we'll need to generate Secrets file. This means you need to run first install [`pouch`](https://github.com/sunshinejr/pouch) (the easiest is using `brew install sunshinejr/formulae/pouch`). Now, you need to have these environment variables available. Have this at the end of the file (bash: most likely in `.bash_profile` or `.bashrc`, zsh: most likely `.zshenv` or `.zshrc`):
```
export AIRTABLE_API_KEY=yourKey123
export AIRTABLE_BASE_ID=appNiceTree
export AIRTABLE_TREES_TABLE_NAME="Trees Planted"
export AIRTABLE_SPECIES_TABLE_NAME=Species
export AIRTABLE_SUPERVISORS_TABLE_NAME=Supervisors
export AIRTABLE_SITES_TABLE_NAME=Sites
export CLOUDINARY_CLOUD_NAME=qqq2ek4mq
export CLOUDINARY_UPLOAD_PRESET_NAME=iadfadff
```
Finally, in the root folder, run `pouch`, which should generate a file at `./TreeTracker/Secrets.swift`.

4. You'll most likely need to change bundle identifier of the project. Basically because the project is set to auto-sign, each person that wants to run this on the device would need to update the bundle to be a unique id not registered before. E.g. from `com.protect.earth.Tree-Tracker` to `com.mynickname.Tree-Tracker`.
5. When running on a device, you'll also need to trust the certificate in Settings -> General -> Profiles, otherwise you'll see an error after installing the build and before running it.

## Contributing
Please feel free to create issues and PRs for anything, really. However, bear in mind that this app is created for specific audience so PRs with functionality that is out of scope might not be merged (if you feel like the PR you're working on is questionable, please feel free to reach out via Issues).

## License
[MIT](License.md)
