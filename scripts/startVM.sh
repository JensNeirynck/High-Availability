#!/bin/bash

# Script voor high availability met een variabel aantal webservers die gebruik maken van één database
# verbonden met een monitoringtool en loadbalancer
# Author:
#	Jens Neirynck

# Special thanks to the teachers @HoGent for the support!

# Colors
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'		 #No Color

echo -e ${CYAN}"Made by Jens Neirynck"${NC}

if $OPTIONA -eq true
then
echo -e ${PURPLE}"U heeft gekozen voor optie: A"${NC}
else
echo -e ${PURPLE}"U heeft gekozen voor optie: B"${NC}
AANTALSERVERS=$(($HIGH_PRIORITY+$NORMAL_PRIORITY+$LOW_PRIORITY))
fi
echo -e ${BLUE}"Aantal webservers: $AANTALSERVERS "${NC}

#Vagrant-hosts worden hier geconfigureerd
echo "Vagrant hosts herconfigureren"
cat /dev/null > ../vagrant-hosts.yml
echo "---" >> ../vagrant-hosts.yml
echo "
- name: db1
  ip: 192.168.1.4
  hostname: database1
  mem: 1024" >> ../vagrant-hosts.yml   

echo "Aantal webservers: $AANTALSERVERS" > webservers.conf

for (( i=1;i<=$AANTALSERVERS; i++ ))	
do
echo "
- name: web$i
  ip: 192.168.1.$((i+4))
  hostname: webserver$i
  mem: 512" >> ../vagrant-hosts.yml     
done
echo "
- name: mon1
  ip: 192.168.1.2
  hostname: monitor1
  mem: 2048

- name: lb1
  ip: 192.168.1.3
  hostname: loadbalancer1
  mem: 1024
  
- name: lamp
  ip: 192.168.1.250
  hostname: lamp
  mem: 1024" >> ../vagrant-hosts.yml

#Site.yml aanpassen
echo "Site.yml aanpassen"
cat /dev/null > ../ansible/site.yml

echo "# site.yml \n---" >> ../ansible/site.yml
echo "
- hosts: all
  become: true
  roles:
    - bertvv.rh-base
    - bertvv.hosts
  vars:
    rhbase_firewall_allow_ports:
      - 10050/tcp" >> ../ansible/site.yml
echo "
- hosts: db1
  become: true
  roles:
    - bertvv.mariadb
    - dj-wasabi.zabbix-agent
  pre_tasks:
    - name: Setting hostname
      hostname:
        name: db1" >> ../ansible/site.yml

for (( i=1; i<=$AANTALSERVERS; i++))
do
# Hier wordt alles van de webservers toegevoegd aan site.yml
echo "
- hosts: web$i
  become: true
  roles:
    - bertvv.drupal
    - bertvv.httpd
    - dj-wasabi.zabbix-agent
  pre_tasks:
    - name: Setting hostname
      hostname:
        name: web$i" >> ../ansible/site.yml
done

# Hier wordt de loadbalancer gedefinieerd
echo "
- hosts: lb1
  become: true
  roles:
    - jensneirynck.pound
    - dj-wasabi.zabbix-agent
  vars:
    Pound_LoadBalancerHTTPIP: 192.168.1.3
    Pound_LoadBalancerHTTPPort: 80
    Pound_LoadBalancerHTTPSIP: 192.168.1.3
    Pound_LoadBalancerHTTPSPort: 443
    Webservers:" >> ../ansible/site.yml
if $OPTIONA -eq true
then
for (( i=1; i<=$AANTALSERVERS; i++))
do
echo "    - ip: "192.168.1.$((i+4))"
      port: "$PORT"
      priority: 5" >> ../ansible/site.yml
done
else
I_IP=5
for (( i=1; i<=$HIGH_PRIORITY; i++))
do
echo "
      - ip: "192.168.1.$I_IP"
        port: "$PORT"
        priority: "9"" >> ../ansible/site.yml
I_IP=$(($I_IP+1))
done
for (( i=1; i<=$NORMAL_PRIORITY; i++))
do
echo "
      - ip: "192.168.1.$I_IP"
        port: "$PORT"
        priority: "5"" >> ../ansible/site.yml
I_IP=$(($I_IP+1))
done
for (( i=1; i<=$LOW_PRIORITY; i++))
do
echo "
      - ip: "192.168.1.$I_IP"
        port: "$PORT"
        priority: "1"" >> ../ansible/site.yml
I_IP=$(($I_IP+1))
done
fi
echo "
  pre_tasks:
    - name: Setting hostname
      hostname:
        name: lb1
" >> ../ansible/site.yml

#Monitoring defininen (geerlinguy.zapache is nodig om zabbix-web te laten werken)
echo "
- hosts: mon1
  become: true
  roles:
    - bertvv.mariadb
    - geerlingguy.apache
    - jensneirynck.zabbixserver
    - dj-wasabi.zabbix-web
" >> ../ansible/site.yml

#Roles uit de site.yml downloaden
echo "Role-Deps uitvoeren"
cd ..
./scripts/role-deps.sh
cd scripts/

#Ansible hosts_vars
find ../ansible/host_vars/ -type f -name web\* -exec rm {} \;

for (( i=1;i<=$AANTALSERVERS; i++ ))
do
touch ../ansible/host_vars/web$i.yaml

# merk op dat hier een sebool wordt gezet. 
# Deze is nodig omdat er anders problemen zijn met het verbinden van een "external" database.	
echo "
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
zabbix_visible_hostname: web$((i))
zabbix_agent_interfaces:
  - type: 1
    main: 1
    useip: 1
    ip: 192.168.1.$((i+4))
" >> ../ansible/host_vars/web$i.yaml 
done

#logs aanmaken voor het geval dat er een fout zit in de vagrant up
logname=$(date +"%d%m%y_%H%M")
touch ../log/$logname.log

#vagrant uppen
echo "De machnes zullen nu opgestart worden. Even geduld aub dit process zal even duren."
echo -ne '######                    (20%) '${ORANGE}'MON1'${NC}  ${RED}'DB1'${NC}  ${RED}'WEBS'${NC}  ${RED}'LB1\r'${NC}
cd ..
vagrant up mon1 >> log/$logname.log
wait
echo -ne '##########                (40%) '${GREEN}'MON1'${NC}  ${ORANGE}'DB1'${NC}  ${RED}'WEBS'${NC}  ${RED}'LB1\r'${NC}
vagrant up db1 >> log/$logname.log
wait
echo -ne '###############           (70%) '${GREEN}'MON1'${NC}  ${GREEN}'DB1'${NC}  ${ORANGE}'WEBS'${NC}  ${RED}'LB1\r'${NC}
for (( i=1; i<=$AANTALSERVERS; i++))
do
vagrant up web$((i)) >> log/$logname.log
wait
done
echo -ne '####################      (80%) '${GREEN}'MON1'${NC}  ${GREEN}'DB1'${NC}  ${GREEN}'WEBS'${NC}  ${ORANGE}'LB1\r'${NC}
vagrant up lb1 >> log/$logname.log
wait
echo -ne '######################### (90%) '${GREEN}'MON1'${NC}  ${GREEN}'DB1'${NC}  ${GREEN}'WEBS'${NC}  ${GREEN}'LB1\r'${NC}
echo -e ${GREEN}"Done! U kan nu volledig gebruik maken van De HA-Omgeving" ${NC}
echo "Een overzicht van de Webservers"
if $OPTIONA -eq true
then
for (( i=1; i<=$AANTALSERVERS; i++))
do
echo "
      name: web$((i))
      ip: "192.168.1.$((i+4))"
"
done
else
I_IP=5
echo "Deze servers zijn High Priority"
for (( i=1; i<=$HIGH_PRIORITY; i++))
do
echo "
      name: web$(($I_IP-4))
      ip: "192.168.1.$I_IP"
"
I_IP=$(($I_IP+1))
done
echo "Deze servers zijn Normal Priority"
for (( i=1; i<=$NORMAL_PRIORITY; i++))
do
echo "
      name: web$(($I_IP-4))
      ip: "192.168.1.$I_IP"
"
I_IP=$(($I_IP+1))
done
echo "Deze servers zijn Low Priority"
for (( i=1; i<=$LOW_PRIORITY; i++))
do
echo "
      name: web$(($I_IP-4))
      ip: "192.168.1.$I_IP"
"
I_IP=$(($I_IP+1))
done
fi
echo "Het ip van de monitor is 192.168.1.2, inloggen kan met u: Admin; pw: zabbix"
echo "Het ip van de databank is 192.168.1.4"
echo "Het ip van de loadbalancer is 192.168.1.3, surf vanaf nu naar dit ip om de loadblancer te testen"
echo $(date '+%Y %b %d %H:%M')
echo -e '##########################(100%) '${GREEN}'DB1'${NC}  ${GREEN}'WEBS'${NC}  ${GREEN}'LB1'${NC}  ${GREEN}'MON1'${NC}