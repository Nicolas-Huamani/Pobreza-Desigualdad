global desi_pob "C:\Users\51937\Documents\Git\desigualdad_pobreza"
global per_apu "$desi_pob\Perú_Apurímac"
global graph "$per_apu\graph"
global enaho "C:\Users\51937\Documents\ENAHO"
cd "$enaho"

*1, 2: Limpiza de data 
use "sumaria-2004", clear

sum linpe

gen facpob = factor07*mieperho		
sum linpe [iw=round(facpob)]

forvalues i = 2004/2021 {
use sumaria-`i', clear
gen year = `i'
save sumaria-`i'_new, replace
}

use "sumaria-2004_new", clear
forvalues i = 2005/2021 {
append using sumaria-`i'_new
}

gen facpob = factor07*mieperho

*tabla de linea de pobreza y pobreza extrema 2004-2019
table year [iw =round(facpob)], c(m linea m linpe) 

gen pobre = (pobreza < 3)
gen pobre1 = pobre*100
*tasa de pobreza 
table year, c(mean pobre1)
table year [iw=round(facpob)], c(mean pobre1)


*generando el ingreso y gasto percapita
gen ypc = inghog2d/(12*mieperho)
gen gpc = gashog2d/(12*mieperho)

*generamos indicador de zona
recode estrato (1/5 =1 "urbano") (6/8 =2 "rural"), gen(area)

*generando departamento
gen departamento= substr(ubigeo,1,2)
destring departamento, replace
*asignando etiquetas de valor 
label define dpto 1 "Amazonas" 2 "Ancash" 3 "Apurimac" ///
 4 "Arequipa" 5 "Ayacucho" 6 "Cajamarca" 7 "Callao" 8 ///
 "Cusco" 9 "Huancavelica" 10 "Huánuco" 11 "Ica" 12 "Junín" ///
 13 "La Libertad" 14 "Lambayeque" 15 "Lima" 16 "Loreto" 17 ///
 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura" ///
 21 "Puno" 22 "San Martín" 23 "Tacna" 24 "Tumbes" 25 "Ucayali"
label value departamento dpto
ta departamento

gen apurimac = (departamento == 3)
label define apu 1 "Apurimac" 0 "Nacional"
label val apurimac apu
*revisión de consistencia 
sort year
bys year: count if missing(ypc)
bys year: count if ypc < 0
bys year: count if ypc == 0  //hay 
bys year: count if 0> ypc  & ypc <1

*opción 1: asignar valores missing a las personas que consignan 0 ingresos (problema de sesgo de selección)
*opción 2: eliminar valores (problema de truncamiento) 

*base 2004 - 2021 
save "$per_apu\sumaria-04-21", replace

*resumen estadístico 
g facpob07 = mieperho*factor07 
g facfw = round(facpob07)
sum ypc [fw = facfw] if year == 2021, detail

*3. 

gen year2012 = year 
replace year2012 = . if year > 2012
gen year2021 = year 
replace year2021 =. if year < 2013

*histogramas 
histogram ypc [fw = facfw] if year == 2010 |year == 2019 | year == 2020 | year == 2021,by(year) kdensity frac ///
	name(g0, replace) 
graph export "$graph\g0.png", replace

histogram ypc [fw = facfw] if departamento == 3 & (year == 2010 |year == 2019 | year == 2020 | year == 2021),by(year) kdensity frac ///
	name(g00, replace) 
graph export "$graph\g00.png", replace
	
*análisis por deciles 	
forvalues i = 2004/2021 { 
pshare estimate ypc  [fw = facfw] if year == `i', nquantiles(10)
}
		
forvalues i = 2004/2021 { 
pshare estimate ypc  [fw = facfw] if year == `i' & departamento ==3 , nquantiles(10)
}

*boxplots comparativos 
graph box ypc [fw = facfw], by(apurimac, note("") title("Comparativo de la distribución de los ingresos per capita mensuales: 2004-2021", size(medium))) over(year) asyvars legend(pos(6) row(2)) ///
	note(" ")  name(g1, replace) 
graph export "$graph\g1.png", replace	
graph box ypc [fw = facfw], by(apurimac, note("") title("Comparativo de la distribución de los ingresos per cápita mensuales (sin outliers): 2004-2021", size(medsmall))) over(year) asyvars noout legend(pos(6) row(2)) ///
	note(" ") name(g2, replace) 
graph export "$graph\g2.png", replace	
//GRAFICAR LA ESTIMACIÓN DE EVOLUCIÓN CON LA DENSIDAD DE KERNEL 

*4. 
*captando coordenadas de las curvas de lorenz 2004-2021 
glcurve ypc [aw = facpob07], lorenz glvar(y_ord) pvar(rank) by(year) split nograph replace //guardando coordenadas
gen recta_45° = rank 
quietly: save "$graph\base_ingresos_lorenz.dta", replace

*generando el gráfico de la curva de lorenz 
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
graph export "$graph\g3.png", replace

*para Apurimac: 
glcurve ypc [aw = facpob07] if departamento==3, lorenz glvar(y_ord_apu) pvar(rank_apu) by(year) split nograph replace //guardando coordenadas
*gen recta_45° = rank_apu 
quietly: save "$graph\base_ingresos_lorenz_apu.dta", replace

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
graph export "$graph\g4.png", replace
*curva de lorenz generalizada 

*5. COEFICIENTE DE GINI, ATKINSON - INDICES DE PALMA THEIL Y KOLM. 
*instalación de paquetes manualmente 1. STB-23 > sg30 y 2. SJ-16-4 > st0457 
*nacional 
forvalues i = 2004/2021 {
	inequal ypc if year==`i' [fw = facfw]
} 

forvalues i = 2004/2021 {
	relsgini ypc if year==`i' [fw = facfw], delta(1.5)
} 

forvalues i = 2004/2021 {
	atkinson ypc [fw = facfw] if year==`i', epsilon(1.5)
} 


*apurimac 

forvalues i = 2004/2021 {
	inequal ypc [fw = facfw] if year==`i' & departamento == 3  
}

forvalues i = 2004/2021 {
	relsgini ypc [fw = facfw] if year==`i' & departamento == 3 , delta(1.5)
} 

forvalues i = 2004/2021 {
	atkinson ypc [fw = facfw] if year==`i' & departamento == 3 , epsilon(1.5)
} 
 


