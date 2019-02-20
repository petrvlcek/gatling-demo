FROM openjdk:jre-alpine

# Install aws-cli
RUN apk -Uuv add python py-pip jq curl
RUN pip install awscli
RUN apk --purge -v del py-pip
RUN rm /var/cache/apk/*

# Simulations
ARG JAR_FILE
COPY ${JAR_FILE} /gatling/simulations.jar

# Test execution script
COPY assets/run-fargate.sh /gatling/run-fargate.sh
COPY assets/compile-report-fargate.sh /gatling/compile-report-fargate.sh