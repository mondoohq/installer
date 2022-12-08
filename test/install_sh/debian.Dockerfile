FROM debian:9 as debian9
RUN apt update -y && apt install -y curl
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version

FROM debian:10 as debian10
RUN apt update -y && apt install -y curl
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version

FROM debian:11 as debian11
RUN apt update -y && apt install -y curl
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version