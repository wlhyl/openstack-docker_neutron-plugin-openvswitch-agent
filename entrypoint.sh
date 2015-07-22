#!/bin/bash

if [ -z "$RABBIT_HOST" ];then
  echo "error: RABBIT_HOST not set"
  exit 1
fi

if [ -z "$RABBIT_USERID" ];then
  echo "error: RABBIT_USERID not set"
  exit 1
fi

if [ -z "$RABBIT_PASSWORD" ];then
  echo "error: RABBIT_PASSWORD not set"
  exit 1
fi

if [ -z "$KEYSTONE_ENDPOINT" ];then
  echo "error: KEYSTONE_ENDPOINT not set"
  exit 1
fi

if [ -z "$NEUTRON_PASS" ];then
  echo "error: NEUTRON_PASS not set. user neutron password."
  exit 1
fi

if [ -z "$LOCAL_IP" ];then
  echo "error: LOCAL_IP not set. tunel ip."
  exit 1
fi

CRUDINI='/usr/bin/crudini'
    
    $CRUDINI --del /etc/neutron/neutron.conf database connection

    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit

    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWORD

    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

    $CRUDINI --del /etc/neutron/neutron.conf keystone_authtoken

    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$KEYSTONE_ENDPOINT:5000
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$KEYSTONE_ENDPOINT:35357
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken project_name service
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken username neutron
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASS
    
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT core_plugin neutron.plugins.ml2.plugin.Ml2Plugin
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT service_plugins neutron.services.l3_router.l3_router_plugin.L3RouterPlugin
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
    
    #计算节点可以不用配置flat_networks
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external

    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 10:100
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vxlan_group 224.0.0.1
    
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
    
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $LOCAL_IP
    
    # 计算节点可以不用配置bridge_mappings
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings external:br-ex
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini agent tunnel_types vxlan
    
    # 清空/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini
    
    cp /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini.orig
    echo > /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini

/usr/bin/supervisord -n