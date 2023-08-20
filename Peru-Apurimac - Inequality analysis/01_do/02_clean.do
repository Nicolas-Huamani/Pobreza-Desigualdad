********************************************************************************
** 	TITLE: 02_clean.do
**
**	PURPOSE: Generate data 2004-2021 with necessary variables
**				
**	AUTHOR: Nicolás Huamaní (nhuamanivelazque@gmail.com)
******************************************************************************** 
clear all
cls

forvalues i = 2004/2021 {
use "$raw\sumaria-`i'", clear
gen year = `i'
save "$raw\sumaria-`i'_raw", replace
}

use "$raw\sumaria-2004_raw", clear

forvalues i = 2005/2021 {
append using "$raw\sumaria-`i'_raw"
}

gen facpob = factor07*mieperho

*tabla de linea de pobreza y pobreza extrema 2004-2019
table year [iw =round(facpob)], c(m linea m linpe) 

gen pobre = (pobreza < 3)
gen pobre1 = pobre*100

*tasa de pobreza 
table year, c(mean pobre1)
table year [iw=round(facpob)], c(mean pobre1)


*generando el ingreso y gasto percapita mensual por persona del hogar
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

*generando variable apurimac (dummy)
gen apurimac = (departamento == 3)
label define apu 1 "Apurimac" 0 "Nacional"
label val apurimac apu

*revisión de consistencia: Identificar ingresos < 1
sort year
bys year: count if missing(ypc)
bys year: count if ypc < 0
bys year: count if ypc == 0  //hay 
bys year: count if 0> ypc  & ypc <1

*posibles soluciones: 
	*opción 1: asignar valores missing a las personas que consignan 0 ingresos (problema de sesgo de selección)
	*opción 2: eliminar valores (problema de truncamiento) 

*base 2004 - 2021 
save "$clean\sumaria-04-21", replace
