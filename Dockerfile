# image name lzh/glance:kilo
FROM 10.64.0.50:5000/lzh/openstackbase:kilo

MAINTAINER Zuhui Liu penguin_tux@live.com

ENV BASE_VERSION 2015-07-16
ENV OPENSTACK_VERSION kilo


ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get -t jessie-backports install neutron-plugin-openvswitch-agent -y
RUN apt-get clean

RUN env --unset=DEBIAN_FRONTEND

RUN cp -rp /etc/neutron/ /neutron
RUN rm -rf /var/log/neutron/*

VOLUME ["/etc/neutron"]
VOLUME ["/var/log/neutron"]

ADD entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

ADD neutron-plugin-openvswitch-agent.conf /etc/supervisor/conf.d/neutron-plugin-openvswitch-agent.conf

ENTRYPOINT ["/usr/bin/entrypoint.sh"]