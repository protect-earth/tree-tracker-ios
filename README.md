#  Tree Tracker
App for cataloguing trees planted and allowing the recorded trees to be uploaded via a custom API to a centralised database. Mainly used by people who plant trees so they don't have to manually type coordinates with pictures they took and then try to guess the site/species afterwards.

## Running the app from Xcode with Mock server
1. Make sure you have downloaded Xcode 13.4+
2. Open the project in Xcode (you'll notice the dependencies will start to fetch in the background).
(In the meantime, Xcode will need to fetch dependencies for the project... 😴)
3. The signing settings for the project are configured for our CICD build pipeline, and will not allow you to build and run the app on your own device. To fix this, simply enable automatic signing in XCode and update the bundle identifier to something unique to you. This will update the .xcodeproj file accordingly. **NOTE** _Changes to signing settings must not be checked in, as these will break the automated builds._
4. Running the `Tree Tracker` scheme will use the API settings you [configure in your secrets file](#config).
5. When running on a device, you'll also need to trust the certificate in _Settings -> General -> Profiles_, otherwise you'll see an error after installing the build and before running it.

## Rollbar
We use [Rollbar](https://www.rollbar.com) for centralised error tracking, to help us troubleshoot issues with the app during real world usage. 
If you wish, you can sign up for a free Rollbar account, generate your own API token and provide it through `ROLLBAR_AUTH_TOKEN` to see telemetry in Rollbar during development. This can be useful if you are specifically adding telemetry features, but otherwise is probably more complex than just looking at the logs in XCode console. 

If you choose not to setup Rollbar, simply add a dummy value for `ROLLBAR_AUTH_TOKEN` and any Rollbar calls will silently fail.

## Additional project config {#config}
Now, to run the project, we'll need to generate the Secrets file. This means you need to run first install [`pouch`](https://github.com/sunshinejr/pouch) (the easiest is using `brew install sunshinejr/formulae/pouch`). Now, you need to have these environment variables available. It would be wise to prepare this file once and keep it somewhere obvious but take care not to check it in to Git. You can simply `source` the file whenever you need to regenerate Secrets.

```
export AWS_BUCKET_NAME=
export AWS_BUCKET_REGION=
export AWS_BUCKET_PREFIX=
export AWS_ACCESS_KEY=
export AWS_SECRET_KEY=
export PROTECT_EARTH_API_TOKEN="n|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export PROTECT_EARTH_API_BASE_URL="api.endpoint.com"
export PROTECT_EARTH_ENV_NAME=Development
export ROLLBAR_AUTH_TOKEN=yourRollbarToken
```

In the root folder, run `pouch`, which should generate a file at `./TreeTracker/Secrets.swift`.

With all that, you can switch the scheme to `Tree Tracker` and it _should_ run just fine.

## Contributing
Please feel free to create issues and PRs for anything, really. However, bear in mind that this app is created for specific audience so PRs with functionality that is out of scope might not be merged (if you feel like the PR you're working on is questionable, please feel free to reach out via Issues).

## License
[MIT](License.md)
