import os
import numpy 
import subprocess
import re

from datetime import datetime


months = ['jan','feb','mar','apr','may','jun','jul','aug','sep',\
                      'sep','oct','nov','dec']

def check_dates (initial=None, final=None, **kwargs):
    # script geomagixs_check_dates.pro
    verbose = kwargs.get('verbose',True)
    gms = kwargs.get('GMS',None)
    system = kwargs.get('system',None)

    if gms is None:
        raise AttributeError ("El método check_dates necesita el parámetro gms.")
    try:

        if initial is None:
            if final is None:
                if verbose:
                    raise ValueError("Conflicto con entrada de datos. La data es inconsistente o invalida. Imposible\
                            de proceder sin un dato de rangos validos")
                    
                return 
            else: 
                if not isinstance(initial,datetime):
                    raise TypeError("El valor inicial de fecha debe ser un objeto datetime")
                if not isinstance(final,datetime):
                    raise TypeError("El valor final de fecha debe ser un objeto datetime.")

                if final<initial:
                    raise ValueError("Ingrese un rango de fechas correcto. La fecha inicial es menor a la final")


        if final is None:
            final= initial
        

        #verificacion con juldays
        # no entiendo porque se complica tanto con juldays

        initial_JUL = JULDAY(initial)
        final_JUL = JULDAY(final)

        if initial_JUL < final_JUL:

            raise ValueError("Entrada de datos invalido, verifique el rango de fechas introducidas.")

        #verificamos con la fecha minima que se debe considerar en el sistema

        lower_JUL = JULDAY(gms[system['gms']][0])
        upper_JUL = JULDAY(gms[system['gms']][1])

        if initial_JUL < lower_JUL :

            raise ValueError("El valor de fecha de inicio debería ser mayor a {}.".format(gms[system['gms']][0]))

        if final_JUL > upper_JUL:
            raise ValueError ("El valor de fecha fin debe ser mayor a la fecha {}.".format(gms[system['gms']][1]))

        return     
                
                    
    except:
        print("Ocurrió un error ")



def vectorize(dict_,key):
    #return a array with all values that belong key from dict 
    return numpy.array([data[key] for data in dict_ ])


def space(number):
    return ' '*number
def execute_command(chain):
    
    
    
    # Aplicacion que permite ejecutar comandos de acuerdo a la terminal 
    #
    result = subprocess.run(chain, shell=True, capture_output=True, text=True)

    # Obtener los resultados y errores
    # tmp_results = result.stdout
    # tmp_errors = result.stderr
    
    return result
 

def JULDAY(datetime):
    
    a = (14 - datetime.month) // 12
    y = datetime.year + 4800 - a
    m = datetime.month + 12 * a - 3
    jdn = datetime.day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045
    
    
    return jdn

def CALDAT(juldays):
    
    jd = juldays
    """
    Calendar date (month, day, year) from julian date, inverse of 'julday()'
    Return value:  month, day, and year in the Gregorian calendar.

    Adapted from "Numerical Recipes in C', 2nd edition, pp. 11

    Works only for years past 1582!

    Parameters
    ----------
    jd : numpy.ndarray or float64
        Julian day.

    Returns
    -------
    month : numpy.ndarray or int32
        Month.
    day : numpy.ndarray or int32
        Day.
    year : numpy.ndarray or int32
        Year.
    """
    jn = numpy.int32(((numpy.array(jd) + 0.000001).round()))

    jalpha = numpy.int32(((jn - 1867216) - 0.25) / 36524.25)
    ja = jn + 1 + jalpha - (numpy.int32(0.25 * jalpha))
    jb = ja + 1524
    jc = numpy.int32(6680.0 + ((jb - 2439870.0) - 122.1) / 365.25)
    jd2 = numpy.int32(365.0 * jc + (0.25 * jc))
    je = numpy.int32((jb - jd2) / 30.6001)

    day = jb - jd2 - numpy.int32(30.6001 * je)
    month = je - 1
    month = (month - 1) % 12 + 1
    year = jc - 4715
    year = year - (month > 2)

    
    return datetime(year,month,day)


def make_IAGAformat(**kwargs):
    
    data = kwargs.get('data',None)
    data_optional = kwargs.get('data_optional',None)
    
    if data is None:
        AttributeError("Debe insertar un archivo de datos para la creación de\
                        un archivo IAGA 2002.")
        
    keys = data.keys()
    
    keys_format = ['format','source','station','IAGA_CODE','geodetic_latitude',\
                    'geodetic_longitude','elevation','reported','sensor_orientation',\
                    'digital_sampling','data_interval_type','data_type']
    
    key_name = ['FORMAT','Source of Data','']
    for key in keys:
        pass
    return 
        
        
def file_search(filename, directory):
 
    for root, dirs, files in os.walk(directory):
        if filename in files:
            return os.path.join(root, filename)        
