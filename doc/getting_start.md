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

> if it bumps into this problem 
> `Could not open library 'sodium' cannot load such file -- rbnacl`,
> please [install libsodium](https://github.com/RubyCrypto/rbnacl/wiki/Installing-libsodium) first

3. Add config/secrets.yml file

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
- If you fail to run the app, please try to install heroku installer first! (this command is for macOS)
```
$ brew tap heroku/brew && brew install heroku
```
- If you have the problem about redis after login to your account, plz run these commands:
```
$ brew install redis
$ redis-server /usr/local/etc/redis.conf
```
- If you fail to open your redis server, plz find the directory of redis.conf in your computer. It may be in the same place of your homebrew file.
### Get Remote Access
Create a Heroku remote to existing Heroku repo
```
$ heroku git:remote -a moonbear
```
