# hutils

A small collection of utilies for [logfmt](http://brandur.org/logfmt) processing.

## Installation

```
gem install hutils
```

## Utilities

### lcut

`lcut` extracts values from a logfmt trace based on some field name.

```
$ ltap 'instrumentation app=api earliest=-1m at=finish' | lcut method path
GET     /providers/users/search
GET     /vendor/resources/6307854
GET     /health
GET     /vendor/resources/6007506
GET     /vendor/resources/7117492
```

### lfmt

`lfmt` prettifies logfmt lines as they emerge from a stream, and highlights their key sections.

(Note that the example below doesn't demonstrate color, which is one of the more important features of `logfmt`.)

```
$ ltap 'instrumentation app=api earliest=-1m at=finish' | lfmt
api.108081@heroku.com app: api at: finish component: manager_apiauthorized elapsed: 0.008 instance_name: api.108081 instrumentation length: 339 method: GET path: /providers/users/search request_id: ef82825d-4c10-41f3-89ed-6bf805aa4513 status: 200 user: heroku-postgresql@addons.heroku.com user_id: 105750 version: 1
api.136540@heroku.com app: api at: finish elapsed: 0.001 instance_name: api.136540 instrumentation method: GET path: /vendor/resources/6307854 request_id: 055df716-fc62-4554-b976-e2fe2472e107 status: 200 user: 3paccounts@dwnldmedia.com user_id: 97546 version: 2
api.93579@heroku.com app: api at: finish elapsed: 0.000 instance_name: api.93579 instrumentation method: GET path: /health request_id: 6af07088-82af-4f50-87c1-8b5d248807f0 status: 200 user: heroku-postgresql@addons.heroku.com user_id: 105750 version: 1
api.108081@heroku.com app: api at: finish elapsed: 0.174 instance_name: api.108081 instrumentation method: GET path: /vendor/resources/6007506 request_id: ef82825d-4c10-41f3-89ed-6bf805aa4513 status: 200 user: heroku-postgresql@addons.heroku.com user_id: 105750 version: 1
api.108081@heroku.com app: api at: finish elapsed: 0.162 instance_name: api.108081 instrumentation method: GET path: /vendor/resources/7117492 request_id: 7480424d-5a8a-488a-a32a-55812fde5f4b status: 200 user: heroku-postgresql@addons.heroku.com user_id: 105750 version: 1
```

### ltap

`ltap` accesses messages from popular log providers in a consistent way so that it can easily be parsed by other utilities that operate on logfmt traces. Currently supported providers are Papertrail and Splunk.

```
$ ltap 'instrumentation app=api earliest=-1m at=finish'
api.108081@heroku.com instrumentation method=GET path=/providers/users/search request_id=d5c373fd-d1ec-4986-bc43-2617431116f2 at=finish elapsed=0.008 length=339 status=200 app=api instance_name=api.108081 version=1 component=manager_apiauthorized app=api instance_name=api.108081 request_id=ef82825d-4c10-41f3-89ed-6bf805aa4513 version=1 user=heroku-postgresql@addons.heroku.com user_id=105750
api.136540@heroku.com instrumentation method=GET path=/vendor/resources/6307854 request_id=d2f25032-9aaa-41e9-8aaf-9a46a44523d1 at=finish elapsed=0.110 status=200 app=api instance_name=api.136540 version=1 user=heroku-postgresql@addons.heroku.com user_id=105750step=check_oauth_scope! request_id=055df716-fc62-4554-b976-e2fe2472e107 version=2 user=account@example.com user_id=97546 app=api instance_name=api.136540 at=finish elapsed=0.001
api.93579@heroku.com instrumentation method=GET path=/health request_id=6af07088-82af-4f50-87c1-8b5d248807f0 at=finish elapsed=0.000 status=200 app=api instance_name=api.93579 version=1 user=heroku-postgresql@addons.heroku.com user_id=105750
api.108081@heroku.com instrumentation method=GET path=/vendor/resources/6007506 request_id=ef82825d-4c10-41f3-89ed-6bf805aa4513 at=finish elapsed=0.174 status=200 app=api instance_name=api.108081 version=1 user=heroku-postgresql@addons.heroku.com user_id=105750
api.108081@heroku.com instrumentation method=GET path=/vendor/resources/7117492 request_id=7480424d-5a8a-488a-a32a-55812fde5f4b at=finish elapsed=0.162 status=200 app=api instance_name=api.108081 version=1 user=heroku-postgresql@addons.heroku.com user_id=105750
```

`ltap` can be configured using `~/.ltap`. A sample Papertrail configuration looks like the following:

```
[global]
profile = my_papertrail

[my_papertrail]
key = an-api-key
type = papertrail
```

A sample Splunk configuration:

```
[global]
profile = my_splunk

[my_splunk]
type = splunk
url = https://brandur:an-api-key@splunk.example.com:8089
```

### lviz

`lviz` helps to visualize logfmt output by building a tree out of some set of data by combining common sets of key/value pairs into shared parent nodes. Messages remain ordered by time, which removes some potential for commonality, but in many cases a disproportionate number of attributes can be moved up to nodes close to the top of the tree. Output is colorized and important keys are highlighted to make traces more easily digestible.

```
$ ltap 'instrumentation app=api earliest=-1m at=finish' | lviz
+ app: api
  instrumentation
  method: GET
  status: 200

        + api.108081@heroku.com
          component: manager_apiauthorized
          elapsed: 0.008
          instance_name: api.108081
          length: 339
          path: /providers/users/search
          request_id: ef82825d-4c10-41f3-89ed-6bf805aa4513
          user: heroku-postgresql@addons.heroku.com
          user_id: 105750
          version: 1

        + api.136540@heroku.com
          elapsed: 0.001
          instance_name: api.136540
          path: /vendor/resources/6307854
          request_id: 055df716-fc62-4554-b976-e2fe2472e107
          user: account@example.com
          user_id: 97546
          version: 2

        + user: heroku-postgresql@addons.heroku.com
          user_id: 105750
          version: 1

                + api.93579@heroku.com
                  elapsed: 0.000
                  instance_name: api.93579
                  path: /health
                  request_id: 6af07088-82af-4f50-87c1-8b5d248807f0

                + api.108081@heroku.com
                  instance_name: api.108081

                        + elapsed: 0.174
                          path: /vendor/resources/6007506
                          request_id: ef82825d-4c10-41f3-89ed-6bf805aa4513

                        + elapsed: 0.162
                          path: /vendor/resources/7117492
                          request_id: 7480424d-5a8a-488a-a32a-55812fde5f4b
```

`lviz` can be configured with `~/.lviz`. For example:

```
[global]
highlights = path,user
ignore = at
```

`lviz` can also produce a compact mode of output using `-c` or `--compact`.

## Testing

```
bundle install
bundle exec rake
```
