# push-docker-manifest



## Usage

```
jobs:
  push_manifest:
    runs-on: ubuntu-latest
    steps:
      - uses: ably/actions/push-docker-manifest@main
        with:
          images: my-image, my-other-image
          registry: ${{ secrets.REGISTRY }}
          tag: my-tag
```
