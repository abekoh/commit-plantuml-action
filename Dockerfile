FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update 
RUN apt-get install -y fonts-ipafont graphviz wget openjdk-8-jre git curl unzip
RUN wget -P / --content-disposition https://sourceforge.net/projects/plantuml/files/plantuml.jar/download

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]