#/bin/bash -e

ARGS_LIST=(
  "bridge_list"
  "ve_index" 
  "ve_number"
  "mgmt_ip"
  "gateway_net"
  "ve_vcpu"
  "ve_ram"
  "root_password"
  "admin_paasword"
  "ssh_policy"
  "snmp_com_spec_name"
  "snmp_com_name"
  "snmp_trapsess_name"
  "snmp_trap_name"
  "snmp_trap_ip"
  "snmp_trap_port"
  "help"
)

OPTS=$(getopt \
  -o b:i:n:m:g:v:r:S:A:s:C:c:T:t:I:P:h \
  -l $(printf "%s:," ${ARGS_LIST[@]}) \
  -n $(basename $0) \
  -- $@
)

if [[ $? == 1 ]]; then
  exit 1;
fi

if [[ $? != 0 ]]; then
  "You do not pass any parameters, ENV Variables are used"
fi

eval set -- $OPTS

echo "$@"

while true; do
  echo $1
  case "$1" in
    -b | --bridge_list )  BR_LIST="$2"; shift 2;;
    -I | --snmp_trap_ip ) TRAP_IP="$2"; shift 2;;
    -- ) shift; break;;
    -h | --help )   usage
         exit 0;;
    [?] ) usage
         exit 0;;
  esac
done


echo ---
echo bridge_list: $BR_LIST
echo ---
echo snmp_trap_ip: $TRAP_IP
echo ---
echo "$@"
echo ---

usage() {
  echo -e "usage"
}
