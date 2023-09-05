/*	ALLVIS-RENSING:
	Er det mulig å lage en maskinell rensing av nesstarkuber, som fjerner de variablene vi ikke vil publisere?
	
	OBS: GIT VERSJONSKONTROLL - MÅ brukes for å vite at du jobber i riktig versjon!
	
	PRINSIPP:
	For hver fil i en katalog:
	- Les fil (kan ikke lese variabler fra csv-filer uten å åpne dem)
	- Lag variabelliste
	- Skriv lista til et separat datasett
	- Repeat
	Lagre lista som fil i underkatalog "Filliste", med annenhver linje tom -
	så den kan brukes til å huke av hva som skal slettes.
	
	MULIG UTVIKLING:
	- Kunne kjøre systemet for nye filer etter at katalogen er blitt renset tidligere:
	  Les fillista i \Allviskatalogen, og trekk den fra fillista fra kildekatalogen.
	  Med datotagger vil da evt. nye versjoner av kubene komme med.
	  
	*/

*===============================================================================	
* VELG KATALOG Å LESE FRA
local path "F:\Forskningsprosjekter\PDB 2455 - Helseprofiler og til_\Nesstar\ALLVISprepping_oversikt\Forsinket_rensing_CSV"
	
*===============================================================================	
* KJØRING
* Initiere en tom liste
frames reset				//Nullstille - trengs i utviklingsfasen
frame create liste			//Separat datasett for å lage lista
tempfile mellomlager		//Samler opp bitene av lista til en fil
save `mellomlager', emptyok

*-----------------------
* Løkke gjennom datafilene i spesifisert katalog
frame change default	
cd "`path'"

local linje = 0			//Styrer hvor info for neste fil blir lagret
local filliste: dir "." files "*.csv" , respectcase

	/***********************************************
	* For utviklingen: Kommenter ut løkka "foreach fil of local filliste".
	local fil "FORNOYDHETm_NHUS_2022-03-23-13-22.csv"
		*"RFU_NH_SNUS_5_postprikking_2023-03-17-10-42.csv"
	pause on
	***********************************************/

foreach fil of local filliste {			//Løkke gjennom filene
	di "Leser inn `fil'"
	local linje = `linje' +1			//Styrer hvor i ferdig liste info for filen blir lagret
	import delimited "`fil'", case(preserve) clear
	
	* FINN VARIABELNAVNENE
	describe, fullnames varlist				// Nå ligger alle var-navn i `r(varlist)'
	local vars = `"`r(varlist)'"'			// Fjerner alle dimensjoner fra denne senere.
		*di `"`vars'"'
	local antall = wordcount("`vars'")		//Gir antall variabelnavn i denne kuben
		*di `antall'
	
	* FINN OM NOEN VARIABLER MANGLER PRIKKING
	* OBS: Dette baseres på at SPVFLAGG finnes og markerer prikkingen.
	
	* Må identifisere dimensjoner vs. måltall. 
	
				/* Bruker Hannas logikk: TELLER er (nesten) alltid første måltall.
				local dimensjoner ""	//Samler variabler her
				local maltall "`vars'"	//Fjerner én og én variabel herfra
				local i = 1
				local var = word("`vars'", `i')
				while "`var'" != "TELLER" {
					local dimensjoner = "`dimensjoner'" + " " + "`var'"
					local maltall = subinstr("`maltall'", "`var'", "", 1)
					local i = `i' +1
					local var = word("`vars'", `i')
				} // end -while- 
				*/

	* IDENTIFISERE (EKSTRA)DIMENSJONER (fra script 2 for boxplots, preppescriptet)
	// Modifisert: Her skal vi jo finne _alle_ dimensjoner.
	gen ekstradims="" 		//liste over variable (in spe)
	foreach var of varlist _all {  // Går gjennom alle variablene i filen og
		// legger dem til listen over ekstradimensjoner, lagret i variabelen
		// <ekstradims>, med mindre den tilhører den lange listen med unntak.
		// F.eks. er en variabel IKKE en ekstradim hvis den heter GEO, AAR osv.
		replace ekstradims = ekstradims + " " + "`var'" in 1 if ///
		"`var'"!="Adjusted" & ///
		"`var'"!="adjusted" & ///
		"`var'"!="ADJUSTED" & ///
		"`var'"!="ANT_OPPGITT" & ///
		"`var'"!="teller_aarlig" & ///
		"`var'"!="Ant_pers" & ///
		"`var'"!="ANTALL" & ///
		"`var'"!="antall" & ///
		"`var'"!="Antall_personer" & ///
		"`var'"!="antallaar" & ///
		"`var'"!="ANTLEDIGE" & ///
		"`var'"!="Crude" & ///
		"`var'"!="crude" & ///
		"`var'"!="CRUDE" & ///
		"`var'"!="DEKNINGSGRAD" & ///
		"`var'"!="dekningsgrad" & ///
		"`var'"!="E0" & ///
		"`var'"!="ekstradims" & ///
		"`var'"!="FODTE" & ///
		"`var'"!="folketall" & ///
		"`var'"!="geonivaa" & ///
		"`var'"!="GINI" & ///
		"`var'"!="MALTALL" & ///
		"`var'"!="MEDIAN_INNTEKT" & ///
		"`var'"!="MEDIANINNTEKT_AH" & ///
		"`var'"!="NETTO" & ///
		"`var'"!="NEVNER" & ///
		"`var'"!="nevner" & ///
		"`var'"!="nevner_aarlig" & ///
		"`var'"!="num_femGeonivaa" & ///
		"`var'"!="num_geonivaa" & ///
		"`var'"!="PERSONER" & ///
		"`var'"!="Personer" & ///
		"`var'"!="personer_distribnett" & ///
		"`var'"!="per1000" & ///
		"`var'"!="PRIKK" & ///
		"`var'"!="prosentandel" & ///
		"`var'"!="RATE" & ///
		"`var'"!="sumnevner" & ///
		"`var'"!="sumNEVNER" & ///
		"`var'"!="SUMNEVNER" & ///
		"`var'"!="sumteller" & ///
		"`var'"!="sumTELLER" & ///
		"`var'"!="SUMTELLER" & ///
		"`var'"!="TELLER" & ///
		"`var'"!="TILVEKST" & ///
		"`var'"!="v6" & ///
		"`var'"!="v7" & ///
		"`var'"!="VERDI" & ///
		regexm("`var'","_MA")==0 & ///
		regexm("`var'","BEF")==0 & ///
		regexm("`var'","FLx")==0 & ///	
		regexm("`var'","LANDSNORM")==0 & ///
		regexm("`var'","MEIS")==0  & ///
		regexm("`var'","RATE")==0 & ///
		regexm("`var'","SMR")==0 & ///
		regexm("`var'","smr")==0 & ///
		regexm("`var'","SPVFLAGG")==0 & ///
		regexm("`var'","spvflagg")==0 
		replace ekstradims = ekstradims + "`var'" +" " if "`var'"=="TYPE_MAAL" //Blir ekskludert av 
																				//en regexm ovenfor!
		noisily di as input "`var', ekstradims = " as result ekstradims // Her
		// vises ekstradim-listen etter hver variabel som er inspisert. Bruk 
		// listen til å sjekke at ikke feil variabler er blitt lagt til listen 
		// over ekstradims. De eneste "standarddims", dvs. dimensjoner som  
		// finnes i alle filer, er GEO og AAR. Ekstradims er dimensjoner som 
		// IKKE finnes i alle filer, f.eks. kjønn, alder og legemiddel  
	} // end -foreach- var
	local dimensjoner = ekstradims	// Leser rad 1
	// Nå skal alle dimensjoner være listet opp i local `dimensjoner'.
	
	local maltall "`vars'"			// Starter med full liste og trekker fra dimensjonene.
	foreach var of local dimensjoner {
		local maltall = subinstr("`maltall'", "`var'", "", 1)
	}
	* Håndtere SPVflagg separat.
	* Og den kan hete "spvflagg" i dct-std filer (NH).
	* Lookfor finner variabler og legger dem i r(varlist).
	lookfor SPVFLAGG 
	local spv = r(varlist)
		*di "spv = (`spv')"	
	local maltall = subinstr("`maltall'", "`spv'", "", 1)
	
	* Hvis SPVFLAGG ikke finnes, må det faktum brukes litt senere
	if "`spv'" == "." local spvFinnes = "FALSE" 
	else local spvFinnes = "TRUE"
		
	di "Dimensjoner: `dimensjoner'"
	di "Måltall: `maltall'"
	// Nå skal alle dimensjoner være listet opp i local `dimensjoner', og 
	// være fjernet fra local `maltall'.
*exit	


	* Sjekke alle måltall og notere hvis uprikket
	* OBS: Dette baseres på at SPVFLAGG finnes og markerer prikkingen.
	if "`spvFinnes'" == "TRUE" {
	
			/*************************
			*Introdusere et funn - må finne en rad med SPV != 0 manuelt
			replace RATE = 999 in 15
			replace SMR  = 999 in 15
			*************************/
	
	local uprikket `""'
	gen flagg = .
	foreach var of local maltall {
	    replace flagg = 1 if (!missing(`spv') & `spv' != 0) & !missing(`var')	//`spv' er aktuelt varnavn (case!) for SPVFLAGG.
		count if !missing(flagg)
		if `r(N)' > 0 local uprikket = "`uprikket'" + "`var'" + ", "	//Det vil alltid være et komma til slutt.
																		//Det var smart for å skille RATE og RATEN.
		replace flagg = .
	} // end -foreach var-
	di "Uprikket: `uprikket'"
	} // end -if "spvFinnes"...-
	
	// Nå er eventuelle uprikkede variabler notert i local `uprikket'.

	* FINNE KATEGORIENE I ALLE DIMENSJONER (unntatt GEO)
	local antdims = wordcount("`dimensjoner'")
	forvalues i = 2/`antdims' {					//GEO er alltid først!
	    local var = word("`dimensjoner'", `i')
		levelsof(`var'), local(kategorier`i') separate(", ") clean 	//Får en liste med komma imellom
	}
	if "`spvFinnes'" == "TRUE" {
		levelsof(`spv'), local(kategorierSPV) separate(", ") clean		//`spv' er aktuelt varnavn (case!) for SPVFLAGG.
		} // end -spvFinnes-
		
	// Nå har hvert var-nummer en tilhørende `kategorier2' etc.
	
	* TELLE ANTALL KATEGORIER I GEO
	* Skal både oppgis i output, og brukes i et filter nedenfor.
	* Også her kunne håndtere lowercase varnavn.
	lookfor GEO 
	local geonavn = r(varlist)
	
	levelsof(`geonavn'), local(geokat)
	local antgeo = wordcount("`geokat'")
	
	* LEGGE RESULTATENE I LISTA
	frame change liste
	clear
	generate filnavn = ""	//kolonne for kubefilnavnene
	forvalues i = 1/50 {	//kolonner for variabelnavnene i hver kube
		generate var`i' = ""
	}
	set obs 500				//Sette av plass til stort nok antall kubefiler

	
	replace filnavn = "`fil'" in `linje'
	forvalues i = 1/`antall' {		//Løkke gjennom alle variabelnavn i denne kuben
		replace var`i' = word("`vars'", `i') in `linje'
	}
	* Bygger om til long-format
	drop if missing(filnavn)
	reshape long var, i(filnavn) j(varnr)
	drop if missing(var)

	generate SLETT_VARIABEL = "", before(filnavn)		// Legger den nye variabelen først.
													// Brukes til å manuelt flagge variabler for sletting.

	* Flagge evt. uprikkede måltall
	generate UPRIKKET = "`uprikket'"
	foreach var of local maltall {
		replace UPRIKKET = "UPRIKKET" if var == "`var'" & regexm("`uprikket'", "`var',")
	}												//Komma etter `var' må være der. Skiller RATE fra RATEN.
	replace UPRIKKET = "" if UPRIKKET != "UPRIKKET"
*exit	
	* Legge til en kolonne med kategorisettene
	generate KATEGORIER = ""
	forvalues i = 2/`antdims' {
		replace KATEGORIER = "`kategorier`i''" if varnr == `i'
	}
	replace KATEGORIER = "`kategorierSPV'" if var == "`spv'"	//`spv' er aktuelt varnavn (case!) for SPVFLAGG.
*exit

	* Legge ut antall geo-kategorier
	replace KATEGORIER = "`antgeo'" if var == "`geonavn'"

	* Legge til kolonner for å flagge rader som skal slettes - eller beholdes
	generate SLETT_KAT = "", before(KATEGORIER)
	generate KEEP_KAT  = "", before(KATEGORIER)

	* Legge inn default-verdier for SLETT_VARIABEL
	*- TELLER/ANTALL flagges for sletting hvis det er mer enn én GEO-kategori
	if `antgeo' > 1 {
		replace SLETT_VARIABEL = "xx" if var == "TELLER"
		replace SLETT_VARIABEL = "xx" if var == "sumTELLER" | var == "sumteller"
		replace SLETT_VARIABEL = "xx" if var == "ANTALL"    | var == "antall"
	}
	
	*- NEVNER, sumNEVNER flagges for sletting unntatt hvis det er en kube fra LKU eller RFU
	if !(regexm(filnavn, ".*LKU.*") | regexm(filnavn, ".*RFU.*") ) {
		replace SLETT_VARIABEL = "xx" if var == "NEVNER"
		replace SLETT_VARIABEL = "xx" if var == "sumNEVNER" | var == "sumnevner"
	}
	
	*- RATEN slettes alltid
	replace SLETT_VARIABEL = "xx" if var == "RATEN"
*exit	

	* Lagre ferdig liste for denne kuben
	append using `mellomlager'
	save `mellomlager', replace
	frame change default
} // end -enkeltfil-
*exit

* Lagre ferdig liste
frame change liste
capture mkdir ".\Filliste"
export delimited ".\Filliste\Variabler_i_kubene.csv" , delimiter(";") replace
