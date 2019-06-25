FROM amazonlinux
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version