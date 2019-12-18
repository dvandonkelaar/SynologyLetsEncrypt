# SynologyLetsEncrypt

Issue or renew the let's encrypt (wildcard) certificate on Synology

Based on https://github.com/Neilpang/acme.sh/


This script can be automatically or manually run by the Synology task manager or through SSH.

The script searches for the default certificate and renews it.


The domain is specified in the config.ini by Domain=mydomain.tld. The script will issue or renew the the following domains:
- mydomain.tld
- *.mydomain.tld


Before starting, the script will download the latest acme.sh from https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh to be sure the latest script is used.


If there is no indicator the script is run before, the script will first issue a certificate.
If the script is run before, mydomain.tld.csr.conf or mydomain.tld.conf exist in the output folder.
If the script is not run before, the following output is generated.
```
Add the following TXT record:
Domain: '_acme-challenge.mydomain.tld'
TXT value: 'LongTextValueWhichNeedsToBeAddedToTheDomain'
Please be aware that you prepend _acme-challenge. before your domain
so the resulting subdomain will be: _acme-challenge.domein.nl
Add the following TXT record:
Domain: '_acme-challenge.mydomain.tld'
TXT value: 'LongTextValueWhichNeedsToBeAddedToTheDomain'
Please be aware that you prepend _acme-challenge. before your domain
so the resulting subdomain will be: _acme-challenge.domein.nl
Please add the TXT records to the domains, and re-run with --renew.
Please add '--debug' or '--log' to check more details.
See: https://github.com/Neilpang/acme.sh/wiki/How-to-debug-acme.sh
```
Both TXT values need to be added to the domain
These TXT-values only need to be added for the first issue. For a renew, the cert will be validated with this values.



As a backup, the script copies the generated scripts to the certificate-folder, with the current date as subfolder and converts them to .pem-files.
The .pem-files are copied to the certificate-folder and nginx is restarted.


At last, the cert.pem is copied to the cert.pem-files for the different packages and the packages are restarted.
