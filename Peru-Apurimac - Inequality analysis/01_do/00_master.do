********************************************************************************
** 	TITLE: 00_master.do
**
**	PURPOSE: Run all do files
**				
**	AUTHOR: Nicolás Huamaní (nhuamanivelazque@gmail.com)
********************************************************************************

clear all

gl cwd   = 	"C:\Users\\`c(username)'\Documents\projects\Inequality and poverty\Peru-Apurimac - Inequality analysis"


do "${cwd}\01_do\01_globals.do"

do "$do\02_clean.do"

do "$do\03_analysis.do"