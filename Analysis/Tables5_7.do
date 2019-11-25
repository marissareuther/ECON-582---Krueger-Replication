clear all
capture log close 
set more off 
ssc install est2tex, replace

cd "//Client/C$/Users/maris/Dropbox/Grad/582 - Metrics I/ECON-582---Krueger-Replication/"
set logtype text
log using "./Analysis/Tables5_7.txt", replace 

use "./Output/Data/CleanData.dta"


********************************************************************************
* II.e Table 5
********************************************************************************

forvalues i == 0/3 {
	preserve 
	use "./Output/Data/CleanData.dta"
	drop if missing(WhiteAsian)
	drop if missing(girl)
	drop if missing(g`i'freelunch_2)
	drop if missing(WhiteTeacher`i')
	drop if missing(MaleTeacher`i')
	drop if missing(g`i'tyears)
	drop if missing(g`i'md)
	save "./Output/Data/g`i'sample.dta", replace
	restore
}

* OLS - Actual Class Size; Outcome is average SAT percentile; Four specifications 
	* 1. Small Class, Regular/Aide class, no school FE. 
forvalues i == 0/3 {
	preserve
	use "./Output/Data/g`i'sample.dta"
	reg g`i'SAT g`i's g`i'ra, vce(cluster g`i'tchid)
	est2vec table5a2`i', replace vars(g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md) name(Col1`i')
	restore
 } 
	* 2. Small Class, Regular/Aide class, school FE
forvalues i == 0/3 {
    preserve
	use "./Output/Data/g`i'sample.dta"
	areg g`i'SAT g`i's g`i'ra, vce(cluster g`i'tchid) absorb(g`i'schid)  
	est2vec table5a2`i', addto(table5a2`i') name(Col2`i')
	restore
} 	
	* 3. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
forvalues i == 0/3 {
	preserve
	use "./Output/Data/g`i'sample.dta"
	areg g`i'SAT g`i's g`i'ra  WhiteAsian girl g`i'freelunch_2, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a2`i', addto(table5a2`i') name(Col3`i')
	restore
} 		
	* 4. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience (gktyears), Teacher Male, Master's Degree, school FE
forvalues i == 0/3 {
	preserve
	use "./Output/Data/g`i'sample.dta"
	areg g`i'SAT g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a2`i', addto(table5a2`i') name(Col4`i')
	restore
} 	

* Output table to latex. Have one table per grade. 	
forvalues i == 0/3 {
	est2tex table5a2`i', replace preserve path("./Output/Table 5/") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)") 
} 

* Reduced Form - Initial Class Size -- Class size from first appearance in TNSTAR; Outcome is average SAT percentile;  Four specifications 
	* 5. Small Class, Regular/Aide class, no school FE
forvalues i == 0/3 {
	preserve
	use "./Output/Data/g`i'sample.dta"
	reg g`i'SAT initials initialra, vce(cluster g`i'tchid) 
	est2vec table5b2`i', replace vars(initials initialra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md) name(Col5`i')
	restore
} 
	* 6. Small Class, Regular/Aide class, school FE
forvalues i == 0/3 {
    preserve
	use "./Output/Data/g`i'sample.dta"
	areg g`i'SAT initials initialra, vce(cluster g`i'tchid) absorb(g`i'schid)  
	est2vec table5b2`i', addto(table5b2`i') name(Col6`i')
	restore
} 	
	* 7. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
forvalues i == 0/3 {
	preserve
	use "./Output/Data/g`i'sample.dta"
	areg g`i'SAT initials initialra WhiteAsian girl g`i'freelunch_2, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5b2`i', addto(table5b2`i') name(Col7`i')
	restore
} 	
	* 8. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience, Master's Degree, school FE
forvalues i == 0/3 {
	preserve
	use "./Output/Data/g`i'sample.dta"
	areg g`i'SAT initials initialra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5b2`i', addto(table5b2`i') name(Col8`i')
	restore
} 	
	
* Output table to latex. Have one table per grade. 	
forvalues i == 0/3 {
	est2tex table5b2`i', replace preserve path("./Output/Table 5/'") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)")
} 

 
 
********************************************************************************
* II.f Table 7
******************************************************************************** 

* OLS and 2SLS Estimates of Effect of Class Size on Achievement. 
* Dependent Variable: Average Percentile Score on SAT.

* Reported Coefficient is for actual number of students in each class. 

forvalues i == 0/3 {
	preserve
	use "./Output/Data/g`i'sample.dta"
	areg g`i'SAT g`i'classsize WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table72`i', replace vars(g`i'classsize) name(Col1`i')
	restore
} 

forvalues i == 0/3 {
	preserve
	use "./Output/Data/g`i'sample.dta"
	ivregress 2sls g`i'SAT (g`i'classsize=i.g`i'classtype) WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md i.g`i'schid, vce(cluster g`i'tchid) 
	est2vec table72`i', addto(table72`i') name(Col2`i')
	restore
} 

* Output table to latex. Have one table per grade. 
forvalues i == 0/3 {
	est2tex table72`i', replace preserve path("./Output/Table 7/table72`i'.tex") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)")
} 
