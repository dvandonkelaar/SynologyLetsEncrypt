#!/bin/bash


  #####  DEFAULT VARIABLES
CertRoot="/usr/syno/etc/certificate/_archive"
PackageCertRoot="/usr/local/etc/certificate"
DefaultCertFolder=$CertRoot/$( sudo cat $CertRoot/DEFAULT )
CertExportDir=/root/.acme.sh
CurDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ExportDir="$CurDir/certificates"
CurrentDate=$(date +"%Y-%m-%d")


	#####  Read domain from config file
ConfigFile="$CurDir/config.ini"
if [[ ! -f $ConfigFile ]]; then
	echo "Config file (config.ini) does not exist. Making it..."
	echo "Domain=" > "$ConfigFile"
fi
ConfigContent=$(cat "$ConfigFile" | sed -r '/[^=]+=[^=]+/!d' | sed -r 's/\s+=\s/=/g')
eval "$ConfigContent"


	#####  Check if we are running as root
if [ $(id -u) -ne 0 ];then
	echo "Please run as root"
	exit 1
fi


	#####  Get latest certificate
acme="$CurDir/acme.sh"
wget -O "$acme" https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh


	#####  Check to issue or renew certificate
if [[ -f "$CertExportDir/$Domain/$Domain.conf" && -f "$CertExportDir/$Domain/$Domain.csr.conf" ]]; then
	argument=renew
else
	argument=issue
fi

"$acme" --$argument -d $Domain -d *.$Domain --dns --force --yes-I-know-dns-manual-mode-enough-go-ahead-please


	#####  Check if we're in the renew process
if [ $argument = renew ]; then

	#####  Certificate renew process
	if [ ! -d "$ExportDir" ]; then
		mkdir -p "$ExportDir"
	fi

	if [ ! -d "$ExportDir/$CurrentDate" ]; then
		mkdir "$ExportDir/$CurrentDate"
	elif [ "$(ls -A $"$ExportDir/$CurrentDate")" ]; then
		rm "$ExportDir/$CurrentDate/*"
	fi

	####  Copy files to local dir
	cp $CertExportDir/$Domain/$Domain.cer "$ExportDir/$CurrentDate"
	cp $CertExportDir/$Domain/$Domain.key "$ExportDir/$CurrentDate"
	cp $CertExportDir/$Domain/ca.cer "$ExportDir/$CurrentDate"
	cp $CertExportDir/$Domain/fullchain.cer "$ExportDir/$CurrentDate"

	####  Convert files to .pem
	cp "$ExportDir/$CurrentDate/$Domain.cer" "$ExportDir/$CurrentDate/cert.pem"
	cp "$ExportDir/$CurrentDate/$Domain.key" "$ExportDir/$CurrentDate/privkey.pem"
	cp "$ExportDir/$CurrentDate/ca.cer" "$ExportDir/$CurrentDate/chain.pem"
	cp "$ExportDir/$CurrentDate/fullchain.cer" "$ExportDir/$CurrentDate/fullchain.pem"

	####  UpDate used certificates
	declare -a files=( "$ExportDir/$CurrentDate/cert.pem" "$ExportDir/$CurrentDate/privkey.pem" "$ExportDir/$CurrentDate/chain.pem" "$ExportDir/$CurrentDate/fullchain.pem" )

	for file in "${files}"
	do
		:
		cp "$file" $DefaultCertFolder
	done

	####  Restart nginx
	/usr/syno/sbin/synoservicectl --reload nginx


	###  Update and restart all installed packages
	PemFiles=$(find $PackageCertRoot -name cert.pem)
	if [ ! -z "$PEMFILES" ]; then
		for File in $PemFiles; do
			:
			#### Skip ActiveDirectoryServer since it has it's own certificate
			if [[ $File != *"/DirectoryServerForWindowsDomain/"* ]]; then
				cp "$ExportDir/$CurrentDate/cert.pem" "$(dirname $File)/"

				####  Get package name from path
				IFS="/"
				read -ra ADDR <<< "$${File/#"$PackageCertRoot/"}"
				Package=${ADDR[0]}

				/usr/syno/bin/synopkg restart $Package
			fi
		done
	fi

fi
