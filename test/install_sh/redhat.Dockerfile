FROM registry.access.redhat.com/ubi8/ubi as rhel8
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version

FROM registry.access.redhat.com/ubi9/ubi as rhel9
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN cnspec version