#!/bin/bash

# Copyright (c) 2018-2020 Fernando Nunes - domusonline@gmail.com
# License: This script is licensed as GPL V2 ( http://www.gnu.org/licenses/old-licenses/gpl-2.0.html )
# $Author: Fernando Nunes - domusonline@gmail.com $
# $Revision: .1 $
# $Date: 2020-01-30 11:08:14 $
# Disclaimer: This software is provided AS IS, without any kind of guarantee. Use at your own risk.
#             Although the author is/was an IBM employee, this software was finished and published outside his job engagements.
#             As such, all credits are due to the author.


show_help()
{
	echo "Usage: ${PROGNAME} -d <CB_DIR> -f <CB_TAB> [ -e <CB_EXT> ] [ -s <separator char>"
	echo "	CB_DIR : Folder where the copybook files exist"
	echo "	CB_TAB : File within the CB_DIR where the list of files to process is defined"
	echo "	CB_EXT : Optional extension to append to the copybook name in the CB_TAB file"
	echo "  separator char : caracter to use as base file column separator. Default is space"
}

get_args()
{

	arg_ok="hVd:f:e:s:"
	while getopts ${arg_ok} OPTION
	do
		case ${OPTION} in
		h)   # show help
			show_help
			exit 0
			;;
		V)      #show version
			echo "${PROGNAME} ${VERSION}" >&1
			exit 0
			;;
		d)
			CB_DIR=${OPTARG}
			if [ ! -d ${CB_DIR} ]
			then
				echo "${PROGNAME}: Error - Copybook directory (${CB_DIR}) is not a directory, or is not accessible" >&2
				return 1
			fi
			CB_DIR_FLAG=1
			;;
		f)
			CB_TAB=${OPTARG}
			CB_TAB_FLAG=1
			;;
		e)
			CB_EXT=${OPTARG}
			CB_EXT_FLAG=1
			;;
		s)
			SEPARATOR_CHAR=${OPTARG}
			SEPARATOR_FLAG=1
			;;
		*)
			echo "${PROGNAME}: Error - Invalid option (${OPTION})" >&2
			return 1
			;;
		esac
	done
}

cleanup()
{
	if [ "X${TMP_DIR}" != "X" ]
	then
		if [ -d ${TMP_DIR} ]
		then
			rm -rf /tmp/${PROGNAME}_$$
		fi
	fi
	rm -f ${TMP_ERR_FILE} ${TMP_OUT_FILE} ${TMP_LOG_FILE} ${TMP_OK_FILE} ${TMP_NOTOK_FILE}
}


#START
trap cleanup 0
PROGNAME=`basename $0`
SCRIPT_DIR=`dirname $0`
VERSION=`echo "$Revision: .1 $" | cut -f2 -d' '`
TMP_DIR=/tmp/${PROGNAME}_$$
TMP_ERR_FILE=/tmp/${PROGNAME}_$$.err
TMP_OUT_FILE=/tmp/${PROGNAME}_$$.out
TMP_LOG_FILE=/tmp/${PROGNAME}_$$.log
TMP_OK_FILE=/tmp/${PROGNAME}_$$.ok
TMP_NOTOK_FILE=/tmp/${PROGNAME}_$$.notok

#---------------------------------------------------------------------------------------
# CONFIG SECTION
# - Edit the variables definition below
#---------------------------------------------------------------------------------------

ISTOOL=/opt/IBM/InformationServer/Clients/istools/cli/istool.sh
JAR_DIR=${SCRIPT_DIR}
STYLESHEET_CSV=${SCRIPT_DIR}/cb2xml_to_csv_istool.xsl
STYLESHEET_AWK=${SCRIPT_DIR}/cb2xml_extract_level.xsl
CLEAN_HOGAN_FLAG=0
CLEAN_HOGAN_AWK=${SCRIPT_DIR}/clean_hogan.awk
AUTHFILE=${SCRIPT_DIR}/AuthFile
JAVA=/opt/IBM/InformationServer/jdk/jre/bin/java
DEBUG_FILES=1


get_args $*
if [ $? != 0 ]
then
	echo "${PROGNAME}: Error - Invalid arguments" >&2
	show_help >&2
	exit 1
fi

if [ "X${CB_DIR_FLAG}" != "X1" ]
then
	echo "${PROGNAME}: Error - Invalid arguments. Option -d is required" >&2
	show_help >&2
	exit 1
else
	if [ "X${CB_TAB_FLAG}" != "X1" ]
	then
		echo "${PROGNAME}: Error - Invalid arguments. Option -d is required" >&2
		show_help >&2
		exit 1
	else
		echo ${CB_TAB} | grep "^/" >/dev/null
		if [ $? = 0 ]
		then
			CB_TAB=$CB_TAB
		else
			CB_TAB=${CB_DIR}/${CB_TAB}
		fi
		if [ ! -r ${CB_TAB} ]
		then
			echo "${PROGNAME}: Error - CB_TAB file (${CB_DIR}/${CB_TAB} does not exist or is not readable" >&2
			exit 1
		fi
		if [ "X${CB_EXT_FLAG}" != "X1" ]
		then
			CB_EXT=""
		else
			echo "${CB_EXT}" | grep "^\." >/dev/null
			if [ $? != 0 ]
			then
				CB_EXT=.${CB_EXT}
			fi
		fi
		if [ "X${SEPARATOR_FLAG}" != "X1" ]
		then
			SEPARATOR_CHAR=" "
		else
			CHAR_COUNT=`echo "${SEPARATOR_CHAR}" | wc -c| cut -f1 `
			if [ $CHAR_COUNT != 1 ]
			then
				echo "${PROGNAME}: Error - SEPARATOR_CHAR (${SEPARATOR_CHAR}) cannot have more than one character" >&2
				exit 1
			fi
		fi
	fi
fi


cd ${SCRIPT_DIR}
mkdir ${TMP_DIR}
#while read vHOST vFOLDER vDATAFILE vRECORD vFIELD vAPL vPATH
while read FILE_LINE
do
	vHOST=`echo "$FILE_LINE"     | awk -F"${SEPARATOR_CHAR}" '{print $1}'`
	vFOLDER=`echo "$FILE_LINE"   | awk -F"${SEPARATOR_CHAR}" '{print $2}'`
	vDATAFILE=`echo "$FILE_LINE" | awk -F"${SEPARATOR_CHAR}" '{print $3}'`
	vRECORD=`echo "$FILE_LINE"   | awk -F"${SEPARATOR_CHAR}" '{print $4}'`
	vFIELD=`echo "$FILE_LINE"    | awk -F"${SEPARATOR_CHAR}" '{print $5}'`
	vAPL=`echo "$FILE_LINE"      | awk -F"${SEPARATOR_CHAR}" '{print $6}'`
	vPATH=`echo "$FILE_LINE"     | awk -F"${SEPARATOR_CHAR}" '{print $7}'`

	if [ "X${vHOST}" = "XHOST" -a "X${vFOLDER}" = "XFOLDER" ]
	then
		continue
	fi

	echo "INFO: Processing ${CB_DIR}/${vRECORD}${CB_EXT} file" >>${TMP_LOG_FILE}
	if [ ! -r ${CB_DIR}/${vRECORD}${CB_EXT} ]
	then
		echo "ERROR: Copybook file (${CB_DIR}/${vRECORD}${CB_EXT}) doesn't exist or can't be read" >>${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		continue
	fi
	COPYBOOK=${TMP_DIR}/${vRECORD}

	if [ "X${CLEAN_HOGAN_FLAG}" = "X1" ]
	then
		gawk -f ${CLEAN_HOGAN_AWK} ${CB_DIR}/${vRECORD}${CB_EXT} >${COPYBOOK} 2>${TMP_ERR_FILE}
		if [ $? != 0 ]
		then
			echo "ERROR: Processing copybook (${vRECORD}${CB_EXT} with awk to remove Hogan fields:" >>${TMP_LOG_FILE}
			cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
			echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
			continue
		fi
	else
		cp ${CB_DIR}/${vRECORD}${CB_EXT} ${COPYBOOK}
	fi
	[ "X${DEBUG_FILES}" = "X1" ] && cat ${COPYBOOK} >>${TMP_LOG_FILE}
	COPYBOOK_XML="${TMP_DIR}/${vRECORD}.xml"
	COPYBOOK_CSV="${TMP_DIR}/${vRECORD}.csv"
	COPYBOOK_AWK="${TMP_DIR}/${vRECORD}.awk"
	ISX_FILE="${TMP_DIR}/${vRECORD}.isx"
	ISX_DIR="${TMP_DIR}/${vRECORD}_isx_dir"


	echo "Converting CopyBook (${COPYBOOK}) to XML (${COPYBOOK_XML})" >>${TMP_LOG_FILE}
	$JAVA -cp ${SCRIPT_DIR} -jar ${JAR_DIR}/cb2xml.jar -indentXml -cobol "${COPYBOOK}" -xml "${COPYBOOK_XML}" 1>${TMP_OUT_FILE} 2>${TMP_ERR_FILE}
	if [ $? != 0 ]
	then
		echo "ERROR: processing copybook (${COPYBOOK}) with CB2XML:" >>${TMP_LOG_FILE}
		cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
		echo >> ${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		continue
	fi
	cat ${TMP_ERR_FILE} >> ${TMP_LOG_FILE}

	[ "X${DEBUG_FILES}" = "X1" ] && cat ${COPYBOOK_XML} >>${TMP_LOG_FILE}

	echo "Converting XML (${COPYBOOK_XML}) to CSV (${COPYBOOK_CSV})" >>${TMP_LOG_FILE}
	$JAVA -cp ${JAR_DIR}/xalan.jar org.apache.xalan.xslt.Process -IN "${COPYBOOK_XML}" -XSL ${STYLESHEET_CSV} -PARAM P_DATAFILE "$vDATAFILE" -PARAM P_DATAFILE_DESCRIPTION "${vDATAFILE}_Description" -PARAM P_DATAFILE_STRUCTURE "$vRECORD" -PARAM P_DATAFILE_STRUCTURE_DESCRIPTION "${vRECORD}_Description" -PARAM P_PATH "${vPATH}" -PARAM P_HOST "${vHOST}" -PARAM P_FOLDER "$vFOLDER" > "${COPYBOOK_CSV}" 2>${TMP_ERR_FILE}
	if [ $? != 0 ]
	then
		echo "ERROR: generating CSV file from XML file (${COPYBOOK_XML})" >>${TMP_LOG_FILE}
		cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		continue
	fi

	[ "X${DEBUG_FILES}" = "X1" ] && cat ${COPYBOOK_CSV} >>${TMP_LOG_FILE}

	echo "Obtaining *.awk file from XML file created by CB2XML (${COPYBOOK_XML})" >>${TMP_LOG_FILE}
	$JAVA -cp ${JAR_DIR}/xalan.jar org.apache.xalan.xslt.Process -IN "${COPYBOOK_XML}" -XSL ${STYLESHEET_AWK} -PARAM P_DATAFILE "$pDATAFILE" -PARAM P_DATAFILE_DESCRIPTION "$pDATAFILE_DESCRIPTION" -PARAM P_DATAFILE_STRUCTURE "$pDATAFILE_STRUCTURE" -PARAM P_DATAFILE_STRUCTURE_DESCRIPTION "$pDATAFILE_STRUCTURE_DESCRIPTION" -PARAM P_PATH "$pPATH" -PARAM P_HOST "$pHOST" -PARAM P_FOLDER "$pFOLDER" -PARAM P_HOST_DESCRIPTION "$pHOST_DESCRIPTION" > "${COPYBOOK_AWK}" 2>${TMP_ERR_FILE}
	if [ $? != 0 ]
	then
		echo "ERROR: generating AWK file from XML file (${COPYBOOK_XML})" >>${TMP_LOG_FILE}
		cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		continue
	fi

	[ "X${DEBUG_FILES}" = "X1" ] && cat ${COPYBOOK_AWK} >>${TMP_LOG_FILE}
	
	echo "Generating istool archive file from CSV file" >>${TMP_LOG_FILE}
	$ISTOOL workbench generate -authfile ${AUTHFILE} -archive ${TMP_DIR} -input ${COPYBOOK_CSV} >${TMP_OUT_FILE} 2>${TMP_ERR_FILE} 1>&2
	if [ $? != 0 ]
	then
		echo "ERROR: generating an XML file from the CSV file (${COPYBOOK_CSV}) with istool" >>${TMP_LOG_FILE}
		cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		continue
	else
		#debug
		cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
	fi

	CURR_DIR=`pwd`
	mkdir ${ISX_DIR}
	cd ${ISX_DIR}
	unzip ${ISX_FILE} >${TMP_OUT_FILE} 2>${TMP_ERR_FILE}
	if [ $? != 0 ]
	then
		echo "ERROR: unziping isx file generated by istool (${ISX_FILE})" >>${TMP_LOG_FILE}
		cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
		ls -l ${ISX_DIR} >> ${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		rm -rf ${ISX_FILE} ${ISX_DIR}
		continue
	fi
	mv CONTENT/db.db CONTENT/temp.db
	
	gawk -f $COPYBOOK_AWK CONTENT/temp.db > CONTENT/db.db 2>${TMP_ERR_FILE}
	if [ $? != 0 ]
	then
		echo "ERROR: processing XML (db.db) file in the isx file (${ISX_FILE}) with awk" >>${TMP_LOG_FILE}
		cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		rm -rf ${ISX_FILE} ${ISX_DIR}
		continue
	fi
	
	rm -f ${ISX_FILE} CONTENT/temp.db 
	zip -r ${ISX_FILE} CONTENT/ META-INF/ >${TMP_OUT_FILE} 2>${TMP_ERR_FILE}
	if [ $? != 0 ]
	then
		echo "ERROR: zipping contents of isx file (${ISX_FILE})" >>${TMP_LOG_FILE}
		cat ${TMP_ERR_FILE} >> ${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		rm -rf ${ISX_FILE} ${ISX_DIR}
		continue
	fi
	echo "DEBUG" >>${TMP_LOG_FILE}
	pwd >>${TMP_LOG_FILE}
	$ISTOOL import -authfile ${AUTHFILE} -replace -archive ${ISX_FILE} -cm '' 1>${TMP_OUT_FILE} 2>${TMP_ERR_FILE}
	if [ $? != 0 ]
	then
		echo "ERROR: Error importing file (${ISX_FILE}):" >>${TMP_LOG_FILE}
		cat ${TMP_ERR_FILE} >>${TMP_LOG_FILE}
		echo "	"${vRECORD}>>${TMP_NOTOK_FILE}
		rm -rf ${ISX_FILE} ${ISX_DIR}
		continue
	fi
	
	echo ${vRECORD}>>${TMP_OK_FILE}
	cd ${CURR_DIR}
	rm -rf ${ISX_FILE} ${ISX_DIR}
done < ${CB_TAB}
if [ -s ${TMP_OK_FILE} ]
then
	echo "Successfully loaded copybooks:"
	cat ${TMP_OK_FILE}
fi

if [ -s ${TMP_NOTOK_FILE} ]
then
	echo "Unsuccessfully processed copybooks:"
	cat ${TMP_NOTOK_FILE}
fi
echo "Complete log:"
cat ${TMP_LOG_FILE}
