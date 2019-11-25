clear all
** in case of installing bug:
*net set ado "//Client/C$/Users/maris/" 
*adopath ++ "//Client/C$/Users/maris/"
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

* Rename gk variables as g0 to make loops possible later on
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

* Create Age as of September 1st, 1985 (start of 1985 school year)
qui gen bday = mdy(birthmonth, birthday, birthyear)
qui gen startschool = mdy(9,1,1985)
qui gen age = (startschool - bday)/365
 qui replace age = 1985 - birthyear if age == .

* Redefine free lunch as (0 1) instead of (1 2)
local freelunch = "g0freelunch g1freelunch g2freelunch g3freelunch"
foreach var of local freelunch {
 qui gen `var'_2 = .  if `var'== .  
  qui replace `var'_2 = 0 if `var' == 2
  qui replace `var'_2 = 1 if `var' == 1
}

* Redefine gender as (0-male,1-female) instead of (1,2) 
qui gen girl = gender - 1

* Create Attrition rate: percent that exits sample before completing third grade. 
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

* Create variable: Percentile Score as SAT average for reading, math, and listening
forvalues i == 0/3 {

	foreach sub in `i'tread `i'tmath `i'wordskill {
		cumul g`sub'ss if inrange(g`i'classtype,2,3), gen(g`sub'xt)
		sort g`sub'ss
		qui replace g`sub'xt=g`sub'xt[_n-1] if g`sub'ss==g`sub'ss[_n-1] & g`i'classtype==1
		qui ipolate g`sub'xt g`sub'ss, gen(ipo)
		qui replace g`sub'xt=ipo if g`i'classtype==1 & mi(g`sub'xt)
		drop ipo
	}
	qui egen g`i'SAT = rmean(g`i'treadxt g`i'tmathxt g`i'wordskillxt)
	 qui replace g`i'SAT=100*g`i'SAT
}

* Create indicator for white teacher 
forvalues i == 0/3 {
	qui gen g`i'twhite = 1 if g`i'trace == 1
	 qui replace g`i'twhite = 0 if g`i'twhite==. & g`i'trace != .
}

* Create indicator for teacher with master's degree or higher
forvalues i == 0/3 {
	qui gen g`i'md = 1 if g`i'thighdegree == 3 | g`i'thighdegree == 4 | g`i'thighdegree == 5 | g`i'thighdegree == 6
	 qui replace g`i'md = 0 if g`i'md==. & g`i'thighdegree != .
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

* Create Indicator for small class, regular class, and regular+aide (needed for II, V, and VII)
forvalues i == 0/3{
	qui gen g`i's = 1 if g`i'classtype==1
	 qui replace g`i's = 0 if g`i's == . & g`i'classtype != .

	qui gen g`i'r = 1 if g`i'classtype==2
	 qui replace g`i'r = 0 if g`i'r == . & g`i'classtype != .

	qui gen g`i'ra = 1 if g`i'classtype==3
	 qui replace g`i'ra = 0 if g`i'ra == . & g`i'classtype !=  .
}

* Create Indicator for students' initial assignment the first year they entered the program (needed for Reduced Form in V)
qui gen fyclasstype = .
forvalues i == 0/3 {
	qui replace fyclasstype = g`i'classtype if gradeenter == `i'
}

qui gen initials = 1 if fyclasstype==1
 qui replace initials = 0 if initials == . & fyclasstype != .

qui gen initialra = 1 if fyclasstype==3
 qui replace initialra = 0 if initialra == . & fyclasstype !=  .
 

*save "./Output/Data/CleanData.dta", replace


********************************************************************************
* II. Tables and Figures
********************************************************************************

********************************************************************************
* II.a Table 1
********************************************************************************
forvalues i == 0/2 {
	local g`i'list = "g`i'freelunch_2 WhiteAsian age g`i'attrition g`i'classsize g`i'SAT"
}
	local g3list = "g3freelunch_2 WhiteAsian age g3classsize g3SAT"
	
forvalues i == 0/3 {
   qui tabstat g`i'freelunch_2 WhiteAsian age g`i'attrition g`i'classsize g`i'SAT if gradeenter == `i', by(g`i'classtype) stat(mean) nototal save
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
   
   outtable using "./Output/Table 1/Table1_`i'.tex", replace mat(g`i'means) nobox 
	
   	  foreach var of local g`i'list { 
        
	    qui mvtest means `var' if gradeenter == `i', by(g`i'classtype)	
		}
}

matrix T1pval=(0.088, 0.518, 0.605, 0.038 \ 0.251, 0.000, 0.000, 0.003 \ 0.335, 0.033, 0.405, 0.498 \ 0.024, 0.069, 0.580, 0.000 \ 0.000, 0.000, 0.000, 0.000 \ 0.000, 0.000, 0.010, 0.006)  
matrix rownames T1pval = "FreeLunch" "White/Asian" "Agein1985" "Attrition" "Class-Size" "Percentile"
matrix colnames T1pval = "K" "1" "2" "3"
matrix list T1pval

outtable using "./Output/Table 1/Table1pval.tex", replace mat(T1pval) nobox 
	
	
********************************************************************************
* II.b Table 2
********************************************************************************
forvalues i == 0/3 {
	
	foreach var of local g`i'list { 
		areg `var' g`i's g`i'ra if gradeenter==`i', absorb(g`i'schid) 
		}
}

matrix T2pval=(0.446, 0.292, 0.579, 0.184 \ 0.647, 0.276, 0.710, 0.369 \ 0.438, 0.120, 0.435, 0.477 \ 0.012, 0.370, 0.848, 0.000 \ 0.000, 0.000, 0.000, 0.000 \ 0.000, 0.000, 0.429, 0.004)  
matrix rownames T2pval = "FreeLunch" "White/Asian" "Agein1985" "Attrition" "Class-Size" "Percentile"
matrix colnames T2pval = "K" "1" "2" "3"
matrix list T2pval

outtable using "./Output/Table 2/Table2pval.tex", replace mat(T2pval) nobox 

 
********************************************************************************
* II.c Table 3
********************************************************************************
qui tab g1classsize g1classtype, matcell(t3)
matrix colnames t3 = "Small" "Regular" "Regular/Aide"
matrix rownames t3 = "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" 
matrix list t3

outtable using "./Output/Table 3/Table3.tex", replace mat(t3) nobox 

qui tabstat g1classsize, by(g1classtype) stat(mean) nototal save
qui tabstatmat t3mean
forvalues r == 1/3{
	  matrix t3mean[`r',1] = round(t3mean[`r',1], 0.001)  
}

matrix rownames t3mean = Small Regular Regular/Aide
matrix rownames t3mean = _:
matrix colnames t3mean = "Average Class Size"
matrix list t3mean

outtable using "./Output/Table 3/Table3m.tex", replace mat(t3mean) nobox 


********************************************************************************
*II.d Figure 1 
********************************************************************************
forvalues n=0/3 {
	twoway kdensity g`n'SAT if (g`n'classtype==1)|| kdensity g`n'SAT if (g`n'classtype==2 | g`n'classtype==3), title("Average SAT Distributions for Grade `n'") ytitle("Density") xtitle("SAT Percentile") legend(label(1 "Small Class") label(2 "Regular Class")) lpattern("solid" "dash") scheme(s1color)
	
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
	label variable g`i'md "Master's Degree"
	label variable initials "Initial Assignment - Small Class"
	label variable initialra "Initial Assignment - Regular Class"
	label variable g`i'classsize "Class Size"
}


* OLS - Actual Class Size
	* 1. Small Class, Regular/Aide class, no school FE. 
forvalues i == 0/3 {
	reg g`i'SAT g`i's g`i'ra, vce(cluster g`i'tchid)
	est2vec table5a`i', replace vars(g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md) name(Col1`i')
 } 
	* 2. Small Class, Regular/Aide class, school FE
forvalues i == 0/3 {
    areg g`i'SAT g`i's g`i'ra, vce(cluster g`i'tchid) absorb(g`i'schid)  
	est2vec table5a`i', addto(table5a`i') name(Col2`i')
} 	
	* 3. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
forvalues i == 0/3 {
	areg g`i'SAT g`i's g`i'ra  WhiteAsian girl g`i'freelunch_2, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a`i', addto(table5a`i') name(Col3`i')
} 		
	* 4. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience (gktyears), Teacher Male, Master's Degree, school FE
forvalues i == 0/3 {
	areg g`i'SAT g`i's g`i'ra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5a`i', addto(table5a`i') name(Col4`i')
} 	

* Reduced Form - Initial Class Size -- Class size from first appearance in TNSTAR; Outcome is average SAT percentile;  
	* 5. Small Class, Regular/Aide class, no school FE
forvalues i == 0/3 {
	reg g`i'SAT initials initialra, vce(cluster g`i'tchid) 
	est2vec table5b`i', replace vars(initials initialra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md) name(Col5`i')
} 
	* 6. Small Class, Regular/Aide class, school FE
forvalues i == 0/3 {
    areg g`i'SAT initials initialra, vce(cluster g`i'tchid) absorb(g`i'schid)  
	est2vec table5b`i', addto(table5b`i') name(Col6`i')
} 	
	* 7. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, school FE
forvalues i == 0/3 {
	areg g`i'SAT initials initialra WhiteAsian girl g`i'freelunch_2, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5b`i', addto(table5b`i') name(Col7`i')
} 	
	* 8. Small Class, Regular/Aide class, White/Asian, Girl, Free Lunch, White Teacher, Teacher Experience, Master's Degree, school FE
forvalues i == 0/3 {
	areg g`i'SAT initials initialra WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table5b`i', addto(table5b`i') name(Col8`i')
} 	

* Output OLS and Reduced table to latex. Have one table per grade. 	
forvalues i == 0/3 {
	est2tex table5b`i', replace preserve path("./Output/Table 5/") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)")
	est2tex table5a`i', replace preserve path("./Output/Table 5/") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)") 
} 

  
********************************************************************************
* II.f Table 7
******************************************************************************** 

* OLS
forvalues i == 0/3 {
	areg g`i'SAT g`i'classsize WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md, vce(cluster g`i'tchid) absorb(g`i'schid)
	est2vec table7`i', replace vars(g`i'classsize) name(Col1`i')
} 

* 2SLS 
forvalues i == 0/3 {
	ivregress 2sls g`i'SAT (g`i'classsize=i.fyclasstype) WhiteAsian girl g`i'freelunch_2 WhiteTeacher`i' MaleTeacher`i' g`i'tyears g`i'md i.g`i'schid, vce(cluster g`i'tchid) 
	est2vec table7`i', addto(table7`i') name(Col2`i')
} 

* Output table 7 to latex. Have one table per grade. 
forvalues i == 0/3 {
	est2tex table7`i', replace preserve path("./Output/Table 7") mark(stars) levels(90 95 99) flexible(2) fancy label leadzero thousep collabels("(1)" "(2)" "(3)" "(4)")
} 



