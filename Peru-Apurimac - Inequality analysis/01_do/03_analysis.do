********************************************************************************
** 	TITLE: 03_analysis.do
**
**	PURPOSE: Conduct an exploratory analysis and inequality indicators.
**				
**	AUTHOR: Nicolás Huamaní (nhuamanivelazque@gmail.com)
******************************************************************************** 

use "$clean\sumaria-04-21", clear 

* generando el factor de expansión poblacional
g facpob07 = mieperho*factor07 
g facfw = round(facpob07)
sum ypc [fw = facfw] if year == 2021, detail

****---ANÁLISIS DESCRIPTIVO---****  

gen year2012 = year 
replace year2012 = . if year > 2012
gen year2021 = year 
replace year2021 =. if year < 2013

	*histogramas 
histogram ypc [fw = facfw] if year == 2010 |year == 2019 | year == 2020 | year == 2021,by(year) kdensity frac ///
	name(g0, replace) 
graph export "$out\Histograma - ypc Perú.png", replace

histogram ypc [fw = facfw] if departamento == 3 & (year == 2010 |year == 2019 | year == 2020 | year == 2021),by(year) kdensity frac ///
	name(g00, replace) 
graph export "$out\Histograma - ypc Apurímac.png", replace
	
	*análisis por decíles 	
forvalues i = 2004/2021 { 
pshare estimate ypc  [fw = facfw] if year == `i', nquantiles(10)
}
		
forvalues i = 2004/2021 { 
pshare estimate ypc  [fw = facfw] if year == `i' & departamento ==3 , nquantiles(10)
}

	*boxplots comparativos 
graph box ypc [fw = facfw], by(apurimac, note("") title("Comparativo de la distribución de los ingresos per capita mensuales: 2004-2021", size(medium))) over(year) asyvars legend(pos(6) row(2)) ///
	note(" ")  name(g1, replace) 
graph export "$out\Comparativo de ypc 2004-2021.png", replace	
graph box ypc [fw = facfw], by(apurimac, note("") title("Comparativo de la distribución de los ingresos per cápita mensuales (sin outliers): 2004-2021", size(medsmall))) over(year) asyvars noout legend(pos(6) row(2)) ///
	note(" ") name(g2, replace) 
graph export "$out\Comparativo de ypc 2004-2021 (sin outliers).png", replace	

****---INDICADOR ORDINAL DE DESIGUALDAD: LA CURVA DE LORENZ---****  
 
	*obteniendo coordenadas de las curvas de lorenz 2004-2021 a nivel nacional
glcurve ypc [aw = facpob07], lorenz glvar(y_ord) pvar(rank) by(year) split nograph replace //guardando coordenadas
gen recta_45° = rank 
quietly: save "$out\base_ingresos_lorenz.dta", replace

	*generando el gráfico de la curva de lorenz a nivel nacional 
#delimit;
graph twoway
	(line y_ord_2010 rank, sort lcolor(orange) lwidth(thin) lpattern(solid))
	(line y_ord_2019 rank, sort lcolor(magenta) lwidth(thin) lpattern(solid))
	(line y_ord_2020 rank, sort lcolor(lime) lwidth(thin) lpattern(solid))
	(line y_ord_2021 rank, sort lcolor(cyan) lwidth(thin) lpattern(solid))
	(line recta_45° rank, sort clwidth(medthin) clcolor(red)),
	ytitle("Proporción acum. de ingresos por Lorenz", margin(r=1))
	ylabel(, angle(0) format(%4.2fc) labsize(small) nogrid)
	xtitle("Proporción acum. de población", margin(t=1))
	xlabel(0(0.2)1, format(%4.2fc) labsize(small) nogrid)
	legend(pos(10) ring(0) cols(1) size(vsmall) bmargin(t=-2) region(lstyle(none) fcolor(none)))
	title("Perú: Curvas de Lorenz para 2010, 2019, 2020 y 2021", tstyle(subheading))
	note("Fuente: Enaho 2009 al 2021. Elaboración propia")
	scheme(s1mono) graphregion(fcolor (white)) plotregion(margin(zero))
	name(g3, replace);	
#delimit cr 
graph export "$out\Curva de Lorenz - Perú.png", replace

	*obteniendo coordenadas de las curvas de lorenz 2004-2021 para Apurímac 
glcurve ypc [aw = facpob07] if departamento==3, lorenz glvar(y_ord_apu) pvar(rank_apu) by(year) split nograph replace //guardando coordenadas
	
quietly: save "$out\base_ingresos_lorenz_apu.dta", replace

	*generando el gráfico de la curva de lorenz para Apurímac 
#delimit;
graph twoway
	(line y_ord_apu_2010 rank_apu, sort lcolor(orange) lwidth(thin) lpattern(solid))
	(line y_ord_apu_2019 rank_apu, sort lcolor(magenta) lwidth(thin) lpattern(solid))
	(line y_ord_apu_2020 rank_apu, sort lcolor(lime) lwidth(thin) lpattern(solid))
	(line y_ord_apu_2021 rank_apu, sort lcolor(cyan) lwidth(thin) lpattern(solid))
	(line recta_45° rank, sort clwidth(medthin) clcolor(red)),
	ytitle("Proporción acum. de ingresos por Lorenz", margin(r=1))
	ylabel(, angle(0) format(%4.2fc) labsize(small) nogrid)
	xtitle("Proporción acum. de población", margin(t=1))
	xlabel(0(0.2)1, format(%4.2fc) labsize(small) nogrid)
	legend(pos(10) ring(0) cols(1) size(vsmall) bmargin(t=-2) region(lstyle(none) fcolor(none)))
	title("Apurímac: Curvas de Lorenz para 2010, 2019, 2020 y 2021", tstyle(subheading))
	note("Fuente: Enaho 2009 al 2021. Elaborado por Nicolás Huamaní")
	scheme(s1mono) graphregion(fcolor (white)) plotregion(margin(zero))
	name(g4, replace);
#delimit cr 
graph export "$out\Curva de Lorenz - Apurímac.png", replace
	
	*forma alternativa a nivel nacional 
	gen year2 =. 
	replace year2 =year if year ==2010
	replace year2=year if year ==2019 
	replace year2=year if year ==2020
	replace year2=year if year ==2021

lorenz estimate ypc, over(year2) graph(aspectratio(1)) 
lorenz graph, overlay aspectratio(1) xlabel(, grid)

	*nos quedamos con los ingresos solo de Apurímac y optenemos lo mismo para la región

****---INDICADORES CARDINALES DE DESIGUALDAD: COEFICIENTE DE GINI, ATKINSON - INDICES DE PALMA THEIL Y KOLM---****  
	*instalación de paquetes manualmente 1. STB-23 > sg30 y 2. SJ-16-4 > st0457 

	*Nuvel nacional 
forvalues i = 2004/2021 {
	inequal ypc if year==`i' [fw = facfw]
} 

forvalues i = 2004/2021 {
	relsgini ypc if year==`i' [fw = facfw], delta(1.5)
} 

forvalues i = 2004/2021 {
	atkinson ypc [fw = facfw] if year==`i', epsilon(1.5)
} 


	*Nivel Apurímac

forvalues i = 2004/2021 {
	inequal ypc [fw = facfw] if year==`i' & departamento == 3  
}

forvalues i = 2004/2021 {
	relsgini ypc [fw = facfw] if year==`i' & departamento == 3 , delta(1.5)
} 

forvalues i = 2004/2021 {
	atkinson ypc [fw = facfw] if year==`i' & departamento == 3 , epsilon(1.5)
} 
 
