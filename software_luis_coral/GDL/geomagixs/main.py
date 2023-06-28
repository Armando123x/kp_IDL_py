from class_proc import geomagixs

from datetime import datetime 

verbose = True
force_all = False
initial_date = datetime(2022,10,1)
final_date = datetime(2022,12,1)
real_time = False
station = 'huancayo'


kwargs = { 'verbose':verbose,
           'force_all':force_all,
           'initial_date':initial_date,
           'final_date':final_date,
           'real_time':real_time,
           'station':station}

if __name__ == "__main__":

    obj = geomagixs(**kwargs)
