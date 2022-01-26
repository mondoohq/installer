FROM registry.access.redhat.com/ubi8/ubi
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version