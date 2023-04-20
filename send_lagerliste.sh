#!/bin/bash

#
# Die Freigabe Apotheke am S3000-Server sollte in fstab eingetragen sein:
#//10.xx.yy.64/Apotheke /mnt/Apo/[IDF] cifs rw,uid=1000,gid=1000,users,username=s3000,password=,domain=D-[IDF] 0 0
#

DEBUG=0
VERBOSE=0
DRYRUN=0

VERSION="0.1 (20.04.2023)"
CONFIGFILE=config.sh

while (( "$#")); do
	if [ $1 == "-v" ]; then
		VERBOSE=1
	fi
	
	if [ "$1" == "--verbose" ]; then
		VERBOSE=1
	fi
	
	if [ "$1" == "--debug" ]; then
		DEBUG=1
		RECIPIENTS=("${ERRORRECIPIENT}")
	fi
	
	if [ "$1" == "--dry" ]; then
		DRYRUN=1		
	fi
	
	shift    
done

if [ $VERBOSE -eq 1 ]; then
	echo -e "\n*** Lagerlisten-Mailer ${VERSION} ***\n\n"
fi

if [ -x $CONFIGFILE ]; then
	source $CONFIGFILE

	if [ $VERBOSE -gt 0 ]; then
		echo "Using config file ${CONFIGFILE}";
	fi
fi

TITLE="Lagerliste ${APONAME}"
HTML=lagerliste
PDF="Lagerliste_Apo_Schug_${STANDORT}"
HTMLPATH=${TEMPDIR}/${HTML}.html
PDFPATH2=${TEMPDIR}/${PDF}.pdf
PDFPATH=${TEMPDIR}/${PDF}_neu!.pdf


if [ ! -d $TEMPDIR ]; then
		echo "ERROR: Temp Dir does not exist ${TEMPDIR} !"
		exit 1
fi

if [ $VERBOSE -eq 1 ]; then
	echo "Creating ${HTML} for ${APONAME} in ${STANDORT}"
	echo "HTML file path is set to ${HTMLPATH}"
	echo "PDF file path is set to ${PDFPATH}"
	echo "PDF2 file path is set to ${PDFPATH2}"
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

HTMLDATA=$('/home/pi/ab-mailer/prepare_html_list.php')

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
 	
 	if [ $? -eq 1 ]; then
 		echo "ERROR on creating $PDFPATH by wkhtmltopdf"
 	else
 		if [ ! -f $PDFPATH2 ]; then
			cp $PDFPATH $PDFPATH2
			if [ $? -eq 1 ]; then
				echo "ERROR copying from $PDFPATH to $PDFPATH2"
			elif [ $VERBOSE -eq 1 ]; then
				echo "Successfully copied from $PDFPATH to $PDFPATH2"			
			fi
		fi
	fi	
fi