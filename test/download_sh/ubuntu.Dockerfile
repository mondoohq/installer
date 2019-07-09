FROM ubuntu
# ubuntu does not ship with curl as default
RUN apt-get update -y && apt-get install -y curl
RUN mkdir -p /root/trial
WORKDIR /root/trial
ADD download.sh /root/trial/download.sh
RUN /root/trial/download.sh
RUN /root/trial/mondoo version