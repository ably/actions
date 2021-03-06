# checkout-submodules

Recursively checks out submodules. This is possible with the default checkout
action, but fails if you're using deploy keys.

This action will specifically checkout submodules with the provided key.

To specify a single submodule use the `submodule` input parameter with the 
submodule path as the value.

## Usage

```
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      ...
      - uses: actions/checkout@v2
      - uses: ably/actions/checkout-submodules@main
        with:
          private_ssh_key: ${{ secrets.PRIVATE_SSH_KEY }}
          submodule: submodule/path
```
