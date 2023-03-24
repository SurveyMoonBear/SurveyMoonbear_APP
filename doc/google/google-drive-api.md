# Google Drive/Calendar API

It uses `google-api-client` package which is [deprecated](https://github.com/googleapis/google-api-ruby-client/blob/master/google-api-client/OVERVIEW.md). If it is not working, please refer to the [`google-api-ruby-client`](https://github.com/googleapis/google-api-ruby-client).

### Step1: A GCP project with the API enabled

1. [create GCP project](https://developers.google.com/workspace/guides/create-project#create_a_new_google_cloud_platform_gcp_project)
![](https://i.imgur.com/qiTpYxr.png)
2. [enable Google Drive API and Google Calendar API](https://developers.google.com/workspace/guides/create-project#enable-api)
3. Button of "Enable APIs and Services" is hard to find 

![](https://i.imgur.com/TvlpLUG.png)

### Step2: Create authorization credentials for a "Web application"

1. [Configure the OAuth consent screen](https://developers.google.com/workspace/guides/create-credentials#configure_the_oauth_consent_screen)
2. [Create a OAuth client ID credential](https://developers.google.com/workspace/guides/create-credentials#create_a_oauth_client_id_credential)
3. The type of project/application's credential choose **[web application](https://developers.google.com/workspace/guides/create-credentials)**.

![](https://i.imgur.com/p32SJ7V.png)

### Step3: Add following three redirect URI in created authorization credentials
* For creating a staging app: `https://<appname-staging>.herokuapp.com/account/login/google_callback`
* For local development: `http://localhost:9090/account/login/google_callback`
* For getting refresh token: `https://developers.google.com/oauthplayground`

### Step4: Get application refresh token
1. go to [oauth play groung](https://developers.google.com/oauthplayground)
2. click setting and check the checkbox:Use your own Oauth credentials
3. copy/paste the Client ID and Client secret from step2
4. select the scopes we used on the left side (in application/controller/app.rb file line 36)
5. click the Authorize APIs
  ![image](https://user-images.githubusercontent.com/44396169/170173450-5d96396c-9e67-419b-af54-670a615e2dc9.png)
6. It will turn back following screen
7. Click Exchange authorization code for tokens and you will see the refresh token
![image](https://user-images.githubusercontent.com/44396169/170173908-4cfdc142-30ec-42ee-a103-de221ed72a47.png)

### Step5: get sample file ID
1. Copy sample file from SurveyMoonbear to your develop google account
2. Find the fileID you want to copy (It would return the id in terminal when the quickstart finish. Or find the fileID in the url) 
  ![](https://i.imgur.com/6klEd4v.png)

### Step6: Update Secrets file

```
GOOGLE_CLIENT_ID: 
GOOGLE_CLIENT_SECRET: 
REFRESH_TOKEN: 
SAMPLE_FILE_ID: 
```

---
#### [ARCHIVED] Use Quickstart to practice how to get refresh_token
*(follow this when choosing **Desktop application** in authorization credentials)*
1. [Install the Google Client Library](https://developers.google.com/drive/api/v3/quickstart/ruby?hl=en#step\_1\_install_the_google_client_library) `gem install google-api-client`
2. [Set up the sample file](https://developers.google.com/drive/api/v3/quickstart/ruby?hl=en#step\_2\_set_up_the_sample) Create a file named quickstart.rb
3. Download the `credentials.json` from GCP Platform _This file has fixed format. You cannot change it._ 
4. `credentials.json` has your `google client ID` and `google client secret` ![](https://i.imgur.com/jwiatwg.png)
5. Run the sample `ruby quickstart.rb`
6. After typing `ruby quickstart.rb` and linking to the auth page, it would show a code. ==Just copy and paste it in terminal== which you're running. Then, it would write down the _token.yaml_ ![](https://i.imgur.com/uRJN6Fw.png)
7. **`refresh_token`** is written in the file **`token.yaml`** only one time once it authorizes. **Keep this file** or you need to delete the authorizaion and try quickstart angain.

#### [ARCHIVED] Change the "Scope" in quickstart.rb to get the right access of refresh_token
*(follow this when choosing **Desktop application** in authorization credentials)*
1. In `quickstart.rb`, there is a line setting the scope
  ![](https://i.imgur.com/V0pYaZc.png)
2. different scope has different [access right](https://developers.google.com/drive/api/v3/about-auth)( you can also [see here](https://googleapis.dev/ruby/google-api-client/latest/Google/Apis/DriveV3.html))
3. use **`AUTH_DRIVE`** instead of **`AUTH_DRIVE_METADATA_READONLY`** to get full permissive scope to access all of a user's files, excluding the Application Data folder
