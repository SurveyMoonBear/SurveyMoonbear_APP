## alpine
### step1
- build a base Unix image which to run our Ruby applications
```
FROM ruby:3.0.2-alpine3.14
RUN apk update && apk upgrade \
    && apk --no-cache add ruby ruby-dev ruby-bundler ruby-json ruby-irb ruby-rake ruby-bigdecimal \
    && apk --no-cache add make g++ \
    && rm -rf /var/cache/apk/*
```   
- build image:
```
docker build --rm --force-rm -t <username>/ruby-http:3.0.2 .
```
- build container from image
```
docker run --rm -it <username>/ruby-http:3.0.2 sh
```
- push image
```
docker push <username>/ruby-http:3.0.2
```

### step 2
Dockerized SurveyMoonbear
```
FROM <username>/ruby-http:3.0.2
ENV WORK_PAH = surveymoonbear_app
RUN cd root && mkdir $WORK_PAH
WORKDIR root/surveymoonbear_app
COPY . .
RUN apk add --no-cache \
    build-base \
    sqlite \
    sqlite-dev \
    sqlite-libs \
    libsodium-dev
RUN bundle config set --local without 'production' && bundle install
RUN apk del --purge build-base sqlite-dev
CMD 'sh'
```
```
docker build --rm --force-rm -t <username>/surveymoonbear .
```
```
docker run --rm -it <username>/surveymoonbear
```
