# Yeti

Yeti stands for "Yet Extraordinary Test Infrastructure" and is a collection
of integration tests for the CloudFoundry platform.

# Running Tests

Don't forget to pull in all submodules.

## Non-parallel

Tests require several environment variables to be set:

    export VCAP_BVT_API_ENDPOINT="http://api.example.com"

    export VCAP_BVT_USER="non-admin-user@example.com"
    export VCAP_BVT_USER_PASSWD="non-admin-password"

After setting up your environment you can use regular rspec to
run tests:

    bundle exec rspec
    bundle exec rspec spec/apps/ruby_spec.rb

Tip: If you do not want to set `VCAP_BVT_USER` and `VCAP_BVT_USER_PASSWD`
you can run `rake prepare` (task used with parallel set up) once
and after that tests will just use first parallel user. (You will have
to set the VCAP_BVT_ADMIN_USER and VCAP_BVT_ADMIN_USER_PASSWD for this.
See below.)

## Parallel

Tests require several environment variables to be set:

    export VCAP_BVT_API_ENDPOINT="http://api.example.com"
    export VCAP_BVT_UAA_CC_SECRET="some-secret"

    export VCAP_BVT_ADMIN_USER="admin-user@example.com"
    export VCAP_BVT_ADMIN_USER_PASSWD="admin-password"

Optional environment variables:

  Will create organizations with this string - useful for automated clean-up. 
    export VCAP_BVT_ORG_NAMESPACE="jenkins"

(Admin credentials are only used for creating other users.)

Run `rake prepare` to create 16 users to be used in parallel specs.
(User credentials will be stored in `~/.bvt/config.yml`)

After setting up your environment here is how to run tests in parallel:

    parallel_rspec spec
    parallel_rspec spec -o '--tag=some-tag'

See [parallel_tests gem](https://github.com/grosser/parallel_tests)
for more information.

# Debugging Tips

- `VCAP_BVT_TRACE=1` turns on tracing of cfoundry calls

# Assets

Binary assets are stored in `http://blobs.cloudfoundry.com` which is a
simple Sinatra application with blob service backend hosted on CloudFoundry.
These assets are then synchronized via `rake assets:sync` into the
`.assets-binaries` directory.

Refer to [asset docs](docs/how-to-build-assets.md) for more information.
