FROM gliderlabs/registrator:v7
MAINTAINER GL-devops

COPY ecs_entrypoint.sh /

# To get ip of the hos
RUN apk-install curl
ENTRYPOINT ["/ecs_entrypoint.sh"]
