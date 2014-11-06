#!/bin/bash

LOG_CONFIG_FILE=/zookeeper/conf/log4j.properties


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
    /zookeeper/conf/zoo_sample.cfg > /zookeeper/conf/zoo.cfg

/zookeeper/bin/zkServer.sh start-foreground
