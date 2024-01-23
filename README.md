# issueyield
Stata ADO file for calculating the [Issue Yield index](https://en.wikipedia.org/wiki/Issue_Yield) (De Sio and Weber 2014, 2020) on a survey dataset. For a particular political party, the index summarizes the electoral risk/opportunity combination associated with a particular issue goal (risks of internal division vs opportunity for electoral expansion among non-supporters).

## Usage
```
issueyield <issue_position_variable>, partyexp(<party_expression>) [wtexp(<weight_expression>)] [credvar(<credibility_variable>)]
```
where variables are:

```issue_position_variable``` : a dichotomous variable indicating whether the respondent supports the issue goal;

```party_expression``` : an expression identifying party supporters;

```credibility_variable``` : a dichotomous variable indicating whether the respondent deems the party credible on the issue goal;

```weight_expression``` : a Stata weight expression to apply weights.

## Examples

### Example 1
Using ANES Time Series 2020 data (retrieved from https://electionstudies.org/anes_timeseries_2020_stata_20220210/), calculates issue yield for *support for death penalty*, separately for (pre-electoral) supporters of the Democratic and Republican presidential candidates.
```
include "issueyield.ado"
use "anes_timeseries_2020_stata_20220210.dta" , clear

recode V201075x (10 20 30 = 1 "Dem") (11 21 31 = 2 "Rep") (12 22 32 = 3 "Other"), gen(pres_voteintpref)
recode V201345x (1 2 = 1 "Favor death penalty") (3 4 = 0 "Oppose death penalty") (-2 = .), gen(issue01_favordeathpenalty)

issueyield issue01_favordeathpenalty, partyexp("pres_voteintpref==1")
issueyield issue01_favordeathpenalty, partyexp("pres_voteintpref==2")
``` 
### Example 2
Same as above (for Republicans), but weighting observations by *V200010b*.
```
issueyield issue01_favordeathpenalty, partyexp("pres_voteintpref==2") wtexp("[aw=V200010b]")
``` 
### Example 3
Using [ICCP](https://cise.luiss.it/iccp/) 2017-18 v2 data, retrieved from [here](https://cise.luiss.it/iccp/wp-content/uploads/2020/02/ICCP_v2.0.0_dta_datasets.zip) (also available as [GESIS study ZA7499](https://search.gesis.org/research_data/ZA7499)), calculates issue yield for *introduction of a flat tax*, separately for (pre-electoral) supporters of Italy's *Lega* and *PD (Partito Democratico)*.
```
use "ICCP_voter_survey_it17_lbl", clear
rename goal_it_p5 issue01_flattax

issueyield issue01_flattax, partyexp(`"voteint_party=="it_lega""')
issueyield issue01_flattax, partyexp(`"voteint_party=="it_pd""')
``` 

### Example 4
Same as Example 3, but also calculating *credibility-weighted Issue Yield*, which takes into account an explicit (dichotomous) measure of party credibility to achieve the goal.
```
issueyield issue01_flattax, partyexp(`"voteint_party=="it_lega""') credvar(cred_it_p5_lega)
issueyield issue01_flattax, partyexp(`"voteint_party=="it_pd""') credvar(cred_it_p5_pd)
``` 

### Example 5
Same as in Example 4, but weighting observations by *wdempol_trim*.
```
issueyield issue01_flattax, partyexp(`"voteint_party=="it_lega""') credvar(cred_it_p5_lega) wtexp("[aw=wdempol_trim]")
```

