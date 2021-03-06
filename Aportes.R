#****************************************************************************************************************
#*****************************    ESTADÍSTICA ESPACIAL - KRIGING UNIVERSAL     **********************************
#****************************************************************************************************************
source("fun.R")
options(scipen=999)

# 0. Cargue de librerías ####
#*********************************************
load.lib("dplyr", "scales", "tidyr", "plotly", "rgeos", "sp", "maptools", "car", "geoR", 
         "gstat", "stringr", "reshape2")
load.lib("rgeos","sp","maptools","car","geoR","gstat","RColorBrewer")

# 1. Cargue información ####
#*********************************************
tipos<-c("factor", "character", "character", "character", "character", "character", "numeric",
         "numeric", "numeric", "numeric", "numeric", "numeric", "character", "character", "numeric", "numeric")

BD <- read.csv("BD.txt", sep = "\t", header = T, dec = ",", colClasses=tipos)
str(BD)

## corrige aportes
BD$Aportes <- str_replace(BD$Aportes, ",", ".")
BD$Aportes <- str_replace(BD$Aportes, "\\$ ", "")
BD$Aportes <- as.numeric(BD$Aportes)

BD_2014 <- BD %>% 
           filter( BD$AÑO == 2014 & BD$Piramide.2_Actual != "4.5 Transaccional"& 
                   BD$Piramide.2_Actual != "4.6 Transaccional - Facultativo" & 
                   BD$Piramide.2_Actual != "4.7 Transaccional - Independiente"& 
                   BD$Piramide.2_Actual != "4.8 Transaccional - Pensionado" & 
                   BD$Piramide.2_Actual != "4.9 Colsubsidio") %>%
           select(Id_Empresa, RazonSocial, Piramide.1, Piramide.2_Actual, ZONA, X, Y, Aportes, Afiliados) %>%
           group_by(Id_Empresa, RazonSocial, Piramide.1, Piramide.2_Actual, ZONA, X, Y) %>%
           summarise(Aportes_total = sum(Aportes, na.rm=T), Afiliados_max = max(Afiliados, na.rm=T))

BD_2015 <- BD %>% 
           filter( BD$AÑO == 2015 & BD$Piramide.2_Actual != "4.5 Transaccional" & 
                   BD$Piramide.2_Actual != "4.6 Transaccional - Facultativo" & 
                   BD$Piramide.2_Actual != "4.7 Transaccional - Independiente"& 
                   BD$Piramide.2_Actual != "4.8 Transaccional - Pensionado" & 
                   BD$Piramide.2_Actual != "4.9 Colsubsidio") %>% 
            select(Id_Empresa, RazonSocial, Piramide.1, Piramide.2_Actual, ZONA, X, Y, Aportes, Afiliados) %>%
            group_by(Id_Empresa, RazonSocial, Piramide.1, Piramide.2_Actual, ZONA, X, Y) %>%
            summarise(Aportes_total = sum(Aportes, na.rm=T), Afiliados_max = max(Afiliados, na.rm=T))

BD_2016 <- BD %>% 
           filter( BD$AÑO == 2016 & BD$Piramide.2_Actual != "4.5 Transaccional" & 
                   BD$Piramide.2_Actual != "4.6 Transaccional - Facultativo" & 
                   BD$Piramide.2_Actual != "4.7 Transaccional - Independiente" & 
                   BD$Piramide.2_Actual != "4.8 Transaccional - Pensionado" & 
                   BD$Piramide.2_Actual != "4.9 Colsubsidio") %>% 
           select(Id_Empresa, RazonSocial, Piramide.1, Piramide.2_Actual, ZONA, X, Y, Aportes, Afiliados) %>%
           group_by(Id_Empresa, RazonSocial, Piramide.1, Piramide.2_Actual, ZONA, X, Y) %>%
           summarise(Aportes_total = sum(Aportes, na.rm=T), Afiliados_max = max(Afiliados, na.rm=T))

BD_2017 <- BD %>% 
           filter( BD$AÑO == 2017 & BD$Piramide.2_Actual != "4.5 Transaccional" & 
                   BD$Piramide.2_Actual != "4.6 Transaccional - Facultativo" & 
                   BD$Piramide.2_Actual != "4.7 Transaccional - Independiente" & 
                   BD$Piramide.2_Actual != "4.8 Transaccional - Pensionado" & 
                   BD$Piramide.2_Actual != "4.9 Colsubsidio" &
                   BD$Piramide.2_Actual !=  "4.3 Trans.Juridica Ent. 11 a 99 Trab." &
                   BD$Piramide.2_Actual != "4.4 Trans.Natural Ent. 11 a 99 Trab.") %>% 
           select(Id_Empresa, RazonSocial, Piramide.1, Piramide.2_Actual, ZONA, X, Y, Aportes, Afiliados) %>%
           group_by(Id_Empresa, RazonSocial, Piramide.1, Piramide.2_Actual, ZONA, X, Y) %>%
           summarise(Aportes_total = sum(Aportes, na.rm=T), Afiliados_max = max(Afiliados, na.rm=T)) %>% 
           filter(ZONA == "ZONA CENTRO" | ZONA == "ZONA NORTE" | ZONA == "ZONA CHAPINERO" | ZONA == "ZONA SUR") %>%
           filter(Aportes_total > 0)



BD_2017$Y <- ifelse(BD_2017$Y>1000000, 4.7316250, BD_2017$Y)

## 1.1. Exploración datos ####
#*********************************************

hist(BD_2017$Aportes_total) #Distribución no simétrica, sesgada hacia la derecha

summary(BD_2017$Aportes_total) # media mayor a la mediana (sesgada hacia la derecha, distribución no-normal)

#Al ser una distribución no simétrica, se aplica logaritmo para transformar
#los valores y obtener una distribución simetrica (normal). 
#Esto, además, reduce los posibles outliers.

BD_2017$Aportes_log <- log10(BD_2017$Aportes_total)
BD_2017$Aportes_log <- ifelse(BD_2017$Aportes_total<=0,0,BD_2017$Aportes_log)
hist(BD_2017$Aportes_log, breaks = 16)

summary(BD_2017$Aportes_total) # No se observa un sesgo tan alto y la distribución es más uniforme

## 1.2. Estructura espacial ####
#********************************************

datos <- data.frame(BD_2017$X, BD_2017$Y, BD_2017$Aportes_log, BD_2017$Aportes_total)
head(datos)
colnames(datos)

#Crear Spatial Data Frame
coordinates(datos) <- c("BD_2017.X", "BD_2017.Y")
class(datos)

str(datos)

plot(datos, asp = 1, pch = 1)
plot(bogota)
points(datos)

plot(bogota)
points(datos, asp = 1, cex = 4 * datos$BD_2017.Aportes_total/max(datos$BD_2017.Aportes_total),pch = 1) 


# 2. Mapas ####
#*********************************************
bogota = readShapePoly("./localidades/localidades_WGS84.shp")
xy = SpatialPoints(BD_2017[c("X", "Y")])	# Puntos Empresas

#	3. Análisis gráfio
#*********************************************

par(mfrow=c(1,1))
plot(bogota)
points(xy, pch = 3, cex = 0.3, col = "red")

library(leaflet)
map <- leaflet(data=BD_2017) %>%
  addTiles() %>% 
  addCircleMarkers(lng =~X, lat =~Y, popup="The birthplace of R")

map

#Análisis descriptivo para los aportes
par(mfrow = c(1, 3))
hist(BD_2017$Aportes_log, freq = FALSE, main = "", xlab = "Aportes", ylab = "Frecuencia")
curve(dnorm(x, mean(BD_2017$Aportes_log), sd(BD_2017$Aportes_log)), add = T)
boxplot(BD_2017$Aportes_log)
qqPlot(BD_2017$Aportes_log, ylab = "Aportes")
title(main=list("Gráficos descriptivos para los aportes", cex=2,col="black", font=3), outer=T,line=-2)
par(mfrow=c(1,1))

limites <- c(min(BD_2017$Aportes_total), quantile(BD_2017$Aportes_total, probs = c(0.2, 0.4, 0.6, 0.8),type = 5), max(BD_2017$Aportes_total))
limites


BD_2017$D_Aportes_75 <- ifelse(BD_2017$Aportes_total > quantile(BD_2017$Aportes_total, probs=0.75) &
                                 BD_2017$Aportes_total <= quantile(BD_2017$Aportes_total, probs=0.9), 1, 0)
BD_2017$D_Aportes_90 <- ifelse(BD_2017$Aportes_total > quantile(BD_2017$Aportes_total, probs=0.90) &
                                 BD_2017$Aportes_total <= quantile(BD_2017$Aportes_total, probs=0.99), 1, 0)
BD_2017$D_Aportes_99 <- ifelse(BD_2017$Aportes_total > quantile(BD_2017$Aportes_total, probs=0.99), 1, 0)

head(BD_2017)

# BD_2017sp <- BD_2017
# coordinates(BD_2017sp) = ~X+Y
# spplot(BD_2017sp, "Aportes", cuts = limites)


## 3.1 Interpolación áreas - prueba ####
#******************************************************************

datos=data.frame(BD_2017$X, BD_2017$Y, BD_2017$Aportes_total)
geo = as.geodata(datos, coords.col = 1:2, data.col = 3)

matriz = matrix(c(BD_2017$X,BD_2017$Y),ncol=2)
sp2 = SpatialPoints(matriz)

#Georeferenciacion de los puntos de ubicaci?n
plot(sp2)
#Generación de las coordenadas donde se va a interpolar
muestra = spsample(sp2,n=100000, type="regular")
#plot(muestra)

#KC1 <- krige.control(cov.model="spherical",type="OK",cov.pars=c(23,846),nugget=0)
#resultado <- krige.conv(geo,locations = data.frame(muestra),krige=KC1)

#Grafico de la interpolacion
#image(resultado, main="Estimaciones por kriging",col=brewer.pal(9, "Blues"),axes=T,xlab="",ylab="")
#contour(resultado,add=T)

## Varianza de predicción, valores rojos son varianzas mas pequeñas que las amarillas
#image(resultado, val=sqrt(resultado$krige.var),axes =FALSE,xlab="",ylab="")


# 4. Aportes Bogotá D.C. - Geoestaditica ####
#*******************************************************************

## 4.1. Graficas descriptivas ####
#*******************************************************************

#Gráfico de la capa y las ubicaciones de las empresas
plot(bogota)
points(xy, pch = 3, cex = 0.3, col = "red")
title(main="Empresas Aportes Bogota")

#Análisis descriptivo para los aportes
par(mfrow = c(1, 3))
hist(BD_2017$Aportes_log, freq = FALSE, main = "", xlab = "Aportes", ylab = "Frecuencia")
curve(dnorm(x, mean(BD_2017$Aportes_log), sd(BD_2017$Aportes_log)), add = T)
boxplot(BD_2017$Aportes_log)
qqPlot(BD_2017$Aportes_log, ylab = "Aportes")
title(main=list("Gráficos descriptivos para los Aportes", cex=2,col="black", font=3), outer=T,line=-2)
par(mfrow = c(1, 1))
# Como hay atipico, podría usarse una transformación box cox para reducir su efecto en los resultados y análisis

# el gráfico para determinar estacionariedad. Aquí NO Estacionaria porque los punticos no están formados aleatoriamente
datossp <- BD_2017[,c("X","Y","Aportes_total","Aportes_log")]
coordinates(datossp) = ~X+Y
spplot(datossp, "Aportes_total", cuts = limites)
#Existe dependencia espacial!!!! porque los puntos de valores similares "estan cerca"...
# para esto se realizan las siguientes pruebas


## 4.2. Estacionariedad ####
#************************************************************************

# Gráficos contra las direcciones
scatterplot(Aportes_log~X, reg.line=lm, smooth=TRUE, spread=TRUE, boxplots=FALSE, span=0.5, data=BD_2017)
scatterplot(Aportes_log~Y, reg.line=lm, smooth=TRUE, spread=TRUE, boxplots=FALSE, span=0.5, data=BD_2017)

head(BD_2017[,c("Aportes_total","Aportes_log")], 1000)

# Al parecer son constante pero existen varios puntos fuera

# Se realiza un modelo en términos de las direcciónes con un stepwise
modelo1 = lm(Aportes_total ~ X + Y + I(X * Y) + I(X^2) + I(Y^2), data = BD_2017)
summary(modelo1)
step(modelo1)
summary(step(modelo1))
# El resultado es que si existe dependencia porque las X y Y son significativas, es decir, no es estacionario.

# Ajuste del modelo
modelo2 = lm(Aportes_total ~ X + Y + I(X * Y) + I(Y^2), data = BD_2017)
summary(modelo2)
step(modelo2)
summary(step(modelo2))

# Gráficos sobre los residuales del modelo ajustado
par(mfrow = c(1, 3))
hist(modelo2$res, freq = FALSE, main = "", xlab = "Residuales", ylab = "Frecuencia")
curve(dnorm(x, mean(modelo2$res), sd(modelo2$res)), add = T)
boxplot(modelo2$res)
qqPlot(modelo2$res, ylab = "Precipitacion")
# Los residuales no siguen una distribución normal, pero no es necesario, solo que sean estacionarios.

# Para revisar si los residuales del modelo dependen de la dirección, 
# se ajusta un modelo de segundo orden sobre los residuales.

modelo3 <- lm(modelo2$res ~ X + Y + I(X * Y) + I(X^2) + I(Y^2), data = BD_2017)
summary(modelo3)

# Como no son significativos los X y Y, quiere decir que los residuos son estacionarios 

# Gráficos contra las direcciones para los residuales (Solo es informativo y de exploración)
scatterplot(modelo2$res ~ X, reg.line=lm, smooth=TRUE, spread=TRUE, boxplots=FALSE, span=0.5, data=BD_2017)
scatterplot(modelo2$res ~ Y, reg.line=lm, smooth=TRUE, spread=TRUE, boxplots=FALSE, span=0.5, data=BD_2017)


## 4.3. Análisis modelo semivarianza ####
#********************************************************************************

# Ahora, se construye el semivariograma sobre los residuales del modelo ajustado
datos2 <- data.frame(x = BD_2017$X, y = BD_2017$Y, res=modelo2$res)
head(datos2)

# Creando objeto de tipo geodata para el calculo del semivariograma
geo <- as.geodata(datos2, coords.col = 1:2, data.col = 3)

# variog para estimar semivariograma
var <- variog(geo, max.dist = max(BD_2017$Aportes_total),direction = "omnidirectional")
par(mfrow=c(1,1))
plot(var)
head(var)

# Ajuste de modelos al semivariograma
# Se puede con varios ajustes
ev <- eyefit(var)
ev

mod1 <- variofit(var,ini=ev,weights="equal")
mod1

# Minimos cuadrados ponderados
mod2 <- variofit(var,ini=ev,weights="npairs")
mod2

# Minimos cuadrados ponderados
mod3 <- variofit(var,ini=ev,weights="cressie")
mod3

# Graficas
plot(var)
lines(mod1, max.dist = 125000, col = 1)
lines(mod2, max.dist = 125000, col = 2)
lines(mod3, max.dist = 125000, col = 3)
legend("bottomright",legend = c("MCO", "MCP - npairs", "MCP - cressie"),
       col = 1:5, lwd = 2, inset = .03)


## 4.4. Validación Cruzada ####
#***************************************************************************

# Validación cruzada sobre los residuales

#cruzada1=xvalid(geo,model=mod1,reestimate = F)
#cruzada2=xvalid(geo,model=mod2,reestimate = F)
#cruzada3=xvalid(geo,model=mod3,reestimate = F)

#sqrt(mean(cruzada1$error^2))
#sqrt(mean(cruzada2$error^2))
#sqrt(mean(cruzada3$error^2))

# Aqui arriba se está haciendo validación cruzada sobre los residuales
# Lo ideal es hacer validación cruzada para la precipitación directamente
# Para hacer esto es conveniente cambiar de paquete, de geoR a gstat
# Se crea un objeto de tipo gstat para utilizarlo en el kriging

# Como todos los modelos de la varianza dan muy parecidos se deja solo uno

mod1_1 <- as.vgm.variomodel(mod1)
class(mod1)
class(mod1_1)

kr <- krige.cv(Aportes_total ~ X+Y+I(X*Y)+I(Y^2) , datossp, mod1_1, maxdist = 100)
head(kr)
mape <- mean(abs(kr$residual)/kr$observed)
mape
head(datossp)
class(datossp)

# 5. Modelo Kriging Universal ####
#****************************************************************************

# Grafica de poligonos de Bogotá D.C.
poligonos <- polygons(bogota)
# Muestra de los pologonos
muestra <- spsample(poligonos, n = 10000, "regular")
# Paso a data frame
muestra1 <- data.frame(muestra)
names(muestra1) = c("X", "Y")
gridded(muestra1) = c("X", "Y")
plot(muestra)
# Para cuadricular la muestra generada! porque se ha generado de forma regular

#kriging universal sobre los aportes.
krig_u <- krige(formula = Aportes_total ~ X+Y+I(X*Y)+I(Y^2), datossp, muestra1, model=mod1_1)

# Mapa para los aportes
spplot(krig_u, c("var1.pred"), main = "Kriging Universal para los aportes", contour = T, 
       labels = T, pretty = TRUE, col = "black", col.regions = terrain.colors(100))

# Con algunas opciones distintas
spplot(krig_u, c("var1.pred"), main = "Kriging Universal para los aportes", contour = FALSE, 
       labels = FALSE, pretty = F, col = "black", col.regions = terrain.colors(100))
spplot(krig_u, c("var1.var"), main = "Mapa para las varianzas de predicción", contour = FALSE, 
       labels = FALSE, pretty = TRUE, col = "black", col.regions = terrain.colors(100))

#Para visualizar los puntos de las estaciones
li = list("sp.polygons", bogota)
pts = list("sp.points", datossp, pch = 3, col = "black", cex = 0.2)
spplot(krig_u, c("var1.pred"), main = "Kriging Universal para los aportes", sp.layout = list(li, pts), 
       contour = FALSE, labels = FALSE, pretty = TRUE, col = "black", col.regions = terrain.colors(100))


# 6. Modelo Kriging ordinario
#******************************************************************************

krig_ord <- krige(formula = Aportes_total ~ 1, datossp, muestra1, model=mod1_1)

#Mapa para la precipitación
spplot(krig_ord, c("var1.pred"), main = "Kriging Ordinario para los aportes", contour = FALSE, 
       labels = FALSE, pretty = TRUE, col = "black", col.regions = terrain.colors(100))
spplot(krig_ord, c("var1.var"), main = "Mapa para las varianzas de predicción", contour = FALSE, 
       labels = FALSE, pretty = TRUE, col = "black", col.regions = terrain.colors(100))

#Para visualizar los puntos de las estaciones
li = list("sp.polygons", bogota)
pts = list("sp.points", datossp, pch = 3, col = "black", cex = 0.2)
spplot(krig_ord, c("var1.pred"), main = "Kriging ordinario para la precipitación", sp.layout = list(li, pts), 
       contour = FALSE, labels = FALSE, pretty = TRUE, col = "black", col.regions = terrain.colors(100))



