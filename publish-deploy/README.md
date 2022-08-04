# publish-deploy

Updates a DynamoDB table with a deploy manifest.

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
    - uses: ably/actions/publish-deploy@main
      id: publish-builds
      with:
        manifest-id: "some-manifest"
        services: "foo,bar"
        release-tag: "my-release-tag"
```
