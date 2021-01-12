source /home/heat-admin/pzhang/overcloudrc

neutron lbaas-pool-delete 1-pl-0-0-0
neutron lbaas-pool-delete 0-pl-0-0-0

neutron lbaas-listener-delete 0-ls-0-0
neutron lbaas-listener-delete 1-ls-0-0

neutron lbaas-loadbalancer-delete 0-lb-0
neutron lbaas-loadbalancer-delete 1-lb-0

neutron subnet-delete lb-subnet-0
neutron subnet-delete mb-subnet-0

neutron subnet-delete lb-subnet-1
neutron subnet-delete mb-subnet-1

neutron net-delete mb-net-0
neutron net-delete lb-net-0

neutron net-delete mb-net-1
neutron net-delete lb-net-1

openstack project delete pf-0
openstack user delete pf-0

openstack project delete pf-1
openstack user delete pf-1
