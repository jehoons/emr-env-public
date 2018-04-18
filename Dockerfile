# FROM       ubuntu:16.04
ARG BASE_IMAGE
FROM jhsong/essential:${BASE_IMAGE} 
ARG BASE_IMAGE
RUN echo "base image: ${BASE_IMAGE}"

MAINTAINER Je-Hoon Song "song.jehoon@gmail.com"

VOLUME /root

EXPOSE 8888 22

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"] 

CMD ["emr"]

