---
description: which view file corresponds to which page?
---

# Client-side browser application

1. `/` > (view::home)
2. `/account`
   * `/login` > `google_callback` > FindAuthenticatedGoogleAccount > `/survey_list`
   * `logout` > `/`
3. `/survey_list` > (view::survey list)
   * when no current account > `/`
   * `create` > CreateSurvey > `/survey_list`
   * `copy` > CopySurvey > `/survey_list`
4. `/survey`
   * `update_settings` > EditSurveyTitle > `/survey_list`
   * `update_options` > UpdateSurveyOptions > `/survey_list`
   * `/preview` > TransformSheetsSurveyToHTML > (view::survey_preview)
   * `start` > StartSurvey > `/survey_list`
   * `close` > CloseSurvey > `/survey_list`
   * `delete` > DeleteSurvey > `/survey_list`
   * `/response_detail` > GetSurveyFromDatabase
   * `/download` > TransformResponsesToCSV
5. `/onlinesurvey`
   * `/submit` > (view::survey_finish) > StoreResponses
   * `/close` > (view::survey_closed)
   * (view::survey_export)
6. `/privacy_policy` > (view::privacy_policy)
