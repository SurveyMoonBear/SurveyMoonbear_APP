# How to Insert a Video
## Step1 - Copy Youtube embed link
1. Click Share Button

![](https://i.imgur.com/wYcDMXT.png)

2. Click Embed Button

![](https://i.imgur.com/767mfcE.png)

3. Customize Your Video Setting

![](https://i.imgur.com/58E65PB.png)

4. Copy the iframe code

![](https://i.imgur.com/LVwICE9.png)

## Step2 - Paste iframe code to Sheets
**Sheets**

![](https://i.imgur.com/Hgn8t78.png)

**Result**

![](https://i.imgur.com/jOmqWQG.png)

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
