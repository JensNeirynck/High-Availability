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

### Phase 1 & 2: NETWORK ACCESS & INTERNET LAYER
Verbinding maken met vboxnet2 (deze is bij mij de juiste)
* `vi /etc/sysconfig/network-scripts/ifcfg-enp0s8`
* --> onboot = yes
* `service network restart`

Nu kan ik een SSH verbinding maken! Nice! :-) 

### Phase 3: TRANSPORT ACCESS
* `vi /etc/hosts`
* --> ziet er normaal uit

* `vi /etc/resolv.conf`
* --> oei, daar ontbreken stukken. searchdomain adden en ns ip wijzigen.

* `systemctl status named`
* --> niet running... geeft me al enige info over een fout in een "cynalco.com'
* --> Conclusie... er zitten fouten in config files

### Phase 4: APPLICATION LAYER
* `vi /etc/named.conf`
* --> listen-on-port 53 uncommenten
* --> andere typo's fixen met reverse zone

`vi /var/named/cynalco.com`
* --> NS record toevoegen voor tamatama
* --> IP's wisselen van beedle en butterfree
* --> CNAME record toevoegen voor files

`systemctl restart named`
* geen errors... altijd leuk.

`./acceptance_test.bats` runnen op golbat.
* --> Deze lukken allemaal

`./acceptance_test.bat` runnen op hosts.
* --> Deze lukken niet. Iets met de firewall?

`sudo firewall-cmd --list-all`
* --> Poort 53 is enkel open op tcp, terwijl udp nodig is...

* Toevoegen poort 53 in udp
`sudo firewall-cmd --add-port=53/udp --permanent`
...
* Bats testen werken nu ook op host

## End result
DNS servers running en de testen geven geen fouten.

 - ✓ Forward lookups private servers
 - ✓ Forward lookups public servers
 - ✓ Reverse lookups private servers
 - ✓ Reverse lookups public servers
 - ✓ Alias lookups private servers
 - ✓ Alias lookups public servers
 - ✓ NS record lookup
 - ✓ Mail server lookup

- 8 tests, 0 failures

## Resources

List all sources of useful information that you encountered while completing this assignment: books, manuals, HOWTO's, blog posts, etc.
## https://unix.stackexchange.com/questions/276893/what-ports-need-to-be-open-on-a-firewall-to-access-the-internet
## https://askubuntu.com/questions/550937/change-from-qwerty-to-azerty-in-command-line
## https://askubuntu.com/questions/550937/change-from-qwerty-to-azerty-in-command-line
