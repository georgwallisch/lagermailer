#!/bin/bash

#
# Die Freigabe Apotheke am S3000-Server sollte in fstab eingetragen sein:
#//10.xx.yy.64/Apotheke /mnt/Apo/[IDF] cifs rw,uid=1000,gid=1000,users,username=s3000,password=,domain=D-[IDF] 0 0
#

DEBUG=0
VERBOSE=0
DRYRUN=0

#RECIPIENT="info@kinderarzt-kemnath.de"
ERRORRECIPIENT="it@apotheke-schug.com"
RECIPIENTS=("kemnath@apotheke-schug.com" "info@kinderarzt-kemnath.de")
#RECIPIENTS=("stephan.schug@apotheke-schug.com" "kemnath@apotheke-schug.com" "it@apotheke-schug.com")

SUBJECT="Aktuelle Lagerliste Antibiotikum-Säfte"
MAILBODY=$('/home/pi/ab-mailer/prepare_mail_body.php')
REPLYTO="kemnath@apotheke-schug.com"

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

if [ $? -eq 1 ]; then
    echo "ERROR preparing mail body:"
    echo "$MAILBODY"
    echo "FEHLER beim Erstellen des Mailinhaltes:\n\n${MAILBODY}" | s-nail -s "FEHLER: ${SUBJECT}" -M "text/html" $ERRORRECIPIENT
elif [ -z "$MAILBODY" ]; then
	echo "ERROR mail body is empty!"
    echo "FEHLER beim Erstellen des Mailinhaltes: Inhalt ist leer!" | s-nail -s "FEHLER: ${SUBJECT}" -M "text/html" $ERRORRECIPIENT    
else
	if [ $VERBOSE -eq 1 ]; then
		echo -e "=== BEGINN Mailbody ===\n\n"
		echo "$MAILBODY"
		echo -e "\n\n=== ENDE Mailbody ===\n\n"
 	fi
 	
	for RECIPIENT in "${RECIPIENTS[@]}"
	do
		if [ $VERBOSE -eq 1 ]; then
			echo -e "Sende Mail an ${RECIPIENT} ..\n"
		fi

		if [ $DRYRUN -eq 0 ]; then
			echo "$MAILBODY" | s-nail -s "$SUBJECT" -r "$REPLYTO" -M "text/html" $RECIPIENT
		else
			if [ $VERBOSE -eq 1 ]; then
				echo "Dry run! Sende nichts!"
			fi
		fi
	done
fi



