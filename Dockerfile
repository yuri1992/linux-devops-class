FROM centos

RUN yum install -y sysstat
RUN yum install -y net-tools
RUN yum install -y docker

RUN mkdir /project
WORKDIR /project
VOLUME /project
