packages <- c('rgdal', 'raster', 'rgeos')
for(package in packages){
  if(suppressMessages(!require(package,character.only=T))){
    install.packages(package,repos='https://cran.mtu.edu/')
    suppressMessages(library(package,character.only=T))
  }
}

# gap delineation parameters

#radius (m) for circular moving window analysis
dist_threshold = 12 

#percent canopy cutoff for defining gap (as a proportion, 0 to 1)
cutoff = 0.05 

# default projection
proj = "+proj=utm +zone=13 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"

# Classified raster (1= opening, 2 = canopy)
ras_path = 'sample_raster.tif'

# area of interest boundary (shapefile)
shp_path = 'sample_boundary/LJ_trt.shp'


# FUnction to generate large gaps from raster
#########################
large.gaps <- function(img, bnd, radius, cutoff, resolution = res(img)[1], extended.gap = TRUE){
  w = focalWeight(img, d = radius, type = 'circle')
  w[w>0]=1
  foc <- focal(img, w = w, fun = mean, na.rm = TRUE) #calculate cover in moving window
  rcl <- matrix(c(0, cutoff, cutoff, 1, 1, 0), ncol = 3, byrow = FALSE) #create matrix with canopy cover classification bins
  gaps <- reclassify(foc, rcl = rcl, include.lowest = TRUE) #reclassify raster using matrix above
  gaps[gaps == 0] <- NA #remove non- large gap areas
  gaps[is.na(gaps) == FALSE] <- 1 #set gap areas to 1
  gaps <- mask(gaps, gBuffer(bnd)) #clip gap raster to boundary less buffer area
  gaps <- rasterToPolygons(gaps, n = 4, dissolve = TRUE)
  if(length(gaps)>0){
    if(extended.gap == TRUE){ #buffers gaps by radius
      gap.ext <- gBuffer(gaps, width = radius, byid = TRUE)
      gaps <- gap.ext
    }
    gaps = spTransform(gaps, CRS(proj4string(bnd)))
    gaps <- intersect(gaps, gBuffer(bnd, width = -radius))
    if(length(gaps)> 0) {
      gaps <- gUnaryUnion(gaps)
      gaps <- disaggregate(gaps)
      gaps <- SpatialPolygonsDataFrame(gaps, data = data.frame(ID = 1:length(gaps)))  
      return(gaps)
    } else return(NULL)
  } else return(NULL)
}


# Load and plot imagery and boundaries
bnd = readOGR(shp_path)
img = raster(ras_path)
bnd = spTransform(bnd, proj4string(img))
img = mask(crop(img,bnd), bnd)
gaps = large.gaps(img, bnd = bnd, radius = dist_threshold, cutoff = cutoff)

plot(img, col = c('cornsilk', 'chartreuse4'))
plot(bnd, add = TRUE, lwd=2)
plot(gaps, add = TRUE, col = '#FF00FF80', border = NA)
    
writeOGR(gaps, 'gap_output', getwd(), layer = 'gap_output', driver='ESRI Shapefile', overwrite_layer = TRUE)
