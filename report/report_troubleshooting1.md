# Enterprise Linux Lab Report - Troubleshooting

- Student name: Jens Neirynck
- Class/group: TIN-TI-3B (Gent)

## Instructions

- Write a detailed report in the "Report" section below (in Dutch or English)
- Use correct Markdown! Use fenced code blocks for commands and their output, terminal transcripts, ...
- The different phases in the bottom-up troubleshooting process are described in their own subsections (heading of level 3, i.e. starting with `###`) with the name of the phase as title.
- Every step is described in detail:
    - describe what is being tested
    - give the command, including options and arguments, needed to execute the test, or the absolute path to the configuration file to be verified
    - give the expected output of the command or content of the configuration file (only the relevant parts are sufficient!)
    - if the actual output is different from the one expected, explain the cause and describe how you fixed this by giving the exact commands or necessary changes to configuration files
- In the section "End result", describe the final state of the service:
    - copy/paste a transcript of running the acceptance tests
    - describe the result of accessing the service from the host system
    - describe any error messages that still remain

## Report

### Phase 1: Internetlaag
#### Kabel was niet aangesloten
kabel aangesloten

#### Gemerkt dat er geen ipv4 adres was
Gevonden door:
`ip a´

Opgelost door:
´vi /etc/sysconfig/network-interfaces/´
--> daar IPADRR veranderen naar IPADDR

### Phase 2: Transportlaag
#### Nginx service startte niet op, er zat een schrijffout in de configfile deze is gewijzigd naar nginx.
gevonden door:
`Sudo journalctl -l -f -u nginx.service´

opgelost door:
´vi /etc/nginx/nginx.conf´
--> wijzig een link naar nginx.pem

#### Nginx.service was niet enabled
gevonden door:
´Sudo systemctl status nginx.service´

opgelost door:
´Sudo systemctl enable nginx.service´

#### Poort 443 draaide niet
Gevonden door: 
´sudo ss -tulpn´
Opgelost door:
´vi /etc/nginx/nginx.conf´ 
--> 8443 naar 443 gezet

#### https was niet toegevoegd in de firewall
gevonden door:
´sudo firewall-cmd --get-services´

opgelost door:
´sudo firewall-cmd --add-service=https --permanent´
'sudo firewall-cmd --reload'

### Phase 3: Applicatielaag
Hier kon ik connectie maken met de http en https en kreeg ik de boodschap te zien

...

## End result

De testen runnen zonder problemen, en ik kan via mijn host de tekst bekijken.

## Resources

List all sources of useful information that you encountered while completing this assignment: books, manuals, HOWTO's, blog posts, etc.
https://github.com/JensNeirynck/cheat-sheets, geforked van bertvv
