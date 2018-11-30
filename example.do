// -------------------------------------------------------------------------- //
// Example file for the command bfmcorr
// -------------------------------------------------------------------------- //

clear programs
global dir_ado "~/GitHub/bfmcorr"
global dir_dta "~/GitHub/bfmcorr/example-data"
sysdir set PERSONAL "$dir_ado"

// -------------------------------------------------------------------------- //
// Example with Brazil data (2014)
// -------------------------------------------------------------------------- //

use "$dir_dta/raw-survey-brazil-2014.dta", clear

keep hh_id male age ytotal_equalsplit person_weight

tostring hh_id, gen(hid)

keep hid person_weight male age ytotal_equalsplit

// Distribution of age in deciles (to keep constant)
xtile age_group = age, nquantiles(10)

// Enforce constant weights within households
egen yhh = mean(ytotal_equalsplit), by(hid)
egen weight = mean(person_weight), by(hid)
replace person_weight = weight
drop weight

bfmcorr using "$dir_dta/gpinter-brazil-2014.csv", ///
	weight(person_weight) income(yhh) households(hid) ///
	taxu(i) trust(0.8) holdmargins(age_group male)

// Show the shape of the bias
postbfm biasplot
// Compare the Lorenz curves
postbfm lorenz
