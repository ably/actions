FROM ruby:3.1-alpine
RUN gem install aws-sdk-dynamodb
COPY run.rb /opt/run.rb
ENTRYPOINT ["ruby", "/opt/run.rb"]
