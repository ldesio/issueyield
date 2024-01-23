capture program drop issueyield
program define issueyield, rclass	
	
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

	di ""
	di "*** Issue Yield index calculation ***"
	di ""
	di "Issue variable: " _column(40) "`varlist' (`goallabel')"
	di "Party expression:" _column(40) `"`partyexp'"'
	
	if ("`wtexp'"!="") di "Using weights: " _column(40) "`wtexp'"
	if ("`credvar'"!="") di "Party credibility variable:" _column(40) "`credvar'"
	
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
			qui sum `varlist' if `partyexp' `wtexp'
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

		di ""
		di "Party size (p):" _column(40) %3.2f `p'
		di "Issue goal general support (i):" _column(40) %3.2f `i'
		di "Joint party-goal support (f):" _column(40) %3.2f `f'
		local yield = (`f' - `i'*`p')/(`p'*(1-`p')) + (`i'-`p')/(1-`p')
		di "* Issue yield:" _column(40) %3.2f `yield'
		
		
		quietly sum `credvar' if `target_group'==1 `wtexp'
		local cred_abs = r(sum_w)*r(mean)/`all' // r(sum_w) / `all'
		
		quietly sum `credvar' if `target_group'==1 & `partyexp' `wtexp'
		local intcred_abs = r(sum_w)*r(mean) / `all'

		// cred and intcred are *relative* measures
		// (internal to issue supporters, party supporters)
		// (see De Sio and Weber 2020)
		local cred = `cred_abs' / `i'
		local intcred = `intcred_abs' / (`p' * `within')
		
		return scalar cred = `cred'
		return scalar intcred = `intcred'

		// absolute credibilities returned for other uses
		return scalar cred_abs = `cred_abs'
		return scalar intcred_abs = `intcred_abs'

		/* De Sio/ Weber 2020, footnote 11:
		
		11. Note that intcred has to be replaced with 1-intcred if (f-ip) is lower than 0
			(i.e., policy support within the party is lower than in the whole sample).
			And, in the same way, cred would need to be replaced with 1-cred if (i-p)
			is lower than 0 (i.e. party support is higher than issue support), but this
			does not occur in our data.
		*/
		
		// difference between observed and expected support: allows to detect side associated with party support
		local d = (`f' - `i'*`p')

		// first term: same formula, but credibility gets calculated on the *remainder* of party supporters
		// 	if the *opposite* side is associated with party support
		if (`d'>=0) local first_term = ((`f' - `i'*`p')*`intcred')/(`p'*(1-`p'))
		if (`d'<0) local first_term = ((`f' - `i'*`p')*(1-`intcred'))/(`p'*(1-`p'))
		
		if (`i' > `p') local second_term = ((`i'-`p')*`cred')/(1-`p')
		if (`p' > `i') local second_term = ((`i'-`p')*(1-`cred'))/(1-`p')

		return scalar credweighted_yield = `first_term' + `second_term'
		local credweighted_yield = `first_term' + `second_term'
		
		if ("`credvar'"!="") {
			di ""
			di "Party credibility (cred):" _column(40) %3.2f `cred'
			di "Party credibility in *f* set (intcred):" _column(40) %3.2f `intcred'
			di "* Credibility-weighted issue yield:" _column(40) %3.2f `credweighted_yield'
		}
		// return scalar credweighted_yield = (`f' - `i'*`p')*`intcred'/(`p'*(1-`p')) + (`i'-`p')*`cred'/(1-`p')
		
		// with "rel" versions, much more meaningful and almost equal to old reports
		// return scalar credweighted_yield = (`f' - `i'*`p')*`intcredrel'/(`p'*(1-`p')) + (`i'-`p')*`credrel'/(1-`p')
		
		return scalar oldyield = `eff_magnitude'
		return local goallabel "`goallabel'"
		
	
end program
