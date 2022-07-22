# notify

Sends a simple Slack notification for the results of a CI build.

## How to use

### Inline

If you use the action within a single job, it will automatically declare
the status:

```
name: CI
on: push

jobs:
  tests:
    name: Test
    runs-on: ubuntu-latest
    steps:
      ...
      - uses: ably/actions/notify@main
        if: always()
        with:
          webhook: ${{ secrets.SLACK_WEBHOOK }}
          release-tag: release-foo-bar
          channel: #notifications
```

### Separate job

If you use the action as a separate job in a more complex pipeline where
you're using the `needs` conditional, you will need to explicitly declare
the status:

```
name: CI
on: push

jobs:
  tests:
    name: Test
    runs-on: ubuntu-latest
    steps:
      ...
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
    ...

  notify_success:
    if: success()
    needs: [ tests, lint ]
    runs-on: ubuntu-latest
    steps:
    - uses: ably/actions/notify@main
      with:
        webhook: ${{ secrets.SLACK_WEBHOOK }}
        release-tag: release-foo-bar
        status: success
        channel: #notifications

  notify_failure:
    if: failure()
    needs: [ tests, lint ]
    runs-on: ubuntu-latest
    steps:
    - uses: ably/actions/notify@main
      with:
        webhook: ${{ secrets.SLACK_WEBHOOK }}
        release-tag: release-foo-bar
        status: failure
        channel: #notifications
```
