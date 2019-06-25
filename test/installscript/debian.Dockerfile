FROM debian
RUN apt-get update -y && apt-get install -y curl
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version