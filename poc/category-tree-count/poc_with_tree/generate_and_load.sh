#!/bin/sh

BASEDIR=$(dirname "$0")
php ${BASEDIR}/generator/generator.php
./load.sh

