/*	ALLVIS-RENSING - DEL 2:
	Plukke opp en utfylt liste over kuber og variabler, og slette de som er markert.

	Prinsipp:
	1. Kjør naboscriptet "Lage varliste for kubene".
	2. Fyll ut den lista - marker de kolonnene som skal slettes ved å huke av under kolonnenavnet (med hvilket tegn er ikke viktig).
	   Lagre med endret navn "..._UTFYLT.csv"
	3. Kjør dette scriptet, som åpner hver kube og sletter, og så lagrer renset kube med nytt navn et annet sted.
	
	Foreløpig legges fillista i underkatalog \Filliste, og ferdige Allvisfiler i underkatalog \Allvis.
	
	Dette scriptet:
	- Utsetter import av kubefilen til vi ser at det faktisk er noe som er flagget for sletting.
	- Bruker frames for å ha styringsparameterne og den aktuelle kubefilen åpne samtidig.
			
*/

*===============================================================================	
* VELG KATALOG SOM SKAL RENSES
local path "F:\Forskningsprosjekter\PDB 2455 - Helseprofiler og til_\PRODUKSJON\PRODUKTER\KUBER\KOMMUNEHELSA\KH2024NESSTAR"

*===============================================================================	
* KJØRING
frames reset
cd "`path'"
import delimited "`path'\Filliste\Variabler_i_kubene_UTFYLT.csv", case(preserve) clear

levelsof(filnavn), local(filnavn) clean
di "`filnavn'"								//Viser en sortert liste over alle filnavn i tabellen

frame create kube				//Her skjer behandlingen av kubefilene.
frame kube: cd "`path'"

describe, short
local antvars = `r(k)' -1
di `antvars'					//Antall variabler i tabellen - inkl. tomme kolonner til høyre.

	*For utviklingen:
	*local fil "FODEVEKT_2023-03-27-10-20.csv"

foreach fil of local filnavn {
    * Les variabellista og hva som skal slettes
	preserve
	keep if filnavn == "`fil'"		//gir to rader
	*Bli kvitt alle de tomme kolonnene
	forvalues i = `antvars'(-1)1 {
	    if missing(var`i') drop var`i' 	//Dette ser bare på første rad, men det er der var-navn ligger.
	}
	
	*Nå har vi bare ett filnavn, en rad med var-navn og en rad med (evt.) merker for å slette.
	*Dropper filnavnet og manipulerer for å hente ut de to radene.
	replace filnavn = strofreal(_n)
	reshape long var, i(filnavn) j(varnr)
	*Når 'filnavn' er 1, er 'var' lik varnavnet. Når 'filnavn' er 2, er 'var' lik avmerkingen.
	*Og linjenummeret _n for et var-navn er lik 'varnr' for både var-navnet og avmerkingen. 
	*Men jeg vil ha to kolonner, en for hvert "filnavn", med varnr som radnummer.
	*Her blir 'varnr' lik radnummer OG variabelens nummer i kuben, 'var1' er kubens var-navn, og 'var2' avmerkingen.
	*Sorteringen ser teit ut, men varnr er likt for varnavnet og merkingen, og det er det som styrer.
	reshape wide var, i(varnr) j(filnavn) string
	
	* Har vi i det hele tatt noen variabler merket for sletting?
		*Først rense vekk alle usynlige tegn
	replace var2 = ustrtrim(var2)		//Fjerner både leading og trailing whitespace. En enkelt space blir borte.
	levelsof var2, local(merker)
	if !missing("`merker'") {			//Vi har noe å slette, så kuben må lastes inn.
										//Sjekket at logikken her holder. Også space teller som ikke-missing.

		frame kube:	import delimited "`fil'", case(preserve) clear
		* Finn i lista:
		local maxvar = _N				//Antall variabler i kuben, i følge fillista
		di "`maxvar'"
*local x = 9							//For å kjøre uten løkke
		forvalues x = 1(1)`maxvar' {
			if !missing(var2[`x']) {
				local slettes = var1[`x']
				di "`slettes'"
				frame kube:	drop `slettes'		// OBS: Makro uten quotes!
			} //end -enkeltvar.-
		} //end -sletting, alle variabler-
*exit	
	* Lagre resultatfilen på nytt sted.
	** DILEMMA: Bevare filnavnet? Da er det enklere å smlikne med eksisterende lister, 
	** men ved flytting av filen blir det umulig å se hvilken versjon det er .
	** BEVARER i første omgang.
	capture mkdir "`path'\Allvis"
	frame kube: export delimited "`path'\Allvis\\`fil'", delimiter(";") replace
	
	} // end -det er noe som skal slettes-
	
	restore		//Starte med full filliste igjen
} //end -enkeltfil løkke-
