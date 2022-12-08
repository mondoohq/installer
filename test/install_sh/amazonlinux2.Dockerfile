FROM amazonlinux:2018
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version

FROM amazonlinux:2
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version

FROM amazonlinux:2022
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version