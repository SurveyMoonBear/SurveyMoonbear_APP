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
$ bundle install --without production
```

> The current project's version of ruby is 3.0.2 , if you don't have the version , you should install it first.
``` 
$ rbenv install 3.0.2
```

> if it bumps into this problem 
> `Could not open library 'sodium' cannot load such file -- rbnacl`,
> please [install libsodium](https://github.com/RubyCrypto/rbnacl/wiki/Installing-libsodium) first

3. Add config/secret.yml file

4. Run DB migrations
```
$ rake db:migrate
$ RACK_ENV=test db:migrate
```

5. Run tests
```
$ rake spec
```

6. Run the app
```
$ rake run:dev
```

### Get Remote Access
Create a Heroku remote to existing Heroku repo
```
$ heroku git:remote -a moonbear
```
