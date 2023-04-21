/*	ALLVIS-RENSING:
	Er det mulig å lage en maskinell rensing av nesstarkuber, som fjerner de variablene vi ikke vil publisere?
	
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
local path "F:\Forskningsprosjekter\PDB 2455 - Helseprofiler og til_\PRODUKSJON\PRODUKTER\KUBER\KOMMUNEHELSA\KH2024NESSTAR"
	
*===============================================================================	
* KJØRING
frames reset			//Nullstille - trengs i utviklingsfasen
frame create liste		//Separat datasett for å lagre lista
frame change liste
generate filnavn = ""
forvalues i = 1/50 {
	generate var`i' = ""
}
set obs 500
*-----------------------
frame change default	//Løkke gjennom datafilene
cd "`path'"

local linje = 0
local filliste: dir "." files "*.csv" , respectcase
foreach fil of local filliste {
	local linje = `linje' +1
	import delimited "`fil'", case(preserve) clear
	describe, fullnames varlist
	* Nå ligger alle var-navn i `r(varlist)'

	local vars = `"`r(varlist)'"'
		*di `"`vars'"'
	local antall = wordcount("`vars'")
		*di `antall'
		
	frame change liste
	replace filnavn = "`fil'" in `linje'
	forvalues i = 1/`antall' {
		replace var`i' = word("`vars'", `i') in `linje'
	}
	frame change default
	
} // end -enkeltfil-

frame change liste

local antall = wordcount(`"`filliste'"')
local start  = `antall' +1
local stopp  = `antall' *2 

forvalues i = `start'/`stopp' {
	local linje = `i' - `antall'
	replace filnavn = word(`"`filliste'"', `linje') in `i'
}
* Må renses for quotes
replace filnavn = subinstr(filnavn, `"""', "", .)

* Sortere så annenhver linje er den tomme
drop if missing(filnavn)	//Slette tomme rader
gsort filnavn -var1

* Droppe ubrukte kolonner
	//Det var ikke så lett. Tema for videreutvikling.
	//Gjør det i script 2, som sletter kolonner. Liten løkke.

* Lagre ferdig liste
capture mkdir ".\Filliste"
export delimited ".\Filliste\Variabler_i_kubene.csv" , delimiter(";") replace