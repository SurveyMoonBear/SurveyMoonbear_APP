# SurveyMoonbear Guide

SurveyMoonbear provides a new way of survey services.  
Login with your Google account and make your own survey from Google Sheets!

## Table of contents
```
- User Guide
- Developer Guide
  - Getting Start
  - Architecture
  - Google
  - AWS
  - Heroku
  - Docker
  - Brainstorming
```
## User Guide
Users could follow the guide to make you own questionaire
- [Why you should use SurveyMoonbear](user_guide/competitive_products.md)
- [Question Type](user_guide/question_type.md)
- [How to Insert an Image](user_guide/insert_image.md)
- [How to Insert a Video](user_guide/insert_video.md)
- [How to make similar/same surveys for different groups without duplicating](user_guide/survey_group.md)


## Developer Guide
Developer could folow the guide to develop SurveyMoonbear.
- If you would like to **contribute to SurveyMoonbear**, please follow these rules
  - Make sure your code quality (you could follow [Test your code](test_code.md))
  - Contribute to new branch you created
  - Make a PR to merge to `branch: develop`
  - Ask Soumya to do code review

- If you would like to **deploy new feature on Heroku**, please follow these rules
  - After testing all things, make a PR merge `branch: develop` to `branch: master`
  - Ask Soumya to do code review
  - Get remote access and update on Heroku 
    ([How to update Heroku with updating GitHub code](heroku/update_from_github.md))
  
- If you would like to **update document or guide**, please follow these rules
  - Contribute document or guide on the `branch: doc` and merge to `branch: master`
  - Ask Soumya to do code review

### Getting Start
- [Getting Start](getting_start.md)
- [Test your code](test_code.md)

### Architecture

* [Architecture Intro](architecture/architecture-intro.md)
* [Infrastructure](architecture/infrastructure.md)
* [Services](architecture/services.md)
* [Client-side browser application](architecture/client-side-browser-application.md)

### Google

* [How to get Google Drive API Token](google/google-drive-api.md)
* [How to apply Google OAuth Verification](google/applying-google-oauth-verification.md)

### AWS
* [How to get a SQS Token](aws/sqs.md)

### Heroku
* [How to update Heroku with updating GitHub code](heroku/update_from_github.md)
* [How to test on Heroku new stack](heroku/test-on-heroku-new-stack.md)
* [pgAdmin Remote Connection](heroku/pgAdmin-remote-connection.md)
* [How to create a staging app](heroku/staging_app.md)

### Docker
- [How to Dockerize](docker/docker_project.md)

### Brainstorming
- [Upcoming Features](brainstorming/upcoming_features.md)
