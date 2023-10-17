# How to Insert a Video
## Step1 - Copy Youtube embed link
1. Click Share Button

![](images/insert_video-share.png)

1. Click Embed Button

![](images/insert_video-embed.png)

1. Customize Your Video Setting

![](images/insert_video-setting.png)

1. Copy the iframe code

![](images/insert_video-iframe_code.png)


## Step2 - Paste iframe code to Sheets
**Sheets**

![](images/insert_video-iframe_to_sheet.png)

**Result**

![](images/insert_video-vedio_result.png)

## Optional - Customize iframe code
**you can skip and use default**

```
<iframe 
width="560" height="315" 
src="https://www.youtube.com/embed/n56jRytFkyw"  //DO NOT CHANGE
title="YouTube video player"
frameborder="0"
allow="accelerometer; autoplay; clipboard-write; 
encrypted-media; gyroscope; picture-in-picture" 
allowfullscreen>
</iframe>
```

| Attribute | Caption | 
| -------- | -------- | 
| width & height   | set size of video |
| src  | DO NOT CHANGE |
| title  | title |
| frameborder  | set border of frame |
| allow  | allow watcher to change something *Options: accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture* |
| allowfullscreen  | allow watcher watch in full screen |
