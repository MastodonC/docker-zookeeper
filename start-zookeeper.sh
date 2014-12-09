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

sed -e "s@dataDir=.*@dataDir=/data/zookeeper/${HOSTNAME}@" \
    /zookeeper/conf/zoo_sample.cfg > ${CONFIG_FILE}

if [ -z "${ZK01_PORT_2888_TCP_ADDR}" ]; then
    echo "server.1=${ZK01_PORT_2888_TCP_ADDR}:${ZK01_PORT_2888_TCP_PORT}:${ZK01_PORT_3888_TCP_PORT}" >> ${CONFIG_FILE}
fi

if [ -z "${ZK02_PORT_2888_TCP_ADDR}" ]; then
    echo "server.2=${ZK02_PORT_2888_TCP_ADDR}:${ZK02_PORT_2888_TCP_PORT}:${ZK02_PORT_3888_TCP_PORT}" >> ${CONFIG_FILE}
fi

if [ -z "${ZK03_PORT_2888_TCP_ADDR}" ]; then
    echo "server.3=${ZK03_PORT_2888_TCP_ADDR}:${ZK03_PORT_2888_TCP_PORT}:${ZK03_PORT_3888_TCP_PORT}" >> ${CONFIG_FILE}
fi

/zookeeper/bin/zkServer.sh start-foreground
