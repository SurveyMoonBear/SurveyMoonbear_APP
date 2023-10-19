# Applying Google OAuth Verification

### Get verification html file of your project from [Google Search Console](https://www.google.com/webmasters/tools/home)

1. Add a property of your project (Insert the project url)
2. Click “Verify this property”

### Upload the file to your project

The html file should be able to visit on “**\<your_app_url>/\<html_file_name.html>**” (e.g. http://moonbear.herokuapp.com/googlea1597013a70c6f23.html)

**Note.** In Heroku, static file path should be enabled: add the code into config.ru

```
use Rack::Static, 
      :urls => ['/googlea1597013a70c6f23.html'], 
      :root => 'public'
```

put the file in /public folder

### Create a privacy policy page(link)

1. Your Privacy policy must be **visible to users, hosted within the domain of your website**.
2. Your privacy policy and in-product privacy notifications must thoroughly **disclose the manner in which your application accesses, uses, stores, or shares Google user data**.

### Summit the verification apply

on Google Cloud Console - Oauth consent screen(https://console.cloud.google.com/apis/credentials/consent)

### Wait for Google’s reply

It takes few days (about 5 days)

> **Note** Once the url changed(home & privacy page) or the html file removed, you’ll lose verification, which means you’ll need to go through the process again.
