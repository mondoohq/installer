FROM ubuntu
RUN apt update -y && apt install -y curl
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version