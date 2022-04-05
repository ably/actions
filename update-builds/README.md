# update-builds

Updates a DynamoDB table with build information.

## Usage

```
jobs:
  example:
    runs-on: ubuntu-latest
    steps:
    - uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: eu-west-2
    # Publish build
    - uses: ably/actions/update-builds@main
      id: publish-builds
    ...
    other steps here
    ...
    # Update builds table with services built during run
    - uses: ably/actions/update-builds@main
      with:
        update: true
        release-tag: ${{ steps.publish-builds.outputs.release-tag }}
        services: foo,bar
```
