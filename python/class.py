#geomagixs_setup_commons.pro

'''
Algunas funciones astronomicas de IDL en python
-----------------------------------------------
https://github.com/sczesla/PyAstronomy/blob/master/src/pyasl/asl/astroTimeLegacy.py

Puedes revisar el formato IAGA-2002 para el compartimiento de archivos
----------------------------------------------------------------------
https://www.ngdc.noaa.gov/IAGA/vdat/IAGA2002/iaga2002format.html


'''
import geomagixs_commons
import numpy
import os 
import subprocess

from copy import deepcopy
from scipy.interpolate import interp1d
from scipy.signal import savgol_filter
from datetime import datetime,timedelta

import urllib.request
import re
from glob import glob

from utils import *

from dateutil.relativedelta import relativedelta
#######################################################################333
##### Parametro quiet en IDL  es practicamente verbose en Python
#####
#####
#####
########################################################################


 
    

 


def ReadCalibration(system,gms):
    #script ->ReadCalibration
 
    calibration_name=gms[system['gms']]['name']+'.calibration'

    file = file_search(system['auxiliar_dir'],calibration_name)

    if file:
        #abrimos el archivo

        with open(file,'r') as f:
            lines = f.readlines()
            for line in lines:

                if line[0] != "#":
                    line    = line.strip().split()

                    if (len(line)!=28):
                        ValueError("Se debe de verificar los archivos de calibración.")
                    
                    else:
                        return numpy.array(line,dtype=float)

    else:
        print('No se encontraron archivos de calibración.')

 
class geomagixs (object):

    Flag_setup=False
    Flag_dates=False
    Flag_error=False
    Flag_system=False
    Flag_commons=True

    '''
    Variables comunes:
    System, $
    Flag_commons, $
    Flag_setup, $ ; usada
    Flag_dates, $
    Flag_error, $
    Flag_system, $
    GMS, $
    Error, $
    Dates
    '''




    def __init__(self,**kwargs):
        #definiremos algo aqui 
        # Se define la funcion geomagixs.pro
        #falta
        try:
            #falta imprimir el tiempo 
            #
            #
            #
            #

            ################################################


            verbose= kwargs.get('verbose',False)

            initial_date = kwargs.get('initial_date',None)
            final_date = kwargs.get('final_date',False)

            ##############################################################
            keys=kwargs.keys()

            if (len(keys)<2 or (len(keys)!=3)):
                raise AttributeError("Revise que los parametros proporcionados sean lo necesario.")

            working_dir =   kwargs.get('working_dir')
            gms_stn     =   kwargs.get("gms_stn")
            real_time   =   0 

            if (len(keys)==3):
                if ('-REAL_TIME'==gms_stn.upper()):
                    real_time=1
                else:
                    return 
            #falta
            #Falta definir directorio 
            #lineas 96-99

            self.__setup__commons()
            self.__check_system()

            #falta
            #falta asegurar que datos sean string
            self.__check_gms(station=gms_stn)

            self.__setup_dates( )
                               
            self.__quietdays_download(initial=initial_date,final= final_date,verbose=verbose)
            station = self.GMS[self.system['gms']]['name']
            

            #########################################3
            self.__quietdays_download(initial_date,final_date,**kwargs)
            self.__magneticdata_download(date_initial=initial_date,date_final=final_date,verbose=verbose,station=station)
            #self.__magneticdata_prep


 
        #script -> geomagixs_quietdays_download.pro
            #falta codigo 170-173
            #falta
            #falta
        
        



        except:

            raise AttributeError("Algo salio mal en el inicio del programa.")



    def __getting_magneticdata_forcleaning(self,initial,**kwargs):

        station = kwargs.get('station',None)
        verbose = kwargs.get('verbose',False)


        initial_year = initial.year
        initial_month= initial.month
        initial_day = initial.day


        initial_hour = initial.minute
        initil_minute = initial.minute

        ###########
        filename = '{}_{:4d}{:02d}{:02d}'.format(self.GMS[self.system['GMS']]['code'],initial_year,initial_month,initial_day)
        filename = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],filename)

        exists = os.path.isfile(filename)

        if exists:
            keys = ['year','month','day','hour','minute','doy','D','F','H','Z']

            struct = dict.fromkeys(keys,0)



            with open(exists,'r') as f:

                
                resulting_data = numpy.empty(numpy.array(f.readlines(),dtype='object').shape[0],dtype='object')
                resulting_data.fill(struct)
                for n,linea in enumerate(f.readlines()):
                    valores = re.findall(r'\d+\.?\d*', linea)

                    # Convertir los valores a enteros o números de punto flotante según corresponda
                    valores = [int(v) if v.isdigit() else float(v) for v in valores]

                    for key,value in zip(resulting_data.keys(),valores):

                        resulting_data[n][key] = value
            

            return resulting_data
        else:
            return None
    

    def __fixing_datafile (self,file_date, **kwargs):

        station = kwargs.get('station',None)
        verbose = kwargs.get('verbose',None)

        initial_year = file_date.year
        initial_month = file_date.month
        initial_day = file_date.day

        tmp_julday = JULDAY(file_date)

        result = CALDAT(JULDAY(tmp_julday))
        tmp_year = result.year
        tmp_month = result.month
        tmp_day = result.day


        #############
        cabecera = 18 

        file_name = '{}{:4d}{:02d}{:02d}rK.min'.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day)

        file_name = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)

        exists = os.path.isfile(file_name)

        if not exists:
            file_name = '{}{:4d}{:02d}{:02d}rmin.min'.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day)
            file_name = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)
            exists = os.path.isfile(file_name)

        if not exists:
            if verbose:
                print("Error extrayendo datos del directorio.")
            return 
        else:
            print('Extrayendo data de {}'.format(os.path.basename(file_name)))

            with open(file_name,'r') as f:

                tmp_data = numpy.array(f.readlines(),dtype='object')
                number_of_lines = tmp_data.shape[0]
            

        minutes_in_a_day = 60*24
        hours_in_a_day = 24

        if station == 'planetary':
            final_file = numpy.empty(hours_in_a_day,dtype=float)
            j_inicio = cabecera - 1

            for i in range(hours_in_a_day) :
                
                diff = JULDAY(file_date)- JULDAY(datetime(initial_year,1,1)+relativedelta(days=-1))
                chain = '{:4d}-{:02d}-{:02d} {:02d}:{:02d}:00.000{:03d}   {:4d}     {:4d}  {:5d}    {:5d}   {:5d}     {:5d}'
                final_file [i] = chain.format(tmp_year,tmp_month,space(1),tmp_day,i,0,diff,999, 999, 999, 999, 9999, 9999)

                if exists:
                    for j in range(j_inicio,number_of_lines):
                        if (tmp_data[j][11:16]==final_file[i][11:16]):
                            string_tmp = tmp_data[j]
                            final_file[i] = string_tmp

                            j_inicio = j+1
        
        else:
            final_file = numpy.empty(minutes_in_a_day, dtype='object')

            j_inicio = cabecera -1

            for i in range(minutes_in_a_day):
                diff = JULDAY(file_date)- JULDAY(datetime(initial_year,1,1)+relativedelta(days=-1))
                chain = '{:4d}-{:02d}-{:02d} {:02d}:{:02d}:00.000{:03d}      {:7.2f} {:9.2f} {:9.2f} {:9.2f}'
                final_file[i] = chain.format(tmp_year,tmp_month,tmp_day,i//60,i mod 60 , diff,9999.00, 999999.00, 999999.00, 999999.00)

                if exists: 

                    for j in range(j_inicio,number_of_lines):
                        if (tmp_data[j][11:16]==final_file[i][11:16]):
                            final_file[i] = tmp_data[j]
                            j_inicio = j+1
        


        output_datafile = '{}_{:4d}{:02d}{:02d}.dat'.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day )

        output_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])

        exist_dir = os.path.isdir(output_path)

        if not exist_dir:
            if verbose:
                print("Error critico: Directorio del sistema perdido -> {}. Verificar el directorio.".format(output_path))
            
        output_datafile = os.path.join(output_path,output_datafile)

        with open(output_datafile,'wb') as file:
            if station == 'planetary':
                file.writelines(final_file[:hours_in_a_day])
            else:
                file.writelines(final_file[:minutes_in_a_day])

        
        if verbose:
            print("Guardando {}".format(output_datafile))


        return 


    def __cleaning_datafile(self,initial,**kwargs):
        ############################################################
        station = kwargs.get("station",None)
        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get('real_time',False)
        offset = kwargs.get('offset',None)

        ############################################################
        #numero de desviaciones standar que necesita un dato para ser 
        # considerado como invalido 
        sigma_criteria = 4
        number_of_minutes = 10 

        #######
        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day


        minutes_per_day = 24*60

        D_values = numpy.empty(minutes_per_day)
        D_values.fill(9999)

        H_values = numpy.empty(minutes_per_day)
        H_values.fill(999999)

        Z_values = numpy.empty(minutes_per_day)
        Z_values.fill(999999)

        F_values = numpy.empty(minutes_per_day)
        F_values.fill(999999)

        string_date = '{:4d}{:02d}{:02d}'.format(initial_year,initial_month,initial_day)

        data_file_name = '{}_{}.dat'.format(self.GMS[self.system['gms']]['code'],string_date)

        exist_data_file = os.path.isfile(data_file_name)

        if station == 'planetary':
            if exist_data_file:
                if verbose:
                    print("Extrayendo data de: {}.".format(os.path.basename(data_file_name)))
                fpath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],data_file_name)
                
                exists = os.path.isfile(fpath)

                if not exists:
                    if verbose:
                        RuntimeWarning("Error critico: No se puede acceder al archivo {}".format(os.path.basename(fpath)))
                    
                    return
                

                with open(fpath,'r') as file:
                    tmp_data = numpy.array(file.readlines(),dtype='object')
                    number_of_lines = tmp_data.shape[0]
                

                output_datafile = '{}_{:4d}{:02d}{:02d}.clean.dat'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)
                output_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])


                exist_dir = os.path.isdir(output_path)

                if not exist_dir:
                    if verbose:
                        print("Error critico: Imposible leer el directorio del sistema {}.Archivos o directorios perdidos o se necesitan permisos.".format(output_path))

                    return 
                
                output_datafile = os.path.join(output_path,output_datafile)

                with open(output_datafile,'wb') as file:
                    file.writelines(tmp_data[:number_of_lines])
                
                if verbose:
                    print("Guardando : {}".format(os.path.basename(output_datafile)))

                return 
            else:
                if verbose:
                    print("Datafile {} no encontrado".format(os.path.basename(data_file_name)))
                return 
        
        if exist_data_file:
            tmp_data = self.__getting_magneticdata_forcleaning(initial,station=station,verbose=verbose)
        
        else:
            if verbose:
                Warning("Inconsistencia! El archivo se encuentra perdido, las condiciones solicitadas podría comprometer los resultados calculados.\
                        Archivo {} no fue encontrado. Procediendo con valores predefinidos (gaps)".format(os.path.basename(data_file_name)))
        

        ######################################################################################3
        if exist_data_file :
            D_values  = deepcopy(vectorize(tmp_data,'D'))
            H_values  = deepcopy(vectorize(tmp_data,'H'))
            Z_values  = deepcopy(vectorize(tmp_data,'Z'))
            F_values  = deepcopy(vectorize(tmp_data,'F'))
        

        ###
        mask = H_values <= 999990
        mask = mask.astype(bool)
        no_gaps = numpy.where(mask)[0]
        no_gaps_count = numpy.count_nonzero(mask)

        ###
        number_of_gaps = numpy.count_nonzero(~mask)

        if no_gaps_count > 0 and offset.shape[0] == 3:

            if offset[0]!=0 :
                D_values[no_gaps] += offset[0]
            if offset[1]!=0:
                H_values[no_gaps] += offset[1]
            if offset[2]!=0:
                Z_values[no_gaps] += offset[2]
            if offset[1]!=0 | offset[2]!=0 :

                F_values[no_gaps] =numpy.sqrt((H_values[no_gaps])^2+(Z_values[no_gaps])^2)


        H_median_value = 0
        H_sigma_value = 0
        F_median_value =0
        F_sigma_value = 0

        elements_of_no_gaps =no_gaps_count
        boolean_flag = numpy.empty(elements_of_no_gaps)
        boolean_flag.fill(1)

        if exist_data_file is True and number_of_gaps != minutes_per_day:

            for i  in range(elements_of_no_gaps):
                if i< number_of_minutes and i+number_of_minutes < elements_of_no_gaps -1 :
                    if i!=0:
                        H_median_value = numpy.median(numpy.concatenate((H_values[no_gaps[:i-1]],H_values[no_gaps[i+1:i+1+number_of_minutes-1]])))
                        H_sigma_value = numpy.std(numpy.concatenate((H_values[no_gaps[:i-1]],H_values[no_gaps[i+1:i+1+number_of_minutes-1]]))-H_median_value)

                        F_median_value = numpy.median(numpy.concatenate((F_values[no_gaps[:i-1]],F_values[no_gaps[i+1:i+1+number_of_minutes-1]])))
                        F_sigma_value = numpy.std(numpy.concatenate((F_values[no_gaps[:i-1]],F_values[no_gaps[i+1:i+1+number_of_minutes-1]]))-F_median_value)
                    else:

                        H_median_value = numpy.median(H_values[no_gaps[i+1:i+1+number_of_minutes]])
                        H_sigma_value  = numpy.std(H_values[no_gaps[i+1:i+1+number_of_minutes]]-H_median_value)

                        F_median_value = numpy.median(F_values[no_gaps[i+1:i+1+number_of_minutes]])
                        F_sigma_value  = numpy.std(F_values[no_gaps[i+1:i+1+number_of_minutes]]-F_median_value)


                if i < number_of_minutes and i + number_of_minutes > elements_of_no_gaps -1 :
                    if i !=0 and i != elements_of_no_gaps -1 :
                        H_median_value = numpy.median(numpy.concatenate((H_values[no_gaps[:i-1]],H_values[no_gaps[i+1:elements_of_no_gaps-1]])))
                        H_sigma_value  = numpy.std(numpy.concatenate(H_values[no_gaps[0:i-1]],H_values[no_gaps[i+1:elements_of_no_gaps-1]])-H_median_value )

                        F_median_value = numpy.median(numpy.concatenate((F_values[no_gaps[:i-1]],F_values[no_gaps[i+1:elements_of_no_gaps-1]])))
                        F_sigma_value  = numpy.std(numpy.concatenate(F_values[no_gaps[0:i-1]],F_values[no_gaps[i+1:elements_of_no_gaps-1]])-F_median_value )
                    
                    if i == 0:

                        H_median_value = numpy.median(H_values[no_gaps[i+1:elements_of_no_gaps-1]])
                        H_sigma_value  = numpy.std(H_values[no_gaps[i+1:elements_of_no_gaps-1]]-H_median_value )

                        F_median_value = numpy.median(F_values[no_gaps[i+1:elements_of_no_gaps-1]])))
                        F_sigma_value  = numpy.std(F_values[no_gaps[i+1:elements_of_no_gaps-1]]-F_median_value )
                    
                    if i == elements_of_no_gaps-1:
                        H_median_value = numpy.median(H_values[no_gaps[:elements_of_no_gaps-2]])
                        H_sigma_value  = numpy.std(H_values[no_gaps[:elements_of_no_gaps-2]]-H_median_value)

                        F_median_value = numpy.median(F_values[no_gaps[:elements_of_no_gaps-2]])
                        F_median_value = numpy.median(F_values[no_gaps[:elements_of_no_gaps-2]]-F_median_value)


                if i >= number_of_minutes and i + number_of_minutes <= elements_of_no_gaps -1:
                    H_median_value = numpy.median(numpy.concatenate(H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:i+number_of_minutes]]))
                    H_sigma_value = numpy.std(numpy.concatenate(H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:i+number_of_minutes]])-H_median_value)

                    F_median_value = numpy.median(numpy.concatenate(F_values[no_gaps[i-number_of_minutes:i-1]], F_values[no_gaps[i+1:i+number_of_minutes]]))
                    F_sigma_value  = numpy.std(numpy.concatenate(F_values[no_gaps[i-number_of_minutes:i-1]], F_values[no_gaps[i+1:i+number_of_minutes]])-F_median_value)

                
                if i >= number_of_minutes and i + number_of_minutes > elements_of_no_gaps -1 :
                    if i == elements_of_no_gaps-1:
                        H_median_value = numpy.median(H_values[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]])
                        H_sigma_value  = numpy.std(H_values[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]]-H_median_value)

                        F_median_value = numpy.median(F_values[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]])
                        F_sigma_value = numpy.std(F_values[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]]-F_median_value)
                    else:
                        H_median_value = numpy.median(numpy.concatenate(H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:elements_of_no_gaps-1]]))
                        H_sigma_value  = numpy.std(numpy.concatenate(H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:elements_of_no_gaps-1]])-H_median_value)

                        F_median_value = numpy.median(numpy.concatenate(F_values[no_gaps[i-number_of_minutes:i-1]], F_values[no_gaps[i+1:elements_of_no_gaps-1]]))
                        F_sigma_value  = numpy.std(numpy.concatenate(F_values[no_gaps[i-number_of_minutes:i-1]], F_values[no_gaps[i+1:elements_of_no_gaps-1]])-F_median_value)

                    

                    ###
                if (numpy.abs(H_values[no_gaps[i]]-H_median_value)> sigma_criteria*H_sigma_value) or (numpy.abs(F_values[no_gaps[i]]-F_median_value))>sigma_criteria*F_sigma_value:
                    boolean_flag[i]=0
                

                H_median_value = 0 
                H_sigma_value = 0
                F_median_value = 0
                F_sigma_value = 0
            
            v1  = boolean_flag > 0 
            v1 = v1.astype(int)

            v2 = boolean_flag <1
            v2 = v2.astype(int)

        if elements_of_no_gaps > 1 :
            
            D_values [no_gaps] =  v1 * (D_values[no_gaps]) + (v2)*9999
            H_values [no_gaps] =  v1 * (H_values[no_gaps]) + (v2)*9999
            Z_values [no_gaps] =  v1 * (Z_values[no_gaps]) + (v2)*9999
            F_values [no_gaps] =  v1 * (F_values[no_gaps]) + (v2)*999999

        ##########################################
        cleaning_count = 0
        if no_gaps_count > 0 :
            result = numpy.abs(H_values[no_gaps]-numpy.median(H_values[no_gaps]))/numpy.median(H_values[no_gaps])
            result >= 0.005 

            cleaning_indexes = numpy.where(result)[0]
            cleaning_count = numpy.count_nonzero(cleaning_indexes)

        else:
            cleaning_count = -1 

        if cleaning_count >0 :
            D_values[cleaning_indexes] = 9999
            H_values[cleaning_indexes] = 999999
            Z_values[cleaning_indexes] = 999999
            F_values[cleaning_indexes] = 999999

        mask = H_values<999990
        mask = mask.astype(bool)
        new_no_gaps = numpy.where(mask)[0]
        new_no_gaps_count = numpy.count_nonzero(new_no_gaps)



        #############################################
        #### Tener cuidado en esta seccion
        #############################################
        mask = H_values <= 999990
        mask = mask.astype(bool)

        bad_minutes_number = numpy.count_nonzero (mask)
        bad_minutes_indexes = numpy.where(mask)[0]



        mask = H_values > 999990
        mask = mask.astype(bool)

        good_minutes_number = numpy.count_nonzero (mask)
        good_minutes_indexes = numpy.where(mask)[0]

        total_minutes = H_values.shape[0]

        criteria_up = .85
        criteria_0 = .025
        fixed_minutes = 0
        

        if (good_minutes_number > criteria_up*total_minutes) and (good_minutes_number<=total_minutes) and real_time is None:

            tmp_D = deepcopy(D_values)
            tmp_H = deepcopy(H_values)
            tmp_Z = deepcopy(Z_values)
            tmp_F = deepcopy(F_values)
            tmp_t = vectorize(tmp_data,'hour')*60 + vectorize(tmp_data,'minute')

            process_number = [1,2,3,4,6,8]

            j = 0

            while 1 :

                n_processes = process_number[j]
                delta_time = minutes_per_day//n_processes
                i=0 

                while 1: 
                    low_limit = i*delta_time
                    up_limit = (i+1)*delta_time-1 

                    ##
                    mask1 = H_values[low_limit:up_limit] >= 999990
                    mask2 = H_values[low_limit:up_limit] < 999990

                    bad_minutes_indexes = numpy.array(numpy.where(mask1)[0])
                    good_minutes_indexes = numpy.array(numpy.where(mask2)[0])

                    bad_minutes_number = numpy.count_nonzero(mask1)
                    good_minutes_number = numpy.count_nonzero(mask2)

                    if bad_minutes_number > 0 and bad_minutes_number < n_processes*criteria_0*good_minutes_number:

                        #INTERPOL(y, x, xinterp)

                        tmp= interp1d(tmp_t[low_limit+good_minutes_indexes],H_values[low_limit+good_minutes_indexes],kind='cubic')
                        tmp_H = tmp(tmp_t)
                        H_values [low_limit+bad_minutes_indexes] = tmp_H[low_limit+bad_minutes_indexes]

                        tmp= interp1d(tmp_t[low_limit+good_minutes_indexes],D_values[low_limit+good_minutes_indexes],kind='cubic')
                        tmp_D = tmp(tmp_t)
                        D_values [low_limit+bad_minutes_indexes] = tmp_D[low_limit+bad_minutes_indexes]

                        tmp= interp1d(tmp_t[low_limit+good_minutes_indexes],Z_values[low_limit+good_minutes_indexes],kind='cubic')
                        tmp_Z = tmp(tmp_t)
                        Z_values [low_limit+bad_minutes_indexes] = tmp_Z[low_limit+bad_minutes_indexes]


                        tmp= interp1d(tmp_t[low_limit+good_minutes_indexes],F_values[low_limit+good_minutes_indexes],kind='cubic')
                        tmp_F = tmp(tmp_t)
                        F_values [low_limit+bad_minutes_indexes] = tmp_F[low_limit+bad_minutes_indexes]

                        fixed_minutes = fixed_minutes + bad_minutes_number
                    
                    mask = H_values >= 999990
                    mask = mask.astype(bool)

                    bad_minutes_indexes = numpy.where(mask)[0]
                    bad_minutes_number = numpy.count_nonzero(mask)

                    i+=1

                    if (bad_minutes_number<=0) or (i >= n_processes): break
                j=j+1

                if (bad_minutes_number<=0) or (j >= process_number.shape[0]):break

        #preparing data for storing
        # 
        # 
        #     
        data_file = numpy.array(minutes_per_day,dtype='object')

        for i in range(minutes_per_day):
            chain = '{:4d}-{:02d}-{:02d} {:02d}:{:02d}:00.000 {:03d}     {:7.2f} {:9.2f} {:9.2f} {:9.2f}'

            data_file[i] = chain.format(tmp_data[i]['year'],tmp_data[i]['month'],tmp_data[i]['day'],
                                        tmp_data[i]['hour'],tmp_data[i]['minute'],tmp_data[i]['doy'],
                                        D_values[i],H_values[i],Z_values[i],F_values[i])
            


        output_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])


        cleaned_data_file_name = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],string_date)

        fpath = os.path.join(output_path,cleaned_data_file_name)
        with open(fpath, 'wb') as file:
            file.writelines(data_file)

        if verbose:
            print("Guardando: {}".format(os.path.basename(fpath)))
            if offset.shape[0] == 3:
                print("Con datos-offset de {:4d} en D, {:4d} en H y {:4d} en Z".format(offset[0],offset[1],offset[2]))

            if (new_no_gaps_count   < minutes_per_day): 
                diff = numpy.abs(minutes_per_day-new_no_gaps_count)
                print("El archivo original tuvo perdido {:4d} minutos de datos.".format(diff))
            if (new_no_gaps_count<no_gaps_count):
                diff = numpy.abs(no_gaps_count-new_no_gaps_count)
                print("Adicionalmente {:4d} minutos de original data fueron descartados".format(diff))
            if (fixed_minutes > 0 ):
                print("Finalmente, {} minutos de la data original se pudo interpolar".format(fixed_minutes))
    
        return 
    def __fixing_voltagefile(self,file_date,**kwargs):
        station = kwargs.get("station",None)
        verbose = kwargs.get('verbose',False)

        '''
        La funcion tiene como propositio en completar vacios 
        en archivos raw del REGMEX GMS y remover las cabezas
        o headers 
        '''

        initial_year = file_date.year
        initial_month = file_date.month
        initial_day = file_date.day

        #######
        # Reading data files 
 
        tmp_julday = JULDAY(file_date)

        result = CALDAT(tmp_julday)
        tmp_year, tmp_month,tmp_day = result.year,result.month,result.day

        cabecera = 18 

        file_name = '{}{:4d}{:02d}{:02d}rK.min'.format(self.GMS[self.system['gms']],tmp_year,tmp_month,tmp_day)

        fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)

        exists = os.path.isfile(fpath)

        if not exists:

            chain = '{}{:4d}{:02d}{:02d}rmin.min'
            file_name = chain.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day) 
            
            exists = os.path.isfile(file_name)

            if exists:
                if verbose:
                    print("Extrayendo datos de {}".format(os.path.basename(file_name)))
                fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)
                with open(fpath,'w') as file:
                    tmp_data = file.readlines()
                
                    tmp_data = numpy.array(tmp_data,dtype='object')
                    number_of_lines = tmp_data.shape[0]
            else:
                if verbose:
                    print("Archivo no encontrado.")
        else:
            if verbose:
                print("Extrayendo datos de {}".format(os.path.basename(file_name)))
               
            fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)
            with open(fpath,'w') as file:
                tmp_data = file.readlines()
            
                tmp_data = numpy.array(tmp_data,dtype='object')

                number_of_lines = tmp_data.shape[0]
        
        minutes_in_a_day  = 1440 
        hours_in_a_day = 24

        if station=='planetary':
            final_file = numpy.array(hours_in_a_day,dtype='object')
            j_inicio = cabecera-1

            for i in range(hours_in_a_day):
                result =  JULDAY(datetime(initial_year,initial_month,initial_day))-(JULDAY(datetime(initial_year,1,0)+relativedelta(days=-1)))
                chain = '{:4d}-{:02d}-{:02d} {:02d}:{:02d}:00.000 {:03d}   {:4d}     {:4d}  {:5d}    {:5d}   {:5d}     {:5d}'
                final_file [i]  =  chain.format(tmp_year, tmp_month,tmp_day,i,0,result,999,999,999,999,9999,9999)

                if exists:
                    j=j_inicio
                    while(j<number_of_lines):
                        if (tmp_data[j][11:16].lower()) == (final_file[i][11:16]):
                            final_file[i] = tmp_data[j]
                            j_inicio = j+1
                            break

                        j=j+1
                    
            
        else:

            final_file = numpy.array(minutes_in_a_day,dtype='object')
            j_inicio = cabecera-1 
            for i in range(minutes_in_a_day):
                result =  JULDAY(datetime(initial_year,initial_month,initial_day))-(JULDAY(datetime(initial_year,1,0)+relativedelta(days=-1)))
                chain = '{:4d}-{:02d}-{:02d} {:02d}:{:02d}:00.000 {:03d}     {:7.2f} {:9.2f} {:9.2f}'
                final_file[i] = chain.format(tmp_year,tmp_month,tmp_day, i//60,i%60,result, 9999.00, 999999.00, 999999.00, 999999.00)

                if exists:
                    j= j_inicio
                    while(j<number_of_lines):
                        if (tmp_data[j][11:16].lower()==final_file[i][11:16].lower()):

                            final_file[i] = tmp_data[j]

                            j_inicio = j+1
                            break
                        
                        j+=1


        #### Creando archivo de datos
        ##############################################################
        output_datafile = '{}_{:4d}{:02d}{:02d}.dat'.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day) 
        opath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])

        exists_dir = os.path.isdir(opath)

        if not exists_dir:
            if verbose:
                print("Error critico: Directorio del sistema perdido {}. Revisa el directorio.".format(opath))
                return 

        fpath = os.path.join(opath,output_datafile)
        with open(fpath,'w') as file:
            file.writelines(final_file)
        
        if verbose:
            print("Guardando {}").format( os.path.basename(opath))
        
        return 
    


    def __magneticdata_prepare(self, initial= None,final=None,**kwargs):

        station = kwargs.get("station",None)
        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get('real_time',False)
        force_all = kwargs.get("force_all",False)
        offset = kwargs.get(force_all,'None')

        if offset is not None and isinstance(offset,list):
            offset = numpy.array(offset)
        
        if offset is not None and isinstance(offset,numpy.ndarray)

            if offset.shape[0] !=3:
                raise ValueError("Valores inconsistentes o invalidos para el atributo OFFSET")
        
        if initial is None:
            initial = self.system['today_date']
        if final is None: 
            final = initial 
        check_dates(initial=initial,final=final,GMS=self.GMS,system=self.system,verbose=verbose)

        
        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day

        final_year = final.year
        final_month = final.month
        final_day = final.day 

        ######
        # Leyendo data files 

        file_number = JULDAY(final)-JULDAY(initial)+1
        data_file_name = numpy.empty(file_number,dtype='object')
        processed_file_name = numpy.empty(file_number,dtype='object')
        string_date = numpy.empty(file_number,dtype='object')

        for i in range(file_number):
            
            tmp = JULDAY(initial)
            result = CALDAT(tmp+i)
            tmp_year = result.year
            tmp_month = result.month
            tmp_day = result.day        
            string_date[i] = "{:4d}{:02d}{:02d}".format(tmp_year,tmp_month,tmp_day)

            data_file_name [i] = '{}{}rk.min'.format(self.GMS[self.system['gms']]['code'],string_date[i])
            processed_file_name[i] = "{}_{}.dat".format(self.GMS[self.system['gms']]['code'],string_date[i])
 
        exist_processed_file =  [os.path.isfile( os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],path) ) and not force_all for path in processed_file_name]    
        exist_processed_file = numpy.array(exist_processed_file)
        
        exist_data_file =  [os.path.isfile( os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],path) ) for path in data_file_name]    
        exist_data_file = numpy.array(exist_data_file)

        if len(numpy.where(exist_processed_file==0)[0]) >1 :updating_files = len(numpy.where(exist_processed_file==0)[0])
        elif (0 in numpy.where(exist_processed_file==0)[0]):updating_files = len(numpy.where(exist_processed_file==0)[0])
        else: updating_files=0

        if verbose: 
            if updating_files > 0:
                print("Un total de {} archivos necesitan ser actualizados.".format(updating_files))
                print("Puede usar el comando /FORCE_ALL para forzar la actualización.")
            
            else:
                print("No hay archivo que requiera ser actualizado.")
            
            if updating_files != exist_data_file.shape[0]:
                print("Hay todavia {} archivo(s) que pueden ser actualizados.".format(exist_processed_file.shape[0]-updating_files))
                print("Use el comando /FORCE_ALL para forzar la actualización a todos los archivos.")
        
        proceed = True 


        for i = 0 in range(exist_processed_file)
#GEOMAGIXS MAGNETICDATA_PREPARE.PRO 
asSSAD
    def __quietday_get(self,initial,station,verbose=False,real_time=False,force_all=False,local=None,statistic_qd=False):
        #script geomagix_quietday_get
        #        @geomagixs_commons
        # geomagixs_setup_commons, /QUIET
        # geomagixs_check_system, /QUIET
        # geomagixs_setup_dates, STATION=station, /QUIET
        if station == 'planetary':
            if verbose:
                Warning("Inconsistencia: Las condiciones solicitidadas podrían comprometer\
                         los resultados calculados. Es imposible o innecesario calcular Q-day para planetary GMS.")

  
        update_flag = 0 

        if initial is None:
            initial = self.system['today_date']
        
        if station is None:

            Warning('Debe definir la estación para el quietday.')

            return 

        result = CALDAT(JULDAY(initial))
        
        initial_tmp = result

        if real_time:
            if statistic_qd is False:
                qday = self.__getting_quietday(initial_tmp,station=station,verbose=verbose,
                                               real_time=real_time, local=local)
            else:
                qday = self.__getting_statistic_quietday(initial_tmp, station=station,verbose=verbose,
                                                         real_time=real_time, local=local)
        #[YYYY, MM, DD]
        else:

            result  = CALDAT(JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(days=-1)))
            tmp_month,tmp_year,tmp_day = result.month,result.year,result.day
            qday0 = self.__getting_quietday(datetime(tmp_year,tmp_month,1),station=station,verbose=verbose, local=local)
            N_days0 = JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(days=-1)) - \
                      JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(days=-1)+relativedelta(months=-1))

            result  = CALDAT(JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)))
            tmp_month,tmp_year,tmp_day = result.month,result.year,result.day
            qday1 = self.__getting_quietday(datetime(tmp_year,tmp_month,1),station=station,verbose=verbose, local=local)
            N_days1 = JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(months=1)+relativedelta(days=-1)) - \
                      JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(days=-1))

            result  = CALDAT(JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(months=+1)))
            tmp_month,tmp_year,tmp_day = result.month,result.year,result.day
            qday2  = self.__getting_quietday(datetime(tmp_year,tmp_month,1),station=station,verbose=verbose, local=local)          
            N_days2 = JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(months=+2)+relativedelta(days=-1)) - \
                      JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(months=+1)+relativedelta(days=-1))


            N_days = JULDAY(initial_tmp)-JULDAY(datetime(initial_tmp.year,initial_tmp.month,initial_tmp.day)+relativedelta(days=-1))

            v = numpy.array([N_days0//2,N_days0+N_days1//2,N_days0+N_days1+N_days2//2])
            w = numpy.array([N_days+1*N_days])

            qday  = deepcopy(qday1)
            #INTERPOL( V, X, XOUT )
            for i in range(vectorize(qday1,'H').shape[0]):
                DH = numpy.interp(w,v[qday0[i]['H'],qday1[i]['H'],qday2[i]['H']])           
                DD= numpy.interp(w,v[qday0[i]['D'],qday1[i]['D'],qday2[i]['D']])           
                DZ = numpy.interp(w,v[qday0[i]['Z'],qday1[i]['Z'],qday2[i]['Z']])           
                DF = numpy.interp(w,v[qday0[i]['F'],qday1[i]['F'],qday2[i]['F']])           
                
                qday[i]['H'] = DH
                qday[i]['D'] = DD
                qday[i]['Z'] = DZ
                qday[i]['F'] = DF

                qday[i]['day']  = initial_tmp.year


        return qday     
    def __getting_magneticdata(self,initial,station=None,verbose=None):
        # script geomagixs_quietday_get.pro
        #listo 
        try:

            initial_year = initial.year
            initial_month = initial.month
            initial_day = initial.day

            file_number = 1
            name = '{:4d}{:02d}{:02d}'.format(initial_year,initial_month,initial_day)
            file_name = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],name)

            file_name = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],file_name)

            exist = os.path.isfile(file_name)

            if exist:
                with open(file_name,'r') as file:

                    magnetic_data = numpy.array(file.readlines(),dtype='object')
            else:
                raise FileNotFoundError("No se encontró el archivo {}.".format(os.path.basename(file_name)))
                return
            ####### Extraemos los datos    

            keys =  ['year','month','day','hour','minute','D','H','Z','F']

            struct = dict.fromkeys(keys,0)

            resulting = numpy.empty(magnetic_data.shape[0],dtype='object')
            resulting.fill(struct)

            for n,linea in enumerate(magnetic_data):

                valores = re.findall(r'\d+\.?\d*', linea)

                valores = numpy.array([int(v) if v.isdigit() else float(v) for v in valores])

                for i,key in enumerate(resulting[n].keys()):
                    resulting[n][key]= valores[i]
            


            return resulting


        except:
            print("Ocurrió un error en __getting_magneticdata.")

    def __reading_kmex_data(self,date,station=None,real_time=None,verbose=False):

        try:
            if real_time is None:
                extension = '.final'
            else:
                extension = '.early'
            
            if station =='planetary':
                extension=''
            
            name = '{}_{:4d}{:02d}{:02d}.k_index{}'.format(self.GMS[self.system['gms']]['code'],date.year,date.month,date.day,extension)

            file_name = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],name)

            exists = os.path.isfile(file_name)

            dat_str = {'z':numpy.zeros(8),'y':0}

            tmp_var = numpy.empty(6)
            tmp_var.fill(dat_str)


            result = {
                'K_mex':numpy.empty(8,dtype=int),
                'K_SUM':0,
                'a_mex': numpy.empty(8,dtype=int),
                'A_median':0,
                'K_mex_max':numpy.empty(8,dtype=int),
                'K_SUM_max':0,
                'a_mex_max':numpy.empty(8,dtype=int),
                'A_median_max':0,
                'K_mex_min':numpy.empty(8,dtype=int),
                'K_SUM_min':0,
                'a_mex_min':numpy.empty(8,dtype=int),
                'A_median_min':0
            }


            if exists:
                with open(file_name,'r') as file:
                    k_index_data = numpy.array(file.readlines(),dtype='object')
                

                ##falta linea 204 para captura de datos

            else:
                if verbose:
                    Warning("Archivo perdido {}. Se procede a llenar con datos aleatorios".format(os.path.basename(file_name)))

                
                for key in result.keys():
                    if isinstance(result['key'],numpy.ndarray):
                        result['key'].fill(999)
                    else:
                        result['key']=999
            

            ###### se reemplaza los datos 
            #falta


            #######
            return result 
        except: 
            pass
    def __getting_local_qdays(self,initial,station= None,verbose=False,real_time=False):
        try:
            initial_year = initial.year
            initial_month = initial.month
            initial_day = initial.day

            #config 
            if real_time is False:
                days_for_qdays = JULDAY(datetime(initial_year,initial_month,1)+relativedelta(months=1))-\
                                JULDAY(datetime(initial_year,initial_month,1))
            else:
                days_for_qdays = JULDAY(datetime(initial_year,initial_month,1))-\
                                JULDAY(datetime(initial_year,initial_month,1)+relativedelta(months=-1))
            

            if real_time is False:
                julday_tmp =JULDAY(datetime(initial_year,initial_month,1)+relativedelta(months=1))
            else:
                julday_tmp=JULDAY(datetime(initial_year,initial_month,1))
            

            tmp_m = 0 
            tmp_d = 0
            tmp_y = 0

            str_tmp = { 'year' : 0, 'month':0,'day':0,'total_k':0,'total_k2':0,'max_k':0}

            data_qd = numpy.empty(days_for_qdays,dtype='object')
            data_qd.fill(str_tmp)

            for i in range(days_for_qdays):
                
                result = CALDAT(julday_tmp+1-i)
                data_qd[i]['year'] = result.year
                data_qd[i]['month'] = result.month
                data_qd[i]['day'] = result.day

                tmp = self.__reading_kmex_data(result,station=station, verbose=verbose,real_time=real_time)

                data_qd[i]['total_k'] = float(tmp['K_SUM'])
                
                
                good_indexes = tmp['K_mex']<99
                good_indexes_count  = numpy.count_nonzero()

                if good_indexes_count <=0:
                    data_qd[i]['total_k2'] = 999**2*8
                    data_qd[i]['max_k'] = 999

                else:
                    data_qd[i]['total_k2'] = numpy.sum(tmp['K_mex'][good_indexes]**2)
                    data_qd[i]['max_k']   = numpy.nanmax(tmp['K_mex'][good_indexes])
            

            sort = numpy.array([data['total_k'] for data in data_qd])
            argsort = numpy.argsort(sort)

            data_qd = data_qd[argsort]
 
            i=0
            #for i in range(days_for_qdays):
            while i<days_for_qdays:
                flatten = numpy.array([data['total_k'] for data in data_qd])
                indexes_equals1 = numpy.where(flatten==data_qd[i]['total_k'])[0]


                if len(indexes_equals1)>1:

                    tmp_struct1 = data_qd[indexes_equals1]
                    
                    sort = numpy.array([data['total_k2']for data in tmp_struct1])
                    argsort = numpy.argsort(sort)

                    for j in range(argsort.shape[0]):
                        temp = numpy.array([data['total_k2'] for data in tmp_struct1])
                        indexes_equals2 = numpy.where(temp)[0]

                        for j,value in enumerate(temp):
                            
                            indexes_equals2 = numpy.where(temp==value)[0]
                            if len(indexes_equals2)>1:
                                tmp_struct2 = tmp_struct1[indexes_equals2]
                                
                                temp = numpy.array([data['max_k']for data in tmp_struct2])
                                argsort3 = numpy.argsort(temp)

                                tmp_struct1 [indexes_equals2] = tmp_struct2[argsort3]
                                j+=len(indexes_equals2)-1
                        
                        data_qd[indexes_equals1] = tmp_struct1[:]
                    
                    i += len(indexes_equals1)-1
            
            flatten = numpy.array([data['total_k'] for data in data_qd])
            flatten2 = numpy.array([data['total_k2'] for data in data_qd])
            flatten3 = numpy.array([data['max_k'] for data in data_qd])
          
            mask1 = flatten<990
            mask1 = mask1.astype(bool)

            mask2 = flatten2<990**2*8
            mask2 = mask2.astype(bool)

            mask3 = flatten3<999
            mask3 = mask3.astype(bool)

            mask = mask1 & mask2 & mask3

            valid_days = numpy.where(mask)[0]
            valid_days_count = numpy.count_nonzero(mask)

            if valid_days_count >= 10:

                if verbose:
                    tmp_month = data_qd[valid_days[0]]['month']
                    try:
                        tmp_string = months[tmp_month]
                    except:
                        raise IndexError("Revisar los valores de months")

                    if valid_days<15:
                        tmp_y = [data_qd[valid_days[0]]['year']]
                        tmp_d = [data['day'] for data in data_qd[valid_days]]

                        tmp_chain ='{:4d}'.format(tmp_y[0])+space(1)
                        for n,tmp in enumerate(tmp_d):
                            tmp_chain = tmp_chain + space(2)+'{:2d}'.format(tmp)
                            if n==4:
                                tmp_chain = tmp_chain + space(2)
                        

                    else:
                        tmp_y = [data_qd[valid_days[0]]['year']]
                        tmp_d = [data['day'] for data in data_qd[valid_days]]
                        tmp_chain ='{:4d}'.format(tmp_y[0])+space(1)

                        for n,tmp in enumerate(tmp_d):
                            tmp_chain = tmp_chain + space(2) + '{:2d}'.format(tmp)
                            n+=1
                            if n%5==0:
                                tmp_chain = tmp_chain + space(2)

                    str_result = '{}{}{}{}'.format(space(1),tmp_string,space(1),tmp_chain)
                    if real_time:
                        kword = ' [early]'
                    else:
                        kword = ' [final]'
                     
 
                    print('\n*Local {} Q & D days for {} GMS.\nMMM YYYY   Q1  Q2  Q3  Q4  Q5    Q6  Q7  Q8  Q9  Q10   D1  D2  D3  D4  D5'.format(tmp_string,self.GMS[self.system['GMS']]['name']))
                    print(str_result)


                resultado = {'year':0,'month':0,'day':None}
                day = numpy.array([data['day'] for data in data_qd[valid_days[:9]]],dtype=int)
                resultado['day'] = day
                resultado['year'] = initial_year
                resultado['month'] = initial_month

            else:
                resultado = {'year':0,'month':0,'day':numpy.empty(10,dtype=int)}

                resultado['day'].fill(99)
                resultado['year'] = initial_year
                resultado['month'] = initial_month

            return resultado

        except:

            print("Ocurrio un error en __getting_local_qdays.")
    def __getting_statistic_quietday(self, initial, station= None, verbose=False,real_time=False,local=False):
        def get_values(result,x,y):

            pass
        
        try:



            initial_year = initial.year
            initial_month = initial.month
            initial_day = initial.day



            kmex_days_for_median = 28
            quadratic_limit      = 7
            statistic_limit      = 5
            file_number    = kmex_days_for_median+1


            data_file_name = numpy.empty(file_number,dtype='object')
            kmex_file_name = numpy.empty(file_number,dtype='object')
            string_date    = numpy.empty(file_number,dtype='object')
            tmp_julday     = JULDAY(initial)-kmex_days_for_median


            minutes_per_day = 24*60

            D_values = numpy.empty((kmex_days_for_median,minutes_per_day),dtype=float)
            D_values.fill(9999)

            H_values = numpy.empty((kmex_days_for_median,minutes_per_day),dtype=float)
            H_values.fill(999999)

            Z_values = numpy.empty((kmex_days_for_median,minutes_per_day),dtype=float)
            Z_values.fill(999999)

            F_values = numpy.empty((kmex_days_for_median,minutes_per_day),dtype=float)
            F_values.fill(999999)

            for n in range(file_number):

                result = CALDAT(tmp_julday+n)
                tmp_year = result.year
                tmp_month = result.month
                tmp_day   = result.day

                tmp = '{:4d}{:02d}{:02d}'.format(tmp_year,tmp_month,tmp_day)

                string_date[n] = tmp
                kmex_file_name[n] = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],string_date[n])

            fpath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],kmex_file_name)
            exists = os.path.isfile(fpath)   

            for i in range(kmex_days_for_median):
                if exists:

                    result = CALDAT(tmp_julday+i)

                    tmp_month = result.month
                    tmp_year = result.year 
                    tmp_day = result.day

                    tmp_data = self.__getting_magneticdata(datetime(tmp_year,tmp_month,tmp_day),
                                                           station=station,
                                                           verbose=verbose,
                                                           ) 
                    
                
                    D_values[i] = vectorize(tmp_data,'D')
                    H_values[i] = vectorize(tmp_data,'H')
                    Z_values[i] = vectorize(tmp_data,'Z')
                    F_values[i] = vectorize(tmp_data,'F')
            
            D_median = numpy.empty(minutes_per_day,dtype=float)
            D_median.fill(9999)

            D_sigma = deepcopy(D_median)

            H_median = numpy.empty(minutes_per_day)
            H_median.fill(999999)

            Z_median = deepcopy(H_median)
            F_median= deepcopy(H_median)
            N_median= deepcopy(H_median)
            H_sigma= deepcopy(H_median)
            Z_sigma= deepcopy(H_median)
            F_sigma= deepcopy(H_median)
            N_sigma= deepcopy(H_median)

            number_of_data = numpy.empty(minutes_per_day,dtype=int)

            arc_secs_2rads = numpy.pi/(60*180)

            keys = ['year','month','day','hour','minute','D','H','Z','F','dD','dH','dZ','dF']
            struct = dict.fromkeys(keys,0)

            qday = numpy.empty(minutes_per_day,dtype='object')
            qday.fill(struct)

            time_days = numpy.arange(kmex_days_for_median)+1

            for i in range(minutes_per_day):

                valid_days = H_values[:kmex_days_for_median-1,i]<999990.00
                
                count  = numpy.count_nonzero(valid_days)

                number_of_data[i] = count

                if number_of_data[i]>= statistic_limit:


 
                    if number_of_data[i] >= quadratic_limit:

                        x = time_days[valid_days]
                        y = D_values[valid_days,i]
                        result = numpy.polyfit(x,y,2)
                        tendency = numpy.polyval(result,x)
                        delta = numpy.std(tendency-y)

                        status_result = numpy.isnan(result).any()

                        if status_result is True or number_of_data[i] < quadratic_limit:
                            
                            
                            result = numpy.polyfit(x,y,1)
                            tendency = numpy.polyval(result,x)
                            delta = numpy.std(tendency-y)

                            status_result = numpy.isnan().any()

                            div = result[1]/delta[1]
                            flag = numpy.isnan(result[1]) & numpy.isnan(delta[1])

                            
                            if div <= 0.5 and flag :
                                status_result=1
                            
                        if status_result:
                            qday[i]['D'] = numpy.median(y)
                            qday[i]['dD'] = numpy.var(y)
                        else:
                            #INTERPOL(y, x, xinterp)
                            qday[i]['D'] = numpy.median(y-tendency) + numpy.interp(time_days[valid_days[number_of_data[i]-1]]+1,time_days[valid_days],tendency)
                            qday[i]['dD'] = numpy.var(y-tendency)


                        # key = [['H_values',['H','dH']],['Z_values',['Z','dZ']]]
                    #####################################################################
                    #####################################################################
                    #####################################################################

                    

                    if number_of_data[i] >= quadratic_limit:

                        x = time_days[valid_days]
                        y = H_values[valid_days,i]

                        result = numpy.polyfit(x,y,2)
                        tendency = numpy.polyval(result,x)
                        delta = numpy.std(tendency-y)

                        status_result = numpy.isnan(result).any()

                        if status_result is True or number_of_data[i] < quadratic_limit:
                          
                            
                            result = numpy.polyfit(x,y,1)
                            tendency = numpy.polyval(result,x)
                            delta = numpy.std(tendency-y)

                            status_result = numpy.isnan().any()

                            div = result[1]/delta[1]
                            flag = numpy.isnan(result[1]) & numpy.isnan(delta[1])

                            
                            if div <= 0.5 and flag :
                                status_result=True
                            
                        if status_result is True:
                            qday[i]['H'] = numpy.median(y)
                            qday[i]['dH'] = numpy.var(y)
                        else:
                            #INTERPOL(y, x, xinterp)
                            qday[i]['H'] = numpy.median(y-tendency) + numpy.interp(time_days[valid_days[number_of_data[i]-1]]+1,time_days[valid_days],tendency)
                            qday[i]['dH'] = numpy.var(y-tendency)
                    
                    #####################################################################
                    #####################################################################
                    #####################################################################
              

                    if number_of_data[i] >= quadratic_limit:

                        x = time_days[valid_days]
                        y = Z_values[valid_days,i]
                        result = numpy.polyfit(x,y,2)
                        tendency = numpy.polyval(result,x)
                        delta = numpy.std(tendency-y)

                        status_result = numpy.isnan(result).any()

                        if status_result is True or number_of_data[i] < quadratic_limit:
                             
                            
                            result = numpy.polyfit(x,y,1)
                            tendency = numpy.polyval(result,x)
                            delta = numpy.std(tendency-y)

                            status_result = numpy.isnan().any()

                            div = result[1]/delta[1]
                            flag = numpy.isnan(result[1]) & numpy.isnan(delta[1])

                            
                            if div <= 0.5 and flag :
                                status_result=True
                            
                        if status_result is True:
                            qday[i]['Z'] = numpy.median(y)
                            qday[i]['dZ'] = numpy.var(y)
                        else:
                            #INTERPOL(y, x, xinterp)
                            qday[i]['Z'] = numpy.median(y-tendency) + numpy.interp(time_days[valid_days[number_of_data[i]-1]]+1,time_days[valid_days],tendency)
                            qday[i]['dZ'] = numpy.var(y-tendency)
                    #####################################################################
                    #####################################################################
                    #####################################################################
                    
                    
                    status_result = 1

                    if number_of_data[i] >= quadratic_limit:

                        x = time_days[valid_days]
                        y = F_values[valid_days,i]
                        result = numpy.polyfit(x,y,2)
                        tendency = numpy.polyval(result,x)
                        delta = numpy.std(tendency-y)

                        status_result = numpy.isnan(result).any()

                        if status_result is True or number_of_data[i] < quadratic_limit:
                            status_result = 0
                            
                            result = numpy.polyfit(x,y,1)
                            tendency = numpy.polyval(result,x)
                            delta = numpy.std(tendency-y)

                            status_result = numpy.isnan().any()

                            div = result[1]/delta[1]
                            flag = numpy.isnan(result[1]) & numpy.isnan(delta[1])

                            
                            if div <= 0.5 and flag :
                                status_result=True
                            
                        if status_result is True :
                            qday[i]['F'] = numpy.median(y)
                            qday[i]['dF'] = numpy.var(y)
                        else:
                            #INTERPOL(y, x, xinterp)
                            qday[i]['F'] = numpy.median(y-tendency) + numpy.interp(time_days[valid_days[number_of_data[i]-1]]+1,time_days[valid_days],tendency)
                            qday[i]['dF'] = numpy.var(y-tendency)
                    #####################################################################
                    #####################################################################
                    #####################################################################
                else:


                    qday[i]['D'] = 9999
                    qday[i]['dD'] = 9999

                    qday[i]['H']=999999.0  
                    qday[i]['dH']=999999.0  

                    qday[i]['Z']=999999.0  
                    qday[i]['dZ']=999999.0  
                    qday[i]['F']=999999.0  
                    qday[i]['dF']=999999.0  

            for n,_ in enumerate(qday):
                qday[n]['year'] = initial.year
                qday[n]['month'] = initial.month
                qday[n]['day'] = initial.day
                try:
                    qday[n]['hour'] = tmp_data[n]['hour']
                    qday[n]['minute'] = tmp_data[n]['minute']
                except IndexError:
                    qday[n]['hour'] = vectorize(tmp_data,'hour')
                    qday[n]['minute'] = vectorize(tmp_data,'minute')  

            bool1 = vectorize(qday,'dH')
            bool2 = .5*vectorize(qday,'H')
            bool1 = bool1>0.05*bool2
            bool1 = bool1.astype(bool)

        

            bool3 = vectorize(qday,'dH')
            th = 4*numpy.median(vectorize(qday,'dH'))
            bool3 = bool3 > th
            bool3 = bool3.astype(bool)

            clean_indexes = bool1 & bool3

            clean_count = numpy.count_nonzero(clean_indexes)


            tmp_arr = numpy.fft.fft(vectorize(qday,'H'))
            tmp_arr_median = numpy.median(numpy.abs(tmp_arr))

            #minutes
            smoothing_period = 15
            smoothing_index = (60*24)/numpy.ceil(smoothing_period)

            tmp_arr[smoothing_index:60*24-1-smoothing_index] = 0 
            
            tmp_arr_2 = numpy.fft.ifft(tmp_arr).real 

            for n,_ in enumerate(tmp_arr_2):

                qday[n]['H'] = tmp_arr_2[n]  
            
            #suavizados por +/- 30 minutos 
            #########################################################
            #########################################################
            #########################################################
            key='H'

            smooth_steps = 30
            smooth_witdh = 10

            n_elements = vectorize(qday,key).shape[0]
            array1 = vectorize(qday[n_elements-smooth_steps:n_elements-1],key)
            array2 = vectorize(qday[:smooth_steps-1],key)

            smoothed_array =  numpy.concatenate((array1,array2))
            smoothed_array = smooth(smoothed_array,smooth_witdh)

            for n,_ in enumerate(qday[:-smooth_steps]):
                qday[smooth_steps+n][key] = smoothed_array[n]
            
            for n,_ in enumerate(qday[:smooth_steps-1]):
                qday[n][key] = smoothed_array[smooth_steps+n]
            #########################################################
            #########################################################
            #########################################################
            key='D'

            smooth_steps = 30
            smooth_witdh = 10

            n_elements = vectorize(qday,key).shape[0]
            array1 = vectorize(qday[n_elements-smooth_steps:n_elements-1],key)
            array2 = vectorize(qday[:smooth_steps-1],key)

            smoothed_array =  numpy.concatenate((array1,array2))
            smoothed_array = smooth(smoothed_array,smooth_witdh)

            for n,_ in enumerate(qday[:-smooth_steps]):
                qday[smooth_steps+n][key] = smoothed_array[n]
            
            for n,_ in enumerate(qday[:smooth_steps-1]):
                qday[n][key] = smoothed_array[smooth_steps+n]
            #########################################################
            #########################################################
            #########################################################
            key='F'

            smooth_steps = 30
            smooth_witdh = 10

            n_elements = vectorize(qday,key).shape[0]
            array1 = vectorize(qday[n_elements-smooth_steps:n_elements-1],key)
            array2 = vectorize(qday[:smooth_steps-1],key)

            smoothed_array =  numpy.concatenate((array1,array2))
            smoothed_array = smooth(smoothed_array,smooth_witdh)

            for n,_ in enumerate(qday[:-smooth_steps]):
                qday[smooth_steps+n][key] = smoothed_array[n]
            
            for n,_ in enumerate(qday[:smooth_steps-1]):
                qday[n][key] = smoothed_array[smooth_steps+n]
            #########################################################
            #########################################################
            #########################################################
            key='Z'

            smooth_steps = 30
            smooth_witdh = 10

            n_elements = vectorize(qday,key).shape[0]
            array1 = vectorize(qday[n_elements-smooth_steps:n_elements-1],key)
            array2 = vectorize(qday[:smooth_steps-1],key)

            smoothed_array =  numpy.concatenate((array1,array2))
            smoothed_array = smooth(smoothed_array,smooth_witdh)

            for n,_ in enumerate(qday[:-smooth_steps]):
                qday[smooth_steps+n][key] = smoothed_array[n]
            
            for n,_ in enumerate(qday[:smooth_steps-1]):
                qday[n][key] = smoothed_array[smooth_steps+n]
            
            #preparing data for storing
            return qday
            

 
        except:

            return 
        
    
    def __getting_quietday(self,initial,station=None,verbose=False,real_time=False,local=None):

        initial_date = initial 
        #[YYYY, MM, DD] 
        if real_time is True:

            result = CALDAT(JULDAY(datetime(initial.year,initial.month,1)))
            initial_date  = datetime(result.year,result.month,initial_date.day)


        tmp_julian = JULDAY(datetime(initial_date.year,initial_date.month,1))
        result = CALDAT(tmp_julian)

        tmp_month = result.month
        tmp_year = result.year
        tmp_day = result.day

        tmp_year0 = tmp_year

        ###
        tmp_millenium = (tmp_year//1000)*1000
        tmp_century = ((tmp_year % 1000)//100)*100
        tmp_decade  = (((tmp_year % 1000) %100)//10)*10

        tmp_year = tmp_millenium + tmp_century + tmp_decade
        


        tmp_today_year = (self.system['today_date'].year//1000)+((self.system['today_date'].yearr % 1000)//100)*100+(((self.system['today_date'].year % 1000) %100)//10)*10

        tmp_julian = JULDAY(datetime(initial_date.year,tmp_month,1))
        tmp_julian_1  = JULDAY(datetime(tmp_today_year,1,1))
        tmp_julian_2  = JULDAY(datetime(tmp_today_year,12,31)+relativedelta(years=+9))



        if tmp_julian < tmp_julian_1:
            file_name = 'qd{:04d}{:02d}.txt'.format(tmp_year,tmp_decade+9)
        elif (tmp_julian>= tmp_julian_1) and(tmp_julian<=tmp_julian_2):
            file_name = 'qd{:4d}{:01d}'.format(tmp_year,tmp_decade//10)

        else: 
            Warning("Error con la entrada de dato!!!")
            return None

        

        fpath = os.path.join(self.system['qdays_dir'],file_name)

        exists = os.path.exists(fpath)
        
        if not exists:
            FileExistsError("Error abriendo el archivo {}".format(os.path.basename(exists)))
        
        with open(fpath,'r') as f:

            qds_list_data = numpy.array(f.readlines(),dtype='object')
        
        #buscamos la linea donde se encuentra la fecha deseada 
        tmp_year = tmp_year0

        tmp_doy = JULDAY(datetime(tmp_year,tmp_month,tmp_day))-JULDAY(datetime(tmp_year,1,1))
        try:
            tmp_string  = months[tmp_month]
        except IndexError as e:
            raise IndexError("Ocurrió un error al buscar el string de fechas")
        
        date_str = ' {} {:4d}'.format(tmp_string,tmp_year)



        # Aplicar conversión a minúsculas
        lowercase_arr = array_to_lower(qds_list_data)
        buff = numpy.char[:9](lowercase_arr)

        # numpy.core.defcharaarray return 0 si hay elementos que coinciden
        # en otro caso solo retorna -1 
        valid_line = numpy.core.defchararray.find(buff.astype(str), date_str)

        valid_line = numpy.array([True if x == 0 else False for x in valid_line])
        valid_line = numpy.where(valid_line)[0]

        tmp_str = {'quiet_day' : numpy.empty(10,dtype=int)}
    

        count = numpy.count_nonzero(valid_line)
        if count >0 and local is None:
            
            valores = qds_list_data[valid_line]
            valores = re.findall(r'\d+', valores)

            standar_day_list = numpy.array([int(x) for x in valores],dtype=int)
            standar_day_list = numpy.array([{'quiet_day':standar_day_list}],dtype='object')
        
        else:
            if local is None:
                if verbose:
                    ResourceWarning("Invalido o datos perdidos de planetary Q-days.\
                                    Procediendo con LOCAL/[early] Q-days.")
                    
            
            qd_tmp = self.__getting_local_qdays(initial=initial,
                                                station=station,
                                                verbose=verbose,
                                                real_time=real_time)
            ###
            tmp_month = qd_tmp['month']
            tmp_year = qd_tmp['year']

            for n , _ in enumerate(standar_day_list):
                standar_day_list[n]['quiet_days'] = qd_tmp['day']

            if qd_tmp['day'][0] >= 99:
                qday = self.__getting_statistic_quietday(initial=initial_date,station=station,verbose= verbose,real_time=real_time)
                return qday

        minutes_per_day = 1440

        struct = { 'year' : numpy.empty(minutes_per_day,dtype=int),
                   'month' : numpy.empty(minutes_per_day,dtype=int),
                   'day':numpy.empty(minutes_per_day,dtype=int),
                   'hour':numpy.empty(minutes_per_day,dtype=int),
                   'minute':numpy.empty(minutes_per_day,dtype=int),
                   'D': numpy.empty(minutes_per_day,dtype=float).fill(9999),
                   'H':numpy.empty(minutes_per_day,dtype=float).fill(999999),
                   'Z':numpy.empty(minutes_per_day,dtype=float).fill(999999),
                   'F':numpy.empty(minutes_per_day,dtype=float).fill(999999),
                   'D_median':9999,'H_median':999999,'Z_median':999999,'F_median':999999}

        qd_data = numpy.empty(standar_day_list[0]['quiet_day'].shape[0],dtype='object')
        qd_data.fill(struct)

        struct = {'year':0 , 'month':0,'day':0,'hour':0,'minute':0,'D':9999,'H':999999,'Z':999999,
                    'dD':9999,'dH':999999,'dZ':999999,'dF':999999}
        qday = numpy.empty(minutes_per_day,dtype='object')
        qday.fill(struct)

        data_file_list = numpy.empty(standar_day_list[0]['quiet_day'].shape[0],dtype='object')

        for i in range(standar_day_list[0]['quiet_day'].shape[0]):

            tmp = self.__getting_magneticdata(initial=datetime(tmp_year,tmp_month,standar_day_list[0]['quiet_day'][i]),station=station,verbose=verbose)

            for k in ['year','month','day','hour','minute','D','H','Z','F']:
                qd_data[i][k] = vectorize(tmp,k)
            

            bool1 = qd_data[i]['H'] < 999990.00
            bool1 = bool1.astype(bool)

            bool2 = qd_data[i]['H'] > 0 
            bool2 = bool2.astype(bool)

            mask = bool1 & bool2 

            indexes = numpy.where(mask)[0]
            count = numpy.count_nonzero(mask)
            

            if count >0:
                for a,b in zip(['D_median','H_median','Z_median','F_median'],['D','H','Z','F']):
                    qd_data[i][a] = numpy.median(qd_data[i][b][indexes])
                    qd_data[i][b][indexes] -= qd_data[i][a]


        for n, _ in enumerate(qday):

            qday[n]['year'] = initial_date.year
            qday[n]['month'] = initial_date.month
            qday[n]['day']  = 1
            qday[n]['hour'] = qd_data[0]['hour']
            qday[n]['minute'] = qd_data[0]['minute']


        buff_h = numpy.vectorize(qd_data,'H')

        for i in range(minutes_per_day):
        
            mask = numpy.ravel(buff_h[:,i]) < 999990.00

            count = numpy.count_nonzero(mask)
            
            indexes = numpy.where(mask)[0]

            
                
            for a,da in zip(['D','H','Z','F'],['dD','dH','dZ','dF']):
                if count >= 2 and count <5 :
                    buff = vectorize(qd_data[indexes],a)
                    qday[i][a] = numpy.mean(buff[:,i])+ numpy.median(buff)
                    qday[i][da] = numpy.std(buff[:,i])

                elif count >= 5:
                    buff = vectorize(qd_data[indexes[:4]],a)
                    qday[i][a] = numpy.mean(buff[:,i])+ numpy.median(buff)
                    qday[i][da] = numpy.std(buff[:,i])                    
                
        

        TS_oddnumber = 11 
        TS_N_ELEMENTS = numpy.ravel(vectorize(qday,'H')).shape[0]

        temp_H = numpy.empty(3*TS_N_ELEMENTS,dtype = float)
        temp_D = deepcopy(temp_H)
        temp_Z = deepcopy(temp_H)
        temp_F = deepcopy(temp_H)

        #########################################################################
        #########################################################################
        #########################################################################

        temp_H [:TS_N_ELEMENTS-1] = numpy.ravel(vectorize(qday,'H'))
        temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1] = numpy.ravel(vectorize(qday,'H'))
        temp_H [2*TS_N_ELEMENTS:] = numpy.ravel(vectorize(qday,'H'))
        
        mask = temp_H < 999990
        mask = mask.astype(bool)

        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes =  numpy.where(mask)[0]

        if tmp_valid_indexes_count <=0 :
            raise ValueError("Error critico: No hay datos para calcular Quiet Day")

        tmp_median = numpy.median(temp_H[tmp_valid_indexes])
        temp_H[tmp_valid_indexes] -= tmp_median
        #########################################################################
        #########################################################################
        #########################################################################
        
        temp_D [:TS_N_ELEMENTS-1] = numpy.ravel(vectorize(qday,'D'))
        temp_D [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1] = numpy.ravel(vectorize(qday,'D'))
        temp_D [2*TS_N_ELEMENTS:] = numpy.ravel(vectorize(qday,'D'))
        
        mask = temp_D < 999990
        mask = mask.astype(bool)

        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes =  numpy.where(mask)[0]

        if tmp_valid_indexes_count <=0 :
            raise ValueError("Error critico: No hay datos para calcular Quiet Day")

        tmp_median = numpy.median(temp_D[tmp_valid_indexes])
        temp_D[tmp_valid_indexes] -= tmp_median

        #########################################################################
        #########################################################################
        #########################################################################
        
        temp_Z [:TS_N_ELEMENTS-1] = numpy.ravel(vectorize(qday,'Z'))
        temp_Z [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1] = numpy.ravel(vectorize(qday,'Z'))
        temp_Z [2*TS_N_ELEMENTS:] = numpy.ravel(vectorize(qday,'Z'))
        
        mask = temp_Z < 999990
        mask = mask.astype(bool)

        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes =  numpy.where(mask)[0]

        if tmp_valid_indexes_count <=0 :
            raise ValueError("Error critico: No hay datos para calcular Quiet Day")

        tmp_median = numpy.median(temp_Z[tmp_valid_indexes])
        temp_Z[tmp_valid_indexes] -= tmp_median

        #########################################################################
        #########################################################################
        #########################################################################
        
        temp_F [:TS_N_ELEMENTS-1] = numpy.ravel(vectorize(qday,'F'))
        temp_F [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1] = numpy.ravel(vectorize(qday,'F'))
        temp_F [2*TS_N_ELEMENTS:] = numpy.ravel(vectorize(qday,'F'))
        
        mask = temp_F < 999990
        mask = mask.astype(bool)

        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes =  numpy.where(mask)[0]

        if tmp_valid_indexes_count <=0 :
            raise ValueError("Error critico: No hay datos para calcular Quiet Day")

        tmp_median = numpy.median(temp_F[tmp_valid_indexes])
        temp_F[tmp_valid_indexes] -= tmp_median



        #########################################################################

        half_hour = 30 
        one_hour = 60
        one_day = 24*one_hour

        one_hour_arr = numpy.arange(one_hour)
        three_days_arr = numpy.arange(TS_N_ELEMENTS)

        deviation_criteria = .5

        for i in range(51):
            
            ####################
            # H-section
            tmp_vector = temp_H[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour-1]
            mask = tmp_vector <999990.0
            mask = mask.astype(bool)


            count = numpy.count_nonzero(mask)
            valid_indexes = numpy.where(mask)[0]

            if count <= 0 :
                raise ValueError("Error critico, no hay datos para calcular Quiet Day")


            result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,2)
            status_result = numpy.isnan(result).any()
            tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
            
            if status_result is True:
                result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,1)
                tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
                delta = numpy.std(tendency-tmp_vector)

                if result[1]/delta[1] <= 0.5:
                    status_result = True
                
            if status_result is True: 
                #INTERPOL(y, x, xinterp)

                interp = interp1d (one_hour_arr[valid_indexes],tmp_vector[valid_indexes],kind='quadratic')
                tendency = interp(one_hour_arr)
                  
            
            deviation = numpy.std(tmp_vector[valid_indexes]-tendency[valid_indexes])
            median_value = numpy.median(numpy.abs(tmp_vector[valid_indexes]-tendency[valid_indexes]))

            mask = numpy.abs(tmp_vector-tendency)>(median_value+deviation_criteria*deviation) 

            mask = mask.astype(bool)

            bad_indexes_count = numpy.count_nonzero(mask)[0]
            bad_indexes = numpy.where(mask)[0]

            if bad_indexes_count >0:
                temp_H[bad_indexes + TS_N_ELEMENTS -one_hour + i*half_hour] = tendency[bad_indexes]

            
            ####################
            # D-section
            tmp_vector = temp_D[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour-1]
            mask = tmp_vector <999990.0
            mask = mask.astype(bool)


            count = numpy.count_nonzero(mask)
            valid_indexes = numpy.where(mask)[0]

            if count <= 0 :
                raise ValueError("Error critico, no hay datos para calcular Quiet Day")


            result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,2)
            status_result = numpy.isnan(result).any()
            tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
            
            if status_result is True:
                result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,1)
                tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
                delta = numpy.std(tendency-tmp_vector)

                if result[1]/delta[1] <= 0.5:
                    status_result = True
                
            if status_result is True: 
                #INTERPOL(y, x, xinterp)
                interp = interp1d (one_hour_arr[valid_indexes],tmp_vector[valid_indexes],kind='quadratic')
                tendency = interp(one_hour_arr)


            deviation = numpy.std(tmp_vector[valid_indexes]-tendency[valid_indexes])
            median_value = numpy.median(numpy.abs(tmp_vector[valid_indexes]-tendency[valid_indexes]))

            mask = numpy.abs(tmp_vector-tendency)>(median_value+deviation_criteria*deviation) 

            mask = mask.astype(bool)

            bad_indexes_count = numpy.count_nonzero(mask)[0]
            bad_indexes = numpy.where(mask)[0]

            if bad_indexes_count >0:
                temp_D[bad_indexes + TS_N_ELEMENTS -one_hour + i*half_hour] = tendency[bad_indexes]

            
            ####################
            # Z-section
            tmp_vector = temp_Z[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour-1]
            mask = tmp_vector <999990.0
            mask = mask.astype(bool)


            count = numpy.count_nonzero(mask)
            valid_indexes = numpy.where(mask)[0]

            if count <= 0 :
                raise ValueError("Error critico, no hay datos para calcular Quiet Day")


            result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,2)
            status_result = numpy.isnan(result).any()
            tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
            
            if status_result is True:
                result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,1)
                tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
                delta = numpy.std(tendency-tmp_vector)

                if result[1]/delta[1] <= 0.5:
                    status_result = True
                
            if status_result is True: 
                #INTERPOL(y, x, xinterp)
                interp = interp1d (one_hour_arr[valid_indexes],tmp_vector[valid_indexes],kind='quadratic')
                tendency = interp(one_hour_arr)


            deviation = numpy.std(tmp_vector[valid_indexes]-tendency[valid_indexes])
            median_value = numpy.median(numpy.abs(tmp_vector[valid_indexes]-tendency[valid_indexes]))

            mask = numpy.abs(tmp_vector-tendency)>(median_value+deviation_criteria*deviation) 

            mask = mask.astype(bool)

            bad_indexes_count = numpy.count_nonzero(mask)[0]
            bad_indexes = numpy.where(mask)[0]

            if bad_indexes_count >0:
                temp_Z[bad_indexes + TS_N_ELEMENTS -one_hour + i*half_hour] = tendency[bad_indexes]
            
            ####################
            # F-section
            tmp_vector = temp_F[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour-1]
            mask = tmp_vector <999990.0
            mask = mask.astype(bool)


            count = numpy.count_nonzero(mask)
            valid_indexes = numpy.where(mask)[0]

            if count <= 0 :
                raise ValueError("Error critico, no hay datos para calcular Quiet Day")


            result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,2)
            status_result = numpy.isnan(result).any()
            tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
            
            if status_result is True:
                result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,1)
                tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
                delta = numpy.std(tendency-tmp_vector)

                if result[1]/delta[1] <= 0.5:
                    status_result = True
                
            if status_result is True: 
                #INTERPOL(y, x, xinterp)
                interp = interp1d (one_hour_arr[valid_indexes],tmp_vector[valid_indexes],kind='quadratic')
                tendency = interp(one_hour_arr)


            deviation = numpy.std(tmp_vector[valid_indexes]-tendency[valid_indexes])
            median_value = numpy.median(numpy.abs(tmp_vector[valid_indexes]-tendency[valid_indexes]))

            mask = numpy.abs(tmp_vector-tendency)>(median_value+deviation_criteria*deviation) 

            mask = mask.astype(bool)

            bad_indexes_count = numpy.count_nonzero(mask)[0]
            bad_indexes = numpy.where(mask)[0]

            if bad_indexes_count >0:
                temp_F[bad_indexes + TS_N_ELEMENTS -one_hour + i*half_hour] = tendency[bad_indexes]


        two_hour_arr = numpy.arange(2*one_hour)
        Delta_time = 40 
        minutes_for_smoothing = 11

        ##############################
        # H-section 
        key = 'H'
        buff = numpy.ravel(vectorize(qday,key))
        mask = buff > 999990
        mask = mask.astype(bool)
        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]]))
        y  = numpy.ravel(numpy.array([temp_H[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_H[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]]))
        xest = two_hour_arr

        f = interp1d(x,y,kind='cubic')
        
        tendency = f(xest)

        temp_H[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_H[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]

        for n,_ in enumerate(qday):
            qday[n][key] = savgol_filter(temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1],minutes_for_smoothing,10)+tmp_median
        
  
        ##############################
        # D-section 
        key = 'D'
        buff = numpy.ravel(vectorize(qday,key))
        mask = buff > 999990
        mask = mask.astype(bool)
        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]]))
        y  = numpy.ravel(numpy.array([temp_D[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_D[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]]))
        xest = two_hour_arr

        f = interp1d(x,y,kind='cubic')
        
        tendency = f(xest)

        temp_D[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_D[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]

        for n,_ in enumerate(qday):
            qday[n][key] = savgol_filter(temp_D[TS_N_ELEMENTS:2*TS_N_ELEMENTS-1],minutes_for_smoothing,10)+tmp_median
        
        ##############################
        # Z-section 
        key = 'Z'
        buff = numpy.ravel(vectorize(qday,key))
        mask = buff > 999990
        mask = mask.astype(bool)
        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]]))
        y  = numpy.ravel(numpy.array([temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_Z[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]]))
        xest = two_hour_arr

        f = interp1d(x,y,kind='cubic')
        
        tendency = f(xest)

        temp_Z[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]

        for n,_ in enumerate(qday):
            qday[n][key] = savgol_filter(temp_Z[TS_N_ELEMENTS:2*TS_N_ELEMENTS-1],minutes_for_smoothing,10)+tmp_median
        
        ##############################
        # Z-section 
        key = 'Z'
        buff = numpy.ravel(vectorize(qday,key))
        mask = buff > 999990
        mask = mask.astype(bool)
        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]]))
        y  = numpy.ravel(numpy.array([temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_Z[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]]))
        xest = two_hour_arr

        f = interp1d(x,y,kind='cubic')
        
        tendency = f(xest)

        temp_Z[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]

        for n,_ in enumerate(qday):
            qday[n][key] = savgol_filter(temp_Z[TS_N_ELEMENTS:2*TS_N_ELEMENTS-1],minutes_for_smoothing,10)+tmp_median
        
        ##############################
        # F-section 
        key = 'F'
        buff = numpy.ravel(vectorize(qday,key))
        mask = buff > 999990
        mask = mask.astype(bool)
        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]]))
        y  = numpy.ravel(numpy.array([temp_F[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_F[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]]))
        xest = two_hour_arr

        f = interp1d(x,y,kind='cubic')
        
        tendency = f(xest)

        temp_F[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_F[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]

        for n,_ in enumerate(qday):
            qday[n][key] = savgol_filter(temp_F[TS_N_ELEMENTS:2*TS_N_ELEMENTS-1],minutes_for_smoothing,10)+tmp_median
        
        #Hay un goto,jump

        return qday 
        
        
         







 






            






 
    def __making_processeddatafiles(self,initial,station=None
                                    ,verbose=None,real_time=None,tendency_days=None
                                    ,statistic_qd=None):
        
        try:
            initial_year = initial.year
            initial_month = initial.month
            initial_day = initial.day

            ###### reading data files

            data_file_name = ''
            kmex_file_name = ''
            string_date = ''

            minutes_per_day = 24*60
            N_days = 5

            if not isinstance(tendency_days,list) or not isinstance(tendency_days,numpy.ndarray) or tendency_days is not None:
                if tendency_days>=1 and tendency_days <=15:
                    N_days=tendency_days
            
            kmex_file_name = numpy.empty(N_days,dtype='object')

            keys =  ['year','month','day','hour','minute','D','H','Z','F']

            struct = dict.fromkeys(keys,0)

            total_magnetic_data = numpy.empty(minutes_per_day*N_days,dtype='object')
            total_magnetic_data.fill(struct)

            magnetic_data = numpy.empty(minutes_per_day,dtype='object')
            magnetic_data.fill(struct)


            total_time = numpy.arange(minutes_per_day*N_days)

            if verbose:
                print("Recopilación de datos para: {}/{}/{}.".format(initial_day,initial_month,initial_year))

                if real_time:
                    print("Modo inicial: Usando data de los meses previos.")
                else:
                    print("Modo final: Usando data del mes actual.")

            

            for j in range(N_days):
                result = CALDAT(JULDAY(initial+relativedelta(days=-1*j)))

                string_date = '{:4d}{:02d}{:02d}'.format(result.year,result.month,result.day)
                kmex_file_name = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],string_date)

                exist = os.path.isfile(kmex_file_name)

                if exist:

                    magnetic_data_tmp = self.__getting_magneticdata(initial,station=station,verbose=verbose)

                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['D'] = numpy.array([tmp['D'] for tmp in magnetic_data_tmp])
                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['H'] = numpy.array([tmp['H'] for tmp in magnetic_data_tmp])
                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['Z'] = numpy.array([tmp['Z'] for tmp in magnetic_data_tmp])
                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['F'] = numpy.array([tmp['F'] for tmp in magnetic_data_tmp])

                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['year'] = numpy.array([tmp['year'] for tmp in magnetic_data_tmp])
                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['month'] = numpy.array([tmp['month'] for tmp in magnetic_data_tmp])
                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['day'] = numpy.array([tmp['day'] for tmp in magnetic_data_tmp])
                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['hour'] = numpy.array([tmp['hour'] for tmp in magnetic_data_tmp])
                    total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1]['minute'] = numpy.array([tmp['minute'] for tmp in magnetic_data_tmp])
                
                else:
                    raise RuntimeError("Error: Imposible de leer el archivo {}. Es posible que el archivo no exista o haya conflictos de permisos.".format(kmex_file_name))
                
            

            D_D = numpy.empty(minutes_per_day,dtype=float)
            D_D.fill(9999)

            D_H = numpy.empty(minutes_per_day,dtype=float)
            D_H.fill(999999)

            D_Z  = deepcopy(D_H)
            D_F  = deepcopy(D_H)
            D_N  = deepcopy(D_H)

            magnetic_data_N = deepcopy(D_H)

            D_median = numpy.empty(minutes_per_day,dtype=float)
            D_median.fill(9999)

            D_sigma = deepcopy(D_median)

            H_median = numpy.empty(minutes_per_day,dtype=float)
            H_median.fill(999999)

            Z_median = deepcopy(H_median)
            F_median = deepcopy(H_median)
            N_median = deepcopy(H_median)
            H_sigma = deepcopy(H_median)
            Z_sigma = deepcopy(H_median)
            F_sigma = deepcopy(H_median)
            N_sigma = deepcopy(H_median)

            arc_secs_2rads = numpy.pi/(60*180)
        ######### falta quietdaysget, nos quedamos aquiii 
            qday_data = self.__quietda







            
        except:
            RuntimeWarning("Ocurruió un error en makig_processddatafiles.")
            return 


 



            
    def __magneticdata_download(self,date_initial=None,date_final=None\
                                ,station=None,verbose=False,force_all=False):
        
        
        try:
            update_flag = True
            
            
            if date_initial is None:
                
                date_initial = datetime.now()
                
            if date_final is None:
                
                date_final = date_initial 
                
            #falta definir al parecer
            self.__check_dates(date_initial,date_final,station,verbose)
            
            # [YYYY, MM, DD] , initial date and time at which th
            if (self.GMS[self.system['gms']]['name'] == 'planetary'):
                
                fnumber = (date_final.year-date_initial.year)*12 + (date_final.month-date_initial.month)+1
            
            else:
                fnumber = JULDAY(date_final)-JULDAY(date_initial)
            
            
            if verbose is True:
                
                if update_flag is True:
                    print("Un total de {} dias en archivos de datos van a ser reescritos o borrados.".format(fnumber))
                
                else:
                    print("Un total de {} archivos van a ser actualizados.".format(fnumber))
                    
            files_source_name_k      = numpy.empty(fnumber,dtype='object')
            files_source_name_r      = numpy.empty(fnumber,dtype='object')
            directories_source_name  = numpy.empty(fnumber,dtype='object')
            files_destiny_name       = numpy.empty(fnumber,dtype='object')
            directories_destiny_name = numpy.empty(fnumber,dtype='object')
            terminal_results_k       = numpy.empty(fnumber,dtype='object')
            terminal_errors_k        = numpy.empty(fnumber,dtype='object')
            terminal_results_r       = numpy.empty(fnumber,dtype='object')
            terminal_errors_r        = numpy.empty(fnumber,dtype='object')  
            
            ###################################################################
            ###################################################################
            ######################     Teoloyucan   ###########################
            ###################################################################
            ###################################################################
            
            
            if self.GMS[self.system['gms']]['name'] == 'teoloyucan' :
                
                for i in range(fnumber):
                    
                    date = CALDAT(JULDAY(date_initial)+i)
                    
                    tmp_y=date.year
                    tmp_m=date.month
                    tmp_d=date.day
                    
                    
                    files_source_name_k [i] =  os.path.join(self.gms[self.system['gms']]['code'],"{:4d}{:2d}{:2d}rK.min".format(tmp_y,tmp_m,tmp_d))
                    files_source_name_r [i] =  os.path.join(self.gms[self.system['gms']]['code'],"{:4d}{:2d}{:2d}r.min".format(tmp_y,tmp_m,tmp_d))
                    
                    directories_source_name[i] = os.path.join(self.system['ssh_user']+"@"+self.system['ssh_address']+self.GMS[self.system['gms']]['code'],'{:4d}'.format(tmp_year))
                    directories_destiny_name[i] = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'])
                    
                    
                    
                    tmp_results = ''
                    tmp_errors = ''
                    
                    if verbose is True:
                        print("Copiando {:4d}{:2d}{:2d}".format(tmp_y,tmp_m,tmp_d))
                        
                    ######
                    
                    command = 'sshpass -p {} scp {} {} '.format(self.system['ssh_password'],
                                                                os.path.join(directories_source_name[i],files_source_name_k[i]),
                                                                os.path.join(directories_destiny_name[i],files_source_name_k[i]))
                    
                    result = execute_command(command)
                    
                    terminal_results_k [i] = result.stdout
                    terminal_errors_k[i]=  result.stderr
                    
                    #######
                    
                    command = 'sshpass -p {} scp {} {} '.format(self.system['ssh_password'],
                                                                os.path.join(directories_source_name[i],files_source_name_r[i]),
                                                                os.path.join(directories_destiny_name[i],files_source_name_r[i]))
                    result = execute_command(command)
                    
                    terminal_results_r [i] = result.stdout
                    terminal_errors_r[i]=  result.stderr                                
                    
                    
                    if verbose is True:
                    
                        if ((terminal_errors_r=='') or (terminal_errors_r=='')   ):
                            
                            print("Al menos un archivo fue correctamente guardado.")
                        
                        else:
                            print("Error durante la adquisición o almacenamiento de datos.")
                
                
                failed_kfiles =numpy.array([x!='' for x in terminal_errors_k])
                failed_rfiles =numpy.array([x!='' for x in terminal_errors_r])
                
                failed_knumber = numpy.count_nonzero(failed_kfiles)
                failed_rnumber = numpy.count_nonzero(failed_rfiles)
                        
                
                if verbose is True:
                    
                    print("Un total de {}/{} [RK.MIN] y {}/{}[R.MIN] archivos fueron guardados.".format(\
                                                                                               fnumber-failed_knumber,fnumber,
                                                                                                  fnumber-failed_rnumber,fnumber))   
            ###################################################################
            ###################################################################
            ######################     Planetary    ###########################
            ###################################################################
            ###################################################################        
            
            
            elif (self.GMS[self.system['gms']]!='planetary'):
                
                for i in range(fnumber):
                    date = CALDAT(JULDAY(datetime)+i)
                    
                    months = ['jan','feb','mar','apr','may','jun',\
                              'jul','aug','sep','oct','nov','dec']
                    
                    tmp_y=date.year
                    tmp_m=date.month
                    tmp_d=date.day
                    
                    tmp_string = months[tmp_m-1]
                    
                    files_source_name_k[i] = os.path.join(self.GMS[self.system['gms']]['code'],'{:2d}{}.{:2d}'.format(tmp_d,tmp_string,tmp_y%1000) )
                                                          
                    directories_source_name[i]  = os.path.join(self.system['ftp_address'],'datamin',self.GMS[self.system['gms']]['name'],'{:4d}'.format(tmp_y))
                    
                    directories_destiny_name[i] = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'])
                                            
            
                    tmp_resultsm = ''
                    tmp_errorsm  = ''
                    tmp_resultsv = ''
                    tmp_errorsv = ''
                    
                    if verbose is True:
                        
                        print("Copiando archivos de {:4d}{:2d}{:2d}".format(tmp_y,tmp_m,tmp_d))
                        
                    
                    commandv = "curl -u {}:{} -f {}v -o {}v".format(self.system['ftp_user'],self.system['ftp_password'],\
                                                                   os.path.join(directories_source_name[i],files_source_name_k[i]),\
                                                                   os.path.join(directories_source_name[i],files_source_name_k[i]))
                    
                    commandm = "curl -u {}:{} -f {}m -o {}m".format(self.system['ftp_user'],self.system['ftp_password'],\
                                                                   os.path.join(directories_source_name[i],files_source_name_k[i]),\
                                                                   os.path.join(directories_source_name[i],files_source_name_k[i]))
                    
                    resultv = execute_command(commandv)
                    resultm = execute_command(commandm)
                    
                    tmp_resultsv=resultv.stdout
                    tmp_errorsv=resultv.stderr 
                    
                    tmp_resultsm=resultm.stdout
                    tmp_errorsm=resultm.stderr
                    
                    date = datetime(tmp_y,tmp_m,tmp_d)

                    self.__making_magneticdatafile(date,station=station,verbose=verbose)                            

                    #agregar cuantos archivos se eliminan o se crean 
                    #falta
                    #
                    #
            elif self.GMS[self.system['gms']]['name'] == 'planetary':

                for i in range(fnumber):

                    result = CALDAT(JULDAY(datetime(date_initial.year,date_initial.month,1))+relativedelta(months=i))        

                    tmp_y = result.year
                    tmp_m = result.month
                    tmp_d = result.day


                    files_source_name_k [i] = 'kp{:02d}{:02d}'.format(tmp_y%1000,tmp_m)
                    directories_source_name[i]  = 'ftp://ftp.gfz-potsdam.de/pub/home/obs/kp-ap/wdc/'


                    if JULDAY(datetime(date_initial.year,date_final.month,1)+relativedelta(months=i)) == JULDAY(datetime(self.system['today_date'].year,\
                                                                                                                         self.system['today_date'].month,1)):
                        
                        directories_source_name[i]= 'http://www-app3.gfz-potsdam.de/kp_index/'
                        files_source_name_k[i]      = 'qlyymm.wdc' 
                    
                    if JULDAY(datetime(date_initial.year,date_final.month,1)+relativedelta(months=i+1)) ==JULDAY(datetime(self.system['today_date'].year,\
                                                                                                                         self.system['today_date'].month,1)):
                        directories_source_name[i]  = 'http://www-app3.gfz-potsdam.de/kp_index/'
                        files_source_name_k[i]      = 'pqlyymm.wdc'
                    
                    directories_destiny_name[i] = os.path.join(self.system['datasource_dir'],self.GMS[''])

                    tmp_results = ''
                    tmp_errors = ''

                    if verbose:
                        print("Copiando {}{}}".format(tmp_y,tmp_m))

                    name = '{:02d}{:02d}.wdc'.format(tmp_y%1000,tmp_m)
                    command = 'wget {} -O {} kp {}'.format(os.path.join(directories_source_name[i],files_source_name_k[i]),directories_destiny_name[i],name)

                    result = execute_command(command)

                    error = result.stderr
                    result = result.stdout



                files_number = JULDAY(date_final)-JULDAY(date_initial)+1 

                for i in files_number:

                    result = CALDAT(JULDAY(date_initial))

                    self.__make_planetarymagneticdatafiles(date=result,station=station,verbose=verbose)   

            if verbose:
                print("Magnetic Data ha sido actualizado.")

        except:
            print("Ocurrio un error")
        
    def __make_planetarymagneticdatafiles(self,date=None, station=None,verbose=False,force_all=False):
        #script -> geomagixs_magneticdata_download.pro
        #falta
        try:
            
            if self.GMS[self.system['gms']]['name'] != "planetary":
                return 
            
            
            initial_year = date.year
            initial_month = date.month
            initial_day = date.day
            
            file_name = "kp{:02d}{:02d}.wdc".format(initial_year %1000,initial_month)
            
            fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'])
            
            file_path = os.path.join(fpath,file_name)
            
            
            file = os.path.exists(file_path)
            
            if not file:
                if verbose:
                    ResourceWarning("Input Warning: Existe conflicto con el valor de fecha(s). Archivo\
                          perdido {}. Se reeemplazará los valores perdidos con datos nulos.".format(file_name))
                
                number_lines = JULDAY(datetime(initial_year,initial_month+1,1))
                
                magnetic_data = numpy.array(['{:02d}{:02d}{:02d}'.format(initial_year%1000,initial_month,x) for x in range(number_lines)],dtype='object')
     
            else:
                with open(file_name,'r') as archivo:
                    
                    buff_lines = archivo.readlines()
                    
                    magnetic_data = numpy.array(buff_lines,dtype='object')
                
            kp_data = numpy.empty(9)
            kp_data.fill(9999)
            
            ap_data = numpy.empty(9)
            ap_data.fill(9999)
            
            line = '{:02d}{:02d}{:02d}'.format(initial_year%1000,
                                               initial_month,
                                               initial_day)
            ind=0
            for n,value in enumerate(magnetic_data):
                if value.lower()[:6]==line.lower[:6]:
                    if n>0:
                        if len(value)>=62:
                            #falta encontrar linea de caracteres
                            # linea 348
                            pass
                        else:
                            tmp_kp = numpy.empty(8)
                            #falta rutina
                            #linea 351
                            
                        ind = numpy.where(kp_data[:7]>90)[0]
                        
                        if ind[0]>0:
                            kp_data[ind]=999
                            ap_data[ind]=999
                            
                            if len(ind)==8:
                                kp_data[8]=999
                                ap_data[8]=999
            
            #for dst
            file_name = 'dst{:02d}{:02d}.dat'.format(initial_year%1000,initial_month)
            file_name = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)
            
            check = os.path.isfile(file_name)
            
            if not check:
                if verbose:
                    ResourceWarning('Conflicto con la entrada de datos. Archivo perdido {}, se\
                                     reemplazará con datos vacios.'.format(os.path.basename(file_name)))
                    
            else:
                #archivo existe 
                
                with (file_name,'r') as f:
                    
                    buff = f.readlines()
                    
                    if len(buff)>0:
                        
                        magnetic_data = numpy.array(buff,dtype='object')
                        
                        number_lines= JULDAY(datetime(initial_year,initial_month,1)+relativedelta(months=+1))-\
                                       JULDAY(datetime(initial_year,initial_month,1))
                    else:
                        
                        if verbose:
                            ResourceWarning("Inconsistencia en los datos del archivo {},los datos están corruptos\
                                            . Se reemplazará los datos con datos aleatorios.".format(os.path.basename(file_name))) 
                            
                        number_lines = JULDAY(datetime(initial_year,initial_month,1)+relativedelta(months=+1)) - \
                                       JULDAY(datetime(initial_year,initial_month,1))      
                                       
                        magnetic_data = numpy.empty(number_lines, dtype='object')
                        
                        for n in range(number_lines):
                            
                            
                            string = 'DST {:02d}{:02d}*{:02d}RRX020   09999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999'.format(initial_year%1000,
                                                                                                                                                                                    initial_month,n+1)
                            magnetic_data[n]= string
            
            
            dst_data = numpy.empty(25,dtype=int) 
            
            dst_data.fill(9999)
            
            line ='DST {:02d}{:02d}*{:02d}'.format(initial_year % 1000,initial_month,initial_day)
            
            
            for n,value in enumerate(magnetic_data):
                if value[:10].lower()==line[:10].lower():
                    # falta colocar el formato linea 424
                    # magnetic_data[n]=
                    pass
            
            cabera = 18

            file_data = numpy.empty(24+cabera,dtype='object')

            file_data[0] = ' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
            file_data[1] = ' Source of Data         Kp/Ap: GFZ Helmholtz Centre & Dst: WDC for Geomagnetism       |'

            chain = ' '*(62-len(self.GMS[self.system['gms']]['name']))

            file_data [2]         = ' Station Name           {}{}|'.format(self.GMS[self.system['gms']]['name'].upper(),chain)
            file_data [3]         = ' IAGA CODE              {}                                                           |'.format(self.GMS[self.system['gms']]['code'])
            file_data [4]         = ' Geodetic Latitude      {:8.3f}                                                      |'.format(self.GMS[self.system['gms']]['latitude'])
            file_data [5]         = ' Geodetic Longitude      {:8.3f}                                                      |'.format(self.GMS[self.system['gms']]['longitude'])
            file_data [6]         = ' Elevation              {:6.1f}                                                        |'.format(self.GMS[self.system['gms']]['elevation'])
            file_data [7]         = ' Reported               [Kp][Sum(Kp)_24h][Ap][<Ap>_24h][Dst][<Dst>_24h]               |'
            file_data[8]          =' Sensor Orientation     variation: N/A                                                |'
            file_data[9]          =' Digital Sampling       3 hours/3 hours/1 hour                                        |'
            file_data[10]         =' Data Interval Type     Filtered hours [X=0,2] (00:00 - 0X:59)                        |'
            file_data[11]         =' Data Type              Reported                                                      |'
            file_data[12]         =' # Element              Planetary Indexes of Geomagnetic Activity                     |'
            file_data[13]         =' # Unit                 Kp [N/A] Ap [nT] Dst [nT]                                     |'
            file_data[14]         =' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
            file_data[15]         =' # URL                  http://www.sciesmex.unam.mx                                   |'
            file_data[16]         =' # Last Modified        Mar 25 2021                                                   |'
        
            file_data[17]         ='DATE       TIME         DOY     Kp    S(Kp)     Ap     <Ap>     Dst     <Dst>         |'
            

            tmp_doy   = JULDAY(datetime(initial_year,initial_month,initial_day))-JULDAY(datetime(initial_year,1,1))


            for i in range(18,42):

                cadena = '{:04d}-{:02d}-{:02d} {:02d}:{:02d}:00.000 {:03d}   {:4d}     {:4d}  {:5d}    {:5d}   {:5d}     {:5d}'

                cadena = cadena.format(initial_year,initial_month,initial_day,(i-18),0,tmp_doy,\
                                       kp_data[int((i-18)/3)],kp_data[8],ap_data[int((i-18)/3)],ap_data[8],dst_data[i-18],dst_data[24])
                
                file_data[i] = cadena

            
            data_file_name = '{}{:04d}{:02d}{:02d}.rK.min'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)

            data_file_name = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],data_file_name)


            if not os.path.isfile(data_file_name):
                
                if not os.access(data_file_name,os.W_OK):
                    PermissionError("No se puede escribir en la ruta {}.".format(data_file_name))

                with open(data_file_name,'wb') as f:
                    for data in file_data:
                        f.write(data)

                    if verbose:
                        print('Guardando:',data_file_name)
            


            


        
        except:
            print("Ocurrio un error en {}".format("__make_planetarymagneticdatafiles"))
    
    
     
    
    
    
    def __making_magneticdatafile (self,date, station=None,verbose=False,force_all=False):
        
        #script -> geomagixs_magneticdata_download.pro
        #completado pero revisar lógica
        
        
        try:
            
            
            #months

            
            
            if (self.GMS[self.system['gms']]['name']=='planetary') or \
                (self.GMS[self.system['gms']]['name']=='teoloyucan'):
                    return 
            
            
            tmp_year = date.year
            tmp_month = date.month
            tmp_day   = date.day
            
            tmp_doy  = JULDAY(date)-JULDAY(datetime(tmp_year,1,1))
            
            tmp_string = months[tmp_month-1]
            
            
            fname = os.path.join(self.GMS[self.system['gms']]['code'],'n_{:2d}{:2d}{:2d}.min'.format((tmp_year % 1000),tmp_month,tmp_day))
            
            fpath       = os.path.join(self.system['datasource_dir'],self.gms[self.system['gms']]['name'],fname)
            fexists     = os.path.exists(fpath)
            
            if fexists:
                if verbose:
                    print("Extrayendo datos de {}.".format(fname))


            else: 
                if verbose:
                    print('No se encontró el archivo {}.'.format(fname))
                    return
            
            with open(fpath,'r') as f:
                
                buff = f.readlines()
                nlines = len(buff) 
                #revisar, codigo original dice 4ll (revisado)
                cabecera = 4  
                
                if nlines <= cabecera + 1:
                    if verbose is True or force_all is True:
                        
                        print('Warning: Conflicto con los archivos de datos. Se observan \
                               datos inconsistentes o invalidos en el archivo de datos {}. El\
                               archivo tiene longitud cero'.format(fname))
                    
                        return

                
                data = {'day':0,'month':0,'year':0,'hour':0,'minute':0,\
                        'D':0, 'H':0,'Z':0,'I':0,'F':0}
                
                aux_lenght = len(buff[cabecera])
                
                aux_00 = numpy.sum(numpy.array(list(map(len,tmp_data[cabecera:]))))
                aux_01 = (nlines - cabecera)*aux_lenght
                aux_02 = (nlines - cabecera)*62
                
                
                if aux_00 != aux_01:
                    buff_len   = list(map(len,buff[cabecera:]))
                    bad_indexes = [x != aux_length for x in buff_len]
                    bad_lines = numpy.array(buff,dtype='object')[bad_indexes]
                    
                    if verbose is True and force_all is False:
                        print("Warning: Conflictos con los archivos de entrada, formatos de datos\
                               es invalido. El archivo {} tiene {} lineas corruptas.".format(fname,bad_lines))
                 
                good_indexes = ~bad_indexes
                
                good_lines = numpy.array(buff[cabecera:],dtype='object')[good_indexes]
                

                    
                #read 
                
                
                #falta revisar el archivo que se intenta descargar
                #linea 189-194
                #falta 
                #falta  
                
                if len(buff[cabecera])==62:
                    
                    read_format = r"\b\d+(?:\.\d+)?\b"
                
                
                data_read = list()
                
                for lines in good_lines:
                    
                    temp = re.findall(read_format,lines)
                    if len(temp)>0:
                        
                        tmp_dict = deepcopy(data)
                        for n,(temp_value,key) in enumerate(zip(temp,data.keys())):
                            
                            tmp_dict[key]=temp_value
                        
                        data_read.append(tmp_dict)
                            
                    else:
                        if verbose is True:
                            print("Error: Linea de archivo no leida.")
                        
                    
                ###RE_JROFILE = r"(?P<optchar>[dDpP]{1})(?P<year>[0-9]{4})(?P<doy>[0-9]{3})(?P<set>[0-9]{3})\.(?P<ext>[^.]+)"
            
            
            cabecera_final = 18
            
            size_data = good_lines.shape[0] 
            file_data = numpy.empty(size_data+cabecera_final,dtype='object')
            
            
            ######################
            # Rellenando datos
            ######################
            
            
            str_tmp1    =   ' '*(62-len(self.GMS[self.system['gms']]['name']))
            
            file_data[0]          =  ' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
            file_data[1]          =  ' Source of Data         Huancayo Magnetic Observatory, IGP                            |'
            file_data[2]          =  ' Station Name           {}{}|'.format(self.GMS[self.system['gms']]['name'].upper(),str_tmp1)
            file_data[3]          =  ' IAGA CODE              {}{}|'.format(self.GMS[self.system['gms']]['code'].upper())+'                                                           |'           
            file_data[4]          =  ' Geodetic Latitude      {:8.3f}{}|'.format(self.GMS[self.system['gms']]['latitude'],'                                                      |')
            file_data[5]          =  ' Geodetic Longitude     {:8.3f}{}|'.format(self.GMS[self.system['gms']]['longitude'],'                                                      |')
            file_data[6]          =  ' Elevation              {:6.1f}{}|'.format(self.GMS[self.system['gms']]['elevation'],'                                                        |')
            file_data[7]          =  ' Reported               DHZF                                                          |'
            file_data[8]          =  ' Sensor Orientation     variation:DHZF                                                |'
            file_data[9]          =  ' Digital Sampling       1 seconds                                                     |'
            file_data[10]         =  ' Data Interval Type     Filtered 1-minute (00:00 - 00:59)                             |'
            file_data[11]         =  ' Data Type              Reported                                                      |'
            file_data[12]         =  ' # Element              Geomagnetic field                                             |'
            file_data[13]         =  ' # Unit                 D(eastward+):minute, H:nT, Z(downward+):nT, F:nT              |'
            file_data[14]         =  ' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
            file_data[15]         =  ' # URL                  http://www.lance.unam.mx                                      |'
            file_data[16]         =  ' # Last Modified        Jan 25 2021                                                   |'            
            
            
            file_data[17]         =   'DATE       TIME         DOY      {}D     {}H       {}Z     {}F                    |'.format(self.GMS[self.system['gms']]['code'].upper(),\
                                                                                                                                   self.GMS[self.system['gms']]['code'].upper(),\
                                                                                                                                   self.GMS[self.system['gms']]['code'].upper(),\
                                                                                                                                   self.GMS[self.system['gms']]['code'].upper())
            
            for ix in range(good_lines):
                
                formato = '{:4d}-{:2d}-{:2d} {:2d}:{:2d}:00.000 {:3d}     {:8.2f}  {:8.2f}  {:8.2f}  {:8.2f}  {:8.2f}'
                
                payload = formato.format(data_read[ix]['year'],data_read[ix]['month'],data_read[ix]['day'],\
                                                    data_read[i]['hour'],data_read[i]['minute'],tmp_doy, \
                                                     data_read[i]['D']*60.,data_read[i]['H'], \
                                                     data_read[i]['Z'],data_read[i]['F'])
                
                file_data[ix + cabecera_final]  = payload
                
            
            fname_data = os.path.join(self.GMS[self.system['gms']]['code'],'{:4d}{:2d}{:2d}.rK.min'.format(tmp_year,tmp_month,tmp_day))
            fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],fname_data)
            
            exists_data_file = os.path.exists(fpath)
            
            if exists_data_file:
                
                #el archivo existe
                if verbose:
                    print("El archivo existe y va a ser sobreescrito.")
                
            else:
                
                if verbose:
                    print("El archivo se guarda en {}.".format(fpath))
                    
                    
            with open(fpath,'w') as archivo:
             
                archivo.writelines(file_data)
                        

        
        except:
            print("Sucedió algo en making_magneticdatafile.")
            
            
                   
    def __quietdays_download(self,initial,final, station=None,\
                            verbose=False, force_all=False):
        #script -> geomagixs_quietdays_download.pro
        #falta

        try:
            update_flag=0
            
            
            #########
            # En IDL:
            #[YYYY, MM, DD] , initial date and time at which the data is read from
            # En python es el objeto datetime
            initial_date  = initial
            
            final_date = final
            
            files_number = int((final_date.year % 1000)-(initial_date % 1000))/10 +1
            
            
            if verbose is True:
                print("Un total de {} archivos van a ser reescritos.\
                    Data previamente guardada será permanentemente borrado si procede." )
            
            proceed = 'Y'
            
            if proceed =='Y':
                
                files_source_name_k         =   numpy.empty(files_number,dtype='object')
                directories_source_name     =   numpy.empty(files_number,dtype='object')
                directories_destiny_name    =   numpy.empty(files_number)
                terminal_results_k          =   numpy.empty(files_number,dtype='object')
                terminal_errors_k           =   numpy.empty(files_number,dtype='object')
            
            count_saved = 0
            count_failed = 0
            
            buff_fsave = list()
            buff_year  = list()
            
            for i in range(files_number):
                
                
                tmp_millenium = int(initial_date.year/1000)
                tmp_century   = int((initial_date.year % 1000)/100)*100
                tmp_decade    = int(((initial_date.year % 1000) % 100)/10+i)*10
                
                tmp_year   = tmp_millenium + tmp_century + tmp_decade 
                
                today_julian = JULDAY(self.system['today_date'])
                tmp_j0      =   JULDAY(datetime(tmp_year,1,1))
                tmp_j1      =   JULDAY(datetime(tmp_year+9,12,31))
                
                if ((today_julian >= tmp_j0) and (today_julian <= tmp_j1)):
                    
                    files_source_name_k [i] = 'qd{:4d}{:1d}x.txt'.format(tmp_year,int(tmp_decade/10))
                else:    
                    files_source_name_k [i] = 'qd{:4d}{:2d}.txt'.format(tmp_year,tmp_decade+9)

                directories_source_name[i]  = 'ftp://ftp.gfz-potsdam.de/pub/home/obs/kp-ap/quietdst/'
                directories_destiny_name[i] = self.system['qdays_dir']
                
                
                if verbose is True:
                    
                    print("Copiando archivo {}-decade.".format(tmp_year))
 
                fdownload = os.path.join(directories_source_name[i],files_source_name_k[i])
                fsave     = os.path.join(directories_destiny_name[i],files_source_name_k[i])
                
                
                
                try:
                    urllib.request.urlretrieve(url, archivo_destino)
                except IOError as e:
                    count_failed+=1
                else:
                    count_saved+=1
                    buff_fsave.append(fsave)
                    buff_year.append(tmp_year)
                    
            
            if verbose is True:
                
                if count_saved>0:
                    print("Un total de {} [qdYYY0yy.txt] archivos fueron guardados.".format(count_saved))
                if count_failed>0:
                    print("No se pudieron guardar {} 'qdYYY0yy.txt archivos.".format(count_failed))
            
            
            #################################################################################################        
            #QD DATA section
            #################################################################################################        
            
            if (count_saved==0):
                
                SystemError("No se pudo descargar algún archivo [qdYYY0yy.txt].")
            
            ###############################################################################
            # Format Quiet Days
            #                                     Quietest Days                 Most Disturbed Days
            # Month
            #             Q1  Q2  Q3  Q4  Q5    Q6  Q7  Q8  Q9  Q10   D1  D2  D3  D4  D5

            # Jan 2020   20  19  14  24  13    27   2  17   1  12    30*  9*  5* 29*  6*
            # Feb 2020   13  25  14  27  16    26   3  24  10   5     6*  7* 21* 18* 19*
            
            
            years = numpy.array(buff_year)
            
            
            qdays_initial_year = numpy.min(years)
            qdays_final_year = numpy.max(years)
            
            
            index_dates   = numpy.zeros(6)        
            
            
            if os.access()
            
            
            ##En las siguientes lineas se resume en generar un .date con 
            # la fecha inicial y final 
            #falta
            
                
                
                    
                    
                
                
            
        except:
            
            print("Ocurrio un error en el modulo quietdays_download.")
        
        

    def __setup_dates(self,update_file=None,station=None, quiet=False, force_all=False):
        #script -> geomagixs_setup_dates.pro
        #falta
        ###############################################
        ###variables
        ###
        ###############################################
        
        index_dates     =   numpy.zeros(6)
        index_dates_0   =   numpy.zeros(6)
        magnetic_dates  =   numpy.zeros(6)
        magnetic_dates1 =   numpy.zeros(6)
        magnetic_dates2 =   numpy.zeros(6)
        
        if ((self.Flag_dates is True) and (update_file is None) and (force_all is False)):
            return 
        
        fpath=os.path.join(self.system['auxiliar_dir'],self.GMS[self.system['gms']]['name']+'.dates')

        if os.access(fpath,os.R_OK):

            if quiet is True:
                print("Error critico: No es posible leer el archivo de datos GSM {}. \
                      Revisa los permisos de lectura.".format(self.GMS[self.system['gms']]['name']+'.dates'))

            self.Error['value'][0]+=1
            self.Error['log']+='GMS file '+self.GMS[self.system['gms']]['name']+'.dates'+' not found or reading permission conflict.  Use /update_file to fix it.'
        
        else:
            fpath = self.system['auxiliar_dir']
            fname = self.GMS[self.system['gms']]['name']+'.dates'
            
            fpath = os.path.join(fpath,fname)
            
            file = file_search(fname,fpath)
            
            #revisar
            if file and (update_file is True):
                #archivo encontrado 
                
                buff_array=list()
                with open(file,'r') as f:
                    for line in f.readlines():
                        if line[0]!="#":
                            buff_array.append(line)
                
                    f.close()
                
                for n in range(3):
                    
                    tmp = [str(int(x)).zfill(6) for x in buff_array[n].strip("- ").split()]
                    tmp = numpy.array([(int(tmp[x][:4]),int(tmp[x][4:6]),int(tmp[x][6:8])) for x in [0,1]])
                    
                    if n==0:
                        index_dates = tmp 
                    elif n==1:
                        index_dates_0 = tmp
                    elif n==2:
                        magnetic_dates = tmp
                    
                
                
                if quiet is True:
                    print("Data cargada de {}.dates file".format(self.GMS[self.system['gms']]['name']))
            
            else:
                if (update_file is True):
                    if quiet is True:
                        print("Warning: Imposible de leer archivos de datos GMS. {}.\
                            Se está intentando generar el archivo.".format(self.GMS[self.system['gms']]['name']))
                    
                    self.Error['value'][3]+=1
                    self.Error['log']+= 'Input data file '+self.GMS[self.system['gms']]['name']+'.dates'+' not found or reading permission conflict. '
                    
                    
            if (self.GMS[self.system['gms']]['name']!="planetary"):
                
                fpath = os.path.join(self.system['indexes_dir'] ,self.GMS[self.system['gms']]['name'])
                fname = self.GMS[self.system['gms']]['code']+'_????????.k_index.early'
                
                fpath = os.path.join(fpath,fname) 
                
                #buscamos archivos con el mismo patron
                file_list = glob(fpath)   
                
                
                directory = os.path.join(os.path.expanduser("~"), "output", "data")
                
                directory = os.path.join(os.path.expanduser("~"),self.system['indexes_dir'],\
                                        self.GMS[self.system['gms']]['name'])
                #en este caso, el codigo idl nos proporciona un directorio
                file_list = os.listdir(directory)
                str_len1 = 
                
                ## no sé que es esta parte 
                # falta linea  150 -> 
                
            
                        
                
                
            
 
            
            
            

    def __check_gms(self,station=None,quiet=False,force_all=False):
        #script -> geomaxis_check_gms.pro
        #está listo
        
        try:
            
            if (len(station)==0):
                station = self.GMS[self.system['gms']]['name']

                if quiet is True:
                    print('Configurando'+self.GMS[self.system['gms']]['name']+'como\
                          la estación GMS por defecto.')
                    
            else:
                station = list(map(str.lower, station))
                
                if len(station)==1:
                    for element in station:

                        codes = [dict_['codes'] for dict_ in self.GSM]
                        names = [dict_['name'] for dict_ in self.GSM]

                        ind1    =   numpy.where(codes==element)[0]
                        ind2    =   numpy.where(names==element)[0]

                        if (((ind1<0 and ind2<0)) or ((ind1>= ind2) and(ind2>= self.system['gms_total']))):
                            
                            if quiet is True:
                                print("Error critico: GMS seleccionado {} no está disponible.\
                                    Revisa la lista de GMS disponibles.".format(station))
                                
                            self.Error['value'][2]+=1
                            self.Error['log']+='Selected GMS is not available or correctly installed. '

                            return 
                        else:
                            station_number = ind1 if ind1 >= 0 else ind2

                            self.system['gms'] = station_number
                            station=self.GMS[self.system['gms']]['name']
                            
                            if (quiet is True) and (self.GMS[self.system['gms']]['check_flag']==0):

                                print('Configurando ',self.GMS[self.system['gms']]['name'], 'como estación GMS.')

            if (force_all is True) and (self.GMS[self.system['gms']]['check_flag']!=0):
                return 
            
            if self.GMS[self.system['gms']]['name']!= "planetary":
                fpath = os.path.join(self.system['auxiliar_dir'],self.GMS[self.system['gms']]['name']+".calibration")

                if os.access(fpath,os.R_OK) is False:

                    if quiet is True:

                        print("Error critico: Incapaz de leer archivo auxiliar {}. Es obligatorio otorgar los permisos de lectura.".format(self.GMS[self.system['gms']]['name']+".calibration"))



                    self.Error["value"][0]+=1
                    self.Error['log']+="Auxiliar file  "+self.GMS[self.system['gms']]['name']+ '.calibration'+" not found or read permissions conflict. "


                tmp_calibration = ReadCalibration()
                self.GMS[self.system['gms']]['calibration']  = tmp_calibration

            

            ###########################################################################
            fpath=os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'])
            if os.access(fpath,os.R_OK) is False:
                if quiet is False:

                    print("Error crítico: Incapaz de leer el directorio {}. Es obligatorio permisos de lectura dentro del directorio.".format(fpath))
                
                self.Error['value'][0]+=1
                self.Error['log']+='Input directory  '+fpath+' not found or read permissions conflict. '
            

            ##

            fpath=os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])
            if os.access(fpath,os.W_OK) is False:
                if quiet is False:

                    print("Error crítico: Incapaz de escribir el directorio {}. Es obligatorio permisos de lectura dentro del directorio.".format(fpath))
                
                self.Error['value'][0]+=1
                self.Error['log']+='Output directory  '+fpath+' not found or read permissions conflict. '

            
            ##
            fpath=os.path.join(self.system['plots_dir'],self.GMS[self.system['gms']]['name'])

            if os.access(fpath,os.W_OK) is False:
                if quiet is False:

                    print("Error crítico: Incapaz de escribir el directorio {}. Es obligatorio permisos de lectura dentro del directorio.".format(fpath))
                
                self.Error['value'][0]+=1
                self.Error['log']+='Output directory  '+fpath+' not found or read permissions conflict. '

            ##
            fpath=os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])
            
            if os.access(fpath,os.W_OK) is False:
                if quiet is False:

                    print("Error crítico: Incapaz de escribir el directorio {}. Es obligatorio permisos de lectura dentro del directorio.".format(fpath))
                
                self.Error['value'][0]+=1
                self.Error['log']+='Output directory  '+fpath+' not found or read permissions conflict. '
           

            self.GMS[self.system['gms']]['check_flag']=1
        

            if quiet is False:
                print("Estación geomagnetica {} está listo".format(self.GMS[self.system['gms']]['name']))

        except:
            print("Ocurrió un error en el método __check_gms()")





    def __check_system(self,quiet=False):
        # archivo ->geomagixs_check_system.pro
        # funcion -> geomagixs_check_system
        #Transcripcion completada

        try:
            if(self.Flag_system == False):

                self.Flag_system = True

                if (self.system['geomagixs_dir'] == ''):
                    os.chdir(os.getcwd())
                    self.system['geomagixs_dir']=os.getcwd()
                #revisar tmp

                if(self.system['setup_file'] == ''):
                    self.system['setup_file']='setup.config'


                if not os.path.isfile(os.path.join(self.system['geomagixs_dir'], self.system['setup_file'])) \
                      or not os.access(os.path.join(self.system['geomagixs_dir'], self.system['setup_file']), \
                                       os.R_OK):
                    
                    if quiet is True:
                        print("Error critico: setup file, 'A' no ha sido encontrado.",self.system['setup_file'],\
                              "Imposible leer system-congif data.")
                        
                    self.Error['value'][0]+=1
                    self.Error['log']+='Setup file '+self.system['setup_file']+' \
                                       not found or reading permission conflict. '
                    

                    return 

                with open(os.path.join(self.system['geomagixs_dir'],self.system['setup_file']),'r') as file:
                        
                        buff_array= list()

                        if quiet is True:
                              
                            print("Leyendo datos del fichero: {}".format(self.system['setup_file']))
                        #modificacion, solo se lee las lineas que empiezan con "~"
                        for linea in file.readlines():
                            if ('~' in linea) and (not("#" in linea)):
                                #guardamos los tres archivos de configuración
                                buff_array.append(linea)

                            
                        #verificamos que se guardó 3 datos

                        if (len(buff_array)!=3):
                            if quiet is True:

                                print("Error critico: Revisar fichero {}, es imposible de leer datos\
                                       del archivo de configuracion.".format(self.system['setupfile']))
                                
                            self.Error['value'][0]+=1
                            self.Error['log']+="El formato de {} no está segun el estandar.".format(self.system['setupfile'])
                        
                        else:
                            
                            input_dir   = buff_array[0]
                            
                            if quiet is True:
                                print("Revisando arbol del directorio {}".format(input_dir))

                            if os.access(input_dir, os.R_OK) is False:
                                #No se tiene permisos para escribir

                                if quiet is True:
                                    print("Error critico: Imposible de leer la carpeta 'input' del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          lectura del directorio 'input'".format(input_dir))
                                
                                self.Error['value'][0]+=1
                                self.Error['log']+='Input directory '+input_dir+' not found or reading permission conflict. '

                            
                            self.system['input_dir']=input_dir

                            #revisamos si tiene permisos la carpeta auxiliar

                            auxiliar_dir = buff_array[1]

                            if os.access(auxiliar_dir, os.R_OK) is False:

                                if quiet is True:
                                    print("Error critico: Imposible de leer la carpeta 'auxiliar' del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          lectura del directorio 'auxiliar'".format(auxiliar_dir))
                                    

                                self.Error['value'][0]+=1
                                self.Error['log']+='Auxiliar directory '+input_dir+' not found or reading permission conflict. '



                            self.system['auxiliar_dir']=auxiliar_dir

                            ###datasource_dir

                            #Carpeta con datos magneticos
 

                            self.system['datasource_dir']=os.path.join(self.system['input_dir'],"data_source") \
                                                            if (self.system['datasource_dir'] == '') \
                                                            else  os.path.join(self.system['input_dir'],self.system['datasource_dir'])
                            

                            if os.access(self.system['datasource_dir'], os.R_OK) is False:
                                

                                if quiet is True:
                                    print("Error critico: Imposible de leer la carpeta 'auxiliar' del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          lectura del directorio 'auxiliar'".format(self.system['datasource_dir']))
                                    
                                self.Error['value'][0]+=1

                                self.Error['log']+='Magnetic data source directory '+self.system['datasource_dir']+' not found or read permission conflict. '



                            #file qdays
                        

                            self.system['qdays_dir']=os.path.join(self.system['datasource_dir'],"qdays") \
                                                            if (self.system['datasource_dir'] == '') \
                                                            else  os.path.join(self.system['datasource_dir'],self.system['qdays_dir'])
                            

                            if os.access(self.system['qdays_dir'], os.R_OK) is False:

                                if quiet is True:

                                    print("Error critico: Imposible de leer la carpeta 'qdays' del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          lectura del directorio 'qdays'".format(self.system['qdays_dir']))
                                    
                                self.Error['value'][0]+=1
                                self.Error['log']+= 'Input data directory '+self.system['qdays_dir']+' not found or read permission conflict. '

                            #comprobamos permisos de escritura para el directorio de salida
                            # 
                            #     
                            output_dir = buff_array[2]


                            if quiet is True:
                                print('Revisando arbol del directorio de salida {}.'.format(self.system['output_dir']))

                            if os.access(output_dir, os.R_OK) is False:

                                if quiet is True:

                                    print("Error critico: Imposible de leer la carpeta 'output' del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          lectura del directorio 'output'".format(output_dir))
                                    
                                self.Error['value'][0]+=1
                                self.Error['log']+= 'Input data directory '+output_dir+' not found or read permission conflict. '

                            
                            self.system['output_dir']=output_dir

                            ####

                            self.system['indexes_dir']=os.path.join(self.system['output_dir'],"indexes") \
                                                            if (self.system['indexes_dir'] == '') \
                                                            else  os.path.join(self.system['output_dir'],self.system['indexes'])

                            
                            if os.access(self.system['indexes_dir'], os.R_OK) is False:

                                if quiet is True:

                                    print("Error critico: Imposible de leer la carpeta 'indexes_directory' del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          lectura del directorio 'indexes_directory'".format(self.system['indexes_dir']))
                                    
                                self.Error['value'][0]+=1
                                self.Error['log']+= 'Computed indexes directory '+self.system['indexes_dir']+' not found or writing permission conflict. '
                            
                            ######

                            self.system['plots_dir']=os.path.join(self.system['output_dir'],"plots") \
                                                            if (self.system['plots_dir'] == '') \
                                                            else  os.path.join(self.system['output_dir'],self.system['plots_dir'])
                                
                            if os.access(self.system['plots_dir'], os.W_OK) is False:
                                
                                if quiet is True:

                                    print("Error critico: Imposible de poder escribir la carpeta 'plots' del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          escritura del directorio 'plots'".format(self.system['plots_dir']))
                                    
                                self.Error['value'][0]+=1
                                self.Error['log']+= 'Plots directory '+self.system['plots_dir']+' not found or writing permission conflict. '

                            
                            ######                            

                            self.system['procesed_dir']=os.path.join(self.system['output_dir'],"processed") \
                                                            if (self.system['procesed_dir'] == '') \
                                                            else  os.path.join(self.system['output_dir'],self.system['processed_dir'])
                                
                            if os.access(self.system['plots_dir'], os.W_OK) is False:
                                
                                if quiet is True:

                                    print("Error critico: Imposible de poder escribir la carpeta 'plots' del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          escritura del directorio 'plots'".format(self.system['plots_dir']))
                                    
                                self.Error['value'][0]+=1
                                self.Error['log']+= 'Processed files directory '+self.system['processed_dir']+' not found or writing permission conflict. '



                            ######################################################################################

                            if (self.system['gms'] == ''): self.system['gms']='gms.config'

                            if os.access(os.path.join(self.system['geomagixs_dir'],self.system['gms_file']),os.R_OK) is False:
                                

                                if quiet is True:

                                    print("Error critico: Imposible de leer GMS data del \
                                          directorio '{}'. Es obligatorio conceder los permisos de \
                                          escritura del directorio 'plots'".format(self.system['gms_file']))
                                    
                                self.Error['value'][0]+=1
                                self.Error['log']+= 'GMS File'+self.system['gms_file']+' not found or reading permission conflict. '

                            
                            else:
                                #abrimos archivo gms.config file

                                with open(os.path.join(self.system['geomagixs_dir'],self.system['gms_file']),'r') as file:

                                    buff_array = list()

                                    for linea in file.readlines():
                                        
                                        if linea[0]!='#':
                                            buff_array.append(linea)
                                    

                                #el archivo acepta multiples configuraciones, en tuplas de 5 

                                if (len(buff_array) % 5 !=0):

                                    if quiet is True:
                                        print("Error critico: Formato erroneo de {}. Imposible leer datade \
                                               file .gms".format(self.system['gms_file']))

                                    self.Error['value'][0]+=1
                                    self.Error['log']+="Formato de "+ self.system['gms_file']+" archivo corrupto o falta de datos."


                                else:

                                    #archivo correcto 
                                    # 
                                    # 
                                    self.system['gms_total']=int(len(buff_array)/5)

                                    #estructura diccionario 

                                    gms_structure = {
                                                'name'        : '',
                                                'code'        : '',
                                                'latitude'    : 0.,
                                                'longitude'   : 0.,
                                                'elevation'   : 0.,
                                                'calibration' : numpy.zeros(28,dtype=numpy.float64),
                                                'data_index'  :  numpy.zeros((4,3)),
                                                'dates_data'  : numpy.zeros((2,3)), #[datetime initial, datetime final]
                                                'base_line'   : numpy.zeros(3),   # [D,H,Z]
                                                'check_flag'  : 0 
                                    }
                                    
                                    self.GMS = list()

                                    for n in range(self.system['gms_total']):


                                        buff = deepcopy(gms_structure)


                                        buff['name']= buff_array[n*5]
                                        buff['code']= buff_array[n*5+1]
                                        buff['latitude']= float(buff_array[n*5+2])
                                        buff['longitude']= float(buff_array[n*5+3])
                                        buff['elevation']= float(buff_array[n*5+4])


                                        self.GMS.append(buff)

                            if ((len(self.system['ftp_address'])*len(self.system['ftp_user'])<=0) and\
                                 (self.system['ftp_on'])>=1):
                                
                                if quiet  is True:

                                    print("Critical Error: Conflicto con la data entrante. Data del FTP server\
                                          es inconsistente o invalido. Imposible de descargar data del servidor FTP.")
                                
                                self.Error['value'][0]+=1
                                self.Error['log']+='Missing user or/and address for FTP server; impossible to download data. '
                            
            
            else:
                return

        except:

            print("Algo salio mal en el método '{}'".format(self.__check_system.__name__))

            return 


    def __setup__commons(self,quiet=False):

        #archivo -> geomagixs_setup.pro
        #funcion -> PRO geomagixs_setup_commons, QUIET=quiet
        #revisar si está terminado


        if(self.Flag_setup == False):

            if (quiet is True):

                print("Configurando ...")
            
            #------- - Variables comunes -----
            #de geomagixs_commons.pro
            self.Flag_commons=True
            self.Flag_dates=False
            self.Flag_error=False
            self.Flag_system=False
            #----------------------------------

            error_message = ['Critical Error: Missing or corrupted system file(s) or directory(ies). Review your installation or check out directory tree and location of data files.', 
                            'Critical Error: Impossible to save (read) output (input) file(s). Missing directories or permissions conflict.',
                            'Critical Error: Conflict with input data. Data inconsistent or invalid.', 
                            'Input Warning: Invalid values or values out of the range, proceeding with predefined values and replacing conflictive values with data gaps.', 
                            'Inconsistency Warning: the requested conditions may compromise the computed results.' ]


            self.Error  =   { 
                'message': error_message,
                'value':   numpy.zeros(int(len(error_message))),
                'critical':0,
                'log':''
            }


            self.system = {
                'output_dir' : '',
                'input_dir'         : '',   # input data directory, if blank the $HOME directory is used.
                'datasource_dir'    : 'data_source',  # input data directory, if blank the $HOME directory is used.
                'auxiliar_dir'      : '',  #input data directory, if blank the $HOME directory is used.
                'indexes_dir'       : 'indexes',  # input data directory, if blank the $HOME directory is used.
                'qdays_dir'         : 'qdays',  # input data directory, if blank the $HOME directory is used.
                'plots_dir'         : 'plots', #input data directory, if blank the $HOME directory is used.
                'processed_dir'     : 'processed',  # input data directory, if blank the $HOME directory is used.
                'geomagixs_dir'     : '$HOME/GDL/geomagixs', # input data directory, if blank the $HOME directory is used.
                'gms_file'          : 'gms.config',  # input data file
                'gms'               : 2, # 0: planetary, 1: Perú, 2: Huancayo, 3: auxiliar-no definided
                'gms_total'         : 0,  
                'setup_file'        : '', # setup data file
                'log'               : '',   
                'qdays_dates'       : numpy.zeros((2,3)), 
                'today_date'        : None, 
                'contact1_mail'     : '',  
                'contact2_mail'     : 'armando.castro.c@uni.pe',  
                'ssh_on'            : 0,#ssh Activated [1] Not Activated [0] 
                'ftp_on'            : 1, # ftp Activated [1] Not Activated [0]
                'ftp_ip'            : '132.248.208.46', 
                'ftp_address'       : 'sftp://132.248.208.46/data/' , 
                'ftp_user'          : 'regmex', 
                'ftp_password'      : 'r3gm3x-m0r3l14', 
                'version'           : '1.2', 
                'date'              : '2022/08/22' 
            }


            #----- Revisar el directorio actual y que quiere simbolizar
            #spawn, 'echo $GEOMAGIXS_DIR', result
            #
            #
            #
            #
            self.system['geomagixs_dir']=os.getcwd()

            self.system['today_date'] = datetime.now().time()
            


            self.Flag_setup =True


         #final 

    
        


        
