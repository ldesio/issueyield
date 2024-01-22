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
```
issueyield supports_gun_control, partyexp("voted=='Dem'")
display r(yield)
``` 
Calculates (and displays) issue yield for the *gun control* issue for the Democratic Party.

### Example 2
```
issueyield supports_gun_control, partyexp("voted=='Dem'") credvar(cred_dem_guncontrol)
display r(yield)
display r(credweighted_yield)
``` 
Same as above, but also taking into account an additional variable capturing credibility of the Democratic Party on the issue goal.
Displays both versions of the index (with and without considering credibility).

### Example 3
```
issueyield supports_gun_control, partyexp("voted=='Dem'") credvar(cred_dem_guncontrol) wtexp(sample_weight)
display r(yield)
display r(credweighted_yield)
``` 
Same as above, but weighting observations by *sample_weight*.


