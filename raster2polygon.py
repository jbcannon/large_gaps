# Created by: Jeff Cannon/Ben Gannon
# Created on: 07/26/2017
# Last Updated: 07/26/2017

'''
The purpose of this script is to convert a raster input file
into a polygon using ArcGIS
'''

#-> Import modules
import arcpy, os, sys, traceback, shutil
from arcpy.sa import *

# Check out spatial analyst extension
arcpy.CheckOutExtension('spatial')

#-> Create workspace
#plist = sys.argv[1].split("\\")                     # Grab script folder pathname
#print(plist)
#path = "\\".join(plist[0:(len(plist)-1)])
#path = r'C:\Users\temp\MTBS_firewindow'

path=sys.argv[1]
print(path)
arcpy.env.workspace = path + r'\DATA'
arcpy.env.scratchWorkspace = path + r'\DATA\INTERMEDIATE\SCRATCH'
print(arcpy.env.workspace)

#-> Create variables

# Input
tmp_raster_asc = arcpy.env.workspace + r'\INPUT\tmp_raster.asc'

# Output
tmp_poly_fc = r'\OUTPUT\tmp_poly.shp'

###---> Main body of analysis

#-> Convert float input into integer raster
try:
    raster_int = Int(tmp_raster_asc)
    print('Converted float input into integer ')
except Exception as err:
    print(err.args[0])

# Process: Raster to Polygon
try:
    if arcpy.Exists(tmp_poly_fc):
        arcpy.Delete_management(tmp_poly_fc)
    arcpy.RasterToPolygon_conversion(raster_int, tmp_poly_fc, "SIMPLIFY", "VALUE")
    print('Converted raster to polygon')
except Exception as err:
    print(err.args[0])

###---> Clean up the scratch workspace (WARNING: not sure how Kosher this is)

# Set the workspace to the SCRATCH folder so you can grab the rasters
arcpy.env.workspace = arcpy.env.scratchWorkspace
rasters = arcpy.ListRasters('*','ALL')

# Delete all the rasters [in arcpy] to release the locks on them
try:
    for raster in rasters:
        arcpy.Delete_management(raster)
except Exception as err:
    print(err.args[0])
    
# Delete all the remaining files and subfolders
folder = arcpy.env.scratchWorkspace
for the_file in os.listdir(folder):
    file_path = os.path.join(folder,the_file)
    try:
        if os.path.isfile(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path)
    except Exception as e:
        del(e)
print
print('Exclusion polygon created')
'''

#-> Run R script as subprocess
command = 'Rscript'
path2script = path + r'\OWNERSHIP_subscript.R'
arg1 = path.replace('\\','/')
try:
    print('###---> Sent data to R script')
    x = subprocess.check_output([command,path2script,arg1])
    print(x)
    print('Successfully ran R Summary script')
    print
except:
    print('Failed to run R script')

'''
