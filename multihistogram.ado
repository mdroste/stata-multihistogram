*===============================================================================
* FILE: multihistogram.ado
* PURPOSE: Quick program to produce overlaid histograms with aligned bins
* Author: Michael Droste
*===============================================================================

program define multihistogram, rclass
	version 15
	set more off
	syntax varlist(max=4 numeric) [if] [in], ///
		[ ///
		twopt(string asis) ///
		start(real -10) ///
		bin(integer -10) ///
		opacity(integer 40) ///
		if1(string asis) if2(string asis) if3(string asis) if4(string asis) ///
		linewidth(string asis) ///
		]
	
	* Specify default colors
	local colors1 ebblue
	local colors2 maroon
	local colors3 emerald
	local colors4 purple
	
	*---------------------------------
	* Exception handling
	*---------------------------------
	
	* Make sure opacity is between 0 and 100
	if `opacity'>100 | `opacity' < 0 {
	    di as error "Error: opacity must be integer between 0 and 100 (default 40). You chose opacity(`opacity')."
		exit 1
	}
	
	* Make sure bin is either default (-10, set below) or positive integer < num obs
	if `bin'<0 & `bin'!=-10 {
	    di as error "Error: number of bins, if specified, should be positive number. You chose bin(`bin')."
		exit 1
	}
	
	* check if linewidth specified right
	
	*---------------------------------
	* If/in
	*---------------------------------
	
	* Preserve data
	preserve
	
	* Apply if/in restrictions
	marksample touse, novarlist
	markout `touse' `exp'
	qui keep if `touse'
	
	*---------------------------------
	* Casewise ifs
	*---------------------------------
	
	if "`if1'"!=""  local fif1 if `if1'
	if "`if2'"!=""  local fif2 if `if2'
	if "`if3'"!=""  local fif3 if `if3'
	if "`if4'"!=""  local fif3 if `if4'
	
	*---------------------------------
	* Process variables
	*---------------------------------
	
	* Find minimum and maximum values across *all * variables, plus min. obs count
	local min_val = 99999999999999
	local max_val = -99999999999999
	local min_N   = 9999999999999
	local curr = 1
	qui foreach v in `varlist' {
	    sum `v' `fif`curr''
		if r(min) <= `min_val' local min_val = r(min)
		if r(max) >= `max_val' local max_val = r(max)
		if r(N)   <= `min_N'   local min_N = r(N) 
		local curr = `curr'+1
	}
	
	*---------------------------------
	* Define a number of bins according to XX rule
	*---------------------------------
	
	if `bin'!=-10 {
	    local k = `bin'
	}
	
	if `bin'==-10 {
		local k = min(sqrt(`min_N'), 10*ln(`min_N')/ln(10))  
	}
	
	* Construct bin widths from k
	local width = (`max_val'-`min_val')/`k'
	
	*---------------------------------
	* labels
	*---------------------------------
	
	local label_counter = 1
	foreach v in `varlist' {
	    local hist_label: variable label `v'
		if "`hist_label'"=="" local hist_label `v'
		local legend_labels `legend_labels' `label_counter' "`hist_label'"
	    local label_counter = `label_counter'+1
	}
	
	*---------------------------------
	* Build a twoway macro command
	*---------------------------------
	
	if "`linewidth'"!="" local flw lwidth(`linewidth')
	if "`linewidth'"=="" local flw lwidth(vthin)
	local twoway_cmd twoway 
	local curr_var 1
	foreach v in `varlist' {
	    local twoway_cmd `twoway_cmd' (histogram `v' `fif`curr_var'', start(`min_val') width(`width') `flw' color(`colors`curr_var''%`opacity'))
		local curr_var = `curr_var' + 1
	}
	
	* add legend
	local twoway_cmd `twoway_cmd', legend(order(`legend_labels'))
	di `"`legend_labels'"'
	
	* add user supplied options
	local twoway_cmd `twoway_cmd' `twopt'
	
	*---------------------------------
	* Run twoway command
	*---------------------------------
	
	`twoway_cmd'
	
	*---------------------------------
	* Restore data to undo if/in restrictions before exiting
	*---------------------------------
	
	restore
	
end
	