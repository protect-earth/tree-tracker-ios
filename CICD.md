# Tree Tracker CI/CD Setup
CI/CD for Tree Tracker has been configured with GitHub Actions to allow new builds to be tested and delivered via TestFlight with a single click or in response to specific repository events.

## Workflow

The GitHub Actions workflow is located in `.github/workflows/build-release.yaml` and will trigger on any push or pull request for the repository. If the triggering event is a merge to `main` AND it is not a pull request (i.e. a validation build as part of PR review), the resulting application will also be published to TestFlight. Unit tests are executed early on in the workflow, which will exit if these do not pass.

## Pre-requisites

In order for the workflow to run successfully, repository secrets must be configured to provide the various API credentials the application requires.

To add these, navigate to _Settings > Security > Secrets > Actions_ and add the following as repository secrets with the appropriate values:

```
CLOUDINARY_CLOUD_NAME
CLOUDINARY_UPLOAD_PRESET_NAME
PROTECT_EARTH_API_TOKEN
PROTECT_EARTH_API_BASE_URL
PROTECT_EARTH_ENV_NAME
ROLLBAR_AUTH_TOKEN
```

Finally, additional secrets must be configured to store the details required for signing and publishing the app to the AppStore. Add the following secrets in the same way as before, with the appropriate values. Note that `KEYCHAIN_PASSWORD` can be any random string. It is used to secure the temporary keychain created during the build process, and is not referenced anywhere outside of the build.

```
PROVISIONING_PROFILE_BASE64
DISTRIBUTION_CERT_BASE64
DISTRIBUTION_CERT_PASSWORD
KEYCHAIN_PASSWORD
APPLE_APPLE_ID
APPLE_APP_SPECIFIC_PASSWORD
```

The provisioning profile used is currently _iOS AppStore Profile 07Mar2023_, which may be downloaded from AppStore Connect. Signing certificates may be managed in XCode and exported from there as a `.p12` file. See https://help.apple.com/xcode/mac/current/#/dev154b28f09 for instructions.

> **_NOTE:_**  A new provisioning profile will need to be created annually since both the profile and the signing certificate it references expire after 1 year.

Both files should be encoded to base64 via the following command line:

`cat <path/to/file> | base64`

The App Specific Password is essentially an additional password which you can use to authenticate your AppleID account with, and should only be used in specific cases. Generate a new password as follows:

* Sign in with your AppleID at https://appleid.apple.com/
* Navigate to _Sign-In and Security > App-Specific Password_
* Add or generate a new App-Specific Password and add the password to the `APPLE_APP_SPECIFIC_PASSWORD` secret as listed above, along with your AppleID in `APPLE_APPLE_ID`.

## TestFlight notes

The build number of the app is set to the run number of the workflow using `agvtool`. Updates to the release number (_marketing version_) should be made manually via `agvtool new-marketing-version` and committed via a PR. Once published,  the appropriate tester groups will need to be added in order to get access to the latest build.