from class_proc import geomagixs

from datetime import datetime 

verbose = True
force_all = True
initial_date = datetime(2022,12,15)
final_date = datetime(2023,1,13)
real_time = True
station = 'hua'


kwargs = {
           'verbose'        :verbose,
           'force_all'      :force_all,
           'initial_date'   :initial_date,
           'final_date'     :final_date,
           'real_time'      :real_time,
           'station'        :station}

if __name__ == "__main__":

    obj = geomagixs(**kwargs)
