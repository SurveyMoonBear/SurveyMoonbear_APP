# Getting Started

## Requirements
### Permissions
- Collaborator of SurveyMoonBear organization in Github
- Collaborator of Heroku moonbear app

### Credentials
- Dev & Test:
  - Create config/secrets.yml on local [secrets_example.yml](../config/secrets_example.yml)
  - Use your personal Google account and [apply for Google Drive API Token](google/google-drive-api.md)
  - Use your personal AWS account and [apply for AWS SQS Token](aws/sqs.md)
  - Get `DB_KEY` and `MSG_KEY` by run
    ```
    $ rake crypto:db_key  
    $ rake crypto:msg_key
    ```
- Production: 
  - Survey Moonbear's Google Drive account & password

## SETUP
### Run on local

1. Clone the repo
```
$ git clone git@github.com:SurveyMoonBear/SurveyMoonbear_APP.git
```

2. Install gems
```
$ bundle config set --local without 'production'
$ bundle install
```

> if it bumps into this problem 
> `Could not open library 'sodium' cannot load such file -- rbnacl`,
> please [install libsodium](https://github.com/RubyCrypto/rbnacl/wiki/Installing-libsodium) first

3. Add config/secret.yml file

4. Run DB migrations
```
$ rake db:migrate
$ RACK_ENV=test rake db:migrate
```

5. Run tests
```
$ rake spec
```

6. Run the app
```
$ rake run:dev
```

> if it bumps into this problem 
> `Error connecting to Redis on 127.0.0.1:6379 (Errno::ECONNREFUSED) (Redis::CannotConnectError)`,
> please [install Redis](https://redis.io/docs/getting-started/installation/) first

### Get Remote Access
Create a Heroku remote to existing Heroku repo
```
$ heroku git:remote -a moonbear
```
