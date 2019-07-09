FROM amazonlinux
# amazon linux does not ship with tar as default
RUN yum install -y tar gzip
RUN mkdir -p /root/trial
WORKDIR /root/trial
ADD download.sh /root/trial/download.sh
RUN /root/trial/download.sh
RUN /root/trial/mondoo version