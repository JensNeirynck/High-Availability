# !/bin/bash

#########################################################################################
# DOORNEMEN ALVORENS VERDER TE GAAN:									                    		
#																					                                            	
# Welkom gebruiker														                                  				
# Dit bestand bevat de configuraties die u naar persoonlijke voorkeur kan aanpassen		  
# Wat u configureert staat steeds boven de sectie aangegeven. 																		                                        
#																					                                              										                       										  											                                           	
# Niets anders in het document aanpassen, dit zou problemen kunnen opleveren en     		
# het mislukken van de installatie tot gevolg hebben!									                  
#########################################################################################
#########################################################################################
# KEUZE VAN DE OPTIE:
#########################################################################################
# Kiest u voor optie A vul dan "true"
# Kiest u optie B, vul dan "false"
	export OPTIONA=true
#########################################################################################

#########################################################################################
# Optie A: Alle webservers hebben dezelfde prioriteit
#########################################################################################
# Vul hier het aantal webservers in die u wenst te gebruiken om te loadbalancen
	export AANTALSERVERS=2
# Op welke poort wenst u te loadbalancen (standaard 80)
	export PORT=80
#########################################################################################

#########################################################################################
# Optie B: De prioriteiten handmatig definieeren
#########################################################################################
# Hoeveel webservers krijgen een hoge prioriteit? (Deze worden dus het meeste belast)
	export HIGH_PRIORITY=1
# Hoeveel webservers krijgen een gewone prioriteit?
	export NORMAL_PRIORITY=0
# Hoeveel webservers krijgen een lage prioriteit (Deze worden het minste belast)
	export LOW_PRIORITY=1

# Op welke poort wenst u te loadbalancen (standaard 80)
	export PORT=80
#########################################################################################

# Dit start de effectieve installatie van de HA omgeving
source ./startvm.sh
