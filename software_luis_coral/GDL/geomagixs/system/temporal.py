import numpy 
import os 
from datetime import datetime 


import geomagixs_commons
'''
INPUT FILES:
      GMSYYYYMMDDrmin.min     [original geomagnetic service data files]

OUTPUT FILES:
       GMS_YYYYMMDD.dat        [mangetic service data to use in SCIESMEX analysis]

'''

# @geomagixs_commons es un archivo que guarda variables, luego lo analizamos
def geomagixs_quietdays_download(initial=None, final=None, STATION=None, QUIET=None,FORCE_ALL=None):

    try:
        geomagixs_setup_commons(QUIET=QUIET)
        geomagixs_check_system(QUIET=QUIET)
        geomagixs_setup_dates(STATION=STATION, QUIET=QUIET)

        #directorios

        if initial is None :
            initial =   datetime.now().time()
        
        if final is None:
            final = initial    
    except:

        return 

def geomagixs_check_dates(initial=None, final=None, **kwargs):
    try:

        one_date = kwargs.get("one_date",None)
        station = kwargs.get("station",None)
        quiet = kwargs.get("quiet",None)
        #----------------------------------------------
        n_params=0

        if one_date is not None:n_params =+1
        if station is not None:n_params =+1
        if quiet is not None:n_params =+1
        if initial is not None:n_params =+1
        if final is not None:n_params =+1
 
        #-------------------------------------------
        
        geomagixs_setup_commons(quiet)
        geomagixs_check_gms (station,quiet)

        if ((initial is None ) and (final is None)):

            if quiet is None:
                raise ValueError("Error crítico: Hay conflicto con la entrada de dato(s) o datos invalos e inconsistentes.\
                                 Es imposible de continuar sin una entrada de datos. ")

            
                return 
            
        if n_params>2:
            if quiet is None:
                raise ValueError("Error crítico: Hay conflicto con la entrada de dato(s) o datos invalos e inconsistentes.\
                                 Es imposible de continuar sin una entrada de datos. ")
              
                return
        
        if (final is None) and (one_date is None):
            
            if (quiet is None):
                raise ValueError("Error crítico: Hay conflicto con la entrada de dato(s) o datos invalos e inconsistentes.\
                                 Es imposible de continuar sin una entrada de datos. ")

        if ((n_params==3) and (one_date is None)):

            if ((initial is None) and (final is None)):
                if (quiet is None):
                    raise ValueError("Error crítico: Hay conflicto con la entrada de dato(s) o datos invalos e inconsistentes.\
                                        Las fechas deberían ser correctas. ")
                
                return 
            #Aqui existe verificaciones de fecha, que no sea más del rango 12, pero el modulo
            # datatime de python ya verifica esto de forma automatica, asi que no es necesario.    
        
        initial_n_days  =   julday(datetime(initial.month+1,0,initial.year))-julday(datetime(initial.month,0,initial.year))                   
        final_n_days  =   julday(datetime(final.month+1,0,initial.year))-julday(datetime(final.month,0,initial.year))                   

        if (initial.day)< 1 or (initial.day!=initial_n_days) or (final.day <1) or (final.day != final_n_days):
                    raise ValueError("Error crítico: Hay conflicto con la entrada de dato(s) o datos invalos e inconsistentes.\
                                        La entrada de dias debe de estar en el rango de 1<=DD<=31. ")

                    return 

        initial_JUL = julday(initial)
        final_JUL   = julday(final)

        if final_JUL < initial_JUL:

            if (quiet is None):
                raise ValueError("Error crítico: Hay conflicto con la entrada de dato(s) o datos invalos e inconsistentes.\
                    La fecha final debe ser despuesen tiempo o igual a la fecha inicial.")

                return 
        #revisar
        geomagixs_setup_dates(station,quiet, force_all)

        lower_JUL
        

    except:

        print("Ocurrió un error desconocido.")
        return



def julday(date):
    #date es propiedad de datetime

    julday = date.toordinal() - datetime(1582, 10, 15).toordinal() + 2299161

    return julday