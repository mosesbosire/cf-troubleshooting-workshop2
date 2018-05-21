# Issue no. 1 - Connecting to CF

Try to reach the CF API via HTTPS using the configured system domain:

```shell
cf login -a "https://api.sys.cf-training-${USER}.training.armakuni.co.uk"
API endpoint: https://api.sys.cf-training.training.armakuni.co.uk
FAILED
Error performing request: Get https://api.sys.cf-training.training.armakuni.co.uk/v2/info: dial tcp 35.177.185.23:443: i/o timeout
```

## Issue no. 2 - Connecting to CF (Service Unavailable)

```shell
cf login -a "https://api.sys.cf-training-${USER}.training.armakuni.co.uk"
API endpoint: https://api.sys.cf-training.training.armakuni.co.uk
FAILED
Server error, status code: 503, error code: 0, message:
```

# Issue no. 3 - Pushing an app to a CF space

Push an existing app to your CF defined space:

```shell
cd app
cf push
Pushing from manifest to org system / space workspace as admin...

[...]
Error staging application: Insufficient resources
FAILED
```

# Issue no. 4 - Trailing CF logs

Start trailing your `hello` application logs:

```shell
cf logs hello
Retrieving logs for app hello in org system / space workspace as admin...

maximum number of connection retries reached
FAILED
```

# Issue/Improvement no. 5 - Configure CF to use a proper apps domain (so that it does not use the sys domain)

# Issue no. 6 - Connect to the app via app domain URL

# Issue no. 7 - Scale up your app

```shell
cf scale -i 4 hello
Scaling app hello in org system / space workspace as admin...
OK

cf apps
Getting apps in org system / space workspace as admin...
OK

name    requested state   instances   memory   disk   urls
hello   started           3/4         1G       1G     hello.app.cf-training.training.armakuni.co.uk
```

# Issue no. 8 - SSH into your app

```shell
cf ssh hello
```
