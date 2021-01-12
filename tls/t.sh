source /home/heat-admin/pzhang/overcloudrc

test=($(openstack secret list | grep pzhang | awk -F "|" '{print $2}'))

for t in ${!test[@]}; do
  echo test ${test[$t]}
done
