#!/bin/bash

#
# Die Freigabe Apotheke am S3000-Server sollte in fstab eingetragen sein:
#//10.xx.yy.64/Apotheke /mnt/Apo/[IDF] cifs rw,uid=1000,gid=1000,users,username=s3000,password=,domain=D-[IDF] 0 0
#

DEBUG=0
VERBOSE=0
DRYRUN=0

VERSION="0.3 (09.06.2023)"
CONFIGFILE=config.sh

SUBJECT="Aktuelle Lagerliste Antibiotika/Fiebermittel"

SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${SCRIPT_PATH}" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
  [[ ${SCRIPT_PATH} != /* ]] && SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_PATH}"
done
SCRIPT_PATH="$(readlink -f "${SCRIPT_PATH}")"
SCRIPT_DIR="$(cd -P "$(dirname -- "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
CONFIGPATH=${SCRIPT_DIR}/${CONFIGFILE}

SUFFIX=_neu!

TEMPDIR=/media/usbstick/temp

if [ ! -d "$TEMPDIR" ]; then
	TEMPDIR=/tmp
fi

while (( "$#")); do
	if [ $1 == "-v" ]; then
		VERBOSE=1
	fi
	
	if [ $1 == "-c" ]; then
		shift
		LOCALCONFIG=$1
		LOCALCONFIGFILE=config-${LOCALCONFIG}.sh
		LOCALCONFIGPATH=${SCRIPT_DIR}/${LOCALCONFIGFILE}
		LOCALMAILTEMPLATE=${SCRIPT_DIR}/mail-template-${LOCALCONFIG}.html

	fi
	
	if [ "$1" == "--verbose" ]; then
		VERBOSE=1
	fi
	
	if [ "$1" == "--debug" ]; then
		DEBUG=1
	fi
	
	if [ "$1" == "--dry" ]; then
		DRYRUN=1		
	fi
	
	shift    
done

if [ $VERBOSE -eq 1 ]; then
	echo -e "\n*** Lagerlisten-Mailer ${VERSION} ***\n\n"
fi

if [ -x $CONFIGPATH ]; then
	source $CONFIGPATH

	if [ $VERBOSE -gt 0 ]; then
		echo "Using config file ${CONFIGFILE}"
	fi
fi

if [ ! -z $LOCALCONFIG ]; then
	if [ -x $LOCALCONFIGPATH ]; then
		source $LOCALCONFIGPATH
	
		if [ $VERBOSE -gt 0 ]; then
			echo "Using LOCAL config file ${LOCALCONFIGFILE}"
		fi
	else
		echo "Local config path does not exist: ${LOCALCONFIGPATH}"
		echo "ERROR: Config set ${LOCALCONFIG} not found!"
		echo "Exiting.."
		exit 1
	fi
fi

if [ $DEBUG -eq 1 ]; then	
	RECIPIENTS=("${ERRORRECIPIENT}")
fi

if [ -z "$HTMLDIR" ]; then
	HTMLDIR=$TEMPDIR
fi

if [ -z "$FINALDIR" ]; then
	FINALDIR=$HTMLDIR
fi

TITLE="Lagerliste ${APONAME}"
HTML=lagerliste
PDF="Lagerliste_Apo_Schug_${STANDORT}"
HTMLPATH=${HTMLDIR}/${HTML}.html

PDFPATH=${TEMPDIR}/${PDF}.pdf
PDFPATH2=${FINALDIR}/${PDF}.pdf
PDFPATH3=${FINALDIR}/${PDF}${SUFFIX}.pdf

if [ -z "$SENDPATH" ]; then
	SENDPATH=$PDFPATH
fi

MAILTEMPLATE=$SCRIPT_DIR'/mail-template.html'

if [ -r "$LOCALMAILTEMPLATE" ]; then
	MAILTEMPLATE=$LOCALMAILTEMPLATE
fi

if [ $VERBOSE -eq 1 ]; then
	echo "Script Dir is determined to ${SCRIPT_DIR}"
	echo "Creating ${HTML} for ${APONAME} in ${STANDORT}"
	echo "HTML file path is set to ${HTMLPATH}"
	echo "PDF file path is set to ${PDFPATH}"
	echo "PDF2 file path is set to ${PDFPATH2}"
fi

if [ ! -z $MOUNTDIR ]; then
	if [ -d $MOUNTDIR ]; then
		if [ $VERBOSE -eq 1 ]; then
			echo "Mount dir is set to ${MOUNTDIR}"
		fi
		
		if [ -z "$(grep $MOUNTDIR /proc/mounts)" ]; then
			if [ $VERBOSE -eq 1 ]; then
				echo "Mount dir seems not to be mounted!"
				echo "Try to mount $MOUNTDIR .."
			fi
			mount $MOUNTDIR
			if [ $? -eq 1 ]; then
				echo "ERROR mounting $MOUNTDIR !"				
			else
				if [ $VERBOSE -eq 1 ]; then
					echo "Successfully mounted $MOUNTDIR"
				fi
			fi
		else
			if [ $VERBOSE -eq 1 ]; then
				echo "Mount dir seems to be mounted correctly"
			fi
		fi
	else
		if [ $VERBOSE -eq 1 ]; then
			echo "Mount dir seems to be valid dir: $MOUNTDIR"
		fi
	fi
fi
	
if [ ! -d $TEMPDIR ]; then
		echo "ERROR: Temp Dir does not exist ${TEMPDIR} !"
		exit 1
fi

if [ ! -d $HTMLDIR ]; then
		echo "ERROR: HTML Dir does not exist ${HTMLDIR} !"
		exit 1
fi

if [ ! -d $FINALDIR ]; then
		echo "ERROR: FINAL Dir does not exist ${FINALDIR} !"
		exit 1
fi


if [ -f $HTMLPATH ]; then
	rm $HTMLPATH

	if [ -f $HTMLPATH ]; then
		echo "ERROR: Cannot remove old ${HTMLPATH} !"
		exit 1
	elif [ $VERBOSE -eq 1 ]; then
		echo "Successfully removed old ${HTMLPATH}"
	fi
	
fi

if [ -f $PDFPATH ]; then
	rm $PDFPATH

	if [ -f $PDFPATH ]; then
		echo "ERROR: Cannot remove old ${PDFPATH} !"
		exit 1
	elif [ $VERBOSE -eq 1 ]; then
		echo "Successfully removed old ${PDFPATH}"
	fi
fi

if [ -f $PDFPATH2 ]; then
	rm $PDFPATH2

	if [ -f $PDFPATH2 ]; then
		echo "WARNING: Cannot remove old ${PDFPATH2} !"		
	elif [ $VERBOSE -eq 1 ]; then
		echo "Successfully removed old ${PDFPATH2}"
	fi
fi

if [ -f $PDFPATH3 ]; then
	rm $PDFPATH3

	if [ -f $PDFPATH3 ]; then
		echo "WARNING: Cannot remove old ${PDFPATH3} !"		
	elif [ $VERBOSE -eq 1 ]; then
		echo "Successfully removed old ${PDFPATH3}"
	fi
fi

if [ -z $LOCALCONFIG ]; then
	HTMLDATA=$($SCRIPT_DIR'/prepare_html_list.php')
else
	HTMLDATA=$($SCRIPT_DIR'/prepare_html_list.php' "$LOCALCONFIG")
fi

if [ $? -eq 1 ]; then
    echo "ERROR preparing data:"
    echo "$HTMLDATA"    
elif [ -z "$HTMLDATA" ]; then
	echo "ERROR data is empty!"        
else

 	echo "${HTMLDATA}" > ${HTMLPATH}

 	TS=$(date +"%d.%m.%Y %H:%M")
 	
 	echo "Jetzt ist ${TS}"
 	#--debug-javascript
 	/usr/local/bin/wkhtmltopdf --title "${TITLE}" -n \
 	--margin-bottom 15mm --margin-top 15mm --margin-left 15mm --margin-right 15mm \
 	--header-left "Lagerliste" --header-font-size 8 --header-center "${APONAME}" --header-line --header-spacing 5 \
 	--footer-right "Seite [page] von [topage]" --footer-left "${TS}" --footer-line --footer-font-size 8 --footer-spacing 5 \
 	${HTMLPATH} ${PDFPATH}
 	
 	if [ $? -gt 0 ]; then
 		echo "ERROR on creating $PDFPATH by wkhtmltopdf"
 	else
 		if [ ! -f $PDFPATH2 ]; then
			cp $PDFPATH $PDFPATH2
			if [ $? -eq 1 ]; then
				echo "ERROR copying from $PDFPATH to $PDFPATH2"				
			else
				if [ $VERBOSE -eq 1 ]; then
					echo "Successfully copied from $PDFPATH to $PDFPATH2"
				fi
			fi
		else
			cp $PDFPATH $PDFPATH3
			if [ $? -eq 1 ]; then
				echo "ERROR copying from $PDFPATH to $PDFPATH3"				
			else
				if [ $VERBOSE -eq 1 ]; then
					echo "Successfully copied from $PDFPATH to $PDFPATH3"
				fi
			fi
		fi
		
		for RECIPIENT in "${RECIPIENTS[@]}"; do
			if [ $VERBOSE -eq 1 ]; then
				echo -e "Sende Mail an ${RECIPIENT} ..\n"
			fi

			if [ $DRYRUN -eq 0 ]; then
				cat $MAILTEMPLATE | s-nail -s "$SUBJECT" -r "$REPLYTO" -M "text/html" -a $SENDPATH $RECIPIENT
			else
				if [ $VERBOSE -eq 1 ]; then
					echo "Dry run! Sende nichts!"
				fi
			fi
		done		
	fi	
fi