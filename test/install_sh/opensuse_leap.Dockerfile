FROM opensuse/leap:15.4 as opensuse_leap154
RUN zypper -n install curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version

FROM opensuse/tumbleweed as opensuse_tumbleweed
RUN zypper -n install curl
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version