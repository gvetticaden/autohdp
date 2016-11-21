#!/bin/bash
# Forked from https://github.com/HortonworksUniversity/Ambari2.x/blob/master/ambari_2_server_node/scripts/install_cluster.sh
# Expects ../repos/hdp.repo and ../repos/hdp-utils to be properly configured

if [[ -z $3 ]]; then
  echo "Usage: $0 <blueprint base name> <cluster name> <hdp short version> <hdp-utils version>"  
  echo "Default utils version 1.1.0.21"
  exit -1
fi

set +x

. functions.sh


BLUEPRINT_BASE=$1
CLUSTER_NAME=$2
HDP_VERSION_SHORT=$3
UTILS_VERSION=${4:-1.1.0.21}
OS=$( get_os_version )
if [[ "$OS" == "centos6" ]]; then
OS=redhat6
elif [[ "$OS" == "centos7" ]]; then
OS=redhat7
fi


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function runcommand() {
   COMMAND="$1"
   echo $COMMAND
   OUTPUT=$( $COMMAND 2> /dev/null )
   echo "$OUTPUT"
   STATUS=$( echo "$OUTPUT" | jq '.status' | tr -d '"' )
   if [[ "$STATUS" != "200" ]]; then echo "Error. Exiting."; exit 1; fi	
}

COMMAND="curl --user admin:admin -H X-Requested-By:autohdp -X PUT http://localhost:8080/api/v1/stacks/HDP/versions/${HDP_VERSION_SHORT}/operating_systems/${OS}/repositories/HDP-${HDP_VERSION_SHORT} -d @$DIR/../tmp/hdp.repo.json"
runcommand "$COMMAND"

COMMAND="curl --user admin:admin -H X-Requested-By:autohdp -X PUT http://localhost:8080/api/v1/stacks/HDP/versions/${HDP_VERSION_SHORT}/operating_systems/${OS}/repositories/HDP-UTILS-${UTILS_VERSION} -d @$DIR/../tmp/hdp-utils.repo.json"
runcommand "$COMMAND"

COMMAND="curl --user admin:admin -H X-Requested-By:autohdp -X POST http://localhost:8080/api/v1/blueprints/$BLUEPRINT_BASE -d @$DIR/../tmp/${BLUEPRINT_BASE}-${CLUSTER_NAME}.blueprint"
runcommand "$COMMAND"

COMMAND="curl --user admin:admin -H X-Requested-By:autohdp -X POST http://localhost:8080/api/v1/clusters/$CLUSTER_NAME -d @$DIR/../tmp/${BLUEPRINT_BASE}-${CLUSTER_NAME}.hostmapping"
runcommand "$COMMAND"

