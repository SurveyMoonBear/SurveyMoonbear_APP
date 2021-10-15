# Google Drive API

It uses `google-api-client` package which is [deprecated](https://github.com/googleapis/google-api-ruby-client/blob/master/google-api-client/OVERVIEW.md). If it is not working, please refer to the [`google-api-ruby-client`](https://github.com/googleapis/google-api-ruby-client).

### A GCP project with the API enabled

* [create GCP project](https://developers.google.com/workspace/guides/create-project#create_a_new_google_cloud_platform_gcp_project)
* [enable Google Drive API](https://developers.google.com/workspace/guides/create-project#enable-api)
* Button of "Enable APIs and Services" is hard to find 

![](https://i.imgur.com/TvlpLUG.png)

### Authorization credentials for a "Desktop application"

* [Configure the OAuth consent screen](https://developers.google.com/workspace/guides/create-credentials#configure_the_oauth_consent_screen)
* [Create a OAuth client ID credential](https://developers.google.com/workspace/guides/create-credentials#create_a_oauth_client_id_credential)
* The type of project/application's credential cannot use web application. It has different policy. ==Only use "[Desktop application](https://developers.google.com/workspace/guides/create-credentials#desktop)"==

![](https://i.imgur.com/p32SJ7V.png)

### Use Quickstart to practice how to get refresh_token

* [Install the Google Client Library](https://developers.google.com/drive/api/v3/quickstart/ruby?hl=en#step\_1\_install_the_google_client_library) `gem install google-api-client`
* [Set up the sample file](https://developers.google.com/drive/api/v3/quickstart/ruby?hl=en#step\_2\_set_up_the_sample) Create a file named quickstart.rb
* Download the `credentials.json` from GCP Platform _This file has fixed format. You cannot change it._ 

![](https://i.imgur.com/jwiatwg.png)

* Run the sample `ruby quickstart.rb`
* After typing `ruby quickstart.rb` and linking to the auth page, it would show a code. ==Just copy and paste it in terminal== which you're running. Then, it would write down the _token.yaml_ 

![](https://i.imgur.com/uRJN6Fw.png)

* **`refresh_token`** is written in the file **`token.yaml`** only one time once it authorizes. **Keep this file** or you need to delete the authorizaion and try quickstart angain.

### Change the "Scope" in quickstart.rb to get the right access of refresh_token

* In `quickstart.rb`, there is a line setting the scope

![](https://i.imgur.com/V0pYaZc.png)

* different scope has different [access right](https://developers.google.com/drive/api/v3/about-auth)
* use **`AUTH_DRIVE`** to get full permissive scope to access all of a user's files, excluding the Application Data folder

### Files Copy

* you can try API and see the document [here](https://developers.google.com/drive/api/v3/reference/files/copy?apix_params=%7B%22fileId%22%3A%221Nf6z-xXU2QT0fiC0H91pNfUiCNHfJPM8lddk_wVcR0c%22%2C%22resource%22%3A%7B%7D%7D#auth)
* Find the fileID you want to copy (It would return the id in terminal when the quickstart finish. Or find the fileID in the url) 

![](https://i.imgur.com/6klEd4v.png)

### Change Secrets file

```
GOOGLE_CLIENT_ID: 
GOOGLE_CLIENT_SECRET: 
REFRESH_TOKEN: 
SAMPLE_FILE_ID: 
```
