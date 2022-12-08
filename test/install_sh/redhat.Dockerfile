FROM registry.access.redhat.com/ubi8/ubi as rhel8
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version

FROM registry.access.redhat.com/ubi9/ubi as rhel9
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version