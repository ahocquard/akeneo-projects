#!/bin/sh

BASEDIR=$(dirname "$0")
php ${BASEDIR}/generator/generator.php
${BASEDIR}/load.sh

