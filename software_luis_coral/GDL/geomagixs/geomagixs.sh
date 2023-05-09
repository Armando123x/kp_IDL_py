#!/bin/sh
#
# Calling sequence
#      ./geomagixs.sh $GMS -[real_time/final]
#
#

#GEOMAGIXS_LIB_DIR_OLD=$GEOMAGIXS_LIB_DIR
GEOMAGIXS_LIB_DIR=$HOME/GDL/geomagixs

#export
###changing initial file

IDL_STARTUP_OLD=$IDL_STARTUP
IDL_STARTUP=$GEOMAGIXS_LIB_DIR/system/geomagixs_idl_startfile

#IDL_DIR=/usr/local/rsi/idl
. /usr/local/rsi/idl/bin/idl_setup.bash

cd $GEOMAGIXS_LIB_DIR
# NUEVO ARCHIVO DE INICIO DE IDL
/usr/local/bin/idl -quiet -e geomagixs -args $GEOMAGIXS_LIB_DIR $1 $2 > $GEOMAGIXS_LIB_DIR/log.$1_daily.txt


# VIEJO ARCHIOVO DE INICIO DE IDL
IDL_STARTUP=$IDL_STARTUP_OLD

