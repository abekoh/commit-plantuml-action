FROM ubuntu:latest

RUN apt-get update 
RUN apt-get install -y fonts-ipafont graphviz wget default-jre
RUN wget -P / --content-disposition https://sourceforge.net/projects/plantuml/files/plantuml.jar/download

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]