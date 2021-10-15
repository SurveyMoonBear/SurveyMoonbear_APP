# AWS SQS setup

## Register an account in AWS
- credit card needed

## Get the Access Key
- get in **My Security Credentials** (at the right top dropdown)
- get in **Access keys** (access key ID and secret access key)
- create new access key
- copy the credentials
    - *NOTE: the credentials is shown only one time except downloading the file*

## Create a SQS queue
- get in [sqs site](https://ap-northeast-1.console.aws.amazon.com/sqs/v2/home?region=ap-northeast-1#/queues)
- set the **region** (at the right top dropdown)
    - dev & test: Asia Pacific (Tokyo)ap-northeast-1
    - production(Heroku): US East (N. Virginia)us-east-1 (NOT SURE)
- create queue
    - *NOTE: the queue name and type could not change after created*
- copy the **queue name** & **queue URL**

## Test the SQS queue (in irb)
### Connect to Queue
```
require 'aws-sdk-sqs'

sqs = Aws::SQS::Client.new(
    access_key_id: config.AWS_ACCESS_KEY_ID,
    secret_access_key: config.AWS_SECRET_ACCESS_KEY,
    region: config.AWS_REGION
)

q_url = sqs.get_queue_url(queue_name: 'your_queue_name').queue_url
queue = Aws::SQS::Queue.new(url: q_url, client: sqs)
```
### Publisher: Send Messsage
```
msg = { code: "The time is #{Time.now}"}
queue.send_message(message_body: msg.to_json)
```

### Subscriber: Receive Message Batch
```
messages = queue.receive_messages
msg = messages.first

# PROCESS THE MESSAGE HERE
JSON.parse(msg.body)

queue.delete_messages(
    entries: [{ 
        id: msg.message_id,
        receipt_handle: msg.receipt_handle
    }])
```
### Poller: Keep receiving messages
```
poller = Aws::SQS::QueuePoller.new(q_url, client: sqs)

poller.poll do |msg|
    print "MESSAGE: #{JSON.parse msg.body}, "
end
```
