# Update Heroku from Github master branch
### Get remote access to SurveyMoonbear
> first time login needed
```
git push heroku master
```

### Push master branch to Heroku

```
git push heroku master 
```

### Run migration on Heroku (If there is anything new in DB)

```
heroku run rake db:migrate
```

### Restart

```
heroku restart
```

### Open

```
heroku open
```
