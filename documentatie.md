# Documentatie High Availability

## Opdracht

[Opdrachtomschrijving](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/blob/master/assignment/assignment.md)

## Algemene informatie

[Algemene info](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/blob/master/algemeneinfo.md)

## Uitwerking opdracht

Deze sectie bestaat uit volgende delen:
* Opdelen van opdracht in deelopdrachten
* Uitwerking en informatie van elke deelopdracht

### Deel 1: Opzetten (single) LAMP-stack
Ik ben van start gegaan met het reproduceren van een gewone lamp-stack waarbij alle services op 1 server draaien. Hiervoor heb ik gebruik gemaakt van volgende rollen.
* [bertvv.mariadb](https://galaxy.ansible.com/bertvv/mariadb)
* [bertvv.drupal](https://galaxy.ansible.com/bertvv/drupal)
* [bertvv.httpd](https://galaxy.ansible.com/bertvv/httpd)

Deze lampstack is te bekijken op het ip 192.168.1.250, er kan ook een drupal site worden aangemaakt door naar 192.168.1.250/drupal7/install.php te gaan.

Het is snel duidelijk dat dit geen ideale omgeving is om een webservice te draaien voor een middelmatig tot groot bedrijf. Dit omdat alle requests naar 1 server worden gestuurd. Dit kan veel efficiënter...

### Deel 2: startvm.sh en initha.sh
Na het opzetten van de lamp stack was het tijd om de 'echte' opdracht te starten, ik ben meteen aan de slag gegaan met het creëren van een script waarin ik alle informatie kon zetten dat nodig is om de volledige HA-omgeving op te zetten([startvm.sh](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/blob/master/scripts/startvm.sh)) 
Dit script is doorheen de delen van de opdracht uitgegroeid tot een volwaardig en 'gebruiksvriendelijk' script.

Bij het opstarten van dat script ziet de gebruiker enkel het nodige, nl. hoe ver staat  het met de opstart van de omgeving. Alle andere info wordt in logs bijgehouden zodat deze later opvraagbaar zijn bij eventuele problemen. [Locatie logbestanden](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/tree/master/log)

Dit script wordt aangeroepen door [initha.sh](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/blob/master/scripts/initha.sh), dit is eigenlijk het enige script waar de gebruiker aanpassingen dient in te doen als hij/zij info wilt wijzigen.
   
Enkele lijnen uit het script:  
Onderstaande code kan aangepast worden naar true of false; Deze keuze beïnvloed de verdere opties in het script.
```
# KEUZE VAN DE OPTIE:
#########################################################################################
# Kiest u voor optie A vul dan "true"
# Kiest u optie B, vul dan "false"
	export OPTIONA=true
```
Optie A: Alle webservers hebben dezelfde prioriteit  
Hier zal de loadbalancer niet kijken naar de prioriteit van elke webserver, en zal er "round-robin" gewijs met requests worden omgegaan.
```
# Vul hier het aantal webservers in die u wenst te gebruiken om te loadbalancen
	export AANTALSERVERS=2
# Op welke poort wenst u te loadbalancen (standaard 80)
	export PORT=80
```
Optie B: Zelf de prioriteiten definiëren  
Aan de hand van onderstaande code zal de loadbalancer requests verdelen volgens prioriteit. De webservers met 'hoge prioriteit' zullen veel meer aangesproken worden dan de webservers met 'lage prioriteit'.
```
# Hoeveel webservers krijgen een hoge prioriteit? (Deze worden dus het meeste belast)
	export HIGH_PRIORITY=1
# Hoeveel webservers krijgen een gewone prioriteit?
	export NORMAL_PRIORITY=0
# Hoeveel webservers krijgen een lage prioriteit (Deze worden het minste belast)
	export LOW_PRIORITY=1

# Op welke poort wenst u te loadbalancen (standaard 80)
	export PORT=80
```
Op het einde van het script wordt het aantal te configureren webservers opgeteld, en zal het startVM.sh script in werking treden.

### Deel 3: Database server
De eerste server die geconfigureerd werd, was de database server. Deze zal aangeroepen worden door alle webservers binnen de omgeving.  
Ik heb gekozen om hier ook voor een mariadb te kiezen omdat ik al vrij gekend ben met deze omgeving.

De rol die ik hiervoor heb gebruikt is  [bertvv.mariadb](https://galaxy.ansible.com/bertvv/mariadb). Via deze rol is het zeer handig om de databank te configureren, en ook de rechten van gebruikers toe te kennen.  

Code-snippet met uit de YAML-file van db1 (host_vars). Hier wordt de databank 'drupal_db' gecreërd, alsook wordt er een user voor drupal aangemaakt. Merk op dat ik de belgische mirror van mariadb gebruik om de installatietijd te minimaliseren.
```
rhbase_firewall_allow_services:
  - mysql
  - http
  - https
httpd_status_enable: true
mariadb_bind_address: '0.0.0.0' #listen on all interfaces
mariadb_port: 3306
mariadb_databases:
  - name: drupal_db
mariadb_users:
  - name: drupal_user
    password: 'drupalha'
    priv: "drupal_db.*:ALL,GRANT"
    append_privs: 'yes'
    host: "192.168.1.%"

mariadb_mirror: 'mariadb.mirror.nucleus.be/yum' #installation is too slow in Belgium, therefore I added abelgian mirror which will be faster in Belgium.
mariadb_root_password: 'mariadb1'
```
De werking van de databank kan getest worden door naar het ip van de loadbalancer (192.168.1.3/testdb.php) te surfen.

### Deel 4: Webserver(s)
Voor de webservers heb ik, zoals de single lamp-stack, gebruik gemaakt van apache. Namelijk de rol [bertvv.httpd](https://galaxy.ansible.com/bertvv/httpd).    
Ook wordt er op de webserver een drupal installatie gezet, [bertvv.drupal](https://galaxy.ansible.com/bertvv/drupal). Deze maakt gebruik van de databank die in het vorige deel besproken is. De drupal installatie kan gedaan worden via '192.168.1.3/drupal7/install.php' nadat de loadblancer geïnstalleerd is.  
Als u een specifieke webserver wilt bezoeken, dient u te wachten tot het script volledig klaar is, deze zal dan op het einde een overzicht geven van de IP's die toegekend zijn aan de webserver(s).
  
Code-snippet uit de YAML-file van de webserver(s). Hier is voor drupal de gebruikersnaam, wachtwoord, databasenaam en het ip van de databank meegegeven.

```
rhbase_firewall_allow_services:
  - http
  - https

rhbase_selinux_booleans:
  - httpd_can_network_connect_db
  
httpd_status_enable: true
drupal_username: drupal_user
drupal_password: drupalha
drupal_database: drupal_db
drupal_database_host: 192.168.1.4
```
Bij het bezoeken van de webserver zal u een pagina te zien krijgen met enkele informatie, deze pagina dient om de effectieve werking van de loadbalancer later aan te tonen.

### Deel 5: Loadbalancing
Het volgende deel is de uitvoering van de effectieve loadbalancing. Ik heb lang gezocht naar een goede service om deze taak uit te voeren, uiteindelijk ben ik op 'pound' terecht gekomen.
Op Ansible Galaxy vond ik geen duidelijk beschreven roles die pound configureren. Daarom heb ik mijn eigen rol geschreven [jensneirynck.pound](https://galaxy.ansible.com/jensneirynck/pound). De uitleg en configuratie van deze rol is terug te vinden op mijn [git-repository over pound](https://github.com/JensNeirynck/ansible-role-pound).

Code-snippet uit de YAML-file van de loadbalancer. Hier wordt het ip ingesteld van de loadbalancer + de poort(en) waarop deze zal luisteren. Ook wordt hier de pool van webservers gedefinieerd waaruit de loabcalancer zal kiezen. Als er bij initha.sh gekozen wordt voor optie B, zullen hier de webservers verschillend prioriteiten hebben.
```
Pound_LoadBalancerHTTPIP: 192.168.1.3
Pound_LoadBalancerHTTPPort: 80
Pound_LoadBalancerHTTPSIP: 192.168.1.3
Pound_LoadBalancerHTTPSPort: 443
Webservers:
  - ip: 192.168.1.5
    port: 80
    priority: 5
  - ip: 192.168.1.6
    port: 80
    priority: 5
```
Dit kan dan weer gestest worden door te surfen naar 192.168.1.3, daar zal u een pagina te zien krijgen die aangboden is door een van de webservers. Bij  het refreshen van de pagina zal het request  mogelijks naar een andere webserver gaan.

### Deel 6: Monitoring
Er zijn zeer veerl monitoringtools om data te capteren en te visualiseren, zabbix is daar een van. Ik heb voor zabbix gekozen omdat deze een zeer mooie UI heeft. Ook bezit deze een dashboard waarop je alle informatie die je wilt zien kan toevoegen.  
Voor het monitoringdeel gebruik ik volgende rollen:  
* Ik heb de rol [dj-wasabi.zabbix-server](https://galaxy.ansible.com/dj-wasabi/zabbix-server) aangepast met enkele wijzigingen zodat selinux niet gedisabled moet worden. Deze aanpassingen zijn dan terug te vinden in [jensneirynck.zabbixserver](https://galaxy.ansible.com/jensneirynck/zabbixserver), een clone van de dj-wasabi.zabbix-server + mijn aanpassingen.
* [dj-wasabi.zabbix-web](https://galaxy.ansible.com/dj-wasabi/zabbix-web) voorziet een gui op de monitoringserver.
* [geerlingguy.apache](https://galaxy.ansible.com/geerlingguy/apache), deze is nodig omdat de rol een requirement is bij zabbix-web
* [dj-wasabi.zabbix-agent](https://galaxy.ansible.com/dj-wasabi/zabbix-agent) wordt geïnstalleerd op alle servers zodat deze kunnen communiceren met de monitor server.  

Code snippet van de configuratie van de monitor server, hier worden de basisinstellingen geconfiugeerd van de monitor-server.

```
zabbix_server_name: Monitoring HA
zabbix_server_database: mysql
zabbix_server_database_long: mysql
zabbix_server_dbport: 3306
zabbix_server_mysql_login_host: localhost
zabbix_server_mysql_login_user: root
zabbix_server_mysql_login_password: mariadb1
zabbix_url: 192.168.1.2/monitor
```

Code snippet van de configuratie van een webserver. Hier wordt de connectie gemaakt met de monitor-server die hierboven beschreven staat. Ook worden er dankzij deze configuratie automatisch host groups en hosts aangemaakt op de zabbix-server.
```
zabbix_agent_server: 192.168.1.2
zabbix_agent_serveractive: 192.168.1.2
zabbix_url: http://192.168.1.2
zabbix_api_create_hosts: true
zabbix_api_create_hostgroup: true
zabbix_create_hostgroup: present
zabbix_api_use: true 
zabbix_api_user: Admin
zabbix_api_pass: zabbix
zabbix_create_host: present
zabbix_useip: 1
zabbix_host_groups:
  - Webservers
zabbix_link_templates:
  - Template OS Linux
zabbix_selinux: true
zabbix_visible_hostname: web1
zabbix_agent_interfaces:
  - type: 1
    main: 1
    useip: 1
    ip: 192.168.1.5
```

Inloggen op de monitor server kan door te surfen naar 192.168.1.2, met als username "Admin" en wachtwoord "zabbix". Daar komt u dan terecht op het dashboard waar u alle informatie kan bundelen tot grafieken en tabellen.
### Deel 7: Rolling updates voor de webservers
Om de rolling updates te realiseren heb ik gebruik gemaakt van een klein [scriptje](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/blob/master/scripts/updatewebs.sh) dat ik zelf heb geschreven.
Dit script kan gestart worden door `updatewebs.sh <Locatie van lokaal bestand> <Externe locatie voor bestand>` te runnen. Deze zal alle webservers afgaan en via scp de bestanden kopiëren naar de gewenste locatie.  

N.B. Hier is wel gebruiksersinteractie nodig om de verbinding naar de webservers te authenticeren.

### Deel 8: Verschillen capteren tussen HA webservice en single LAMP-stack
Om de loadtesten uit te voeren heb ik gebruik gemaakt van [JMeter](https://jmeter.apache.org/). Dit is een zeer handige tool om de throughput van een webserver te bekijken.

Als ik deze dan effectief uitvoer kom ik tot de constatering dat het weldegelijk heeft opgebracht om de omgeving 'High Available" te maken.
## Recreëren van de HA-omgeving
Stappen voor het recreëren van de HA-omgeving:
* Pas [initha.sh](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/blob/master/scripts/initha.sh) aan door een gewenste optie te kiezen (A of B), en definieer het aantal webservers.
* Navigeer naar de 'scripts' directory en voer initha.sh uit, dit script duurt (bij 2 webservers) 20 minuten.
  ```
  cd elnx-1819-ha-JensNeirynck/scripts
  ./initlamp.sh
  ```

Nu staat de volledige omgeving al op. Wenst u ook nog de single-lamp op te starten, kan dit door onderstaande commando's. Dit zal ook weer enige tijd duren.
  ```
  cd elnx-1819-ha-JensNeirynck/scripts
  ./initha.sh
  ```

## Eigen evaluatie + motivatie a.d.h.v de rubics
Punten waarop gescoord zal worden:
  * Hoofdopdracht: High Availability -> Gevorderd/Deskundig
  Mijn opdracht heeft alle componenten die nodig waren voor de opdracht, zoals gezien in de demo draaien er 3 webservers parallel met elkaar. Ook is er een monitoring-dashboard voorzien. Ook is het mogelijk om de webservers te updaten. Deze kunnen uit de loadbalancer worden gehaald. Maar er kunnen geen extra webservers toegevoegd worden zonder de loadbalancer te herprovisionen.
  * Opdracht actualiteit -> Gevorderd  
  De pound-rol die ik heb geschreven is goed gedocumenteerd, en is ook een significante contributie aan de open-source wereld. Ook is mijn aanpassing van djwasabi.zabbix-server op ansible galaxy verschenen.
  * Troubleshooting -> Deskundig  
 Beide troubleshooting-labo's zijn postief verlopen. Deze heb ik volgens de correcte methode aangepakt en afgewerkt.
  * Laboverslagen -> Bekwaam  
  [verslag labo 1](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/blob/master/labos/labo1-verslag.md)
  [verslag labo 2](https://github.com/HoGentTIN/elnx-1819-ha-JensNeirynck/blob/master/labos/labo2-verslag.md)
  * Demonstraties -> Deskundig  
  Ik vind dat ik de demonstratie grondig heb voorbereid. Ik heb getracht om alle aspecten en criteria van de opdracht te tonen.
  * Cheat sheets -> Bekwaam  
  [Repository naar mijn cheat sheets](https://github.com/JensNeirynck/cheat-sheets)

## Eindevaluatie + rubics
  * Hoofdopdracht: High Availability -> 
  * Opdracht actualiteit -> 
  * Troubleshooting -> 
  * Laboverslagen -> 
  * Demonstraties -> 
  * Cheat sheets -> 
