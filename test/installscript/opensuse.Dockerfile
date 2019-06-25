FROM opensuse
RUN zypper -n install curl
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version