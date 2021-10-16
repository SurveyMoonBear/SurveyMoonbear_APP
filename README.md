# Survey Moonbear

 Survey Moonbear provides a new way of survey services.

## Status
[![Ruby v2.7.3](https://img.shields.io/badge/Ruby-2.7.3-green)](https://www.ruby-lang.org/en/news/2021/04/05/ruby-2-7-3-released/)

## Resources
- [Github](https://github.com/SurveyMoonBear/SurveyMoonbear_APP)
- [Heroku](https://moonbear.herokuapp.com/)
- [HackMD Doc](https://hackmd.io/@WVFBeK-KRt-CDsNCu4hqdQ/r1u3-zSSt)
- [GitHub Doc](doc/README.md)

## Getting Started

### Requirements
#### Permissions
- Collaborator of SurveyMoonBear organization in Github
- Collaborator of Heroku moonbear app

#### Credentials
- config/secrets.yml
- Moonbear Google Drive account & password

### SETUP
#### Run on local

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

#### Get Remote Access
Create a Heroku remote to existing Heroku repo
```
$ heroku git:remote -a moonbear
```

