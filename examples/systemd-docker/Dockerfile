FROM registry.access.redhat.com/ubi8/ubi-init
RUN curl --silent --location https://releases.mondoo.io/rpm/mondoo.repo | tee /etc/yum.repos.d/mondoo.repo
RUN yum install -y mondoo

# allows customization of times
COPY mondoo.timer /etc/systemd/system/mondoo.timer
RUN systemctl enable mondoo.timer

CMD [ "/sbin/init" ]