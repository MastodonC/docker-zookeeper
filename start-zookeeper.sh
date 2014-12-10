#!/bin/bash

LOG_CONFIG_FILE=/zookeeper/conf/log4j.properties
CONFIG_FILE=/zookeeper/conf/zoo.cfg

LOG_DIR="/logs/zookeeper/${HOSTNAME}"
mkdir -p "${LOG_DIR}"

DATA_DIR="/data/zookeeper/${HOSTNAME}"

mkdir -p ${DATA_DIR}

sed -i \
    -e "s@zookeeper\.log\.dir=.*@zookeeper.log.dir=${LOGDIR}@" \
    -e "s@zookeeper\.tracelog\.dir=.*@zookeeper.log.dir=${LOGDIR}@" \
    -e "s@^zookeeper.root.logger=.*@zookeeper.root.logger=INFO,CONSOLE,LOGSTASH@" \
    ${LOG_CONFIG_FILE}

cat <<EOF >> ${LOG_CONFIG_FILE}

# Add Logstash appender
log4j.appender.LOGSTASH=org.apache.log4j.net.SocketAppender
log4j.appender.LOGSTASH.Port=${LOGSTASH_PORT_4561_TCP_PORT}
log4j.appender.LOGSTASH.RemoteHost=${LOGSTASH_PORT_4561_TCP_ADDR}
log4j.appender.LOGSTASH.ReconnectionDelay=30000
EOF

function zk_server_string() {
    local name=${1^^}
    local myid=${2}
    local p1="${name}_PORT_2888_TCP_ADDR"
    local p2="${name}_PORT_2888_TCP_PORT"
    local p3="${name}_PORT_3888_TCP_PORT"

    if [ -z "${!p1}" ] ; then
	echo "No config for $1"
    else
	local conf="server.${myid}=${!p1}:${!p2}:${!p3}"

	echo "Adding $1 server config: ${conf}"
	echo ${conf} >> ${CONFIG_FILE}

    fi
}

myid_file="${DATA_DIR}/myid"
echo "Creating ${myid_file} ..."
echo "${ZOOKEEPER_INSTANCE_ID:?ZOOKEEPER_INSTANCE_ID_NOT_DEFINED}" > "${myid_file}"

sed -e "s@dataDir=.*@dataDir=/data/zookeeper/${HOSTNAME}@" \
    /zookeeper/conf/zoo_sample.cfg > ${CONFIG_FILE}

#Add entries for zookeeper peers.
for i in $(seq 255)
do
    local zk_name=$(printf "ZK%02s" ${i})
    local zk_env_name="${zk_name}_PORT_2181_TCP_ADDR"

    [ ! -z "${!zk_env_name}"] && zk_server_string ${zk_name} ${i}

done

/zookeeper/bin/zkServer.sh start-foreground
