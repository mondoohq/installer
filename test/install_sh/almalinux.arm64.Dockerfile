FROM arm64v8/almalinux:8 as almalinux8_arm64
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version

FROM arm64v8/almalinux:9 as almalinux9_arm64
COPY install.sh /run/install.sh
RUN /run/install.sh
RUN mondoo version