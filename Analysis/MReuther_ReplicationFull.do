clear all
ssc install est2tex, replace
ssc install outtable, replace
ssc install tabstatmat, replace
capture log close 
set more off 

cd "//Client/C$/Users/maris/Dropbox/Grad/582 - Metrics I/ECON-582---Krueger-Replication/"
set logtype text
log using "./Analysis/Log-TablesAndFigures.txt", replace 

use "./Raw Data/STAR_Students.dta"


********************************************************************************
* I. Create / Reformat Variables
********************************************************************************

* Rename gk variables as g0 to make loops over grades possible later on
local k = "freelunch classtype classsize tmathss wordskillss treadss trace thighdegree schid tchid tyears tgen"
foreach var of local k{
   rename gk`var' g0`var'
}

* Create gradeenter as when a student entered TNSTAR
qui gen gradeenter = 0 if flagsgk == 1
qui replace gradeenter = 1 if flagsgk == 0 & flagsg1 == 1
qui replace gradeenter = 2 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 1 
qui replace gradeenter = 3 if flagsgk == 0 & flagsg1 == 0 & flagsg2 == 0 & flagsg3 == 1 

* Create White/Asian indicator
qui gen WhiteAsian = 1 if race == 1 | race == 3
qui replace WhiteAsian = 0 if WhiteAsian == . & race != .

* Create age as of September 1st, 1985 (start of 1985 school year)
qui gen bday = mdy(birthmonth, birthday, birthyear)
qui gen startschool = mdy(9,1,1985)
qui gen age = (startschool - bday)/365
qui replace age = 1985 - birthyear if age == .

* Redefine free lunch as (0 1)
local freelunch = "g0freelunch g1freelunch g2freelunch g3freelunch"
foreach var of local freelunch {
	qui gen `var'_2 = .  if `var'== .  
	qui replace `var'_2 = 0 if `var' == 2
	qui replace `var'_2 = 1 if `var' == 1
}

* Redefine gender as (0-male,1-female)
qui gen girl = gender - 1

* Create attrition rate: percent that exits sample at any time before completing third grade. 
* K:
qui gen g0attrition = 1 if flagsgk == 1 & flagsg1 == 0 | flagsg2 == 0 | flagsg3 == 0 
qui replace g0attrition = 0 if g0attrition == .
* 1:
qui gen g1attrition = 1 if flagsg1 == 1 & flagsg2 == 0 | flagsg3 == 0 
qui replace g1attrition = 0 if g1attrition == .
* 2:
qui gen g2attrition = 1 if flagsg2 == 1 & flagsg3 == 0 
qui replace g2attrition = 0 if g2attrition == .
* 3:
qui gen g3attrition = 0

* Create variable: Percentile Score as SAT average for reading, math, and word skills
forvalues i == 0/3 {

	foreach sub in `i'tread `i'tmath `i'wordskill {
		cumul g`sub'ss if inrange(g`i'classtype,2,3), gen(g`sub'xt)
		sort g`sub'ss
		qui replace g`sub'xt=g`sub'xt[_n-1] if g`sub'ss==g`sub'ss[_n-1] & g`i'classtype==1
		qui ipolate g`sub'xt g`sub'ss, gen(ipo)
		qui replace g`sub'xt=ipo if g`i'classtype==1 & mi(g`sub'xt)
		drop ipo
	}
	qui egen g`i'score = rmean(g`i'treadxt g`i'tmathxt g`i'wordskillxt)
	qui replace g`i'score = 100*g`i'score
}

* Create indicator for teacher with master's degree or higher
forvalues i == 0/3 {
	qui gen g`i'mdeg = 1 if g`i'thighdegree == 3 | g`i'thighdegree == 4 | g`i'thighdegree == 5 | g`i'thighdegree == 6
	qui replace g`i'mdeg = 0 if g`i'mddeg == . & g`i'thighdegree != .
}

* Create White Teacher indicator
forvalues i == 0/3 {
	qui gen WhiteTeacher`i' = 1 if g`i'trace == 1
	qui replace WhiteTeacher`i' = 0 if WhiteTeacher`i' == . & g`i'trace != .
}

* Create Male Teacher indicator
forvalues i == 0/3 {
	qui gen MaleTeacher`i' = 1 if g`i'tgen == 1
	qui replace MaleTeacher`i' = 0 if MaleTeacher`i' == . & g`i'tgen != .
}

* Create Indicator for small class, regular class, and regular+aide (needed for regressions in II, V, and VII)
forvalues i == 0/3{
	qui gen g`i's = 1 if g`i'classtype==1
	qui replace g`i's = 0 if g`i's == . & g`i'classtype != .

	qui gen g`i'r = 1 if g`i'classtype==2
	qui replace g`i'r = 0 if g`i'r == . & g`i'classtype != .

	qui gen g`i'ra = 1 if g`i'classtype==3
	qui replace g`i'ra = 0 if g`i'ra == . & g`i'classtype !=  .
}

* Create Indicator for students' initial assignment the first year they entered the program (needed for Reduced Form in V and instrument in VII)
qui gen firstclasstype = .
forvalues i == 0/3 {
	qui replace firstclasstype = g`i'classtype if gradeenter == `i'
}

qui gen initials = 1 if firstclasstype==1
qui replace initials = 0 if initials == . & firstclasstype != .
 
qui gen initialr = 1 if firstclasstype==2
qui replace initialr = 0 if initials == . & firstclasstype != .

qui gen initialra = 1 if firstclasstype==3
qui replace initialra = 0 if initialra == . & firstclasstype != .
 

********************************************************************************
* II. Tables and Figures
********************************************************************************
********************************************************************************
* II.a Table 1
********************************************************************************
forvalues i == 0/2 {
	local g`i'list = "g`i'freelunch_2 WhiteAsian age g`i'attrition g`i'classsize g`i'score"
}
local g3list = "g3freelunch_2 WhiteAsian age g3classsize g3score"
	
forvalues i == 0/3 {
   qui tabstat g`i'freelunch_2 WhiteAsian age g`i'attrition g`i'classsize g`i'score if gradeenter == `i', by(g`i'classtype) stat(mean) nototal save  //Create Means 
   qui tabstatmat g`i'means
   
   forvalues r == 1/3{
	  matrix g`i'means[`r',1] = round(g`i'means[`r',1], 0.001)
	 
	forvalues c == 1/6{
	    matrix g`i'means[`r',`c'] = round(g`i'means[`r',`c'], 0.001)
	    }
	}
   matrix rownames g`i'means = Small Regular Regular/Aide
   matrix rownames g`i'means = _:
   matrix colnames g`i'means = "FreeLunch" "White/Asian" "Agein1985" "Attrition" "Class-Size" "Percentile"
   matrix list g`i'means
   
   outtable using "./Output/Table 1/Table1_`i'.tex", replace mat(g`i'means) nobox    //Output table of means to latex
	
	matrix tab1pval_`i' = J(1, 6 , .) 
	qui gen n=1
   	  foreach var of local g`i'list { 
        qui mvtest means `var' if gradeenter == `i', by(g`i'classtype)	     //F test
		
		matrix tab1pval_`i'[1, n] = r(p_F)
		qui replace n = n+1	
		}
		drop n	
				
	forvalues c == 1/6{
		matrix tab1pval_`i'[1,`c'] = round(tab1pval_`i'[1, `c'], 0.001)	
		}
	
	matrix rownames tab1pval_`i' = "Joint P Value"
	matrix colnames tab1pval_`i' = "FreeLunch" "White/Asian" "Agein1985" "Attrition" "Class-Size" "Percentile" 
	matrix list tab1pval_`i'
	
	outtable using "./Output/Table 1/Table1pval_`i'.tex", replace mat(tab1pval_`i') nobox   //Output table of p values to latex
}
	
	
********************************************************************************
* II.b Table 2
********************************************************************************
forvalues i == 0/3 {
	
	matrix tab2pval_`i' = J(6, 1, .)
	qui gen n=1
	foreach var of local g`i'list { 
		qui areg `var' g`i's g`i'ra if gradeenter==`i', absorb(g`i'schid)       //Run regression to get p values 
		
		matrix tab2pval_`i'[n, 1] = e(p)
		qui replace n = n+1	
		}
		drop n
		
	forvalues r == 1/6{
		matrix tab2pval_`i'[`r', 1] = round(tab2pval_`i'[`r', 1], 0.001)	
		}
	
	matrix rownames tab2pval_`i' = "FreeLunch" "White/Asian" "Agein1985" "Attrition" "Class-Size" "Percentile"
	matrix colnames tab2pval_`i' =  "`i'"
	matrix list tab2pval_`i'
	
	outtable using "./Output/Table 2/Table2pval_`i'.tex", replace mat(tab2pval_`i') nobox      //Output table of p values to latex
}

 
********************************************************************************
* II.c Table 3
********************************************************************************
qui tab g1classsize g1classtype, matcell(t3)               //Create table 3
matrix colnames t3 = "Small" "Regular" "Regular/Aide"
matrix rownames t3 = "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" 
matrix list t3

outtable using "./Output/Table 3/Table3.tex", replace mat(t3) nobox    //Output table 3 to latex

qui tabstat g1classsize, by(g1classtype) stat(mean) nototal save       //Create averages for bottom of table 3
qui tabstatmat t3mean
forvalues r == 1/3{
	  matrix t3mean[`r',1] = round(t3mean[`r',1], 0.001)  
}

matrix rownames t3mean = Small Regular Regular/Aide
matrix rownames t3mean = _:
matrix colnames t3mean = "Average Class Size"
matrix list t3mean

outtable using "./Output/Table 3/Table3m.tex", replace mat(t3mean) nobox    //Output averages in table 3 to latex


********************************************************************************
*II.d Figure 1 
********************************************************************************
forvalues n=0/3 {
	twoway kdensity g`n'score if (g`n'classtype==1) || kdensity g`n'score if (g`n'classtype==2 | g`n'classtype==3), title("Average SAT Distributions for Grade `n'") ytitle("Density") xtitle("SAT Percentile") legend(label(1 "Small Class") label(2 "Regular Class")) scheme(economist)
	
	graph export "./Output/Figure 1/figure1_`n'.png", replace
}


********************************************************************************
* II.e Table 5
********************************************************************************
label variable WhiteAsian "White/Asian"
label variable girl "Girl"
forvalues i == 0/3 {
	label variable g`i's "Small Class"	
	label variable g`i'ra "Regular + Aide Class"
	label variable g`i'freelunch_2 "Free Lunch"
	label variable WhiteTeacher`i' "White Teacher"
	label variable MaleTeacher`i' "Male Teacher"
	label variable g`i'tyears "Teacher Experience"
	label variable g`i'mdeg "Master's Degree"
	label variable initials "Initial Assignment - Small Class"
	label variable initialra "Initial Assignment - Regular Class"
	label variable g`i'classsize "Class Size"
}

* OLS - Actual Class Size
	* 1. Small Class, Regular/Aide class, no school FE. 
forvalues i == 0/3 {
	reg g`i'score g`i's g`i'ra, vce(cluster g`i'tchid)
	est2vec table5a`i', replace vars(g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'mdeg) name(Col1`i')
 } 
	* 2. Small Class, Regular/Aide class, school FE
forvalues i == 0/3 {
    areg g`i'score g`i's g`i'ra, vce(cluster g`i'tchid) absorb(g`i'schid)  
	est2vec table5a`i', addto(table5a`i') name(Col2`i')
} 	
	* 3. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
forvalues i == 0/3 {
	areg g`i'score g`i's g`i'ra  WhiteAsian girl g`i'freelunch_2, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a`i', addto(table5a`i') name(Col3`i')
} 		
	* 4. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience (gktyears), Teacher Male, Master's Degree, school FE
forvalues i == 0/3 {
	areg g`i'score g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'mdeg, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a`i', addto(table5a`i') name(Col4`i')
} 	

* Reduced Form - Initial Class Size -- Class size from first appearance in TNSTAR; Outcome is average SAT percentile;  
	* 5. Small Class, Regular/Aide class, no school FE
forvalues i == 0/3 {
	reg g`i'score initials initialra, vce(cluster g`i'tchid) 
	est2vec table5b`i', replace vars(initials initialra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'mdeg) name(Col5`i')
} 
	* 6. Small Class, Regular/Aide class, school FE
forvalues i == 0/3 {
    areg g`i'score initials initialra, vce(cluster g`i'tchid) absorb(g`i'schid)  
	est2vec table5b`i', addto(table5b`i') name(Col6`i')
} 	
	* 7. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
forvalues i == 0/3 {
	areg g`i'score initials initialra WhiteAsian girl g`i'freelunch_2, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5b`i', addto(table5b`i') name(Col7`i')
} 	
	* 8. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience, Master's Degree, school FE
forvalues i == 0/3 {
	areg g`i'score initials initialra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'mdeg, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5b`i', addto(table5b`i') name(Col8`i')
} 	

* Output OLS (cols 1-4) and Reduced Form (cols 5-8) tables to latex. Have one table per grade. 	
forvalues i == 0/3 {.
	est2tex table5a`i', replace preserve path("./Output/Table 5/") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)") 
	est2tex table5b`i', replace preserve path("./Output/Table 5/") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)")
} 

  
********************************************************************************
* II.f Table 7
******************************************************************************** 

* OLS - Using full controls. Using actual class size instead of class type. 
forvalues i == 0/3 {
	areg g`i'score g`i'classsize WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'mdeg, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table7`i', replace vars(g`i'classsize) name(Col1`i')
} 

* 2SLS - Using full controls. Initial class assignment as an instrument for actual class size. 
forvalues i == 0/3 {
	ivregress 2sls g`i'score (g`i'classsize=i.firstclasstype) WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'mdeg i.g`i'schid, vce(cluster g`i'tchid) 
	est2vec table7`i', addto(table7`i') name(Col2`i')
} 

* Output table 7 to latex. OLS is column 1; 2SLS is column 2; Have one table per grade. 
forvalues i == 0/3 {
	est2tex table7`i', replace preserve path("./Output/Table 7") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)")
} 



