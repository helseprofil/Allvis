/*	RENSE MANUELT: NH2023NESSTAR_PreAllvis\
	-LESEFERD_1_2022-12-19-16-24
	-REGNEFERD_1_2022-12-19-16-30

	For begge:
	- Beholde BARE kategori 0 for INNVKAT
	- Slette TELLER, sumTELLER og sumNEVNER.
	- Lagre i underkatalog \Allvis.
	
*/
/*===============================================================================	
* VELG KATALOG SOM SKAL RENSES
local path "F:\Forskningsprosjekter\PDB 2455 - Helseprofiler og til_\PRODUKSJON\PRODUKTER\KUBER\NORGESHELSA\NH2023NESSTAR_PreAllvis"
cd "`path'"

*===============================================================================	

local fil "LESEFERD_1_2022-12-19-16-24"
import delimited "`fil'", case(preserve) clear

keep if INNVKAT == 0
drop TELLER
drop sumTELLER
drop sumNEVNER

export delimited "`path'\Allvis\\`fil'", delimiter(";") replace

*===============================================================================	

local fil "REGNEFERD_1_2022-12-19-16-30"
import delimited "`fil'", case(preserve) clear

keep if INNVKAT == 0
drop TELLER
drop sumTELLER
drop sumNEVNER

export delimited "`path'\Allvis\\`fil'", delimiter(";") replace

*Done!
*/
*===============================================================================	
* VELG KATALOG SOM SKAL RENSES
local path "F:\Forskningsprosjekter\PDB 2455 - Helseprofiler og til_\Nesstar\ALLVISprepping_oversikt\TIL_MIGRERING\2023-09-13"
cd "`path'"

*===============================================================================	

local fil "BARNEVERN_UNDERSOKELSE_2023-03-07-14-04.csv"
import delimited "`fil'", stringcols(1) case(preserve) clear

drop TELLER
drop sumNEVNER

export delimited "`path'\Allvis\\`fil'", delimiter(";") replace
