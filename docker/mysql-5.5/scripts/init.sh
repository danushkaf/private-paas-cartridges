#!/bin/bash
# ------------------------------------------------------------------------
#
# Copyright 2005-2015 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
#
# ------------------------------------------------------------------------

set -e
if [ "${START_CMD}" = "PCA" ]; then
    echo "Starting python cartridge agent..."
	/usr/local/bin/start-agent.sh
	echo "Python cartridge agent started successfully"

else
    chown -R mysql:mysql /var/lib/mysql
    mysql_install_db --user mysql > /dev/null

    MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-""}
    MYSQL_DATABASE=${MYSQL_DATABASE:-""}
    MYSQL_USER=${MYSQL_USER:-""}
    MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}
    MYSQLD_ARGS=${MYSQLD_ARGS:-""}

    tfile=`mktemp`
    if [[ ! -f "$tfile" ]]; then
        return 1
    fi

cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("$MYSQL_ROOT_PASSWORD") WHERE user='root';
EOF

    if [[ $MYSQL_DATABASE != "" ]]; then
        echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tfile

        if [[ $MYSQL_USER != "" ]]; then
            echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
        fi
    fi

    /usr/sbin/mysqld --bootstrap --verbose=0 $MYSQLD_ARGS < $tfile
    #rm -f $tfile
    service mysql restart
    #exec /usr/sbin/mysqld $MYSQLD_ARGS --init-file=/etc/mysql/conf.d/my_sql.sql
fi