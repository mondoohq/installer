FROM centos:7
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version