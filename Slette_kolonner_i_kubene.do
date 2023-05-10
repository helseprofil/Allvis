quietly {
/*	ALLVIS-RENSING - DEL 2:
	Plukke opp en utfylt liste over kuber og variabler, og slette de som er markert.

	Prinsipp:
	1. Kjør naboscriptet "Lage varliste for kubene".
	2. Fyll ut den lista - marker de kolonnene som skal slettes ved å huke av SLETT_VARIABEL 
	   på raden for kolonnenavnet (med hvilket tegn er ikke viktig).
	   Lagre med endret navn - for utviklingen "Variabler_i_kubene_UTVIKLING.csv"
	3. Kjør dette scriptet, som åpner hver kube og sletter, og så lagrer renset kube med nytt navn et annet sted.
	
	Filstruktur (fra 10.5.23):
	- Ikke-rensede datafiler er flyttet til \PRODUKSJON\PRODUKTER\KUBER\KOMMUNEHELSA\KH2024NESSTAR_PreAllvis  etc.
	- Fillista ligger i underkatalog til denne, ...\Filliste.
	- Ferdigrensede Allvisfiler legges i underkatalog \Allvis.
	  De skal kopieres til skarp \KH2024NESSTAR - men jeg gjør det manuelt etter kjøring, for sikkerhets skyld.
	
	Dette scriptet:
	- Utsetter import av kubefilen til vi ser at det faktisk er noe som er flagget for sletting.
	- Bruker frames for å ha styringsparameterne og den aktuelle kubefilen åpne samtidig.
			
***********************************************************
	OBS:  STATUS 10.5.23:
	IKKE FERDIG UTVIKLET sletting av KATEGORIER. Vi vedtok å vente med det.
	- Sletting av kategorier som er markert i SLETT_KAT funker, men KEEP_KAT er ikke implementert.
	
***********************************************************

*/

*===============================================================================	
* VELG KATALOG SOM SKAL RENSES
local path "F:\Forskningsprosjekter\PDB 2455 - Helseprofiler og til_\PRODUKSJON\PRODUKTER\KUBER\KOMMUNEHELSA\KH2024NESSTAR_PreAllvis"

* Utfylt listefil:
	//   For test: Variabler_i_kubene_UTVIKLING.csv
local utfyltliste "Variabler_i_kubene_05.05.2023.csv"

*===============================================================================	
* KJØRING
pause on
capture mkdir "`path'\Allvis"	//Der ferdigrensede filer lagres
frames reset
cd "`path'"
noisily pwd
import delimited "`path'\Filliste\\`utfyltliste'" , stringcols(1 2 4 5 6 7 8) case(preserve) clear

						// ANM: Import delimited lagrer som StrL hvis det sparer plass. Hver celle i StrL
						// tar bare det aktuelle antallet bytes, mens en Str# bruker # bytes for alle celler.
						// Etter import kan altså KATEGORIER være StrL selv om den ikke er over 2045 tegn.
						
levelsof(filnavn), local(filnavn) clean
*noisily di "`filnavn'"								//Viser en sortert liste over alle filnavn i tabellen

frame create kube				//Her skjer behandlingen av kubefilene.
frame kube: cd "`path'"

local feil ""					//Til å samle opp hvis det skjer noe underveis

	/*For utviklingen: KOMMENTER UT -foreach fil- nedenfor, og sluttparentesen dens.
	local fil "BEFOLK_GK_2023-03-29-13-07.csv"
	// Utvikling: La inn for FODEVEKT-filen at OVER_UNDER == "AVEKT_O4500" skal droppes (Slett_Kat er var6 i lista), 
	// og bare AAR == "2013_2022" skal keep'es (Keep_Kat er var7).
	*/

foreach fil of local filnavn {
	local enkeltfeil ""								//Nullstille feilindikatoren
	frame change default
	capture frame drop spec							//Capture fordi den ikke eksisterer før første fil.
	
    * Les variabellista og hva som skal slettes
	noisily di as res "Behandler `fil'"
	frame put if filnavn == "`fil'", into(spec)		//kopierer radene for aktuell fil til en ny frame
	frame change spec
	
*exit	
	

	* Har vi i det hele tatt noe som er merket for sletting - variabler eller kategorier?
	//Først rense vekk alle usynlige tegn, så lese ut evt. innhold til locals.
	replace SLETT_VARIABEL = ustrtrim(SLETT_VARIABEL)		//Fjerner både leading og trailing whitespace. En enkelt space blir borte.
	levelsof SLETT_VARIABEL, local(merker)
	replace SLETT_KAT = ustrtrim(SLETT_KAT)		//Fjerner både leading og trailing whitespace. En enkelt space blir borte.
	levelsof SLETT_KAT, local(kat1)
	replace KEEP_KAT = ustrtrim(KEEP_KAT)		//Fjerner både leading og trailing whitespace. En enkelt space blir borte.
	levelsof KEEP_KAT, local(kat2)

	if !missing("`merker'") | !missing("`kat1'") | !missing("`kat2'") {			//Vi har noe å slette, så kuben må lastes inn.
										//Sjekket at logikken her holder. Også space teller som ikke-missing.
		* Vi har noe som skal slettes. Lese inn kubefilen.
		frame kube:	import delimited "`fil'", case(preserve) clear
		* Finn i lista:
		local maxvar = _N				//Antall variabler i kuben, i følge fillista
		di "Ant.vars: `maxvar'"
*local x = 11							//Utvikling: For å kjøre uten løkke - kommenter ut løkka.

		* Løkke over alle variabler
		forvalues x = 1(1)`maxvar' {
			local variabel = var[`x']
			noisily di as result "   behandler: `variabel'"
			frame kube: local vartype : type `variabel'
			* noisily di "Vartype: `vartype'"
						
			* Kategorier: Først sjekke at ikke både keep og slett er fylt ut.
			noisily capture assert !( !missing(SLETT_KAT[`x']) & !missing(KEEP_KAT[`x']))
			if _rc != 0 {
				noisily di as err "   For `variabel' er både SLETT_KAT og KEEP_KAT fylt ut. Én av dem må være tom."
				local enkeltfeil = "feil"		// Flagge at denne filen ikke skal lagres.
				local feil = "feil"				// Plukke opp til slutt og varsle om at noe skjedde.
				continue						// Fortsetter med neste runde i løkka.
			}
			
			* Slette 'Slett'-flaggede kategorier for denne variabelen
			if !missing(SLETT_KAT[`x']) {
				local slettes = SLETT_KAT[`x']
				noisily di "   Slett_Kategorier:  `slettes'"
				
				if substr("`vartype'", 1, 3) == "str" {		//Variabelen er string
					frame kube: drop if inlist(`variabel', "`slettes'")
				} // end -stringvar-
				else {										//Variabelen er numerisk
					scalar slett = real("`slettes'")
					*noisily di "Scalar slett: " slett
					frame kube: drop if inlist(`variabel', slett)
				} // end -numerisk var-
			} //end -slette 'Slett'-flaggede kategorier for denne variabelen-
			
			/* Beholde bare 'keep'-flaggede kategorier for denne variabelen - IKKE FERDIG UTVIKLET!
			if !missing(KEEP_KAT[`x']) {
				local behold = KEEP_KAT[`x']
				frame kube: keep if `variabel' == "`behold'"
			}
			*/
			
			* Slette flaggede variabler
			if !missing(SLETT_VARIABEL[`x']) {
				
				* SJEKK at ikke variabelen har flere kategorier - da må disse ryddes først!

					// HMM: De kan være ryddet ovenfor, så jeg burde sjekke antall kategorier om igjen.
					// Men da må jeg kjøre hele "identifisere dimensjoner vs. måltall" om igjen først.
					// Dropper det nå (10.5.23), siden vi vedtok å vente med kategori-sletting.
					*frame kube: levelsof(`variabel'), local(ant_kat)

				if missing(KATEGORIER[`x']) | !(wordcount(KATEGORIER[`x']) >1) {
					noisily di "   Sletter `variabel'"
					frame kube:	drop `variabel'		// OBS: Makro uten quotes!
				} //end -if var. har max én kategori-
				else {
					local enkeltfeil = "feil"
					local feil = "feil"
					noisily di as err "   Variabel `variabel' flagget for sletting har mer enn én kategori."
				} //end -feil-
				
			} //end -slette var.-

		} //end -løkke gjennom alle variabler-
*exit	

		* Lagre resultatfilen på nytt sted.
		** BEVARER FILNAVNET.
		if missing("`enkeltfeil'") {
			frame kube: export delimited "`path'\Allvis\\`fil'", delimiter(";") replace
		}
		else {
			noisily di as err "   Kubefilen er ikke ferdig renset, og ikke lagret." _n
		} //end -lagre resultatfil-
	
	} // end -det er noe som skal slettes-

	else { // Det var ikke noe som skulle slettes, kopier filen til katalogen med rensede filer!	
		shell copy ".\\`path'\\`fil'" "`path'\Allvis\\`fil'"
	}
	
} //end -foreach fil (enkeltfil-løkke)-

* Helt til slutt: Si fra hvis det var trøbbel underveis
if !missing("`feil'") {
	noisily di as err _n "Det har skjedd en feil, sjekk for meldinger ovenfor!" _n
} //end -varsle om feil-

noisily di _n "Ferdig - husk å kopiere rensede filer til skarp NESSTAR-katalog." _n
} // end -quietly-

