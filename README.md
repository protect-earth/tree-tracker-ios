#  Tree Tracker
App for taking pictures of trees and storing that on a remote server. Mainly used by people who plant trees so they don't have to manually type coordinates with pictures they took and then try to guess the site/species afterwards.

## Running the app from Xcode with Mock server
1. Make sure you have downloaded Xcode 13.4+
2. Open the project in Xcode (you'll notice the dependencies will start to fetch in the background).
(In the meantime, Xcode will need to fetch dependencies for the project... 😴)
3. The signing settings for the project are configured for our CICD build pipeline, and will not allow you to build and run the app on your own device. To fix this, simply enable automatic signing in XCode and update the bundle identifier to something unique to you. This will update the .xcodeproj file accordingly. **NOTE** _Changes to signing settings must not be checked in, as these will break the automated builds._
4. Running the `Tree Tracker` scheme will use the main Airtable base you [configure in your secrets file](#config) and will make inserts to your base tables. Running the `Tree Tracker (Mock server` scheme will use hard-coded mock API responses and will not touch Airtable.
5. When running on a device, you'll also need to trust the certificate in _Settings -> General -> Profiles_, otherwise you'll see an error after installing the build and before running it.

## Using your own Airtable/Cloudinary server
Well, this is a bit complicated but still doable. 
Sign up for a free [Airtable](https://www.airtable.com) account, as you will need to provide the details of *2* Airtable bases - one 
to support the execution of integration tests, and one for the app to use when in normal usage. 

For development purposes, the 2 bases 
can actually be the same. If you are doing this, it is recommended to create two sets of tables in the same base, and use a prefix on 
the table name. This can then be specified in the `TEST_AIRTABLE_TABLE_NAME_PREFIX` secret (see [later](#config)).

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

## Rollbar
We use [Rollbar](https://www.rollbar.com) for centralised logging of errors, to help us troubleshoot issues with the app during real world usage. 
If you wish, you can sign up for a free Rollbar account, generate your own API token and provide it through `ROLLBAR_AUTH_TOKEN` to see telemetry 
in Rollbar during development. This can be useful if you are specifically adding telemetry features, but otherwise is probably more complex than 
just looking at the logs in XCode console. 

If you choose not to setup Rollbar, simply add a dummy value for `ROLLBAR_AUTH_TOKEN` and any Rollbar calls will silently fail.

## Additional project config {#config}
Now, to run the project, we'll need to generate Secrets file. This means you need to run first install [`pouch`](https://github.com/sunshinejr/pouch) (the easiest is using `brew install sunshinejr/formulae/pouch`). Now, you need to have these environment variables available. Have this at the end of the file (bash: most likely in `.bash_profile` or `.bashrc`, zsh: most likely `.zshenv` or `.zshrc`):
```
export AIRTABLE_API_KEY=yourKey123
export AIRTABLE_BASE_ID=appNiceTree
export AIRTABLE_TREES_TABLE_NAME="Trees Planted"
export AIRTABLE_SPECIES_TABLE_NAME=Species
export AIRTABLE_SUPERVISORS_TABLE_NAME=Supervisors
export AIRTABLE_SITES_TABLE_NAME=Sites
export CLOUDINARY_CLOUD_NAME=qqq2ek4mq
export CLOUDINARY_UPLOAD_PRESET_NAME=iadfadff
export TEST_AIRTABLE_API_KEY=yourTestKey123
export TEST_AIRTABLE_BASE_ID=appNiceTreeTest
export TEST_AIRTABLE_TABLE_NAME_PREFIX=test_
export ROLLBAR_AUTH_TOKEN=yourRollbarToken
```
In the root folder, run `pouch`, which should generate a file at `./TreeTracker/Secrets.swift`.

With all that, you can switch the scheme to `Tree Tracker` and it _should_ run just fine.

## Contributing
Please feel free to create issues and PRs for anything, really. However, bear in mind that this app is created for specific audience so PRs with functionality that is out of scope might not be merged (if you feel like the PR you're working on is questionable, please feel free to reach out via Issues).

## License
[MIT](License.md)
