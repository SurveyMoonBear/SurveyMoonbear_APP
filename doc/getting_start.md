# Getting Started

## Requirements
### Permissions
- Collaborator of SurveyMoonBear organization in Github
- Collaborator of Heroku moonbear app

### Credentials
- config/secrets.yml
- Moonbear Google Drive account & password

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
