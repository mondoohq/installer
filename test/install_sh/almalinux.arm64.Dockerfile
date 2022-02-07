FROM arm64v8/almalinux
ADD install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version