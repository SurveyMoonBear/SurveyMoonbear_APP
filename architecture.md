# Survey MoonBear

 Survey MoonBear provides a new way of survey services. Survey MoonBear launches a survey from excel and outputs the responses to excel csv file.

## Architecture

Survey MoonBear is a Ruby Web application.

### Services
*which service corresponds to which function of the application?*
- `FindAuthenticatedGoogleAccount`: service to return  an authenticated user, or nil. e.g. id, email, username, access_token
- `TransformResponsesToCSV`: service to transform Launch.responses to CSV file
- `TransformDBSurveyToHTML`: service to create HTML strings: title & array of each survey page
- `TransformSheetsSurveyToHTML`: service to create HTML strings: title & array of each survey page
- `StoreResponses`: send message(responses_hash) to queue
- `GetSurveyFromDatabase`: return an entity of survey from database
- `GetSurveyFromSpreadsheet`: return an entity of survey from spreadsheet
- `CreateSurvey`: create a new template survey
- `StartSurvey`: get update survey in spreadsheet then store in db and return the updated survey
- `UpdateSurveyOptions`: return updated survey entity with new option, only db is updated
- `EditSurveyTitle`: return updated survey entity with new title, both spreadsheet and db are updated
- `CopySurvey`: copy the survey to a new one
- `CloseSurvey`: close the survey and launch, return launch entity with close state
- `DeleteSurvey`: delete survey in db and spreadsheet, return delete_survey

### Client-side browser application
1. During survey-taking, browser javascript acts like an SPA (single page application).
    Next page button just changes the view in javascript.
    Only when respondent submits the survey at the end, browser javascript POSTs the filled survey to App.
2. TODO: Front-end views: which view file corresponds to which page?
3. TODO: Google Token

### Infrastructure

1. File store service (Google Drive)
    - Stores spreadsheets??

2. Spreadsheet service (Google Sheets)
    - Fixed spreadsheet that is a Template for all new surveys
    - (gets copied to a new spreadsheet when user ‘creates’ a new survey)
    - Each ‘survey’ is represented by a single spreadsheet

3. Database (Postgres on Heroku)
    - How is the survey stored on database tables?
        *DETAILS: https://app.quickdatabasediagrams.com/#/d/ksihWW*
        - `Account`: Login with google account
        - `Survey`: a Account could create many survey
        - `Launch`: if owner want to edit the survey, close the survey first and launch again after edited. 
        - `Page`: different pages in a survey
        - `Item`: item is the question in different page in different survey
        - `Response`: each response is replied for each question(item) 
    - TODO:　Each deployed/previewed survey is stored in database??
    - We store not only the responses to each question, we also store a copy of the survey structure for each respondent
    - Prototype Design Pattern -- get video of it (Soumya)

4. Queuing (AWS SQS)
    - situation: browser javascript POSTs submission to App; App writes to database
    - problem: respondents submitting surveys caused heavy DB writes, which caused application to hang (> 50 writes per survey response) with hundreds of simultaneous submissions, even with Postgres multisert
    - solution: browser javascript POSTs survey submission to App; App queues the submission information on AWS SQS; Background worker (shoryuken?) reads from SQS queue and systematically writes to DB.
