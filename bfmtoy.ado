///////////////////////////////////////////////////////////////////////////////
//																			 //
//								TOY BFM										 //
//																			 //
///////////////////////////////////////////////////////////////////////////////

program bfmtoy, eclass
	version 11
	syntax , [OBS(real 5000000) THETA(numlist >0 <1 max=2) ///
		MISreporting(numlist max=4) TRUe(numlist max=2) ///
		TRUNCGraph(real 15) SAMple(real 0.01) ///
		save(string) EXPort(string) REPlace(real 0.99) ///
		NOFigure PREPare BINs(int 60)]  SEED(real)
	
	//Temporary variables
	tempvar F ftile aux_spl1 aux_spl2
	
	// ---------------------------------------------------------------------- //
	// Check validity of the input data and arguments
	// ---------------------------------------------------------------------- //
	
	//True Income distribution parameters
	if ("`true'" != "") {
		if (wordcount("`true'") == 1) {
			display as error "Option true() incorrectly specified:" ///
				" Must contain both the mean and standard deviation" ///
				" (in that order). Default is 0 and 1 respectively."
			exit 198
		}
		local tru_mean: word 1 of `true'
		local tru_sd: word 2 of `true'
	}
	else {
		local tru_mean = 0
		local tru_sd = 1
	}
	
	//Response rates (Theta)
	if ("`theta'" != "") {
		if (wordcount("`theta'") == 1) {
			display as error "Option theta() incorrectly specified:" ///
				" Must contain both the baseline value and the fractile" ///
				" F* at which theta starts decreasing (in that order)." ///
				" Default is 0.5 and 0.9 respectively."
			exit 198
		}
		local theta_base: word 1 of `theta'
		local theta_begin: word 2 of `theta'
	}
	else {
		local theta_base = 0.5
		local theta_begin = 0.9
	}
	
	//Misreporting parameters (distribution & probability)
	if ("`misreporting'" != "") {
		if (inlist (wordcount("`misreporting'"), 1, 2, 3))  {
			display as error "Option misreporting() incorrectly specified:" ///
				" Must contain 4 parameters: First, both the mean and standard deviation " ///
				"of the misreported-income distribution. Second, the baseline value and " ///
				"the fractile F* at which the probability of misreporting starts increasing" /// 
				" (in that order). Default is 0, 1, 0.9 and 0.2 respectively."
			exit 198
		}
		local mis_base: word 1 of `misreporting'
		local mis_begin: word 2 of `misreporting'
		local mis_mean: word 3 of `misreporting'
		local mis_sd: word 4 of `misreporting'
	}
	else {
		local mis_begin = 0.8
		local mis_base = 0.2 
		local mis_mean = 0 
		local mis_sd = 1
	}
	
	// ---------------------------------------------------------------------- //
	// Simulation
	// ---------------------------------------------------------------------- //
	
	display as text "Simulating sample from lognormal distribution..."
	quietly clear
	//set numb of observations 
	quietly set obs `obs'
	if ("`seed'" != "") {
		local state = c(rngstate)
		set seed `seed'
	}
	
	//Generate lognorm observations
	drawnorm y_true, means(`tru_mean') sd(`tru_sd')
	drawnorm y_m, means(`mis_mean') sd(`mis_sd')
	quietly replace y_true = exp(y_true)
	quietly label var y_true "True"
	quietly replace y_m = exp(y_m)
	quietly label var y_m "Misreported"
	quietly gen `F' = normal(ln(y_true))
	
	//Generate cumulative distribution
	quietly sort y_true 
	quietly gen F_y = _n/_N
	
	//Theta bias
	quietly gen theta = `theta_base' if `F' <= `theta_begin'
	quietly replace theta = `theta_base' -  ///
		`theta_base' * (`F'  - `theta_begin') / (1 - `theta_begin') ///
		if missing(theta)
	quietly label var theta "Pb. of Response"	
	quietly sum theta, meanonly 
	local avg_theta = round(r(mean), 0.001)
	
	//Probability of Misreporting
	quietly gen p = `mis_base' if `F' <= `mis_begin' 
	quietly replace p = `mis_base' + ///
		(1 - `mis_base') * (`F' - `mis_begin' ) / (1 - `mis_begin') ///
		if `F' > `mis_begin' 
	quietly label var p "Pb. of misreporting"
	quietly sum p, meanonly 
	local avg_p = round(r(mean), 0.001)
	
	//Activate biases
	foreach v in "theta" "p" {
		quietly gen aux_`v' = uniform()
		quietly gen dum_`v' = 1 if `v' > aux_`v'
	}
	
	//Define indiv. responses to survey
	quietly gen y_svy = y_true if dum_theta == 1
	quietly replace y_svy = y_m if dum_p == 1
	
	//Draw sample
	if ("`seed'" != "") {
		set seed `state'
	}
	quietly gen `aux_spl1' = uniform()
	quietly sort `aux_spl1', stable 
	quietly sum `aux_spl1', meanonly
	quietly gen insample = 1 if _n < `sample' * `obs'
	quietly replace y_svy = . if insample != 1 
	quietly sort y_true
	
	//Record sample size 
	quietly count if !missing(insample) 
	local loc_aux = r(N) / `obs' 
	
	// ---------------------------------------------------------------------- //
	// Display Summary stats
	// ---------------------------------------------------------------------- //
	
	// Display structure of population
	display as text "{hline 75}"
	display as text "Summary statistics"
	display as text "{hline 75}"
	display as text "(1) Avg. Probability of Misreporting:                " %5.2f 100*`avg_p'   "%"
	display as text "(2) Avg. Probability of Response:                    " %5.2f 100*`avg_theta'   "%"
	display as text "(3) Sample size (as % of target pop):                " %5.2f 100*`loc_aux'   "%"
	display as text "{hline 75}"
	
	// ---------------------------------------------------------------------- //
	// Graph all
	// ---------------------------------------------------------------------- //
	
	//Graph 
	if ("`nofigure'" == "") {
		preserve
			if ("`truncgraph'" != "") {
				quietly drop if (y_true > `truncgraph' | y_svy > `truncgraph')
			}
			graph twoway (line p y_true, lcolor(sand) yaxis(2)) ///
				(line theta y_true, lcolor(gray) yaxis(2)) ///
				(histogram y_svy, percent bin(`bins') ///
				fcolor(edkblue) lcolor(edkblue) yaxis(1)) ///
				(histogram y_true, percent bin(`bins') yaxis(1) ///
				fcolor(none) lcolor(red) lwidth(thin)) ///
				, ylabel(0(0.2)1, axis(2))  ///
				graphregion(color(white)) plotregion(lcolor(bluishgray)) scale(1.2) ///
				ytitle("Frequency (%)", axis(1)) ///
				ytitle("Probability (Response/Misreporting)", axis(2)) ///
				ylabel(, labsize(medsmall) angle(horizontal) format(%2.0f) grid labels axis(1)) ///
				ylabel(, labsize(medsmall) angle(horizontal) format(%2.1f) axis(2)) ///
				xlabel(, labsize(medsmall) angle(horizontal) format(%2.0f) grid labels) ///
				scheme(s1color) ///
				legend(label(3 "Sample") label(4 "True") forcesize) ///
				xtitle("Income level")
		restore	
	}	
	
	// ---------------------------------------------------------------------- //
	// Prepare for BFMCORR
	// ---------------------------------------------------------------------- //
	
	if ("`prepare'" != "") {
	
		display as text "Preparing sample input in bfmcorr..."
		
		//Generate set of weights
		quietly gen weight_true = 100
		quietly count if missing(y_svy)
		quietly gen weight_svy = `obs' / (`obs' - r(N)) * 100 ///
			if !missing(y_svy)
		quietly sum weight_svy 
		local sum_wghts_svy = round(r(sum))
		local sum_wghts_tru = `obs' * 100
		display as text "Sum of true weights --> `sum_wghts_tru'; " ///
			"Sum of survey (biased) weights -->`sum_wghts_svy'"
	
		// ---------------------------------------------------------------------- //
		// Store data for summarizing initial data 
		// ---------------------------------------------------------------------- //
		preserve
		
			quietly keep y_true weight_true 
			tempvar freq F fy cumfy L d_eq bckt_size trunc_avg ftile wy
			
			//Total average
			sort y_true
			quietly sum y_true [w=weight_true], meanonly
			local true_avg = r(mean) 
			local y_max_true=r(max)
			
			//Gini
			quietly sum weight_true, meanonly
			local poptot = r(sum)
			
			quietly gen `freq'  = weight_true / `poptot'
			quietly gen `F'     = sum(`freq') 
			quietly gen `fy'    = `freq' * y_true
			quietly gen `cumfy' = sum(`fy')
			
			quietly sum `cumfy', meanonly
			local cumfy_max = r(max)
			
			quietly gen `L'    = `cumfy'/`cumfy_max'
			quietly gen `d_eq' = (`F' - `L') * weight_true / `poptot'
			
			quietly sum `d_eq', meanonly
			local d_eq_tot = r(sum)
			local gini = `d_eq_tot' * 2
			di as text "gini_true: `gini'"
			
			// Classify obs in 127 g-percentiles
			quietly egen `ftile' = cut(`F'), ///
				at(0(0.01)0.99 0.991(0.001)0.999 0.9991(0.0001)0.9999 0.99991(0.00001)0.99999 1)
			
			// Top average 
			gsort -`F'
			quietly gen `wy' = y_true * weight_true
			quietly gen topavg_true = sum(`wy') / sum(weight_true)
			sort `F'
			
			// Interval thresholds
			quietly collapse (min) thr_true = y_true (mean) bckt_avg_true = y_true ///
				(min) topavg_true [w=weight_true], by (`ftile')
			sort `ftile'
			quietly gen ftile = `ftile'
			
			// Generate 127 percentiles from scratch
			tempfile collapsed_sum
			quietly save "`collapsed_sum'"
			clear
			quietly set obs 127
			quietly gen ftile = (_n - 1)/100 in 1/100
			quietly replace ftile = (99 + (_n - 100)/10)/100 in 101/109
			quietly replace ftile = (99.9 + (_n - 109)/100)/100 in 110/118
			quietly replace ftile = (99.99 + (_n - 118)/1000)/100 in 119/127
			quietly merge n:1 ftile using "`collapsed_sum'"
			
			
			// Interpolate missing info
			quietly ipolate bckt_avg_true ftile, gen(bckt_avg2_true)      
			quietly ipolate thr_true ftile, gen(thr2_true)
			quietly ipolate topavg_true ftile, gen(topavg2_true)
			
			sort ftile
			drop bckt_avg_true thr_true topavg_true
			quietly rename bckt_avg2_true bckt_avg_true
			quietly rename thr2_true thr_true
			quietly rename topavg2_true topavg_true
			quietly sum bckt_avg_true, meanonly
			quietly replace bckt_avg_true = r(max) if missing(bckt_avg_true)
			quietly sum thr_true, meanonly
			quietly replace thr_true = r(max) if missing(thr_true) 
			quietly sum topavg_true, meanonly
			quietly replace topavg_true = r(max) if missing(topavg_true)
			
			// Top shares  
			quietly replace ftile = round(ftile, 0.00001)
			quietly gen topshare_true = (topavg_true/`true_avg')*(1 - ftile)  
			
			// Total average  
			quietly gen average_true = .
			quietly replace average_true = `true_avg' in 1
			
			// Inverted beta coefficient
			quietly gen b_true = topavg_true/thr_true
			
			// Fractile
			quietly gen p_true = round(ftile, 0.00001) 
			
			// Gini 
			quietly gen gini_true = `gini'
			
			//Order and save
			order gini_true p_true thr_true average_true bckt_avg_true topavg_true topshare_true b_true
			keep gini_true p_true thr_true average_true bckt_avg_true topavg_true topshare_true b_true
			tempname mat_sum_true
			mkmat gini_true average_true p_true thr_true bckt_avg_true topavg_true topshare_true b_true ///
				, matrix(`mat_sum_true')	
		
		restore
		
		tempfile aux_file
		quietly save `aux_file'
		
		// ---------------------------------------------------------------------- //
		// Rescaling / Replace - option
		// ---------------------------------------------------------------------- //
		if ("`replace'" != "") {
			//save file with top% in true
			preserve
				quietly keep if F_y >= `replace'
				quietly keep F_y y_true weight_true
				tempfile replace_file
				quietly save `replace_file'
			restore
			
			//keep bottom% in survey 
			quietly sort y_svy
			quietly gen F_svy = sum(weight_svy)/_N/100 if !missing(weight_svy)
			quietly keep if !missing(y_svy)
			quietly drop if F_svy >= `replace'
			
			//Combine
			append using `replace_file'
			quietly gen y_resc = y_svy if !missing(y_svy)
			quietly replace y_resc = y_true if missing(y_svy)
			quietly gen F_resc = F_svy if !missing(F_svy)
			quietly replace F_resc = F_y if missing(F_svy)
			sort F_resc
			
			//Clean	
			quietly keep y_resc F_resc 
			tempvar freq F fy cumfy L d_eq bckt_size trunc_avg ftile wy
			
			//find weights
			quietly gen aux_wght = F_resc * `poptot' in 1
			//quietly count if (F_resc - F_resc[_n-1]) < 0 
			//if r(N) > 0 exit 1
			quietly replace aux_wght = (F_resc - F_resc[_n-1]) * `poptot'
			quietly replace aux_wght = round(aux_wght)
			quietly gen test=sum(aux_wght)
			
			//Total average
			sort y_resc
			quietly sum y_resc [w=aux_wght], meanonly
			local resc_avg = r(mean) 
			local y_max_resc=r(max)
			
			//Gini
			quietly sum aux_wght, meanonly
			local poptot_resc = r(sum)
			
			quietly gen `freq'  = aux_wght/`poptot'
			quietly gen `F'     = sum(`freq') 
			quietly gen `fy'    = `freq' * y_resc
			quietly gen `cumfy' = sum(`fy')
			
			quietly sum `cumfy', meanonly
			local cumfy_max = r(max)
			
			quietly gen `L'    = `cumfy'/`cumfy_max'
			quietly gen `d_eq' = (F_resc - `L') * aux_wght / `poptot'
			
			quietly sum `d_eq', meanonly
			local d_eq_tot = r(sum)
			local gini_resc = `d_eq_tot' * 2
			di as text "gini_resc: `gini_resc'"
	
			// Classify obs in 127 percentiles
			quietly replace F_resc = 0.99991 if F_resc == 1
			quietly egen `ftile' = cut(F_resc), ///
				at(0(0.01)0.99 0.991(0.001)0.999 0.9991(0.0001)0.9999 0.99991(0.00001)0.99999 1)
				
			// Top average 
			gsort - F_resc
			quietly gen `wy' = y_resc * aux_wght
			quietly gen topavg_resc = sum(`wy') / sum(aux_wght)
			sort F_resc
			
			// Interval thresholds
			quietly collapse (min) thr_resc = y_resc (mean) bckt_avg_resc = y_resc ///
				(min) topavg_resc [w=aux_wght], by (`ftile')
			sort `ftile'
			quietly gen ftile = `ftile'
		
			// Generate 127 percentiles from scratch
			tempfile collapsed_sum_resc
			quietly save "`collapsed_sum_resc'"
			clear
			quietly set obs 127
			quietly gen ftile = (_n - 1)/100 in 1/100
			quietly replace ftile = (99 + (_n - 100)/10)/100 in 101/109
			quietly replace ftile = (99.9 + (_n - 109)/100)/100 in 110/118
			quietly replace ftile = (99.99 + (_n - 118)/1000)/100 in 119/127
			quietly merge n:1 ftile using "`collapsed_sum_resc'"
			
			// Interpolate missing info
			quietly ipolate bckt_avg_resc ftile, gen(bckt_avg2_resc)      
			quietly ipolate thr_resc ftile, gen(thr2_resc)
			quietly ipolate topavg_resc ftile, gen(topavg2_resc)
			
			sort ftile
			drop bckt_avg_resc thr_resc topavg_resc
			quietly rename bckt_avg2_resc bckt_avg_resc
			quietly rename thr2_resc thr_resc
			quietly rename topavg2_resc topavg_resc
			quietly sum bckt_avg_resc, meanonly
			quietly replace bckt_avg_resc = r(max) if missing(bckt_avg_resc)
			quietly sum thr_resc, meanonly
			quietly replace thr_resc = r(max) if missing(thr_resc) 
			quietly sum topavg_resc, meanonly
			quietly replace topavg_resc = r(max) if missing(topavg_resc)
			
			// Top shares  
			quietly replace ftile = round(ftile, 0.00001)
			quietly gen topshare_resc = (topavg_resc/`resc_avg')*(1 - ftile)  
			
			// Total average  
			quietly gen average_resc = .
			quietly replace average_resc = `resc_avg' in 1
			
			// Inverted beta coefficient
			quietly gen b_resc = topavg_resc/thr_resc
			
			// Fractile
			quietly gen p_resc = round(ftile, 0.00001) 
			
			// Gini 
			quietly gen gini_resc = `gini_resc'
			
			//Order and save
			order gini_resc p_resc thr_resc average_resc bckt_avg_resc topavg_resc topshare_resc b_resc
			keep gini_resc p_resc thr_resc average_resc bckt_avg_resc topavg_resc topshare_resc b_resc
			tempname mat_sum_resc
			mkmat gini_resc average_resc p_resc thr_resc bckt_avg_resc topavg_resc topshare_resc b_resc ///
				, matrix(`mat_sum_resc')	
			
		}
		//-------------------------------------------------------------------------
		
		quietly use `aux_file', replace
		
		//Some variables for BFM
		quietly gen house = _n 
	
		//save 
		tempfile tf 
		quietly save "`tf'"
		
		//Generate simulated tax data (tabulation)
		preserve
			//cut and clean
			quietly keep y_true weight_true F_y
			quietly rename y_true y_tax 
			quietly replace F_y = 0.99991 if F_y == 1
			quietly egen p = cut(F_y), ///
				at(0.00(0.01)0.99 0.991(0.001)0.999 0.9991(0.0001)1)
			quietly collapse (min) thr = y_tax (mean) bracketavg = y_tax , by(p)
			quietly save "`save'", replace
		restore
		
		//Prepare simulated survey data
		quietly keep y_svy weight_svy house 
		quietly rename weight_svy weight
		quietly drop if missing(y_svy)
		
		//Store results for later
		ereturn matrix mat_sum_true = `mat_sum_true'
		ereturn matrix mat_sum_resc = `mat_sum_resc'
	}
	
end	

///////////////////////////////////////////////////////////////////////////////
