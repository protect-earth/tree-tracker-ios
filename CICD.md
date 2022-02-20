# Tree Tracker CI/CD Setup
CI/CD for Tree Tracker has been configured with GitHub Actions to allow new builds to be tested and delivered via TestFlight with a single click or in response to specific repository events.

## Workflow

The GitHub Actions workflow is located in `.github/workflows/build-release.yaml` and will trigger on any push or pull request for the repository. If the triggering event is a merge to `main`, the resulting application will also be published to TestFlight. Unit tests are executed early on in the workflow, which will exit if these do not pass.

## Pre-requisites

In order for the workflow to run successfully, repository secrets must be configured to provide the various API credentials the application requires.

To add these, navigate to _Settings > Security > Secrets > Actions_ and add the following as repository secrets with the appropriate values:

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

Finally, additional secrets must be configured to store the details required for signing and publishing the app to the AppStore. Add the following secrets in the same way as before, with the appropriate values:

```
PROVISIONING_PROFILE_BASE64
DISTRIBUTION_CERT_BASE64
APPLE_APPLE_ID
APPLE_APP_SPECIFIC_PASSWORD
```

The provisioning profile used is currently _iOS App Store Distribution Profile 20220213_, which may be downloaded from AppStore Connect. Both files should be encoded to base64 via the following command line:

`cat <path/to/file> | base64`

The App Specific Password is essentially an additional password which you can use to authenticate your AppleID account with, and should only be used in specific cases. Generate a new password as follows:

* Sign in with your AppleID at https://appleid.apple.com/
* Navigate to _Sign-In and Security > App-Specific Password_
* Add or generate a new App-Specific Password and add the password to the `APPLE_APP_SPECIFIC_PASSWORD` secret as listed above, along with your AppleID in `APPLE_APPLE_ID`.

## TestFlight notes

The build number of the app is set to the run number of the workflow using `agvtool`. Updates to the release number should be made manually via a PR. Once published, compliance requirements will need to be accepted manually in TestFlight, and the appropriate tester groups will need to be added in order to get access to the latest build.