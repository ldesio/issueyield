capture program drop yield
program define yield, rclass	
	
	// adapted from iyield.ado
	
	
	syntax varlist, partyexp(string) [wtexp(string)] [credvar(varname)]
	
	tempvar target_group
	tempvar const
	
	qui gen `target_group' = 1
	qui gen `const' = 1
	
	local numvars : list sizeof varlist
	
	/* apparently not needed for handling 0.5s if single issue (in any case: no neutrals in ICCP)
	di "*`numvars'*"
	*/
	
	if (`numvars'>1 & "`creds'"!="") {
		display "Specifying a credibility variable is only compatible with using a single issue."
		exit 
	}
	
	local goallabel = ""
	
	foreach v of varlist `varlist' {
		// assuming dichotomous variables: no 0.5s
		qui replace `target_group' = `target_group' * `v'
		local thislab : variable label `v'
		local goallabel = "`goallabel' * `thislab'"
	}
	local goallabel = substr("`goallabel'",4,.)

	// this is correct
	// tab `target_group'
	
	quietly count
	local all = r(N)
	// di "all: `all'"
	
	// classic i
	quietly sum `target_group' `wtexp'
	local i = r(mean)
	// di "i: `i'"
	
		quietly sum `const' if `partyexp' `wtexp'
		local pcount = r(sum_w)
		local p = r(sum_w) / `all'
		// di "`pt' p: `p'"
		
		quietly sum `const' if `target_group'==1 & `partyexp' `wtexp'
		// local f = r(N) / `all'
		local f = r(sum_w) / `all'
		
		
		local within = `f' / `p'
		if (`numvars'==1) {
			sum `varlist' if `partyexp' `wtexp'
			local within = r(mean)
		}
		
		// counting neutrals as half
		// WILL NEED TO BE ADAPTED FOR A GENERAL IYIELD SCRIPT: INCOMPATIBLE WITH multiple SUBSET above (apparently)
		/*
		quietly sum `const' if `target_group'==0.5 & `partyexp' `wtexp'
		// local f = `f' + (r(N)/2) / `all'
		local f = `f' + (r(sum_w)/2) / `all'
		*/
		
		// OLD VERSION of yield (robustness check): THE SAME
		local x = `f' - `p' * `i'
		local y = `i' - `p'
		local x = `x' * 1/(`p'-`p'^2)
		local y = `y' * 1/(1-`p')
		local ref_angle = atan2(1, 1)*180/_pi 
		local raw_angle = atan2(`y', `x')*180/_pi 
		local angle = `raw_angle' - `ref_angle'
		local direction = cos(`angle' * _pi / 180)
		local magnitude = sqrt(`x'^2 + `y'^2)
		local eff_magnitude = `magnitude' * `direction'
		local eff_magnitude = `eff_magnitude'/(sqrt(2)/2)

		
		return scalar p = `p'
		return scalar i = `i'
		return scalar f = `f'
		return scalar within = `within'
		return scalar yield = (`f' - `i'*`p')/(`p'*(1-`p')) + (`i'-`p')/(1-`p')

		quietly sum `credvar' if `target_group'==1 `wtexp'
		local cred = r(sum_w)*r(mean)/`all' // r(sum_w) / `all'
		
		quietly sum `credvar' if `target_group'==1 & `partyexp' `wtexp'
		local intcred = r(sum_w)*r(mean) / `all'
		
		return scalar cred = `cred'
		return scalar intcred = `intcred'
		
		local credrel = `cred' / `i'
		local intcredrel = `intcred' / (`p' * `within')
		
		// difference between observed and expected support: allows to detect side associated with party support
		local d = (`f' - `i'*`p')

		// first term: same formula, but credibility gets calculated on the *remainder* of party supporters
		// 	if the *opposite* side is associated with party support
		if (`d'>=0) local first_term = ((`f' - `i'*`p')*`intcredrel')/(`p'*(1-`p'))
		if (`d'<0) local first_term = ((`f' - `i'*`p')*(1-`intcredrel'))/(`p'*(1-`p'))
		

		// second term: same formula for both cases
		local second_term = ((`i'-`p')*`credrel')/(1-`p')

		return scalar credweighted_yield = `first_term' + `second_term'
		
		
		// return scalar credweighted_yield = (`f' - `i'*`p')*`intcred'/(`p'*(1-`p')) + (`i'-`p')*`cred'/(1-`p')
		
		// with "rel" versions, much more meaningful and almost equal to old reports
		// return scalar credweighted_yield = (`f' - `i'*`p')*`intcredrel'/(`p'*(1-`p')) + (`i'-`p')*`credrel'/(1-`p')
		
		return scalar oldyield = `eff_magnitude'
		return local goallabel "`goallabel'"
		
	
end program
