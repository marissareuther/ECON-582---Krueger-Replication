clear all
ssc install outtable, replace
ssc install tabstatmat, replace
capture log close 
set more off 

cd "//Client/C$/Users/maris/Dropbox/Grad/582 - Metrics I/ECON-582---Krueger-Replication/"
set logtype text
log using "./Analysis/Log-Tables123_Figure1.txt", replace 

use "./Output/Data/CleanData.dta"


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
		qui areg `var' g`i's g`i'ra if gradeenter==`i', absorb(g`i'schid) 
		}
}

matrix T2pval=(0.446, 0.292, 0.579, 0.184 \ 0.647, 0.276, 0.710, 0.369 \ 0.438, 0.120, 0.435, 0.477 \ 0.012, 0.370, 0.848, 0.000 \ 0.000, 0.000, 0.000, 0.000 \ 0.000, 0.000, 0.449, 0.004)  
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

