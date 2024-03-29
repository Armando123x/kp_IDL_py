#geomagixs_setup_commons.pro

'''
Algunas funciones astronomicas de IDL en python
-----------------------------------------------
https://github.com/sczesla/PyAstronomy/blob/master/src/pyasl/asl/astroTimeLegacy.py

Puedes revisar el formato IAGA-2002 para el compartimiento de archivos
----------------------------------------------------------------------
https://www.ngdc.noaa.gov/IAGA/vdat/IAGA2002/iaga2002format.html


''' 
import re
import os 
import gc
import numpy
import subprocess

from copy import deepcopy
from scipy.interpolate import splrep,splev
from scipy.signal import savgol_filter
from datetime import datetime,timedelta

import urllib.request
 
from glob import glob
import pytz

from utils import *

from dateutil.relativedelta import relativedelta
#######################################################################333
##### Parametro quiet en IDL  es practicamente verbose en Python
#####
#####
#####
########################################################################


 
    

 

 
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
 
        # Se define la funcion geomagixs.pro
   
 
            ##########################################################
            ### Presentación
            #
            hoy = datetime.now()
            print("###########################")
            print("Iniciamos el sistema")
            print("Tiempo local: {:4.0f}/{:02.0f}/{:02.0f} {:02.0f}:{:02.0f}".format(hoy.year,hoy.month,hoy.day,hoy.hour,hoy.minute))
            hoy = datetime.now(pytz.UTC)
            print("Tiempo UTC: {:4.0f}/{:02.0f}/{:02.0f} {:02.0f}:{:02.0f}".format(hoy.year,hoy.month,hoy.day,hoy.hour,hoy.minute))
            print("###########################")
            

            verbose= kwargs.get('verbose',False)
            force_all = kwargs.get('force_all',False)
            real_time = kwargs.get('real_time',False)
            station  = kwargs.get("station",None)
            working_dir =   kwargs.get('working_dir','')

            initial_date = kwargs.get('initial_date',None)
            final_date = kwargs.get('final_date',None)
            update_file = kwargs.get("update_file",None)

            #############################################################
            print("\n\n###########################")
            print("###########################")

            print("Verbose está en modo {}".format(verbose))
            print("Force_all está en modo {}".format(force_all))
            print("Real_time está en modo {}".format(real_time))
            print("Estación definida {}".format(station))
            print("###########################")
            print("###########################")

            ##############################################################
      

 

            kwargs['station'] = station
          

 
            
            self.__setup__commons(**kwargs)
            self.__check_system(**kwargs)

            #falta
            #falta asegurar que datos sean string
            self.__check_gms(station=station)

            kwargs['station'] = station

            self.__setup_dates(**kwargs)
                               
            self.__quietdays_download(initial=initial_date,final= final_date,**kwargs)
            

            #########################################
            ### Actualizando archivos 
            
            self.__quietdays_download(initial_date,final_date,**kwargs)
            self.__magneticdata_download(initial_date,final_date,**kwargs)
            self.__magneticdata_prepare(initial_date,final_date,**kwargs)
            self.__magneticdata_process(initial_date,final_date,**kwargs)

            #################################################
            # CARGANDO DATOS

            self.__magneticindex_compute(initial_date,final_date,**kwargs)
            
            self.__magneticindex_monthlyfile(initial_date,final_date,**kwargs)


            self.__setup_dates(**kwargs)
            #######
            # No se define los scripts de ploteo
            # geomagixs_magneticindex_plotk, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
                
            # 	geomagixs_magneticindex_plotdh, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
                    
            # 	geomagixs_magneticindex_plotb, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
            
            ####################################3

            datatype = 'realtime' if real_time else 'final'

            datatype = '' if self.GMS[self.system['gms']]['code'] == 'pla' else datatype

            if real_time:
                extention = '' if self.GMS[self.system['gms']]['code'] == 'pla' else '.early'


                result = datetime.now()

                Y,M,D = result.year,result.month,result.day
                name = '{}_{:4.0f}{:02.0f}'.format(self.GMS[self.system['gms']]['code'],Y,M)

                dst_month_file = '{}.delta_H{}'.format(name,extention)
                kmex_monthly_file = '{}.k_index{}'.format(name,extention)
                
                fpath = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],dst_month_file)
                ftopath = os.path.join("/publicdata/",self.GMS[self.system['gms']]['name'],datatype+dst_month_file,)
                command = "sshpass -p {} scp {} {}@{}:".format(self.system['ftp_password'],fpath,self.system['ftp_user'],ftopath)

                execute_command(command)                    

                fpath = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],kmex_monthly_file)
                ftopath = os.path.join("/publicdata/",self.GMS[self.system['gms']]['name'],datatype+kmex_monthly_file,)
                command = "sshpass -p {} scp {} {}@{}:".format(self.system['ftp_password'],fpath,self.system['ftp_user'],ftopath)

                execute_command(command)              


                result = JULDAY(final_date) - 6 
                result = CALDAT(result)

                tmp_y,tmp_m,tmp_d = result.year , result.month, result.day

                if self.GMS[self.system['gms']]['code'] == 'pla':
                    dst_today_plot = '{}_{:4.0f}{:02.0f}{:02.0f}_07days.dH.png'.format(self.GMS[self.system['gms']]['code'],tmp_y,tmp_m,tmp_d)
                    kmex_today_plot = '{}_{:4.0f}{:02.0f}{:02.0f}_07days.k.png'.format(self.GMS[self.system['gms']]['code'],tmp_y,tmp_m,tmp_d)

                    dst_latest_plot  = 'latest_dst.png'
                    kmex_latest_plot = 'latest_kp.png'

                else:
                    dst_today_plot = '{}_{:4.0f}{:02.0f}{:02.0f}_07days.dH.early.png'.format(self.GMS[self.system['gms']]['code'],tmp_y,tmp_m,tmp_d)
                    kmex_today_plot = '{}_{:4.0f}{:02.0f}{:02.0f}_07days.k.early.png'.format(self.GMS[self.system['gms']]['code'],tmp_y,tmp_m,tmp_d)
                    profiles_today_plot = '{}_{:4.0f}{:02.0f}{:02.0f}_07days.B.early.png'.format(self.GMS[self.system['gms']]['code'],tmp_y,tmp_m,tmp_d)

                    dst_latest_plot     = 'latest_{}_dh.png'.format(self.GMS[self.system['gms']]['code'])
                    kmex_latest_plot    = 'latest_{}_k.png'.format(self.GMS[self.system['gms']]['code'])
                    profile_latest_plot = 'latest_{}_B.png'.format(self.GMS[self.system['gms']]['code'])
                


                #### Se envia los archivos png por ftp, pero no se implementa.
    
    

 
    def __ReadCalibration(self,):

        calibration_name = os.path.join(self.system['auxiliar_dir'],self.GMS[self.system['gms']]['name']+'.calibration')

        exists = os.path.isfile(calibration_name)

        if not exists:
            print("Archivos de calibración no ha sido encontrado.")

            return 
        
        result = numpy.empty(28,dtype=float)

        dat_str = {'z':0}
        
        tmp_var = numpy.empty(28, dtype=object)
        tmp_var = fill(tmp_var,dat_str)

 

        with open(calibration_name,'r') as file:
            buff = file.read().splitlines() 
            for linea in buff:
                valores = re.findall(r'-?\d+\.?\d*', linea)
                # Convertir los valores a enteros o números de punto flotante según corresponda
                valores = [int(v) if v.isdigit() else float(v) for v in valores]

                if len(valores)>10:
                    result = numpy.array(valores)
                else:
                    result = numpy.zeros(8)

        return result 
                                            
        



    def __getting_deltab(self,initial,**kwargs):

        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get('real_time',False)

        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day

        keys = ['hour','Max_D','Min_D','sigma_D','delta_D','Max_H','Min_H','sigma_H','delta_H',
                'Max_Z','Min_Z','sigma_Z','delta_Z','Max_F','Min_F','sigma_F','delta_F','Max_N','Min_N',
                'sigma_N','delta_N']

        struct = dict.fromkeys(keys,0)

        hour = [0,3,6,9,12,15,18,21]

        read_data = numpy.empty(8,dtype='object')
        read_data = fill(read_data,struct)
   

        for n,_ in enumerate(read_data):
            for key in keys:   

                if key =='hour':  
                    read_data[n][key]  = hour[n]
                elif key in ['Max_D','Min_D','sigma_D','delta_D']:
                    read_data[n][key] = 9999
                else:
                    read_data[n][key] = 999999

        file_kind = '.early' if real_time else '.final'

        file_name = '{}_{:4.0f}{:02.0f}{:02.0f}.differences{}'.format(self.GMS[self.system['gms']]['code'],initial_year, initial_month, initial_day,file_kind)

        fpath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],file_name)

        exists = os.path.exists(fpath)

        if exists is True:

            with open(fpath,'r') as file:
                magnetic_data = file.read().splitlines() 
                magnetic_data = numpy.array(magnetic_data,dtype='object')
                

                for n,linea in enumerate(magnetic_data):
                    valores = re.findall(r'-?\d+\.?\d*', linea)

                        # Convertir los valores a enteros o números de punto flotante según corresponda
                    valores = [int(v) if v.isdigit() else float(v) for v in valores]
                    
                    if len(valores)>0:
                      
                        for key,valor in zip(keys,valores):
                            read_data[n][key] = valor
        else:
            if verbose:
                print("El archivo para extraer differencer no existe", fpath)
        
        result = dict.fromkeys(keys,0)

        for key in result.keys():
            result[key] = deepcopy(vectorize(read_data,key))


        return result 

                    
                
    def __getting_deltah(self,initial,**kwargs):

        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get('real_time',False)

        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day
#  [1440, 23, 59, 
#   -247.98, 24703.51, -624.51, 24711.41, 
#   -247.16, 24712.57, -629.5, 24726.87, -1779.84, 
#   -247.53, 24692.36, -624.8, 24706.1, -3567.02, 
#   -1.09, -19.13, 6.36, -19.23, -5.24]
        struct = {'i','hour','minute',
                  'D','H','Z','F',
                  'D_median','H_median','Z_median','F_median','N_median',
                  'D_sigma','sigma_H','Z_sigma','F_sigma','N_sigma',
                  'd_D','delta_H','d_Z','d_F','d_N'}

        struct = dict.fromkeys(struct,0)

        keys_array = ['i','hour','minute',
                  'D','H','Z','F',
                  'D_median','H_median','Z_median','F_median','N_median',
                  'D_sigma','sigma_H','Z_sigma','F_sigma','N_sigma',
                  'd_D','delta_H','d_Z','d_F','d_N']
        

        minutes_per_day = 1440
# valores extraidos [959, 15, 58, 
#                    -241.48, 24767.0, -614.3, 24774.6, 
#                    -245.73, 24771.89, -630.21, 24783.19, -1773.74, 
#                    -247.07,  24748.71, -624.75, 24759.9, -3561.53, 
#                    3.96, 50.04, 9.38, 49.69, 31.15]
# delta_H 24771.89
# sigma_H 24748.71        
        read_data = numpy.empty(minutes_per_day,dtype='object')

        read_data =fill(read_data,struct)

        for n,_ in enumerate(read_data):
            for key in ['delta_H','sigma_H']:
                read_data[n][key] = 999999

        file_kind = '.early' if real_time else '.final'

        file_name = '{}_{:4.0f}{:02.0f}{:02.0f}.data{}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day,file_kind)

        fpath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],file_name)

        exists = os.path.isfile(fpath)

        if exists:
            with open(fpath,'r') as file:

                magnetic_data = numpy.array(file.read().splitlines() ,dtype='object')
 
                for n, linea in enumerate(magnetic_data):

                    valores = re.findall(r'-?\d+\.?\d*', linea)

                    # Convertir los valores a enteros o números de punto flotante según corresponda
                    valores = [int(v) if v.isdigit() else float(v) for v in valores]
        #   data_file [i] = chain.format(i+1,i//60,i % 60 ,
        #                                     (magnetic_data[i]['D']),magnetic_data[i]['H'],magnetic_data[i]['Z'],magnetic_data[i]['F'], 
        #                                D_median[i],H_median[i],Z_median[i],F_median[i], N_median[i], 
        #                                D_sigma[i],H_sigma[i],Z_sigma[i],F_sigma[i], N_sigma[i], 
        #                                D_D[i], D_H[i], D_Z[i], D_F[i], D_N[i])
                    
                    if (len(valores)>0):
                 
                        for key,value in zip(keys_array,valores):
 
                            read_data[n][key] = value
                        
                   
        
        else:
            raise FileNotFoundError("El archivo {} no existe.".format(os.path.basename(fpath)))


        result =  {'hour':numpy.empty(24,dtype=int),
                   'delta_H' : numpy.empty(24,dtype=int),
                   'sigma_H' : numpy.empty(24,dtype=int)}

        for i in range(24):
            result['hour'][i] = read_data[i*60]['hour']

            d_H =  vectorize(read_data[i*60:(i+1)*60],'delta_H')
            sigma_H = vectorize(read_data[i*60:(i+1)*60],'sigma_H')

            good_indexes = numpy.where((numpy.abs(d_H) <999990).astype(bool) & (numpy.abs(sigma_H) <999990).astype(bool))[0]
       

 
            d_H = d_H[good_indexes]
            sigma_H  = sigma_H[good_indexes]


            if d_H.shape[0]>0:

                result['delta_H'][i] = numpy.median(d_H)
                result['sigma_H'][i]    = numpy.median(sigma_H)
            else:

                result['delta_H'][i] = 999999
                result['sigma_H'][i]    = 999999
 
        

        return result
    
    def __getting_magneticprofiles(self,initial,**kwargs):

        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get('real_time',False)

        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day
        # ------ Format ----------
        # i+1,i//60,i % 60 ,
        # (magnetic_data[i]['D']),magnetic_data[i]['H'],magnetic_data[i]['Z'],magnetic_data[i]['F'], 
        # D_median[i],H_median[i],Z_median[i],F_median[i], N_median[i], 
        # D_sigma[i],H_sigma[i],Z_sigma[i],F_sigma[i], N_sigma[i], 
        # D_D[i], D_H[i], D_Z[i], D_F[i], D_N[i])

        ###################################333
        key = ['i','hour','minute',
               'D','H','Z','F',
               'D_median','H_median','Z_median','F_median','N_median',
               'D_sigma','H_sigma','Z_sigma','F_sigma','N_sigma',
               'D_D','D_H','D_Z','D_F','D_N']
        
        key_array = deepcopy(key)
        struct = dict.fromkeys(key,999999)
        struct['D'] = 9999


        minutes_per_day = 1440

        read_data = numpy.empty(minutes_per_day,dtype='object')
        read_data = fill(read_data,struct)
 

        for n,i in enumerate(numpy.arange(24)):
            read_data[i]['hour'] = n
        
            data_index = read_data[i*60:(i+1)*60]
            data_to_index =  numpy.arange(60)

            for n,_ in enumerate(data_index):
                read_data[i*60+n]['minute'] = data_to_index[n]
       

 
        
        file_kind = '.early' if real_time else '.final'

        file_name = '{}_{:4.0f}{:02.0f}{:02.0f}.data{}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day,file_kind)

        fpath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],file_name)

        exists = os.path.isfile(fpath)

        if exists:
            with open(fpath,'r') as file:
                magnetic_data = file.read().splitlines()
                magnetic_data = numpy.array(magnetic_data,dtype='object')
             

                for n,linea in enumerate(magnetic_data):
                    valores = re.findall(r'-?\d+\.?\d*', linea)

                    # Convertir los valores a enteros o números de punto flotante según corresponda
                    valores = [int(v) if v.isdigit() else float(v) for v in valores]
                  
                    if (len(valores)>0):
                        valores = valores 
                        for key,value in zip(key_array,valores):

                            read_data[n][key] = value

        else:
            return 

        data_per_hour = 10 
        data_points = 24*data_per_hour
        data_period = 60//data_per_hour
        key = ['hour','minute','D','H','Z','F']
        
        result = {'hour':numpy.empty(data_points,dtype=float), 'minute':numpy.empty(data_points,dtype=float),'D':numpy.empty(data_points,dtype=float),
                  'H':numpy.empty(data_points,dtype=float),'Z':numpy.empty(data_points,dtype=float),
                   'F':numpy.empty(data_points,dtype=float) }
         

        for i in range(data_points):
            result['hour'][i]        = read_data[i*data_period]['hour']
            result['minute'][i]    = read_data[i*data_period]['minute']

            result['D'][i] = numpy.median(vectorize(read_data[i*data_period:(i+1)*data_period],'D'))   
            result['H'][i] = numpy.median(vectorize(read_data[i*data_period:(i+1)*data_period],'H'))   
            result['Z'][i] = numpy.median(vectorize(read_data[i*data_period:(i+1)*data_period],'Z'))   
            result['F'][i] = numpy.median(vectorize(read_data[i*data_period:(i+1)*data_period],'F'))   
        

        return result 
    
    def __kp2ap (self,k_tmp):
        k_tmp = numpy.array(k_tmp,dtype=int)

        result = 0*(numpy.equal(k_tmp,0).astype(int)) + 2*(numpy.equal(k_tmp,3).astype(int))+ 3*(numpy.equal(k_tmp,7).astype(int))+\
                4*(numpy.equal(k_tmp,10).astype(int)) + 5*(numpy.equal(k_tmp,13).astype(int)) + 6*(numpy.equal(k_tmp,17).astype(int))+ \
                7*(numpy.equal(k_tmp,20).astype(int)) + 9*(numpy.equal(k_tmp,23).astype(int)) + 12*(numpy.equal(k_tmp,27).astype(int))+\
                15*(numpy.equal(k_tmp,30).astype(int)) + 18*(numpy.equal(k_tmp,33).astype(int)) + 22*(numpy.equal(k_tmp,37).astype(int)) + \
                27*(numpy.equal(k_tmp,40).astype(int)) + 32*(numpy.equal(k_tmp,43).astype(int))  + 39*(numpy.equal(k_tmp,47).astype(int)) + \
                48*(numpy.equal(k_tmp,50).astype(int)) +  56*(numpy.equal(k_tmp,53).astype(int)) + 67*(numpy.equal(k_tmp,57).astype(int)) + \
                80*(numpy.equal(k_tmp,6).astype(int))  +  94*(numpy.equal(k_tmp,63).astype(int)) + 111*(numpy.equal(k_tmp,67).astype(int)) + \
                132*(numpy.equal(k_tmp,70).astype(int)) + 154*(numpy.equal(k_tmp,73).astype(int)) + 179*(numpy.equal(k_tmp,77).astype(int)) + \
                207*(numpy.equal(k_tmp,80).astype(int)) + 236*(numpy.equal(k_tmp,83).astype(int)) + 300*(numpy.equal(k_tmp,87).astype(int)) + \
                400*(numpy.equal(k_tmp,90).astype(int)) + 999*(numpy.equal(k_tmp,999).astype(int))        

        return result 
      

    def __dayly_kp (self,k_tmp):
        #script -> geomagixs_magneticindex_compute.pro
        tmp = numpy.where(k_tmp<999)[0]

        if len(tmp) == 0: return 999

        result = numpy.ceil(numpy.sum(k_tmp[tmp]))

        result = ((result // 10) * 10 +3) if ((result % 10) ==2) else result
        result = ((result // 10) * 10 +3) if ((result % 10) ==5) else result
        result = ((result // 10) * 10 +7) if ((result % 10) ==6) else result
        result = ((result // 10) * 10 +7) if ((result % 10) ==8) else result
        result = ((result // 10) * 10 +10) if ((result % 10) ==9) else result

        return result 
    
    def __dayly_a(self,a_tmp):
        tmp = numpy.where(a_tmp < 999)[0]

        if len(tmp) == 0: return 999

        return numpy.ceil(numpy.mean(a_tmp[tmp]))
    

    def __dH2Kp (self,dH_tmp,dH_table):

        MAX_dH  = 1000
      
        if not isinstance(dH_table,numpy.ndarray):
            dH_table = numpy.array(dH_table)
        


        if dH_table.shape[0] != 28:
            MAX_dH =1000
            dH_table =  [ 4.7,  5.4,  6.4,  7.2,  8.2,  9.7, 11.0, 
                          12.5, 14.8, 16.8, 19.1, 22.6, 25.6, 29.1,  
                          34.4, 39.1, 44.4, 52.5, 59.6, 67.7, 80.1,  
                          90.9,103.2,122.2,138.7,157.5,186.4,211.6]

        dH_table = numpy.sort(dH_table)

        result = 0*((numpy.array((dH_tmp <= dH_table[1]),dtype=bool)).astype(int)) +  \
                    3*((numpy.array(dH_tmp > dH_table[1],dtype=bool)  & numpy.array(dH_tmp <= dH_table[2],dtype=bool)).astype(int)) +  \
                    7*((numpy.array(dH_tmp > dH_table[2],dtype=bool)  & numpy.array(dH_tmp <= dH_table[3],dtype=bool)).astype(int)) +  \
                    10*((numpy.array(dH_tmp > dH_table[3],dtype=bool)  & numpy.array(dH_tmp <= dH_table[4],dtype=bool)).astype(int)) +  \
                    13*((numpy.array(dH_tmp > dH_table[4],dtype=bool)  & numpy.array(dH_tmp <= dH_table[5],dtype=bool)).astype(int)) + \
                    17*((numpy.array(dH_tmp > dH_table[5],dtype=bool)  & numpy.array(dH_tmp <= dH_table[6],dtype=bool)).astype(int)) +  \
                    20*((numpy.array(dH_tmp > dH_table[6],dtype=bool)  & numpy.array(dH_tmp <= dH_table[7],dtype=bool)).astype(int)) +  \
                    23*((numpy.array(dH_tmp > dH_table[7],dtype=bool)  & numpy.array(dH_tmp <= dH_table[8],dtype=bool)).astype(int)) +  \
                    27*((numpy.array(dH_tmp > dH_table[8],dtype=bool)  & numpy.array(dH_tmp <= dH_table[9],dtype=bool)).astype(int)) +  \
                    30*((numpy.array(dH_tmp > dH_table[9],dtype=bool)  & numpy.array(dH_tmp <= dH_table[10],dtype=bool)).astype(int)) +  \
                    33*((numpy.array(dH_tmp > dH_table[10],dtype=bool)  & numpy.array(dH_tmp <= dH_table[11],dtype=bool)).astype(int)) +  \
                    37*((numpy.array(dH_tmp > dH_table[11],dtype=bool)  & numpy.array(dH_tmp <= dH_table[12],dtype=bool)).astype(int)) +  \
                    40*((numpy.array(dH_tmp > dH_table[12],dtype=bool)  & numpy.array(dH_tmp <= dH_table[13],dtype=bool)).astype(int)) +  \
                    43*((numpy.array(dH_tmp > dH_table[13],dtype=bool)  & numpy.array(dH_tmp <= dH_table[14],dtype=bool)).astype(int)) +  \
                    47*((numpy.array(dH_tmp > dH_table[14],dtype=bool)  & numpy.array(dH_tmp <= dH_table[15],dtype=bool)).astype(int)) +  \
                    50*((numpy.array(dH_tmp > dH_table[15],dtype=bool)  & numpy.array(dH_tmp <= dH_table[16],dtype=bool)).astype(int)) +  \
                    53*((numpy.array(dH_tmp > dH_table[16],dtype=bool)  & numpy.array(dH_tmp <= dH_table[17],dtype=bool)).astype(int)) +  \
                    57*((numpy.array(dH_tmp > dH_table[17],dtype=bool)  & numpy.array(dH_tmp <= dH_table[18],dtype=bool)).astype(int)) +  \
                    60*((numpy.array(dH_tmp > dH_table[18],dtype=bool)  & numpy.array(dH_tmp <= dH_table[19],dtype=bool)).astype(int)) +  \
                    63*((numpy.array(dH_tmp > dH_table[19],dtype=bool)  & numpy.array(dH_tmp <= dH_table[20],dtype=bool)).astype(int)) +  \
                    67*((numpy.array(dH_tmp > dH_table[20],dtype=bool)  & numpy.array(dH_tmp <= dH_table[21],dtype=bool)).astype(int)) +  \
                    70*((numpy.array(dH_tmp > dH_table[21],dtype=bool)  & numpy.array(dH_tmp <= dH_table[22],dtype=bool)).astype(int)) +  \
                    73*((numpy.array(dH_tmp > dH_table[22],dtype=bool)  & numpy.array(dH_tmp <= dH_table[23],dtype=bool)).astype(int)) +  \
                    77*((numpy.array(dH_tmp > dH_table[23],dtype=bool)  & numpy.array(dH_tmp <= dH_table[24],dtype=bool)).astype(int)) +  \
                    80*((numpy.array(dH_tmp > dH_table[24],dtype=bool)  & numpy.array(dH_tmp <= dH_table[25],dtype=bool)).astype(int)) +  \
                    83*((numpy.array(dH_tmp > dH_table[25],dtype=bool)  & numpy.array(dH_tmp <= dH_table[26],dtype=bool)).astype(int)) +  \
                    87*((numpy.array(dH_tmp > dH_table[26],dtype=bool)  & numpy.array(dH_tmp <= dH_table[27],dtype=bool)).astype(int)) +  \
                    90*((numpy.array(dH_tmp  > dH_table[27],dtype=bool)  & numpy.array(dH_tmp < MAX_dH,dtype=bool)).astype(int)) +  \
                    999*((numpy.array(dH_tmp >= MAX_dH,dtype=bool).astype(int)))
        
 
        return result
        
    def __ReadCalibration_MAGIND(self):

        calibration_name = os.path.join(self.system['auxiliar_dir'],self.GMS[self.system['gms']]['name']+'.calibration')

        exist = os.path.isfile(calibration_name)

        if not exist:
            raise FileNotFoundError("No existe el archivo de calibración.")

        with open(calibration_name,'r') as file:

            calibration_data = numpy.array(file.read().splitlines() ,dtype='object')

            number_of_lines = calibration_data.shape[0]


            

            valores = re.findall(r'-?\d+\.?\d*', calibration_data[12])

            # Convertir los valores a enteros o números de punto flotante según corresponda
            valores = [int(v) if v.isdigit() else float(v) for v in valores]

            result = {'dH_table': numpy.array(valores,dtype=float)}

        return result

    def __getting_kindex(self,date,**kwargs):

        def generate_chain (type_A,type_B):
        
            init = ''

            for data in type_A:
                if len(init)>0: init = init +' '
                chain = '{:03.0f}'.format(data)
                init = init + chain
            for data in type_B:
                if len(init)>0: init = init +' '
                chain = '{:03.0f}'.format(data)
                init = init + chain            
            
            return init 
        



        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get('real_time',False)
        station = kwargs.get('station',None)


        initial_year,initial_month,initial_day = date.year,date.month,date.day

        calibration = self.__ReadCalibration_MAGIND()

        
        data = self.__getting_deltab(date,verbose=verbose,real_time=real_time)

        K_mex = self.__dH2Kp(data['delta_H'],calibration['dH_table'])
        K_mex_max = self.__dH2Kp(data['delta_H']+data['sigma_H'],calibration['dH_table'])
        K_mex_min = self.__dH2Kp(data['delta_H']-data['sigma_H'],calibration['dH_table'])

    
        a_mex = self.__kp2ap(K_mex)
        a_mex_max = self.__kp2ap(K_mex_max)
        a_mex_min = self.__kp2ap(K_mex_min)

        for i ,_ in enumerate(K_mex):

            if i >1 :
                if K_mex[i] == 90  and K_mex[i-1] <= 37:
                    K_mex[i] = 999
            if i < K_mex.shape[0]-1 :
                if K_mex[i] == 90 and K_mex[i+1]<= 57:
                    K_mex[i] = 999

        
        k_mex_data = numpy.empty(6,dtype=object)
        
        ###
 
        k_mex_data[0] = generate_chain(K_mex,[self.__dayly_kp(K_mex)])
        k_mex_data[1] = generate_chain(a_mex ,[self.__dayly_a(a_mex)])

        k_mex_data[2] = generate_chain(K_mex_max,[self.__dayly_kp(K_mex_max)])
        k_mex_data[3] = generate_chain(a_mex_max ,[self.__dayly_a(a_mex_max)])

        k_mex_data[4] = generate_chain(K_mex_min,[self.__dayly_kp(K_mex_min)])
        k_mex_data[5] = generate_chain(a_mex_min ,[self.__dayly_a(a_mex_min)])

          
        extension = '.early' if real_time else '.final'

        output_datafile = '{}_{:4.0f}{:02.0f}{:02.0f}.k_index{}'.format(self.GMS[self.system['gms']]['code'],
                                                                        initial_year,
                                                                        initial_month,
                                                                        initial_day,
                                                                        extension)
        output_path = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],output_datafile)
        
        if not os.path.isdir(os.path.dirname(output_path)): 
            os.makedirs(os.path.dirname(output_path))

        with open(output_path,'w') as file:
            file.writelines(line + '\n' for line in  k_mex_data)


        if verbose:
            print("Guardando {}.".format(os.path.basename(output_path)))

        return 
    
    def __getting_deltahindex(self,date,**kwargs):



        def generate_chain (type_A,type_B):
            
 
            init = ''

            for data in type_A:
              
                chain = ' {:8.1f}'.format(data)
             
                init = init + chain
            for data in type_B:
                if len(init)>0: init = init +' '
    
                chain = ' {:8.1f}'.format(data)
                init = init + chain            
            
            return init 
        

        verbose = kwargs.get("verbose",False)
        real_time = kwargs.get("real_time",False)
        station = kwargs.get("station",None)


        initial_year, initial_month,initial_day = date.year,date.month,date.day

        ###(
        data = self.__getting_deltah(date,verbose=verbose,real_time=real_time)

        good_indexes = numpy.where(data['delta_H']<9990)[0]


        dh_mex_data = numpy.empty(2,dtype='object')

        if len(good_indexes)==0:
            dh_mex_data[0] = generate_chain(data['delta_H'],[numpy.mean(data['delta_H'])])
            dh_mex_data[1] = generate_chain(data['sigma_H'],[numpy.mean(data['sigma_H'])])
        else:
            dh_mex_data[0] = generate_chain(data['delta_H'],[numpy.mean(data['delta_H'][good_indexes])])
            dh_mex_data[1] = generate_chain(data['sigma_H'],[numpy.mean(data['sigma_H'][good_indexes])])




        extention = '.early' if real_time else '.final'

        output_datafile = '{}_{:04d}{:02d}{:02d}.delta_H{}'.format(self.GMS[self.system['gms']]['code'],
                                                                   initial_year,
                                                                   initial_month,
                                                                   initial_day
                                                                   ,extention)    
        output_path = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])
        
        fpath = os.path.join(output_path,output_datafile)
        
        
        print("dmex0",dh_mex_data[0])
        print("dmex1",dh_mex_data[1])

        
        with open(fpath, 'w') as file:

            file.writelines(line + '\n' for line in dh_mex_data)
        

        if verbose:
            print("Guardando {}".format(os.path.basename(fpath)))
        

        return 

    
    def __getting_profiles(self,date,**kwargs):
        
        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get("real_time",False)
        station = kwargs.get("station",None)

        initial_year = date.year
        initial_month = date.month
        initial_day = date.day  

        ###################33
        # Leyendo y procesando datos 

        data = self.__getting_magneticprofiles(date,verbose=verbose,real_time=real_time)

        good_indexes = numpy.where(data['H']<999990)

        profile_data = numpy.empty(data['H'].shape[0],dtype='object')

        for i in range(data['H'].shape[0]):
            chain = '{:02.0f}:{:02.0f}  '+'  {:8.1f}'*4
            profile_data [i] = chain.format(data['hour'][i],data['minute'][i],data['D'][i],data['H'][i],data['Z'][i],data['F'][i])
            # print("profile data",profile_data[i])
            # print("data",data['hour'][i],data['minute'][i],data['D'][i],data['H'][i],data['Z'][i],data['F'][i])
        extention = '.early' if real_time else '.final'

        output_datafile  = '{}_{:4.0f}{:02.0f}{:02.0f}.profiles{}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day,extention)
        output_path = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])

        fpath = os.path.join(output_path,output_datafile)

        with open(fpath,'w') as file:
            file.writelines(line +'\n' for line in profile_data)
        
        if verbose:
            print("Guardando {}.".format(os.path.basename(fpath)))

        return 
    
    def __getting_kpindex(self,date,**kwargs):
        
        def generate_txt (textA,textB):

            if verifyisnumber(textA): textA = [textA]
            if verifyisnumber(textB): textB = [textB]

            chain = '{:03.0f}'
            text = ''
            for n,value in enumerate(textA):
                if n>0 : text = text + ' '
                text = text+ chain.format(value)

            text = text + ' '   
            for n,value in enumerate(textB):
                if n>0 : text = text + ' '
                text = text+ chain.format(value)
            
            return text 

        verbose = kwargs.get("verbose",False)
        real_time = kwargs.get("real_time",False)
        station = kwargs.get("station",None)

        initial_year = date.year
        initial_month = date.month
        initial_day = date.day  

        string_date ='{:4.0f}{:02.0f}{:02.0f}'.format(initial_year,initial_month,initial_day)
        ###################3
        kmex_file_name = '{}_{}.differences'.format(self.GMS[self.system['gms']]['code'],string_date)        

        fpath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],kmex_file_name)

        exists = os.path.isfile(fpath)

        if exists:
            with open(fpath,'r') as file:
                tmp_data = numpy.array(file.read().splitlines() ,dtype='object')
                number_of_lines = tmp_data.shape[0]
        else:
            raise ("Archivo se encuentra perdido {}".format(os.path.basename(fpath)))
            return 
        
        str_tmp = {'kp':0}

        kp_data = numpy.empty(number_of_lines,dtype='object')
        kp_data = fill(kp_data, str_tmp)

        for n,linea in enumerate(tmp_data):
            
            valores = re.findall(r'-?\d+\.?\d*', linea)

                    # Convertir los valores a enteros o números de punto flotante según corresponda
            valores = [int(v) if v.isdigit() else float(v) for v in valores]

            kp_data[n]['kp'] = valores[0]
        ###################3
        kmex_file_name = '{}_{}.data'.format(self.GMS[self.system['gms']]['code'],string_date)        

        fpath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],kmex_file_name)

        exists = os.path.isfile(fpath)

        if exists:
            with open(fpath,'r') as file:
                tmp_data = numpy.array(file.read().splitlines() ,dtype='object')
                number_of_lines = tmp_data.shape[0]
        else:
            print ("Archivo se encuentra perdido {}".format(os.path.basename(fpath)))
            return 
        
        str_tmp = {'Dst':0}

        dst_data = numpy.empty(number_of_lines,dtype='object')
        dst_data = fill(dst_data, str_tmp)

        for n,linea in enumerate(tmp_data):
            
            valores = re.findall(r'-?\d+\.?\d*', linea)

                    # Convertir los valores a enteros o números de punto flotante según corresponda
            valores = [int(v) if v.isdigit() else float(v) for v in valores]

            dst_data[n]['kp'] = valores[0]
        
        K_mex = vectorize(kp_data,'kp')
        K_mex_max = K_mex*0
        K_mex_min = K_mex*0

        a_mex = self.__kp2ap(K_mex)
        a_mex_max = self.__kp2ap(K_mex_max)
        a_mex_min = self.__kp2ap(K_mex_min)

        k_mex_data = numpy.empty(6,dtype='object')


        for n,element in enumerate([K_mex,a_mex,K_mex_max,a_mex_max,K_mex_min,a_mex_min]):

            k_mex_data[n] = generate_txt(element,self.__dayly_kp(element))


        #creamos el data file 

        extention  = ''

        output_datafile = '{}_{:4.0f}{:02.0f}{:02.0f}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)
        output_path = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])

        fpath = os.path.join(output_path,output_datafile)

        with open(fpath,'w') as file:
            file.writelines(line + '\n' for line in k_mex_data)

        if verbose:
            print("Guardando {}".format(os.path.basename(output_datafile)))

        
        data = vectorize(dst_data,'Dst')

        good_indexes = numpy.where(data<9990)

        dH_mex_data = numpy.empty(2,dtype='object')
        tmp = numpy.empty(25,dtype=float)

        def generate_txt2(textA,textB=None):
            data = ''
            if verifyisnumber(textA):textA=[textA]
            if verifyisnumber(textB):textB=[textB]
            format_ = ' {:8.1f}'
            text = ''

            for n,value in enumerate(textA):text = text + format_.format(value)
            if textB is not None:
                for n,value in enumerate(textB):text = text + format_.format(value)
            return text


        if len(good_indexes)==0:
            dH_mex_data[0] = generate_txt2(data,numpy.mean(data))
            dH_mex_data[1] = generate_txt2(tmp)
        else:
            dH_mex_data[0] = generate_txt2(data,numpy.mean(data[good_indexes]))
            dH_mex_data[1] = generate_txt2(tmp)

        extention = ''

        output_datafile = '{}_{:4.0f}{:02.0f}{:02.0f}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)
        output_path = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])

        fpath = os.path.join(output_path,output_datafile)
        
        with open(fpath,'w') as file:
            file.writelines(line +'\n' for line in dH_mex_data)
        
        if verbose:
            print("Guardando {}".format(os.path.basename(fpath)))


    def __magneticindex_compute(self,initial,final,**kwargs):
        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose",False)
        force_all = kwargs.get("force_all",False)
        real_time = kwargs.get("real_time",False)

        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day

        final_year = final.year
        final_month = final.month
        final_day = final.day


        file_number = (JULDAY(final)-JULDAY(initial))+1

        data_file_name = numpy.empty(file_number,dtype='object')

        string_date = numpy.empty(file_number,dtype='object')

        if station != 'planetary':
            extention = '.early' if real_time else '.final'
        else:
            extention = ''
        
        for i in range(file_number):
            
            tmp_julday = JULDAY(initial) + i
            result = CALDAT(tmp_julday)
            tmp_year, tmp_month,tmp_day = result.year,result.month,result.day

            string_date[i] =  '{:4.0f}{:02.0f}{:02.0f}'.format(tmp_year,tmp_month,tmp_day)

            data_file_name[i] = '{}_{}.differences{}'.format(self.GMS[self.system['gms']]['code'],string_date[i],extention)

        fpath = [os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],file) for file in data_file_name]
 
        exists_files = [os.path.isfile(fp) for fp in fpath]
 
        capable_to_update = len(numpy.where(numpy.array(exists_files,dtype=bool) == True)[0])
 
        if capable_to_update == 0 :
            if verbose:
                print(" Data File Error: No se encuentran archivos del tipo GMS_YYYYMMDD.differences{}. La data será asumida con gaps.".format(extention))
        
        name_k_index = numpy.empty(file_number,dtype= 'object')

        for n,value in enumerate(string_date):
            name_k_index[n] = '{}_{}.k_index{}'.format(self.GMS[self.system['gms']]['code'],string_date[n],extention)
            name_k_index[n] = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],name_k_index[n])

        exist_result_files = [os.path.isfile(fp) and not force_all for fp in name_k_index]
        
        exist_result_files = numpy.array(exist_result_files,dtype=bool)
        exists_files  = numpy.array(exists_files,dtype= bool)


        make_update_file = exists_files  & ~ exist_result_files

        if numpy.sum(make_update_file)>0:
            files_to_update = len(numpy.where(make_update_file)[0])
        else:
            files_to_update = 0 
        
        if verbose:
            if files_to_update>0:
                print("Un total de archivos necesitan ser actualizados".format(files_to_update))
            else:
                print("No hay archivos para actualizar.")
            
            if capable_to_update > files_to_update : 
                print("Todavia hay {} archivos que pueden ser actualizados. Use el comando /FORCE_ALL para forzar la actualización".format(capable_to_update-files_to_update))
            
            if len(exists_files) > capable_to_update:
                print("Existen {} archivos que son imposibles de actualizar. Use la herramienta UPDATE_MAGNETICDATA para actualizar la database.".format(len(exists_files)-capable_to_update))

        
        for i,_ in enumerate(make_update_file):
            if make_update_file[i]:
                tmp_year, tmp_month,tmp_day = int(string_date[i][:4]),int(string_date[i][4:6]),int(string_date[i][6:8])
                date = datetime(tmp_year,tmp_month,tmp_day)
                if station != 'planetary':
                    self.__getting_kindex(date,verbose=verbose,station=station,real_time=real_time)
                    self.__getting_deltahindex(date,verbose=verbose,station=station,real_time=real_time)
            
                    self.__getting_profiles(date,verbose=verbose,station=station,real_time=real_time)
                else:
                    self.__getting_kpindex(date,verbose=verbose,station=station,real_time=real_time)
            
        if verbose:
            print("Magnetic-Index fueron actualizados.")

        return 
    

            

    def __getting_magneticdata_forcleaning(self,initial,**kwargs):
        ######################################################
        # geomagixs_magnetictdata_prepare.pro

        station = kwargs.get('station',None)
        verbose = kwargs.get('verbose',False)


        initial_year = initial.year
        initial_month= initial.month
        initial_day = initial.day


        initial_hour = initial.minute
        initil_minute = initial.minute

        ###########
        filename = '{}_{:4.0f}{:02.0f}{:02.0f}.dat'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)
        filename = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],filename)

        exists = os.path.isfile(filename)

        if exists:

            if verbose:
                print("El archivo {} existe".format(filename))


            keys = ['year','month','day','hour','minute','secs','doy','D','H','Z','F']


            struct = dict.fromkeys(keys,0)



            with open(filename,'r') as f:

                buff = numpy.array(f.read().splitlines(),dtype='object')

                resulting_data = numpy.empty(buff.shape[0],dtype='object')
                 
                resulting_data = fill(resulting_data,struct)

                for n,linea in enumerate(buff ):
                    valores = re.findall(r'-?\d+\.?\d*', linea)

                    # Convertir los valores a enteros o números de punto flotante según corresponda
                    valores = [int(v) if v.isdigit() else float(v) for v in valores]

                    if len(valores)>0:
                        
           
                        for key,value in zip(keys,valores):

                            resulting_data[n][key] = value
                            
            
            

            return resulting_data
        else:
            if verbose:
                print("El archivo {} no existe".format(filename))
            return None
    

    def __fixing_datafile (self,file_date, **kwargs):

        station = kwargs.get('station',None)
        verbose = kwargs.get('verbose',None)

        initial_year = file_date.year
        initial_month = file_date.month
        initial_day = file_date.day

        tmp_julday = JULDAY(file_date)
 
        result = CALDAT((tmp_julday))

        tmp_year = result.year
        tmp_month = result.month
        tmp_day = result.day
  
        #############
        cabecera = 18 

        file_name = '{}{:4.0f}{:02.0f}{:02.0f}.rK.min'.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day)

        file_name = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)

        exists = os.path.isfile(file_name)
 

        if not exists:
            file_name = '{}{:4.0f}{:02.0f}{:02.0f}rmin.min'.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day)
            file_name = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)
            exists = os.path.isfile(file_name)

        if not exists:
            if verbose:
                print("Error extrayendo datos del directorio.")
            return 
        else:
            print('Extrayendo data de {}'.format(os.path.basename(file_name)))

            with open(file_name,'r') as f:

                tmp_data = numpy.array(f.read().splitlines() ,dtype='object')
                number_of_lines = tmp_data.shape[0]
            

        minutes_in_a_day = 60*24
        hours_in_a_day = 24

        if station == 'planetary':
            final_file = numpy.empty(hours_in_a_day,dtype=float)
            j_inicio = cabecera - 1

            for i in range(hours_in_a_day) :
                
                diff = JULDAY(file_date)- JULDAY(datetime(initial_year,1,1)+relativedelta(days=-1))
                chain = '{:4.0f}-{:02.0f}-{:02.0f} {:02.0f}:{:02.0f}:00.000{:03.0f}   {:4.0f}     {:4.0f}  {:5.0f}    {:5.0f}   {:5.0f}     {:5.0f}'
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
                chain = '{:4.0f}-{:02.0f}-{:02.0f} {:02.0f}:{:02.0f}:00.000{:03.0f}      {:7.2f} {:9.2f} {:9.2f} {:9.2f}'
                final_file[i] = chain.format(tmp_year,tmp_month,tmp_day,i//60,i % 60 , diff,9999.00, 999999.00, 999999.00, 999999.00)

                if exists: 

                    for j in range(j_inicio,number_of_lines):
                        if (tmp_data[j][11:16]==final_file[i][11:16]):
                            final_file[i] = tmp_data[j]
                            j_inicio = j+1
        


        output_datafile = '{}_{:4.0f}{:02.0f}{:02.0f}.dat'.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day )

        output_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])

        exist_dir = os.path.isdir(output_path)

        if not exist_dir:
            if verbose:
                print("Error critico: Directorio del sistema perdido -> {}.".format(output_path))
                print("Se crea el directorio.")
            
            os.makedirs(output_path)
            
        output_datafile = os.path.join(output_path,output_datafile)

        with open(output_datafile,'w') as file:
            if station == 'planetary':
                file.writelines(line+'\n' for line in final_file[:hours_in_a_day])
            else:
                if verbose:
                    print("Guardando archivo {}".format(os.path.basename(output_datafile)))
                file.writelines(line + '\n' for line in final_file[:minutes_in_a_day])

        
        if verbose:
            print("Guardando {}".format(output_datafile))


        return 


    def __cleaning_datafile(self,initial,**kwargs):
        '''
        script -> geomagixs_dataprepare_
        '''
        ############################################################
        station = kwargs.get("station",None)
        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get('real_time',False)
        offset = kwargs.get('offset',list())

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

        string_date = '{:4.0f}{:02.0f}{:02.0f}'.format(initial_year,initial_month,initial_day)

        data_file_name = '{}_{}.dat'.format(self.GMS[self.system['gms']]['code'],string_date)


        data_file_name = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],data_file_name)
        exist_data_file = os.path.isfile(data_file_name)

        print("!!!!!!Guardando .clean.dat files")
        if exist_data_file:
            if verbose:
                print("Existe el archivo {} en la ruta {}".format(os.path.basename(data_file_name),os.path.dirname(data_file_name)))
        else:
            if verbose:                
                print("No existe el archivo {} en la ruta {}".format(os.path.basename(data_file_name),os.path.dirname(data_file_name)))
              
        if station == 'planetary':
            if exist_data_file:
                if verbose:
                    print("Extrayendo data de: {}.".format(os.path.basename(data_file_name)))
                fpath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],data_file_name)
                
                exists = os.path.isfile(fpath)

                if not exists:
                    if verbose:
                        print("Error critico: No se puede acceder al archivo {}".format(os.path.basename(fpath)))
                    
                    return
                

                with open(fpath,'r') as file:
                    tmp_data = numpy.array(file.read().splitlines() ,dtype='object')
                    print("#########################")
                    print("#########################")
                    print("#########################")
                    print("Extrayendo",tmp_data[:10])
                    number_of_lines = tmp_data.shape[0]
                

                output_datafile = '{}_{:4.0f}{:02.0f}{:02.0f}.clean.dat'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)
                output_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])


                exist_dir = os.path.isdir(output_path)

                if not exist_dir:
                    if verbose:
                        print("Error critico: Imposible leer el directorio del sistema {}.Archivos o directorios perdidos o se necesitan permisos.".format(output_path))

                    return 
                
                output_datafile = os.path.join(output_path,output_datafile)

                with open(output_datafile,'w') as file:
                    file.writelines(line+'\n' for line in tmp_data[:number_of_lines])
                
                if verbose:
                    print("Guardando : {}".format(os.path.basename(output_datafile)))

                return 
            else:
                if verbose:
                    print("Datafile {} no encontrado".format(os.path.basename(data_file_name)))
                return 
        

        ######################################################################################################################33
        ######################################################################################################################33
        ######################################################################################################################33
        ######################################################################################################################33

        if exist_data_file:
            tmp_data = self.__getting_magneticdata_forcleaning(initial,station=station,verbose=verbose)
        
        else:
            if verbose:
                print("Inconsistencia! El archivo se encuentra perdido, las condiciones solicitadas podría comprometer los resultados calculados.\
                        Archivo {} no fue encontrado. Procediendo con valores predefinidos (gaps)".format(os.path.basename(data_file_name)))
        

        ######################################################################################3
        if exist_data_file :
            D_values  = deepcopy(vectorize(tmp_data,'D'))
            H_values  = deepcopy(vectorize(tmp_data,'H'))
            Z_values  = deepcopy(vectorize(tmp_data,'Z'))
            F_values  = deepcopy(vectorize(tmp_data,'F'))
        
 
        ###
        mask = numpy.abs(H_values) <= 999990
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

                if (i< number_of_minutes) and ((i+number_of_minutes) < (elements_of_no_gaps -1)):
                    if i!=0:
                        H_median_value = numpy.median(numpy.concatenate((H_values[no_gaps[:i]],H_values[no_gaps[i+1:i+1+number_of_minutes]])))
                         
                        H_sigma_value = numpy.std(numpy.concatenate((H_values[no_gaps[:i]],H_values[no_gaps[i+1:i+1+number_of_minutes]]))-H_median_value)
                        # 
                        F_median_value = numpy.median(numpy.concatenate((F_values[no_gaps[:i]],F_values[no_gaps[i+1:i+1+number_of_minutes]])))
                        F_sigma_value = numpy.std(numpy.concatenate((F_values[no_gaps[:i]],F_values[no_gaps[i+1:i+1+number_of_minutes]]))-F_median_value)
                    else:

                        H_median_value = numpy.median(H_values[no_gaps[i+1:i+1+number_of_minutes]])
                        H_sigma_value  = numpy.std(H_values[no_gaps[i+1:i+1+number_of_minutes]]-H_median_value)

                        F_median_value = numpy.median(F_values[no_gaps[i+1:i+1+number_of_minutes]])
                        F_sigma_value  = numpy.std(F_values[no_gaps[i+1:i+1+number_of_minutes]]-F_median_value)


                if i < number_of_minutes and (i + number_of_minutes) > (elements_of_no_gaps -1 ):
                    if i !=0 and i != elements_of_no_gaps -1 :
                        H_median_value = numpy.median(numpy.concatenate((H_values[no_gaps[:i]],H_values[no_gaps[i+1:elements_of_no_gaps]])))
                        H_sigma_value  = numpy.std(numpy.concatenate(H_values[no_gaps[0:i]],H_values[no_gaps[i+1:elements_of_no_gaps]])-H_median_value )

                        F_median_value = numpy.median(numpy.concatenate((F_values[no_gaps[:i]],F_values[no_gaps[i+1:elements_of_no_gaps]])))
                        F_sigma_value  = numpy.std(numpy.concatenate(F_values[no_gaps[0:i]],F_values[no_gaps[i+1:elements_of_no_gaps]])-F_median_value )
                    
                    if i == 0:

                        H_median_value = numpy.median(H_values[no_gaps[i+1:elements_of_no_gaps]])
                        H_sigma_value  = numpy.std(H_values[no_gaps[i+1:elements_of_no_gaps]]-H_median_value )

                        F_median_value = numpy.median(F_values[no_gaps[i+1:elements_of_no_gaps]])
                        F_sigma_value  = numpy.std(F_values[no_gaps[i+1:elements_of_no_gaps]]-F_median_value )
                    
                    if i == elements_of_no_gaps-1:
                        H_median_value = numpy.median(H_values[no_gaps[:elements_of_no_gaps]])
                        H_sigma_value  = numpy.std(H_values[no_gaps[:elements_of_no_gaps]]-H_median_value)

                        F_median_value = numpy.median(F_values[no_gaps[:elements_of_no_gaps]])
                        F_median_value = numpy.median(F_values[no_gaps[:elements_of_no_gaps]]-F_median_value)


                if i >= number_of_minutes and i + number_of_minutes <= elements_of_no_gaps -1:

                    H_median_value = numpy.median(numpy.concatenate((H_values[no_gaps[i-number_of_minutes:i]], H_values[no_gaps[i+1:i+number_of_minutes]])))
                    H_sigma_value = numpy.std(numpy.concatenate((H_values[no_gaps[i-number_of_minutes:i]], H_values[no_gaps[i+1:i+number_of_minutes]]))-H_median_value)

                    F_median_value = numpy.median(numpy.concatenate((F_values[no_gaps[i-number_of_minutes:i]], F_values[no_gaps[i+1:i+number_of_minutes]])))
                    F_sigma_value  = numpy.std(numpy.concatenate((F_values[no_gaps[i-number_of_minutes:i]], F_values[no_gaps[i+1:i+number_of_minutes]]))-F_median_value)

                
                if i >= number_of_minutes and i + number_of_minutes > elements_of_no_gaps -1 :
                    if i == elements_of_no_gaps-1:
                        H_median_value = numpy.median(H_values[no_gaps[i-number_of_minutes:elements_of_no_gaps]])
                        H_sigma_value  = numpy.std(H_values[no_gaps[i-number_of_minutes:elements_of_no_gaps]]-H_median_value)

                        F_median_value = numpy.median(F_values[no_gaps[i-number_of_minutes:elements_of_no_gaps]])
                        F_sigma_value = numpy.std(F_values[no_gaps[i-number_of_minutes:elements_of_no_gaps]]-F_median_value)
                    else:
                        H_median_value = numpy.median(numpy.concatenate((H_values[no_gaps[i-number_of_minutes:i]], H_values[no_gaps[i+1:elements_of_no_gaps]])))
                        H_sigma_value  = numpy.std(numpy.concatenate((H_values[no_gaps[i-number_of_minutes:i]], H_values[no_gaps[i+1:elements_of_no_gaps]]))-H_median_value)

                        F_median_value = numpy.median(numpy.concatenate((F_values[no_gaps[i-number_of_minutes:i]], F_values[no_gaps[i+1:elements_of_no_gaps]])))
                        F_sigma_value  = numpy.std(numpy.concatenate((F_values[no_gaps[i-number_of_minutes:i]], F_values[no_gaps[i+1:elements_of_no_gaps]]))-F_median_value)

                    

                    ###
                if (numpy.abs(H_values[no_gaps[i]]-H_median_value)> sigma_criteria*H_sigma_value) or ((numpy.abs(F_values[no_gaps[i]]-F_median_value))>sigma_criteria*F_sigma_value):
                    boolean_flag[i]=0
                print("H_median_value",H_median_value)
                print("H_sigma_value",H_sigma_value)
                H_median_value = 0 
                H_sigma_value = 0
                F_median_value = 0
                F_sigma_value = 0
            
        v1  = boolean_flag > 0 
        v1 = v1.astype(int)

        v2 = boolean_flag <1
        v2 = v2.astype(int)
        
 
        

        if elements_of_no_gaps > 1 : 

            D_values [no_gaps] =  v1[:] * (D_values[no_gaps]) + (v2[:])*9999        
            H_values [no_gaps] =  v1[:] * (H_values[no_gaps]) + (v2[:])*9999
            Z_values [no_gaps] =  v1[:] * (Z_values[no_gaps]) + (v2[:])*9999
            F_values [no_gaps] =  v1[:] * (F_values[no_gaps]) + (v2[:])*999999
 

        ##########################################
        cleaning_count = 0
        if no_gaps_count > 0 :
            result = numpy.abs(H_values[no_gaps]-numpy.median(H_values[no_gaps]))/numpy.median(H_values[no_gaps])
            mask = (result >= 0.005 ).astype(bool)
            
            cleaning_indexes = numpy.where(mask)[0]
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
        mask = H_values > 999990
        mask = mask.astype(bool)

        bad_minutes_number = numpy.count_nonzero (mask)
        bad_minutes_indexes = numpy.where(mask)[0]



        mask = H_values < 999990
        mask = mask.astype(bool)

        good_minutes_number = numpy.count_nonzero (mask)
        good_minutes_indexes = numpy.where(mask)[0]

        total_minutes = H_values.shape[0] 
        criteria_up = .85
        criteria_0 = .025
        fixed_minutes = 0
        

        if (good_minutes_number > criteria_up*total_minutes) and  (good_minutes_number<=total_minutes)    and real_time is False:

            tmp_D = deepcopy(D_values)
            tmp_H = deepcopy(H_values)
            tmp_Z = deepcopy(Z_values)
            tmp_F = deepcopy(F_values)
            
            tmp_t = vectorize(tmp_data,'hour')*60 + vectorize(tmp_data,'minute')

            process_number = [1,2,3,4,6,8,9,10,20,40]

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

                    if bad_minutes_number > 0 and \
                    bad_minutes_number < n_processes*criteria_0*good_minutes_number:

                        #INTERPOL(y, x, xinterp)
                       
                        tmp= splrep(tmp_t[low_limit+good_minutes_indexes],H_values[low_limit+good_minutes_indexes])
                        tmp_H = splev(tmp_t[low_limit+bad_minutes_indexes], tmp)
                        H_values [low_limit+bad_minutes_indexes] = tmp_H 

                        tmp= splrep(tmp_t[low_limit+good_minutes_indexes],D_values[low_limit+good_minutes_indexes])
                        tmp_D = splev(tmp_t[low_limit+bad_minutes_indexes], tmp)
                        D_values [low_limit+bad_minutes_indexes] = tmp_D 

                        tmp= splrep(tmp_t[low_limit+good_minutes_indexes],Z_values[low_limit+good_minutes_indexes])
                        tmp_Z = splev(tmp_t[low_limit+bad_minutes_indexes], tmp)
                        Z_values [low_limit+bad_minutes_indexes] = tmp_Z 


                        tmp= splrep(tmp_t[low_limit+good_minutes_indexes],F_values[low_limit+good_minutes_indexes])
                        tmp_F = splev(tmp_t[low_limit+bad_minutes_indexes], tmp)
                        F_values [low_limit+bad_minutes_indexes] = tmp_F 

                        fixed_minutes = fixed_minutes + bad_minutes_number
                    
                    mask = H_values >= 999990
                    mask = mask.astype(bool)

                    bad_minutes_indexes = numpy.where(mask)[0]
                    bad_minutes_number = numpy.count_nonzero(mask)

                    i+=1

                    if (bad_minutes_number<=0) or (i >= n_processes): break
                j=j+1

                if (bad_minutes_number<=0) or (j >= len(process_number)):break

        #preparing data for storing
        # 
        # 
        #     
        data_file = numpy.empty(minutes_per_day,dtype='object')

        for i in range(minutes_per_day):
            chain = '{:4.0f}/{:02.0f}/{:02.0f} {:02.0f}:{:02.0f}:00.000 {:03.0f}     {:7.2f} {:9.2f} {:9.2f} {:9.2f}'

            data_file[i] = chain.format(tmp_data[i]['year'],abs(int(tmp_data[i]['month'])),abs(int(tmp_data[i]['day'])),
                                        tmp_data[i]['hour'],tmp_data[i]['minute'],tmp_data[i]['doy'],
                                        D_values[i],H_values[i],Z_values[i],F_values[i])
            


        output_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])


        cleaned_data_file_name = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],string_date)

        fpath = os.path.join(output_path,cleaned_data_file_name)

         
        with open(fpath, 'w') as file:
            file.writelines(line +'\n' for line in data_file)

        if verbose:
            print("Guardando: {}".format(os.path.basename(fpath)))
            if offset.shape[0] == 3:
                print("Con datos-offset de {:4.0f} en D, {:4.0f} en H y {:4.0f} en Z".format(offset[0],offset[1],offset[2]))

            if (new_no_gaps_count   < minutes_per_day): 
                diff = numpy.abs(minutes_per_day-new_no_gaps_count)
                print("El archivo original tuvo perdido {:4.0f} minutos de datos.".format(diff))
            if (new_no_gaps_count<no_gaps_count):
                diff = numpy.abs(no_gaps_count-new_no_gaps_count)
                print("Adicionalmente {:4.0f} minutos de original data fueron descartados".format(diff))
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

        file_name = '{}{:4.0f}{:02.0f}{:02.0f}.rK.min'.format(self.GMS[self.system['gms']],tmp_year,tmp_month,tmp_day)

        fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)

        exists = os.path.isfile(fpath)

        if not exists:

            chain = '{}{:4.0f}{:02.0f}{:02.0f}rmin.min'
            file_name = chain.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day) 
            
            exists = os.path.isfile(file_name)

            if exists:
                if verbose:
                    print("Extrayendo datos de {}".format(os.path.basename(file_name)))
                fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)


                with open(fpath,'r') as file:
                    tmp_data = file.read().splitlines() 
                
                    tmp_data = numpy.array(tmp_data,dtype='object')
                    number_of_lines = tmp_data.shape[0]
            else:
                if verbose:
                    print("Archivo no encontrado.")
        else:
            if verbose:
                print("Extrayendo datos de {}".format(os.path.basename(file_name)))
               
            fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)

            
            with open(fpath,'r') as file:
                tmp_data = file.read().splitlines() 
            
                tmp_data = numpy.array(tmp_data,dtype='object')

                number_of_lines = tmp_data.shape[0]
        
        minutes_in_a_day  = 1440 
        hours_in_a_day = 24

        if station=='planetary':
            final_file = numpy.array(hours_in_a_day,dtype='object')
            j_inicio = cabecera-1

            for i in range(hours_in_a_day):
                result =  JULDAY(datetime(initial_year,initial_month,initial_day))-(JULDAY(datetime(initial_year,1,0)+relativedelta(days=-1)))
                chain = '{:4.0f}-{:02.0f}-{:02.0f} {:02.0f}:{:02.0f}:00.000 {:03.0f}   {:4.0f}     {:4.0f}  {:5.0f}    {:5.0f}   {:5.0f}     {:5.0f}'
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
                chain = '{:4.0f}-{:02.0f}-{:02.0f} {:02.0f}:{:02.0f}:00.000 {:03.0f}     {:7.2f} {:9.2f} {:9.2f}'
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
        output_datafile = '{}_{:4.0f}{:02.0f}{:02.0f}.dat'.format(self.GMS[self.system['gms']]['code'],tmp_year,tmp_month,tmp_day) 
        opath = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])

        exists_dir = os.path.isdir(opath)

        if not exists_dir:
            if verbose:
                print("Error critico: Directorio del sistema perdido {}. Revisa el directorio.".format(opath))
                return 

        fpath = os.path.join(opath,output_datafile)
        with open(fpath,'w') as file:
            file.writelines(line + '\n' for line in final_file)
        
        if verbose:
            print("Guardando {}").format( os.path.basename(opath))
        
        return 
    


    def __magneticdata_prepare(self, initial= None,final=None,**kwargs):

        station = kwargs.get("station",None)
        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get('real_time',False)
        force_all = kwargs.get("force_all",False)

        offset = kwargs.get(force_all,numpy.array([]))

        if offset is not None and isinstance(offset,list):
            offset = numpy.array(offset)
        
        if offset is not None and isinstance(offset,numpy.ndarray):

            if offset.shape[0] !=3:
                
                Warning("Valores inconsistentes o invalidos para el atributo OFFSET")
                offset = numpy.array([0,0,0])
        
        if initial is None:
            initial = self.system['today_date']
        if final is None: 
            final = initial 


        check_dates(self,initial=initial,final=final,**kwargs)

        
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
            string_date[i] = "{:4.0f}{:02.0f}{:02.0f}".format(tmp_year,tmp_month,tmp_day)

            data_file_name [i] = '{}{}.rk.min'.format(self.GMS[self.system['gms']]['code'],string_date[i])
            processed_file_name[i] = "{}_{}.dat".format(self.GMS[self.system['gms']]['code'],string_date[i])

        # *.dat file
        exist_processed_file =  [(os.path.isfile( os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],path) ) and True) for path in processed_file_name]    
        exist_processed_file = numpy.array(exist_processed_file,dtype=bool)
        # *.rk.min file
        exist_data_file =  [os.path.isfile( os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],path) ) for path in data_file_name]    
        exist_data_file = numpy.array(exist_data_file,dtype=bool)

        mask1 = numpy.where(exist_processed_file==False)[0]
      


        number1 = len(mask1)
        number2 = exist_processed_file.shape[0] - number1

        if number1 >=1 :
            # revisa los archivos que no se han actualizado
            updating_files = number1
         
        else: 
            updating_files=0

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
         

        for i in range(exist_processed_file.shape[0]):
            if exist_processed_file[i] ==  False:

                valores = re.findall(r'-?\d+\.?\d*', string_date[i])
         
                valores = numpy.array([int(v) if v.isdigit() else float(v) for v in valores])
                
                if valores.shape[0]>0:

                    valores = valores[0]
                    tmp_year, tmp_month,tmp_day = int(str(valores)[:4]),int(str(valores)[4:6]),int(str(valores)[-2:])

                    self.__fixing_datafile(datetime(tmp_year,tmp_month,tmp_day),verbose= verbose,station=station)
                    self.__cleaning_datafile(datetime(tmp_year,tmp_month,tmp_day),verbose=verbose,
                                            station=station,offset=offset, real_time=real_time)
        
        if verbose:
            print("Archivos listos para calcular!")
        return 
    

    def __quietday_get(self,**kwargs):
        #script geomagix_quietday_get
        #        @geomagixs_commons
        # geomagixs_setup_commons, /QUIET
        # geomagixs_check_system, /QUIET
        # geomagixs_setup_dates, STATION=station, /QUIET

        #############################################
        #------------------------------------------------#

        initial = kwargs.get("initial",None)
        station = kwargs.get("station",None)
        real_time = kwargs.get("real_time",False)
        force_all = kwargs.get("force_all",False)
        local = kwargs.get("local",False)
        statistic_qd = kwargs.get("statistic_qd",False)
        verbose = kwargs.get("verbose",False)

        #------------------------------------------------#


        if station == 'planetary':
            if verbose:
                Warning("Inconsistencia: Las condiciones solicitidadas podrían comprometer\
                         los resultados calculados. Es imposible o innecesario calcular Q-day para planetary GMS.")

        #------------------------------------------------#
    
  
        update_flag = 0 

        if initial is None:
            initial = self.system['today_date']
        
        if station is None:

            raise AttributeError('Debe definir la estación para el quietday.')

  
           

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
            qday2   = self.__getting_quietday(datetime(tmp_year,tmp_month,1),station=station,verbose=verbose, local=local)          
            N_days2 = JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(months=+2)+relativedelta(days=-1)) - \
                      JULDAY(datetime(initial_tmp.year,initial_tmp.month,1)+relativedelta(months=+1)+relativedelta(days=-1))


            N_days = JULDAY(initial_tmp)-JULDAY(datetime(initial_tmp.year,
                                                         initial_tmp.month,
                                                         1)+relativedelta(days=-1))

            v = numpy.array([N_days0//2,    N_days0+N_days1//2, N_days0+N_days1+N_days2//2])
            w = numpy.array([N_days0+1*N_days])

            qday  = deepcopy(qday1)
            #INTERPOL( V, X, XOUT )

            for i in range(vectorize(qday1,'H').shape[0]):
              
                DH = numpy.interp(w,v,[numpy.median(qday0[i]['H']),numpy.median(qday1[i]['H']),numpy.median(qday2[i]['H'])])           
                DD = numpy.interp(w,v,[numpy.median(qday0[i]['D']),numpy.median(qday1[i]['D']),numpy.median(qday2[i]['D'])])           
                DZ = numpy.interp(w,v,[numpy.median(qday0[i]['Z']),numpy.median(qday1[i]['Z']),numpy.median(qday2[i]['Z'])])           
                DF = numpy.interp(w,v,[numpy.median(qday0[i]['F']),numpy.median(qday1[i]['F']),numpy.median(qday2[i]['F'])])           
         
                qday[i]['H'] = DH
                qday[i]['D'] = DD
                qday[i]['Z'] = DZ
                qday[i]['F'] = DF

                qday[i]['day']  = initial_tmp.day


        return qday   


    def __getting_magneticdata(self,initial,**kwargs):
        # script geomagixs_quietday_get.pro
        #listo 
 
            
            verbose = kwargs.get('verbose',False)
            station = kwargs.get('station',None)

            initial_year = initial.year
            initial_month = initial.month
            initial_day = initial.day

             
            name = '{:4.0f}{:02.0f}{:02.0f}'.format(initial_year,initial_month,initial_day)
            file_name = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],name)

            file_name = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],file_name)

            exist = os.path.isfile(file_name)

            if exist:
                if verbose: 
                    print("En magnetic data, el archivo {} existe.".format(os.path.basename(file_name)))
                
                with open(file_name,'r') as file:

                    magnetic_data = numpy.array(file.read().splitlines() ,dtype='object')
 

            else:
                    if verbose: 

                        print("En magnetic data, el archivo no existe{} .".format(os.path.basename(file_name)))
                        
                    initial = initial + relativedelta(days=+27)
                    
                    initial_year = initial.year
                    initial_month = initial.month
                    initial_day = initial.day

             
                    # name = '{:4.0f}{:02.0f}{:02.0f}'.format(initial_year,initial_month,initial_day)
                    # file_name = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],name)

                    # file_name = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],file_name)
                    # if verbose:
                    #     print("Intentando con {}".format(os.path.basename(file_name)))

                    # if os.path.isfile(file_name):
                    #     if verbose: 
                    #         print("Se encontró con el archivo {} existe.".format(os.path.basename(file_name)))
                        
                    #     with open(file_name,'r') as file:

                    #         magnetic_data = numpy.array(file.read().splitlines() ,dtype='object')
                    # else:
                    #     if verbose:
                    #         print("En magnetic data, el archivo tampoco existe{} .".format(os.path.basename(file_name)))
                    magnetic_data = numpy.empty(1440,dtype=object)
            ####### Extraemos los datos    

 
            struct = {'year':0,'month':0,'day':0,'hour':0,'minute':0,'sec':0,'doy':0,
                      'D':0,'H':0,'Z':0,'F':0}
 
            key_array = ['year','month','day','hour','minute','sec','doy','D','H','Z','F']
            resulting = numpy.empty(magnetic_data.shape[0],dtype='object')

            resulting = fill(resulting,struct)

            if exist:
                for n,linea in enumerate(magnetic_data):

                    valores = re.findall(r'-?\d+\.?\d*', linea)

                    valores = numpy.array([int(v) if v.isdigit() else float(v) for v in valores])
                  
                    if valores.shape[0]>1:
                        for i,key in enumerate(key_array):
                            resulting[n][key]= valores[i]

            
            


            return resulting


 

    def __reading_kmex_data(self,date,**kwargs):

        
            station = kwargs.get("station",None)
            real_time = kwargs.get("real_time",False)
            verbose = kwargs.get("verbose",False)


            extension = '.early' if real_time else '.final'
            
            if station =='planetary':
                extension=''
            
            name = '{}_{:4.0f}{:02.0f}{:02.0f}.k_index{}'.format(self.GMS[self.system['gms']]['code'],date.year,date.month,date.day,extension)

            file_name = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],name)

            exists = os.path.isfile(file_name)

            dat_str = {'z':numpy.zeros(8),'y':0}

            tmp_var = numpy.empty(6,dtype=object)

            tmp_var = fill(tmp_var,dat_str)
 


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
                    k_index_data = numpy.array(file.read().splitlines() ,dtype='object')
                    
                    keys = [['K_mex','K_SUM'],['a_mex','A_median'],['K_mex_max','K_SUM_max'],['a_mex_max','A_median_max'],['K_mex_min','K_SUM_min'],['a_mex_min','A_median_min']]
                    for n,linea in enumerate(k_index_data):
                        valores = re.findall(r'-?\d+\.?\d*', linea)

                        # Convertir los valores a enteros o números de punto flotante según corresponda
                        valores = [int(v) if v.isdigit() else float(v) for v in valores]                

                  
                        result[keys[n][0]] = numpy.array(valores[:-1])
                        result[keys[n][1]] = numpy.array(valores[-1])
                

            else:
                if verbose:
                    Warning("Archivo perdido {}. Se procede a llenar con datos aleatorios".format(os.path.basename(file_name)))

                
                for key in result.keys():
                    if isinstance(result[key],numpy.ndarray):
                        result[key] = result[key].fill(999)
                    else:
                        result[key]=999
            

       
            return result 
    
    def __making_montlyfile_k(self,initial,**kwargs):

        station = kwargs.get("station",None)
        real_time = kwargs.get("real_time",False)
        verbose = kwargs.get("verbose",False)



        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day


        files_numbers = JULDAY((datetime(initial_year,initial_month,1)+relativedelta(days=-1))+relativedelta(months=1)) - JULDAY(datetime(initial_year,initial_month,1)+relativedelta(days=-1))

        data_file_name = numpy.empty(files_numbers,dtype='object')
        string_date = numpy.empty(files_numbers,dtype=object)
        extention = '.early' if real_time else '.final'

        for i in range(files_numbers):

            tmp_julday = JULDAY(initial)

            result = CALDAT(tmp_julday+i)
            tmp_year,tmp_month,tmp_day = result.year,result.month,result.day
            string_date[i] = (("{:4d}{:02d}{:02d}".format(int(tmp_year),int(tmp_month),int(tmp_day))))
            data_file_name[i] = '{}_{}.k_index{}'.format(self.GMS[self.system['gms']]['code'],string_date[i],extention)
        
        fpaths = [os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],file) for file in data_file_name]
        exist_data_file = [os.path.isfile(path) for path in fpaths]

        tmp = numpy.where(numpy.array(exist_data_file,dtype=bool) == True)[0]
        capable_to_make = len(tmp)

        if capable_to_make  != files_numbers:
            print("Datos invalidos. Reemplazando datos con datos vacios. ")
        

        ###### creating empty containers

        k_mex_data = numpy.empty(files_numbers*8,dtype=int)
        k_SUM_data = numpy.empty(files_numbers,dtype=int)
        a_mex_data = numpy.empty(files_numbers*8,dtype=int)
        a_median_data = numpy.empty(files_numbers,dtype=int)

        for i in range(files_numbers):
            if exist_data_file[i]:
                print("archivo existeee ", fpaths[i])
                tmp_year,tmp_month,tmp_day = string_date[i][:4],string_date[i][4:6],string_date[i][6:8]
                
                tmp_year = int(tmp_year)
                tmp_month = int(tmp_month)
                tmp_day = int(tmp_day)
            
                date = datetime(tmp_year,tmp_month,tmp_day)

                tmp_data = self.__reading_kmex_data(date,verbose=verbose, station=station,real_time=real_time)

                k_mex_data [i*8:(i+1)*8] = tmp_data['K_mex']
                a_mex_data [i*8:(i+1)*8] = tmp_data['a_mex']
                k_SUM_data [i] = tmp_data['K_SUM']
                a_median_data [i] = tmp_data['A_median']
            else:
                print("archivo no existeeeee", fpaths[i])
                k_mex_data [i*8:(i+1)*8] = 999
                a_mex_data [i*8:(i+1)*8] = 999
                k_SUM_data [i] = 999
                a_median_data [i] =999

        cabecera_final  =  21

        file_data = numpy.empty(files_numbers+cabecera_final,dtype=object)

        data_type ='(nowcast)   ' if   real_time else  '(definitive)'

        file_data[0] = ' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
        file_data[1]          =' Source of Data         Space Weather National Laboratory, UNAM                       |'
        str_tmp1 = ''
        for _ in range (61 - len(self.GMS[self.system['gms']]['name'])+1) : str_tmp1+=' '
        file_data[2]          =' Station Name           {}{}|'.format(self.GMS[self.system['gms']]['name'].upper(),str_tmp1)
        file_data[3]        = ' IAGA CODE              {}{}'.format(self.GMS[self.system['gms']]['code'].upper(),'                                                           |')
        file_data[4] =' Geodetic Latitude      {:8.3f}'.format(self.GMS[self.system['gms']]['latitude'])+'                                                      |'
        file_data[5] =' Geodetic Longitude      {:8.3f}'.format(self.GMS[self.system['gms']]['longitude'])+'                                                      |'
        file_data[6] =' Elevation      {:6.1f}'.format(self.GMS[self.system['gms']]['elevation'])+'                                                        |'
        
        file_data[7]          =' Reported               K and a indexes '+data_type+'                                  |'
        file_data[8]          =' Sensor Orientation     variation:DHZF                                                |'
        file_data[9]          =' Digital Sampling       1 seconds                                                     |'
        file_data[10]         =' Data Interval Type     Filtered 3-hours (00:00:00 - 02:59:59)                        |'
        file_data[11]         =' Data Type              Computed                                                      |'
        file_data[12]         =' # Element              16 3-hourly values, and daily-total (k) and daily-average (a) |'
        file_data[13]         =' # Unit                 nT                                                            |'
        file_data[14]         =' # Data Gap             999                                                           |'
        file_data[15]         =' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
        file_data[16]         =' # URL                  http://www.lance.unam.mx                                      |'
        file_data[17]         =' # Last Modified        Aug 17 2022                                                   |'
        file_data[18]         =' # File type            Monthly                                                       |'
        file_data[19]         =' # Reading Format       (I4,I2,I2,3X,I3,3X,9(X, I3),3X,9(X, I3))                      |'
    
        tmp_code = (self.GMS[self.system['gms']]['code'])
        file_data[20] = 'DATE       DOY   K:03  06  09  12  15  18  21  24 Tot   a:03  06  09  12  15  18  21  24 Avg |'

        extention = '.early' if real_time else '.final'
        extention = '' if station=='planetary' else extention

        file_name = '{}_{:4.0f}{:02.0f}.k_index{}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,extention)

        file_dir = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])

        fpath = os.path.join(file_dir,file_name)

        with open(fpath,'w') as file:
            buff = list()
            for line in file_data:
                if line is not None:
                    buff.append(line+'\n')

            file.writelines(buff)

            for i in range(files_numbers):
     
                tmp_year,tmp_month,tmp_day = str(string_date[i])[:4],str(string_date[i])[4:6],str(string_date[i])[6:8]

                tmp_year = int(tmp_year)
                tmp_month = int(tmp_month)
                tmp_day = int(tmp_day)

                tmp_doy = JULDAY(datetime(tmp_year,tmp_month,tmp_day)) - JULDAY(datetime(tmp_year-1,12,31))

                ##################
                ###Generator format
                ###################
                chain = '{:4.0f}{:02.0f}{:02.0f}   {:03.0f}   '
                chain = chain + ' {:3.0f}'*9 + ' '*3 + ' {:3.0f}'*9

                a0,a1,a2,a3,a4,a5,a6,a7 = k_mex_data[i*8],k_mex_data[i*8+1],k_mex_data[i*8+2],k_mex_data[i*8+3],k_mex_data[i*8+4],k_mex_data[i*8+5],k_mex_data[i*8+6],k_mex_data[i*8+7]
                b0,b1,b2,b3,b4,b5,b6,b7 = a_mex_data[i*8],a_mex_data[i*8+1],a_mex_data[i*8+2],a_mex_data[i*8+3],a_mex_data[i*8+4],a_mex_data[i*8+5],a_mex_data[i*8+6],a_mex_data[i*8+7]
                chain = chain.format(int(string_date[i]),tmp_year,tmp_month,tmp_day,tmp_doy,a0,a1,a2,a3,a4,a5,a6,a7,k_SUM_data[i],
                                     b0,b1,b2,b3,b4,b5,b6,b7,a_median_data[i])
                file.write(chain+'\n')
            
        if verbose:
            print("Guardando {}".format(os.path.basename(fpath)))


    def __reading_deltah_data(self,date,**kwargs):


        station = kwargs.get("station",None)
        real_time = kwargs.get("real_time",False)
        verbose = kwargs.get("verbose",False)


        extention = '.early' if real_time  else '.final'
        extention = '' if station=='planetary' else extention

        string_date = '{:4.0f}{:02.0f}{:02.0f}'.format(date.year,date.month,date.day)

        file_name =os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],'{}_{}.delta_H{}'.format(self.GMS[self.system['gms']]['code'],string_date,extention))



        exists = os.path.isfile(file_name)

        if exists:
            with open(file_name,'r') as file:
                k_index_data =  numpy.array(file.read().splitlines() )
                number_of_lines = k_index_data.shape[0]

        
        result = {'delta_H': numpy.empty(25,dtype=float),
                  'sigma_H': numpy.empty(25,dtype=float)}

        tmp = {'z':numpy.empty(25,dtype=float)}

        tmp_var = numpy.empty(2,dtype=object)
        tmp_var = fill(tmp_var, tmp)
        
        for n,linea in enumerate(k_index_data):
            valores = re.findall(r'-?\d+\.?\d*', linea)
            # Convertir los valores a enteros o números de punto flotante según corresponda
            valores = [int(v) if v.isdigit() else float(v) for v in valores]
            if n==0:result['delta_H'] = numpy.array(valores)
            if n==1:result['sigma_H'] = numpy.array(valores)

        return result 

    def __making_montlyfile_dh(self,initial,**kwargs):

        #----------------------------------------------------------------------
        #script -> geomagixs_magneticindex_monthlyfile.pro

        station = kwargs.get("station",None)
        real_time = kwargs.get("real_time",False)
        verbose = kwargs.get("verbose",False)


        ####3

        initial_year = initial.year
        initial_month  = initial.month
        initial_day  = initial.day



        ####

        file_number  = (JULDAY(datetime(initial_year,initial_month,1)+relativedelta(months=1)+relativedelta(days=-1)))
        file_number = file_number - JULDAY(datetime(initial_year,initial_month,1)+relativedelta(days=-1))

        data_file_name = numpy.empty(file_number,dtype='object')

        string_date = numpy.empty(file_number,dtype='object')

        extention = '.early' if real_time else '.final'

        extention = '' if station=='planetary' else extention

        for i in range(file_number):

            result = JULDAY(initial)

            result = CALDAT(result+i)
            tmp_year,tmp_month,tmp_day=result.year,result.month,result.day

            string_date[i] = '{:4.0f}{:02.0f}{:02.0f}'.format(tmp_year,tmp_month,tmp_day)

            data_file_name[i] = '{}_{}.delta_H{}'.format(self.GMS[self.system['gms']]['code'],string_date[i],extention)
        
        fpaths = [os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],file) for file in data_file_name]
        exist_data_file = [os.path.isfile(file) for file in fpaths]

        tmp = numpy.where(exist_data_file==True)[0]
        capable_to_make = len(tmp)

        if capable_to_make != file_number and verbose:
            print("Warning: Valores invalidos, reemplazando valores conflictivos con datos genericos. Archivos de tipo GMS_YYYYMMDD.delta_H{}.".format(extention))

        dH_data = numpy.empty(file_number*25,dtype=float)

        for i in range(file_number):

            if exist_data_file[i] == True:
                
                tmp_year, tmp_month,tmp_day = string_date[i][:4],string_date[i][4:6],string_date[i][6:8]

                tmp_year = int(tmp_year)
                tmp_month = int(tmp_month)
                tmp_day = int(tmp_day)


                tmp_data = self.__reading_deltah_data(datetime(tmp_year,tmp_month,tmp_day),verbose=verbose,station=station,real_time=real_time)

                dH_data [i*25:(i+1)*25] = tmp_data['delta_H']

            else:
                dH_data[i*25:(i+1)*25] = 999999
            

            
        cabecera_final = 21

        file_data = numpy.empty(file_number+cabecera_final,dtype=object)


        data_type ='(nowcast)   ' if   real_time else  '(definitive)'

        file_data[1]          =' Source of Data         Space Weather National Laboratory, UNAM                       |'
        str_tmp1 = ''
        for _ in range (61 - len(self.GMS[self.system['gms']]['name'])+1) : str_tmp1+=' '
        file_data[2]          =' Station Name           {}{}|'.format(self.GMS[self.system['gms']]['name'].upper(),str_tmp1)
        file_data[3]        = ' IAGA CODE              {}{}'.format(self.GMS[self.system['gms']]['code'].upper(),'                                                           |')
        file_data[4] =' Geodetic Latitude      {:8.3f}'.format(self.GMS[self.system['gms']]['latitude'])+'                                                      |'
        file_data[5] =' Geodetic Longitude      {:8.3f}'.format(self.GMS[self.system['gms']]['longitude'])+'                                                      |'
        file_data[6] =' Elevation      {:6.1f}'.format(self.GMS[self.system['gms']]['elevation'])+'                                                        |'
        
        file_data[7]          =' Reported               K and a indexes '+data_type+'                                  |'
        file_data[8]          =' Sensor Orientation     variation:DHZF                                                |'
        file_data[9]          =' Digital Sampling       1 seconds                                                     |'
        file_data[10]         =' Data Interval Type     Filtered 3-hours (00:00:00 - 02:59:59)                        |'
        file_data[11]         =' Data Type              Computed                                                      |'
        file_data[12]         =' # Element              16 3-hourly values, and daily-total (k) and daily-average (a) |'
        file_data[13]         =' # Unit                 nT                                                            |'
        file_data[14]         =' # Data Gap             999                                                           |'
        file_data[15]         =' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
        file_data[16]         =' # URL                  http://www.lance.unam.mx                                      |'
        file_data[17]         =' # Last Modified        Aug 17 2022                                                   |'
        file_data[18]         =' # File type            Monthly                                                       |'
        file_data[19]         =' # Reading Format       (I4,I2,I2,3X,I3,3X,9(X, I3),3X,9(X, I3))                      |'
        file_data[0] = str(' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |')
    
        tmp_code = (self.GMS[self.system['gms']]['code'])
        file_data[20] = 'DATE       DOY   K:03  06  09  12  15  18  21  24 Tot   a:03  06  09  12  15  18  21  24 Avg |'

        extention = '.early' if real_time else '.final'
        extention = '' if station=='planetary' else extention

        file_name = '{}_{:4.0f}{:02.0f}.delta_H{}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,extention)
        
        file_dir = os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])

        fpath = os.path.join(file_dir,file_name)

        if not os.path.isdir(os.path.dirname(fpath)): os.makedirs(os.path.dirname(fpath))

        with open(fpath, 'w') as file:
            buff = list()
            for line in file_data:
                if line is not None:
                     buff.append(line+'\n'  )
            file.writelines(buff)

            for i in range(cabecera_final):
                 
                tmp_year  = int(string_date[i][:4])
                tmp_month = int(string_date[i][4:6])
                tmp_day  = int(string_date[i][6:8])
            
                doy = JULDAY(datetime(tmp_year,tmp_month,tmp_day)) - JULDAY(datetime(tmp_year-1,12,31))
                tmp_chain=''
                for value in dH_data[i*25:(i+1)*25]:
                    tmp_chain = tmp_chain + ' {:8.1f}'.format(value)
            
                chain = '{:4.0f}{:02.0f}{:02.0f}   {:03.0f}   {}'.format(tmp_year,tmp_month,tmp_day,doy,tmp_chain)

                file.write(chain+'\n')
            
        return 
    
    def __magneticindex_monthlyfile(self,initial=None,final=None,**kwargs):
        #--------------------------------- Parameters -----------------------------------#

        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose",False)
        force_all = kwargs.get("force_all",False)
        real_time = kwargs.get("real_time",False)

        #--------------------------------------------------------------------------------#
        # @geomagixs_commons
        # geomagixs_setup_commons, /QUIET
        # geomagixs_check_system, /QUIET
        # geomagixs_setup_dates, STATION=station, /QUIET, /FORCE_ALL

        # geomagixs_check_gms, STATION=station, /QUIET

        if initial is not None and final is not None:
            check_dates(self,initial,final,gms=self.GMS,verbose=verbose,system=self.system)
        if initial is None:
            initial=self.system['today_date']
        if final is None:
            final = initial



        #####3
        initial_year = initial.year
        initial_month = initial.month
        initial_day  = initial.day

        final_year = final.year
        final_month = final.month
        final_day = final.day


        ####### Reading data files

        month_number = (final_month-initial_month)+(final_year-initial_year)*12 + 1
        if month_number ==0: month_number=1

        files_number = (JULDAY(datetime(final_year,final_month,1)+relativedelta(months=+1)+relativedelta(days=-1))-JULDAY(initial-relativedelta(days=-1)))

        data_deltah_name = numpy.empty(files_number,dtype='object')
        data_kmex_name = numpy.empty(files_number,dtype='object')
        data_profiles_name = numpy.empty( files_number,dtype='object')

        string_date = numpy.empty(files_number,dtype='object')

        extention = '.early' if real_time else '.final'

        data_month_dh_name = numpy.empty(month_number,dtype='object')
        data_month_k_name = numpy.empty(month_number,dtype='object')
        data_month_prof_name = numpy.empty(month_number,dtype='object')

        for i in range(month_number):
            tmp_year = initial_year + (i+initial_month-1)//12
            tmp_month = ((i+initial_month)%12) * ((i+initial_month % 12 !=0)) + (12)*((i + initial_month)%12==0)

            string_date [i] = '{:4.0f}{:02.0f}'.format(tmp_year,tmp_month)

            data_month_dh_name[i] = '{}_{}.delta_H{}'.format(self.GMS[self.system['gms']]['code'],string_date[i],extention)
            data_month_k_name[i] = '{}_{}.k_index{}'.format(self.GMS[self.system['gms']]['code'],string_date[i],extention)
            data_month_prof_name[i] = '{}_{}.profiles{}'.format(self.GMS[self.system['gms']]['code'],string_date[i],extention)

        
        ### verify if exists document4
        # verificar path, creo que existe error en el origianl
        fpaths = [ os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'],file) for file in data_month_k_name]
        exist_monthly_file = [os.path.isfile(file) and not force_all for file in fpaths]

        capable_to_update = len(exist_monthly_file)
        files_to_update = len(numpy.where(numpy.array(exist_monthly_file,dtype=bool) != True)[0])

        if verbose or force_all is True:

            if files_to_update > 0 :
                print("Un total de {} archivo(s) necesitan ser actualizados.".format(files_to_update))

            else:
                print("No hay archivos requeridos a actualizar.")
        
            if capable_to_update > files_to_update:
                print("Hay todavía {} archivo(s) que pueden ser actualizados. Usa el comando /FORCE_ALL para forzar la actualización.".format(capable_to_update-files_to_update))

        
        for i in range(month_number):

            if exist_monthly_file[i] == 0:
                tmp_year,tmp_month,tmp_day = string_date[i][:4],string_date[i][4:6],string_date[i][-2:]
                
                tmp_year = int(tmp_year)
                tmp_month = int(tmp_month)
                tmp_day = int(tmp_day)


                date = datetime(tmp_year,tmp_month,1)

                self.__making_montlyfile_dh(date, station= self.GMS[self.system['gms']]['name'],verbose= verbose,real_time=real_time)
                self.__making_montlyfile_k(date, station= self.GMS[self.system['gms']]['name'],verbose= verbose,real_time=real_time)

        if verbose:
            print("delta H-plot archivos fueron actualizados.")
        
        return 
 
    def __getting_local_qdays(self,initial,station= None,verbose=False,real_time=False):
            '''
            script -> geomagixs_get_quietday.pro
            
            '''
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

            data_qd = fill(data_qd,str_tmp)
     
            for i in range(days_for_qdays):
                
                result = CALDAT(julday_tmp+1-i)
                data_qd[i]['year'] = result.year
                data_qd[i]['month'] = result.month
                data_qd[i]['day'] = result.day

                tmp = self.__reading_kmex_data(result,station=station, verbose=verbose,real_time=real_time)

                data_qd[i]['total_k'] = float(tmp['K_SUM'])
                
                
                good_indexes = tmp['K_mex']<99
                good_indexes_count  = numpy.count_nonzero(good_indexes)

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

                        tmp_chain ='{:4.0f}'.format(tmp_y[0])+space(1)
                        for n,tmp in enumerate(tmp_d):
                            tmp_chain = tmp_chain + space(2)+'{:2.0f}'.format(tmp)
                            if n==4:
                                tmp_chain = tmp_chain + space(2)
                        

                    else:
                        tmp_y = [data_qd[valid_days[0]]['year']]
                        tmp_d = [data['day'] for data in data_qd[valid_days]]
                        tmp_chain ='{:4.0f}'.format(tmp_y[0])+space(1)

                        for n,tmp in enumerate(tmp_d):
                            tmp_chain = tmp_chain + space(2) + '{:2.0f}'.format(tmp)
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

 
    def __getting_statistic_quietday(self, initial, station= None, verbose=False,real_time=False,local=False):
        
        
        
            initial_year = initial.year
            initial_month = initial.month
            initial_day = initial.day



            kmex_days_for_median = 27
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

                tmp = '{:4.0f}{:02.0f}{:02.0f}'.format(tmp_year,tmp_month,tmp_day)

                string_date[n] = tmp
                kmex_file_name[n] = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],string_date[n])


            fpath = [os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],path) for path in kmex_file_name]
            fpath = numpy.array(fpath,dtype=object)

            exists = numpy.array([os.path.isfile(path) for path in  fpath])
 
           
            for i in range(kmex_days_for_median):
                if exists[i]:
                    if verbose:
                        print("Archivo {} existe".format(os.path.basename(fpath[i])))

                    result = CALDAT(tmp_julday+i)

                    tmp_month = result.month
                    tmp_year = result.year 
                    tmp_day = result.day

                    tmp_data = self.__getting_magneticdata(datetime(tmp_year,tmp_month,tmp_day),
                                                           station=station,
                                                           verbose=verbose,
                                                           ) 
                    
                
                    D_values[i] = deepcopy(vectorize(tmp_data,'D'))
                    H_values[i] = deepcopy(vectorize(tmp_data,'H'))
                    Z_values[i] = deepcopy(vectorize(tmp_data,'Z'))
                    F_values[i] = deepcopy(vectorize(tmp_data,'F'))

                else:
                    if verbose:
                        print("Archivo {} no existe.".format(os.path.basename(fpath[i])))


                    tmp_data = self.__getting_magneticdata(CALDAT(tmp_julday),station=station,verbose=verbose)

                    # D_values[i] = deepcopy(vectorize(tmp_data,'D'))
                    # H_values[i] = deepcopy(vectorize(tmp_data,'H'))
                    # Z_values[i] = deepcopy(vectorize(tmp_data,'Z'))
                    # F_values[i] = deepcopy(vectorize(tmp_data,'F'))


            D_median = numpy.empty(minutes_per_day,dtype=float)
            D_median.fill(9999)

            D_sigma = deepcopy(D_median)

            H_median = numpy.empty(minutes_per_day)
            H_median.fill(999999)

            Z_median = deepcopy(H_median)
            F_median = deepcopy(H_median)
            N_median = deepcopy(H_median)
            H_sigma  = deepcopy(H_median)
            Z_sigma  = deepcopy(H_median)
            F_sigma  = deepcopy(H_median)
            N_sigma  = deepcopy(H_median)

            number_of_data = numpy.empty(minutes_per_day,dtype=int)

            arc_secs_2rads = numpy.pi/(60*180)

            keys = ['year','month','day','hour','minute','D','H','Z','F','dD','dH','dZ','dF']
            struct = dict.fromkeys(keys,0)

            qday = numpy.empty(1440,dtype='object')
            qday = fill(qday,struct)
        

            time_days = numpy.arange(kmex_days_for_median)+1
          
            for i in range(minutes_per_day):

                valid_days = numpy.ravel(numpy.abs((H_values[:,i])<999990.00).astype(bool))
                
                
                count  = numpy.count_nonzero(valid_days)
            
                valid_days = numpy.where(valid_days)[0]
                number_of_data[i] = count

                if number_of_data[i]>= statistic_limit:
 
                    if number_of_data[i] >= quadratic_limit:

                        x = time_days[valid_days]
                        y = D_values[valid_days,i]
                   
                        fit = POLY_FIT(x,y,2)
                        result = fit.result
                        status_result = fit.status_result
                        delta = fit.delta
                        tendency = fit.tendency

                        status_result = numpy.isnan(result).any()
                     
                        if status_result is True or number_of_data[i] < quadratic_limit:
                            
                            
                            result = numpy.polyfit(x,y,1)
                            tendency = numpy.polyval(result,x)
                            delta = numpy.std(tendency-y)

                            status_result = numpy.isnan(result).any()
                            
                      
                
                            status_result = False
                            
                        if status_result:
                            qday[i]['D'] = numpy.median(y)
                            qday[i]['dD'] = numpy.var(y) 
                            #print("calculo11",qday[i]['D'],qday[i]['dD'])
                            
                        else:
                            #INTERPOL(y, x, xinterp)
                            qday[i]['D'] = numpy.median(y-tendency) + \
                                            numpy.interp(time_days[valid_days[number_of_data[i]-1]]+1,time_days[valid_days],tendency)
                            qday[i]['D'] = numpy.median(qday[i]['D']) 

                            qday[i]['dD'] = numpy.var(y-tendency)
                            #print("calculo22",qday[i]['D'],qday[i]['dD'])
                       


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

                            status_result = False
                            
                        if status_result is True:
                            qday[i]['H'] = numpy.median(y)
                            qday[i]['dH'] = numpy.var(y)
                        else:
                            #INTERPOL(y, x, xinterp)
                            qday[i]['H'] = numpy.median(y-tendency) + numpy.interp(time_days[valid_days[number_of_data[i]-1]]+1,time_days[valid_days],tendency)
                            qday[i]['H'] = numpy.median(qday[i]['H'])
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
                            

                        
                            status_result=False
                            
                        if status_result is True:
                            qday[i]['Z'] = numpy.median(y)
                            qday[i]['dZ'] = numpy.var(y)
                        else:
                            #INTERPOL(y, x, xinterp)
                            qday[i]['Z'] = numpy.median(y-tendency) + numpy.interp(time_days[valid_days[number_of_data[i]-1]]+1,time_days[valid_days],tendency)
                            qday[i]['Z'] = numpy.median(qday[i]['Z'])
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
                        
                            
                            result = numpy.polyfit(x,y,1)
                            tendency = numpy.polyval(result,x)
                   
  
                            status_result=False
                            
                        if status_result is True :
                            qday[i]['F'] = numpy.median(y)
                            qday[i]['dF'] = numpy.var(y)
                        else:
                            #INTERPOL(y, x, xinterp)
                            qday[i]['F'] = numpy.median(y-tendency) + numpy.interp(time_days[valid_days[number_of_data[i]-1]]+1,time_days[valid_days],tendency)
                            qday[i]['F'] = numpy.median(qday[i]['F'])
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
            smoothing_index = (60*24)//numpy.ceil(smoothing_period)

         
            tmp_arr[int(smoothing_index):int(60*24-smoothing_index)] = 0 
            
            tmp_arr_2 = numpy.fft.ifft(tmp_arr).real 
            numpy.set_printoptions()
       

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
 
            array1 = vectorize(qday[n_elements-smooth_steps:n_elements],key)
            array2 = vectorize(qday[:smooth_steps],key)

            smoothed_array =  numpy.concatenate((array1,array2))
            smoothed_array = smooth(smoothed_array,smooth_witdh)
 
            for n in range(smooth_steps):
                qday[n_elements-smooth_steps+n][key] = smoothed_array[n]
                qday[n][key]            = smoothed_array[smooth_steps+n]

 
            #########################################################
            #########################################################
            #########################################################
            key='D'

            smooth_steps = 30
            smooth_witdh = 10

            n_elements = vectorize(qday,key).shape[0]
            array1 = vectorize(qday[n_elements-smooth_steps:n_elements],key)
            array2 = vectorize(qday[:smooth_steps],key)

            smoothed_array =  numpy.concatenate((array1,array2))
            smoothed_array = smooth(smoothed_array,smooth_witdh)

            for n in range(smooth_steps):
                qday[n_elements-smooth_steps+n][key] = smoothed_array[n]
                qday[n][key]            = smoothed_array[smooth_steps+n]
            #########################################################
            #########################################################
            #########################################################
            key='F'

            smooth_steps = 30
            smooth_witdh = 10

            n_elements = vectorize(qday,key).shape[0]
            array1 = vectorize(qday[n_elements-smooth_steps:n_elements],key)
            array2 = vectorize(qday[:smooth_steps],key)

            smoothed_array =  numpy.concatenate((array1,array2))
            smoothed_array = smooth(smoothed_array,smooth_witdh)

            for n in range(smooth_steps):
                qday[n_elements-smooth_steps+n][key] = smoothed_array[n]
                qday[n][key]            = smoothed_array[smooth_steps+n]
            #########################################################
            #########################################################
            #########################################################
            key='Z'

            smooth_steps = 30
            smooth_witdh = 10

            n_elements = vectorize(qday,key).shape[0]
            array1 = vectorize(qday[(n_elements-smooth_steps):n_elements],key)
            array2 = vectorize(qday[:smooth_steps],key)

            smoothed_array =  numpy.concatenate((array1,array2))
            smoothed_array = smooth(smoothed_array,smooth_witdh)

            for n in range(smooth_steps):
                qday[n_elements-smooth_steps+n][key] = smoothed_array[n]
                qday[n][key]            = smoothed_array[smooth_steps+n]
            
            #preparing data for storing
            return qday
            

 
        
    
    def  __getting_quietday(self,initial,**kwargs):

        # script -> geomagixs_quietday_get.pro
        #-------------------------------------------------------------------------#
        #         
        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose",False)
        real_time = kwargs.get("real_time", False)
        local   = kwargs.get("local",False)

        #-------------------------------------------------------------------------#

        if station is None:
            raise AttributeError("El valor de station no debe ser nulo.")
        
        #-------------------------------------------------------------------------#
 
        initial_date = initial 
        #[YYYY, MM, DD] 
        if real_time is True:
            result = CALDAT(JULDAY(datetime(initial.year,initial.month,1)+relativedelta(days=-1)))
            initial_date = initial  = datetime(result.year,result.month,result.day)
            
# JULDAY(Month, Day, Year, Hour, Minute, Second
        tmp_julian = JULDAY(datetime(initial.year,initial.month,1))

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
        


        tmp_today_year = (self.system['today_date'].year//1000)*1000+((self.system['today_date'].year % 1000)//100)*100+(((self.system['today_date'].year % 1000) %100)//10)*10

        tmp_julian = JULDAY(datetime(initial_date.year,tmp_month,1))
        tmp_julian_1  = JULDAY(datetime(tmp_today_year,1,1))
        tmp_julian_2  = JULDAY(datetime(tmp_today_year,12,31)+relativedelta(years=+9))

 
        if tmp_julian < tmp_julian_1:
            file_name = 'qd{:04.0f}{:02.0f}.txt'.format(tmp_year,tmp_decade+9)
        elif (tmp_julian>= tmp_julian_1) and(tmp_julian<=tmp_julian_2):
            file_name = 'qd{:4.0f}{:01.0f}x.txt'.format(tmp_year,tmp_decade//10)

        else: 
            print("Error con la entrada de datos!!!")
            return None

        

        fpath = os.path.join(self.system['qdays_dir'],file_name)

        exists = os.path.exists(fpath)
        
        if not exists:
            if verbose:
                print("Error abriendo el archivo qday {} en el directorio {}.".format(os.path.basename(fpath),os.path.dirname(fpath)))
            return 
        
        with open(fpath,'r') as f:

            qds_list_data = numpy.array(f.read().splitlines() ,dtype='object')
        
        #buscamos la linea donde se encuentra la fecha deseada 
        tmp_year = tmp_year0

        tmp_doy = JULDAY(datetime(tmp_year,tmp_month,tmp_day))-JULDAY(datetime(tmp_year,1,1))
        
        try:
            tmp_string  = months[tmp_month]
        except IndexError as e:

            raise IndexError("Ocurrió un error al buscar el string de fechas")
        
        date_str = ' {} {:4.0f}'.format(tmp_string,tmp_year)



        # Aplicar conversión a minúsculas
        lowercase_arr = array_to_lower(qds_list_data)
        
        
        buff = numpy.empty(lowercase_arr.shape[0],dtype=object)

        for n,array in enumerate(lowercase_arr): buff[n] = array[:9]


        # numpy.core.defcharaarray return 0 si hay elementos que coinciden
        # en otro caso solo retorna -1 
        valid_line = numpy.core.defchararray.find(buff.astype(str), date_str)
 
 
        valid_line = numpy.array([True if x == 0 else False for x in valid_line])
       
        valid_line = numpy.where(valid_line)[0]

        tmp_str = {'quiet_day' : numpy.empty(10,dtype=int)}

      
    
        standar_day_list = numpy.empty(1,dtype=object)
        standar_day_list = fill(standar_day_list,tmp_str)


        count = numpy.count_nonzero(valid_line)

        if count >0 and local is False:
       
            valores = qds_list_data[valid_line][0][9:]
      
 
       
            valores = re.findall(r'-?\d+\.?\d*', valores)

            #solo extraemos los valores de dias quietos
            valores = valores[:10]
            
            standar_day_list = numpy.array([int(x) for x in valores],dtype=int)

            standar_day_list = numpy.array([{'quiet_day':standar_day_list}],dtype='object')

     
        
        else:
            if local is False:
                if verbose:
                    print("Invalido o datos perdidos de planetary Q-days.\
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
        
        ###############################################################

        minutes_per_day = 1440
      
        struct = { 'year' :     numpy.empty(minutes_per_day,dtype=int),
                   'month' :    numpy.empty(minutes_per_day,dtype=int),
                   'day':       numpy.empty(minutes_per_day,dtype=int),
                   'hour':      numpy.empty(minutes_per_day,dtype=int),
                   'minute':    numpy.empty(minutes_per_day,dtype=int),
                   'D':         numpy.empty(minutes_per_day,dtype=float).fill(9999),
                   'H':         numpy.empty(minutes_per_day,dtype=float).fill(999999),
                   'Z':         numpy.empty(minutes_per_day,dtype=float).fill(999999),
                   'F':         numpy.empty(minutes_per_day,dtype=float).fill(999999),
                   'D_median':  9999,
                   'H_median':  999999,
                   'Z_median':  999999,
                   'F_median':  999999}

        qd_data = numpy.empty(standar_day_list[0]['quiet_day'].shape[0],dtype=object)
        qd_data = fill(qd_data,struct)

        struct = {'year':0 , 'month':0,'day':0,'hour':0,'minute':0,'D':9999,'H':999999,'Z':999999,
                    'dD':9999,'dH':999999,'dZ':999999,'dF':999999}
        
        qday = numpy.empty(minutes_per_day,dtype='object')

        qday = fill(qday,struct)
     

        data_file_list = numpy.empty(standar_day_list[0]['quiet_day'].shape[0],dtype='object')

        for i in range(standar_day_list[0]['quiet_day'].shape[0]):
            
            date = datetime(tmp_year,tmp_month,1) + relativedelta(days=-1)+ relativedelta(days=int(standar_day_list[0]['quiet_day'][i]) )
            tmp = self.__getting_magneticdata(initial=date,station=station,verbose=verbose)
            
            
            for k in ['year','month','day','hour','minute','D','H','Z','F']:
                qd_data[i][k] = vectorize(tmp,k)
            
                #print("tmp data qday getting ", k,qd_data[i][k])

            mask = numpy.abs(qd_data[i]['H']) < 999990.00
            mask = mask.astype(bool)

         

          
            indexes = numpy.where(mask)[0]
            count = numpy.count_nonzero(mask)
            

            if count >0:
                for a,b in zip(['D_median','H_median','Z_median','F_median'],['D','H','Z','F']):
                    qd_data[i][a] = numpy.median(qd_data[i][b][indexes]).astype('float64')
               
                    qd_data[i][b][indexes] = qd_data[i][b][indexes]  -qd_data[i][a]


        for n, _ in enumerate(qday):

            qday[n]['year'] = initial_date.year
            qday[n]['month'] = initial_date.month
            qday[n]['day']  = 1
            qday[n]['hour'] = qd_data[0]['hour']
            qday[n]['minute'] = qd_data[0]['minute']


        # for n,element in enumerate(qd_data):
        #     print("shapeee qdata H",qd_data[n]['H'].shape)
        buff_h = vectorize(qd_data,'H')
 
        for i in range(minutes_per_day):
        
            mask = (numpy.ravel(buff_h[:,i]) < 999990).astype(bool)

            count = numpy.count_nonzero(mask)
            
            indexes = numpy.where(mask)[0]

            
                
            for a,da,c in zip(['D','H','Z','F'],['dD','dH','dZ','dF'],['D_median','H_median','Z_median','F_median']):
                if count >= 2 and count <5 :

                    buff = vectorize(qd_data[indexes],a)
                    buff2 = vectorize(qd_data[indexes],c)

                    qday[i][a] = numpy.mean(buff[:,i])+ numpy.median(buff2)
                    qday[i][da] = numpy.std(buff[:,i])
 
                elif count >= 5:
                    buff = vectorize(qd_data[indexes[:5]],a)
                    buff2 =vectorize(qd_data[indexes[:5]],c)
                    qday[i][a] = numpy.mean(buff[:,i])+ numpy.median(buff2)
                    qday[i][da] = numpy.std(buff[:,i])                

               
                
        

        TS_N_ELEMENTS = numpy.ravel(vectorize(qday,'H')).shape[0]


        temp_H = numpy.empty(3*TS_N_ELEMENTS,dtype = float)
        temp_D = deepcopy(temp_H)
        temp_Z = deepcopy(temp_H)
        temp_F = deepcopy(temp_H)

        #########################################################################
        #########################################################################
        #########################################################################

        temp_H [:TS_N_ELEMENTS] = deepcopy(numpy.ravel(vectorize(qday,'H')))
 
        temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS] = deepcopy(numpy.ravel(vectorize(qday,'H')))
        temp_H [2*TS_N_ELEMENTS:] = deepcopy(numpy.ravel(vectorize(qday,'H')))
        
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
        
        temp_D [:TS_N_ELEMENTS] = numpy.ravel(vectorize(qday,'D'))
        temp_D [TS_N_ELEMENTS:2*TS_N_ELEMENTS] = numpy.ravel(vectorize(qday,'D'))
        temp_D [2*TS_N_ELEMENTS:] = numpy.ravel(vectorize(qday,'D'))
        
        mask = temp_D < 9990
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
        
        temp_Z [:TS_N_ELEMENTS] = numpy.ravel(vectorize(qday,'Z'))
        temp_Z [TS_N_ELEMENTS:2*TS_N_ELEMENTS] = numpy.ravel(vectorize(qday,'Z'))
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
        
        temp_F [:TS_N_ELEMENTS] = numpy.ravel(vectorize(qday,'F'))
        temp_F [TS_N_ELEMENTS:2*TS_N_ELEMENTS] = numpy.ravel(vectorize(qday,'F'))
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
            tmp_vector = temp_H[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour]
            mask = numpy.abs(tmp_vector) <999990.0
            mask = mask.astype(bool)


            count = numpy.count_nonzero(mask)
            valid_indexes = numpy.where(mask)[0]

            if count <= 0 :
                raise ValueError("Error critico, no hay datos para calcular Quiet Day")

            # falta revisar
            result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,2)
            status_result = numpy.isnan(result).any()
    
            tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
            
            if status_result is True:
                result = numpy.polyfit(one_hour_arr[valid_indexes],tmp_vector,1)
                tendency = numpy.polyval(result,one_hour_arr[valid_indexes])
                delta = numpy.std(tendency-tmp_vector)

         
                status_result = False
                
            if status_result is True: 
                #INTERPOL(y, x, xinterp)

                interp = splrep (one_hour_arr[valid_indexes],tmp_vector[valid_indexes],kind='quadratic')
                tendency = interp(one_hour_arr)
                  
            
            deviation = numpy.std(tmp_vector[valid_indexes]-tendency[valid_indexes])
            median_value = numpy.median(numpy.abs(tmp_vector[valid_indexes]-tendency[valid_indexes]))

            mask = numpy.abs(tmp_vector-tendency)>(median_value+deviation_criteria*deviation) 

            mask = mask.astype(bool)

            bad_indexes_count = numpy.count_nonzero(mask)
            bad_indexes = numpy.where(mask)[0]

            if bad_indexes_count >0:
                temp_H[bad_indexes + TS_N_ELEMENTS -one_hour + i*half_hour] = tendency[bad_indexes]

            
            ####################
            # D-section
            tmp_vector = temp_D[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour]
            mask = numpy.abs(tmp_vector) <9990.0
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

                 
                status_result = False
                
            if status_result is True: 
                #INTERPOL(y, x, xinterp)
                interp = splrep (one_hour_arr[valid_indexes],tmp_vector[valid_indexes],kind='quadratic')
                tendency = interp(one_hour_arr)


            deviation = numpy.std(tmp_vector[valid_indexes]-tendency[valid_indexes])
            median_value = numpy.median(numpy.abs(tmp_vector[valid_indexes]-tendency[valid_indexes]))

            mask = numpy.abs(tmp_vector-tendency)>(median_value+deviation_criteria*deviation) 

            mask = mask.astype(bool)

            bad_indexes_count = numpy.count_nonzero(mask)
            bad_indexes = numpy.where(mask)[0]

            if bad_indexes_count >0:
                temp_D[bad_indexes + TS_N_ELEMENTS -one_hour + i*half_hour] = tendency[bad_indexes]

            
            ####################
            # Z-section
            tmp_vector = temp_Z[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour]
            mask = numpy.abs(tmp_vector) <999990.0
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

                
                status_result = False
                
            if status_result is True: 
                #INTERPOL(y, x, xinterp)
                interp = splrep (one_hour_arr[valid_indexes],tmp_vector[valid_indexes],kind='quadratic')
                tendency = interp(one_hour_arr)


            deviation = numpy.std(tmp_vector[valid_indexes]-tendency[valid_indexes])
            median_value = numpy.median(numpy.abs(tmp_vector[valid_indexes]-tendency[valid_indexes]))

            mask = numpy.abs(tmp_vector-tendency)>(median_value+deviation_criteria*deviation) 

            mask = mask.astype(bool)

            bad_indexes_count = numpy.count_nonzero(mask)
            bad_indexes = numpy.where(mask)[0]

            if bad_indexes_count >0:
                temp_Z[bad_indexes + TS_N_ELEMENTS -one_hour + i*half_hour] = tendency[bad_indexes]
            
            ####################
            # F-section
            tmp_vector = temp_F[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour]
            mask = numpy.abs(tmp_vector) <999990.0
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

                
                status_result = False
                
            if status_result is True: 
                #INTERPOL(y, x, xinterp)
                interp = splrep (one_hour_arr[valid_indexes],tmp_vector[valid_indexes],kind='quadratic')
                tendency = interp(one_hour_arr)


            deviation = numpy.std(tmp_vector[valid_indexes]-tendency[valid_indexes])
            median_value = numpy.median(numpy.abs(tmp_vector[valid_indexes]-tendency[valid_indexes]))

            mask = numpy.abs(tmp_vector-tendency)>(median_value+deviation_criteria*deviation) 

            mask = mask.astype(bool)

            bad_indexes_count = numpy.count_nonzero(mask)
            bad_indexes = numpy.where(mask)[0]

            if bad_indexes_count >0:
                temp_F[bad_indexes + TS_N_ELEMENTS -one_hour + i*half_hour] = tendency[bad_indexes]

        ####################################################################################################
        ####################################################################################################
        ####################################################################################################


        two_hour_arr = numpy.arange(2*one_hour)
        Delta_time = 40 
        minutes_for_smoothing = 11

        ##############################
        # H-section 
        key = 'H'
        buff = numpy.ravel(vectorize(qday,key))
        mask = numpy.abs(buff) < 999990
        mask = mask.astype(bool)
        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : 
            raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[:one_hour-Delta_time], two_hour_arr[one_hour+Delta_time:2*one_hour]]))
        y  = numpy.ravel(numpy.array([temp_H[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-Delta_time], temp_H[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour]]))
        xest = two_hour_arr

        f = splrep(x,y)
        tendency =   splev(xest,f)
 

        temp_H[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour]     = splev(xest[one_hour:2*one_hour],f)   
        temp_H[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS] = splev(xest[:one_hour],f)   


        for n,_ in enumerate(qday):
            qday[n][key] = smooth(temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS],minutes_for_smoothing)[n]+tmp_median
            
            # if(key=='H'):
            #     print("checaaa H",qday[n][key]) 


        ####################################################################################################
        ####################################################################################################
        ####################################################################################################
        ##############################
        # D-section 
        key = 'D'
        buff = numpy.ravel(vectorize(qday,key))
        mask = numpy.abs(buff) < 9990
        mask = mask.astype(bool)
        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[:one_hour-Delta_time], two_hour_arr[one_hour+Delta_time:2*one_hour]]))
        y  = numpy.ravel(numpy.array([temp_D[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-Delta_time], temp_D[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour]]))
        xest = two_hour_arr

        f = splrep(x,y)
        tendency = splev(xest,f)
         

        temp_D[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour]     = splev(xest[one_hour:2*one_hour],f)   
        temp_D[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS] = splev(xest[:one_hour],f)  

        for n,_ in enumerate(qday):
            qday[n][key] = smooth(temp_D[TS_N_ELEMENTS:2*TS_N_ELEMENTS],minutes_for_smoothing)[n]+tmp_median
        
        ##############################
        # Z-section 
        key = 'Z'
        buff = numpy.ravel(vectorize(qday,key))
        mask = numpy.abs(buff) < 999990
        mask = mask.astype(bool)
        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[:one_hour-Delta_time], two_hour_arr[one_hour+Delta_time:2*one_hour]]))
        y  = numpy.ravel(numpy.array([temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-Delta_time], temp_Z[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour]]))
        xest = two_hour_arr

        f = splrep(x,y )
        
        tendency = splev(xest,f)

        temp_Z[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour]     = splev(xest[one_hour:2*one_hour],f)  
        temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS] = splev(xest[:one_hour],f)  

        for n,_ in enumerate(qday):
            qday[n][key] = smooth(temp_Z[TS_N_ELEMENTS:2*TS_N_ELEMENTS],minutes_for_smoothing)[n]+tmp_median
        
        ##############################
        # F-section 
        key = 'F'

        buff = numpy.ravel(vectorize(qday,key))

        mask = numpy.abs(buff) < 999990
        mask = mask.astype(bool)

        tmp_valid_indexes_count = numpy.count_nonzero(mask)
        tmp_valid_indexes = numpy.where(mask)[0]

        if tmp_valid_indexes_count <0 : raise ValueError("No hay data para calcular Quiet Day.")

        tmp_median = numpy.median(vectorize(qday[tmp_valid_indexes],key))
        #INTERPOL(y, x, xinterp)

        x  = numpy.ravel(numpy.array([two_hour_arr[:one_hour-Delta_time], two_hour_arr[one_hour+Delta_time:2*one_hour]]))
        y  = numpy.ravel(numpy.array([temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-Delta_time], temp_Z[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour]]))
        xest = two_hour_arr

        f = splrep(x,y )
        
        tendency = splev(xest,f)

        temp_Z[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour]     = splev(xest[one_hour:2*one_hour],f)  
        temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS] = splev(xest[:one_hour],f)  

        for n,_ in enumerate(qday):
            qday[n][key] = smooth(temp_Z[TS_N_ELEMENTS:2*TS_N_ELEMENTS],minutes_for_smoothing)[n]+tmp_median
        
 
        #Hay un goto,jump

        return qday 
        
        
         







 






            





    def __making_processedplanetarydatafiles(self,initial,**kwargs):
        station = kwargs.get('station',None)
        verbose = kwargs.get('verbose',False)
        real_time = kwargs.get("real_time",False)

        initial_year = initial.year
        initial_month = initial.month
        initial_day  = initial.day

        string_date = '{:4.0f}{:02.0f}{:02.0f}'.format(initial_year,initial_month,initial_day)

        kmex_file_name = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],string_date)

        kmex_file_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],kmex_file_name)

        exist_kmex_file = os.path.isfile(kmex_file_path)


        if exist_kmex_file:
            
            with open(exist_kmex_file,'r') as file:

                tmp_data = file.read().splitlines() 
                tmp_data = numpy.array(tmp_data,dtype='object')
                number_of_lines = tmp_data.shape[0]
            

                keys = ['kp','total_kp','Ap','average_Ap','dst','average_dst']
                str_tmp = dict.fromkeys(keys,0)

                index_data = numpy.empty(number_of_lines,dtype='object')
                index_data = fill(index_data,str_tmp)
 

                for n,linea in enumerate(number_of_lines):

                    valores = re.findall(r'-?\d+\.?\d*', linea)

                    # Convertir los valores a enteros o números de punto flotante según corresponda
                    valores = [int(v) if v.isdigit() else float(v) for v in valores]
                    for valor,key in zip(valores,keys):
                        index_data[n][key] = valor
        else:

            if verbose:
                raise FileNotFoundError("Imposible leer los datos del archivo {}. Archivos perdidos.".format(kmex_file_name))
            return  
        
        if verbose:
            print("Reuniendo datos de la fecha: {:04.0f}/{:02.0f}/{:02.0f}".format(initial_year,initial_month,initial_day))
        
        file_data = numpy.empty(24,dtype='object')
        file_differences = numpy.empty(8,dtype='object')

        for i in range (24):
            chain = '{:03.0f} {:02.0f}:{:02.0f}   {:5.0f}   {:5.0f}'
            file_data[i] = chain.format(i,i,0,index_data[i]['dst'],index_data[i]['average_dst'])
        
        for i in range(8):
            chain = '{:02.0f}   {:4.0f}   {:4.0f}   {:5.0f}   {:5.0f}'
            file_differences[i] = chain.format(i*3,index_data[i*3]['kp'],index_data[i*3]['total_kp'],index_data[i*3]['kp'],index_data[i*3]['average_Ap'])

        extention = ''
        output_file = '{}_{:4.0f}{:02.0f}{:02.0f}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)

        output_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])

        exist_dir = os.path.isdir(output_path)

        if not exist_dir:
            if verbose:
                raise NotADirectoryError("Error critico: Directorio perdido {}. Revisa el directorio.".format(output_path))
            return

        fpath = os.path.join(output_path,output_file+'.differences'+extention)

        with open(fpath,'w') as file:
            file.writelines(line+'\n' for line in file_differences)
        if verbose:
            print("Guardando {}".format(os.path.basename(fpath)))
        fpath = os.path.join(output_path,output_file+'.data'+extention)

        with open(fpath,'w') as file:
            file.writelines(line +'\n' for line in file_data)        
        if verbose:
            print("Guardando {}".format(os.path.basename(fpath)))

        return        


    def __magneticdata_process(self,initial,final,**kwargs):
        '''
        Secuencia principal
        
        script -> geomagixs_magneticdata_process.pro
        '''
        
        station = kwargs.get('station',None)
        verbose = kwargs.get('verbose',None)
        force_all = kwargs.get('force_all',False)
        statistic_qd = kwargs.get('statistic_qd',None)
        real_time = kwargs.get('real_time',False)
        #################################################################
        ###############################################################################3

        # inicializamos fecha y hora

        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day

        final_year = final.year
        final_month = final.month
        final_day  = final.day

        ###### Leyendo archivo de datos 

        file_number = (JULDAY(final)-JULDAY(initial))+1

        data_file_name = numpy.empty(file_number,dtype='object')

        string_date = numpy.empty(file_number,dtype='object')

        extention = '.early' if real_time else '.final'

        tmp_julday = JULDAY(initial)

        for i in range(file_number):

            result = CALDAT(tmp_julday+i)
            tmp_year,tmp_month,tmp_day = result.year,result.month,result.day

            string_date[i]  = '{:4.0f}{:02.0f}{:02.0f}'.format(tmp_year,tmp_month,tmp_day)
            data_file_name[i] = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],string_date[i])

        fpath = numpy.array([os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],file) for file in data_file_name],dtype='object')

        exist_data_file = [os.path.isfile(path) for path in fpath]
        exist_data_file = numpy.array(exist_data_file,dtype='bool')

        capable_to_update = len(numpy.where(exist_data_file==True)[0])

        if verbose:
            if capable_to_update <1 :
                print("Data files Error: No hay archivos con el formato GMS_YYYYMMDD.clean.dat")
                print("La data será asumido con valores vacios")
            
        
        exist_result_file = [os.path.isfile(os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],'{}_{}.data{}'.format(self.GMS[self.system['gms']]['code'],date,extention))) and not force_all for date in string_date]
        exist_result_file = numpy.array(exist_result_file,dtype='bool')
        make_update_file = exist_data_file & ~exist_result_file


        total = numpy.count_nonzero(make_update_file)

        if total >0:
            files_to_update = len(numpy.where(make_update_file==True)[0])
        else:
            files_to_update = 0
        
        if verbose:
            if  files_to_update >0:
                print("Un total de {} archivos necesitan ser actualizados".format(files_to_update))
            else:
                print("Ningún archivo será actualizado")
            
            if capable_to_update > files_to_update:
                print(" Hay todavia {} archivos que pueden ser actualizados.\
                      Use el comando \FORCE ALL para forzar la actualización de todos los archivos.")
                

        # procediendo a actualizar

        for i,element in enumerate(make_update_file):

            if make_update_file [i] ==True:
 
                tmp_year = string_date[i][:4]
                tmp_month = string_date[i][4:6]
                tmp_day = string_date[i][6:]

                tmp_year = int(tmp_year)
                tmp_month = int(tmp_month)
                tmp_day = int(tmp_day)

                date = datetime(tmp_year,tmp_month,tmp_day)
           

                if station != 'planetary' : 
                    self.__making_processeddatafiles(date,verbose=verbose,station=station,real_time=real_time,statistic_qd=statistic_qd)
                else:
                    self.__making_processedplanetarydatafiles(date,verbose=verbose,station=station,real_time = real_time)


        if verbose:
            print("Los archivos fueron procesados")


    def __making_processeddatafiles(self,initial,**kwargs):
        
            '''
            Script geomagixs 
            geomagixs_magneticdata_process.pro
            
            '''
            
            station = kwargs.get("station",None)
            verbose = kwargs.get("verbose",False)
            real_time = kwargs.get("real_time",False)
            tendency_days = kwargs.get("tendency_days",5)
            statistic_qd = kwargs.get("statistic_qd",False)

            ###############################################3
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

            struct = dict.fromkeys(keys[:-4],0)

            struct ['D'] = 9999
            struct ['H'] = 999999
            struct ['Z'] = 999999
            struct ['F'] = 999999


            total_magnetic_data = numpy.empty(minutes_per_day*N_days,dtype='object')
            total_magnetic_data = fill(total_magnetic_data,struct)
             

            magnetic_data = numpy.empty(minutes_per_day,dtype='object')
            magnetic_data = fill(magnetic_data,struct)
       

            total_time = numpy.arange(minutes_per_day*N_days)

            if verbose:
                print("Recopilación de datos para: {}/{}/{}.".format(initial_day,initial_month,initial_year))

                if real_time:
                    print("Modo inicial: Usando data de los meses previos.")
                else:
                    print("Modo final: Usando data del mes actual.")

            

            for j in range(N_days):


                result = CALDAT(JULDAY(initial+relativedelta(days=-1*j)))

                string_date = '{:4.0f}{:02.0f}{:02.0f}'.format(result.year,result.month,result.day)
                kmex_file_name = '{}_{}.clean.dat'.format(self.GMS[self.system['gms']]['code'],string_date)

                kmex_file_name = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'],kmex_file_name)
                
                
                exist = os.path.isfile(kmex_file_name)
       

                if exist:
                     
                    magnetic_data_tmp = self.__getting_magneticdata(result,station=station,verbose=verbose)
          
                    '''
                        struct = {'year':0,'month':0,'day':0,'hour':0,'sec':0,
                      'minute':0,'D':0,'H':0,'Z':0,'F':0}
                    '''          
                   
                    for count_r,number in enumerate(range(minutes_per_day*(N_days-1-j),minutes_per_day*(N_days-j))):
                        
               
                        total_magnetic_data[number]['D'] = deepcopy(numpy.array(magnetic_data_tmp[count_r]['D']))
                        
                        total_magnetic_data[number]['H'] = deepcopy(numpy.array(magnetic_data_tmp[count_r]['H']))
                        total_magnetic_data[number]['Z'] = deepcopy(numpy.array(magnetic_data_tmp[count_r]['Z']))
                        total_magnetic_data[number]['F'] = deepcopy(numpy.array(magnetic_data_tmp[count_r]['F']))

                        total_magnetic_data[number]['year']     = deepcopy(numpy.array(magnetic_data_tmp[count_r]['year']))
                        total_magnetic_data[number]['month']    = deepcopy(numpy.array(magnetic_data_tmp[count_r]['month']))
                        total_magnetic_data[number]['day']      = deepcopy(numpy.array(magnetic_data_tmp[count_r]['day']))
                        total_magnetic_data[number]['hour']     = deepcopy(numpy.array(magnetic_data_tmp[count_r]['hour']))
                        total_magnetic_data[number]['minute']   = deepcopy(numpy.array(magnetic_data_tmp[count_r]['minute']))

                     
                else:
                    print("Error: Imposible de leer el archivo {}. \
                          Es posible que el archivo no exista o haya conflictos de permisos.".format(kmex_file_name))

                    return 
            

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
            
   
            qday_data = self.__quietday_get(initial=initial,station=station,real_time=real_time,verbose=verbose)
            
            mask0 = (numpy.abs(vectorize(qday_data,'H')) < 999990)
            mask0 = mask0.astype(bool)

            mask = (numpy.abs(vectorize(total_magnetic_data,'H')) < 999990)
            mask = mask.astype(bool)
            
            mask1 = (numpy.abs(vectorize(total_magnetic_data,'Z')) < 999990)
            mask1 = mask1.astype(bool)

            mask2 = (numpy.abs(vectorize(total_magnetic_data,'F')) < 999990)
            mask2 = mask2.astype(bool)

            mask3 = (numpy.abs(vectorize(total_magnetic_data,'D')) < 9990)
            mask3 = mask3.astype(bool)

            mask = mask1 & mask2 & mask  & mask3

            days_count  = numpy.count_nonzero(mask)
            valid_days = numpy.where(mask)[0]

            mask = numpy.abs(vectorize(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)],'H')) < 999990.00
            mask = mask.astype('bool')

            mask0 = numpy.abs(vectorize(qday_data,'H')) < 999990.00
            mask0 = mask0.astype('bool')

            mask1 = numpy.abs(vectorize(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)],'Z')) < 999990.00
            mask1 = mask1.astype('bool')

            mask2 = numpy.abs(vectorize(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)],'F')) < 999990.00
            mask2 = mask2.astype('bool')

            mask3 = numpy.abs(vectorize(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)],'D')) < 9990
            mask3 = mask3.astype('bool')

            mask = mask1 & mask2 & mask  & mask3


            valid_minutes = numpy.where(mask)[0]
            count = numpy.count_nonzero(mask)

     

            if count > 2:
                if days_count > minutes_per_day*0.6*N_days:
       
                    ######################################################################
                    key = 'D'

                    for key in  ['D','H','Z','F','N']:

                        if key != "N":

                            x = total_time[valid_days]
    
                            y = vectorize(total_magnetic_data[valid_days] , key)
            

                                            
                            fit = POLY_FIT(x,y,2)
                            status_result  = fit.status_result


                            if fit.status_result:
                                x = total_time[valid_days]
                                y = numpy.ravel(vectorize(total_magnetic_data[valid_days] , key))

                                fit = POLY_FIT(x,y,1)

                                status_result = False
                            
                            if status_result == False:

                                total_tendency = deepcopy(numpy.ravel(vectorize(total_magnetic_data,key)))
                                total_tendency[valid_days] = deepcopy(fit.tendency)
                                
                                
                                for _,indx in enumerate(valid_days) : 
                                    
                                    total_magnetic_data[indx][key] -= total_tendency[indx]
 

                                for indx in valid_minutes:
                                    magnetic_data[indx][key] = total_magnetic_data[minutes_per_day*(N_days-1) + indx][key] + total_tendency [minutes_per_day*(  N_days-1) + indx]
                                    if key == 'D': 
                                        print("qdaydaya",qday_data.shape,valid_minutes.shape)
                                        D_median[indx] = qday_data[indx][key] - numpy.median(vectorize(qday_data[valid_minutes],key) ) + total_tendency [minutes_per_day*(N_days-1) + indx]
                                      
                                    if key == 'H': 
                                        H_median[indx] = qday_data[indx][key] - numpy.median(vectorize(qday_data[valid_minutes],key) ) + total_tendency [minutes_per_day*(N_days-1) + indx]
                                        #print(H_median[indx],"H_median")

                                    if key == 'Z': 
                                        Z_median[indx] = qday_data[indx][key] - numpy.median(vectorize(qday_data[valid_minutes],key) ) + total_tendency [minutes_per_day*(N_days-1) + indx]
                                        #print(Z_median[indx],"Z_median")
                                    
                                    if key == 'F': 
                                        F_median[indx] = qday_data[indx][key] - numpy.median(vectorize(qday_data[valid_minutes],key) ) + total_tendency [minutes_per_day*(N_days-1) + indx]
                                        #print(F_median[indx],"F_median")
                                    
                          

                            else:
                                
                                for indx in valid_minutes:
                                    magnetic_data[indx][key] = total_magnetic_data[minutes_per_day*(N_days-1) + indx][key]
                                    if key == 'D': 
                                        D_median[indx]  = qday_data[indx][key] - numpy.median(vectorize(qday_data[valid_minutes],'D')) + numpy.median(vectorize(magnetic_data[valid_minutes],key))
                                    if key == 'H': 
                                        H_median[indx]  = qday_data[indx][key] - numpy.median(vectorize(qday_data[valid_minutes],'H')) + numpy.median(vectorize(magnetic_data[valid_minutes],key))
                                    if key == 'Z': 
                                        Z_median[indx]  = qday_data[indx][key] - numpy.median(vectorize(qday_data[valid_minutes],'Z')) + numpy.median(vectorize(magnetic_data[valid_minutes],key))
                                    if key == 'F': 
                                        F_median[indx]  = qday_data[indx][key] - numpy.median(vectorize(qday_data[valid_minutes],'F')) + numpy.median(vectorize(magnetic_data[valid_minutes],key))
            
                        if key =='D':    
                            D_sigma[valid_minutes]  = numpy.ravel(vectorize(qday_data[valid_minutes],'dD'))
                            #print("data en D_sigma",numpy.ravel(vectorize(qday_data[valid_minutes],key)).shape,numpy.ravel(vectorize(qday_data[valid_minutes],key))[:10])
                            D_D[valid_minutes]      = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key))-numpy.median(D_median[valid_minutes]))

                        if key =='H':    
                            H_sigma[valid_minutes]  = numpy.ravel(vectorize(qday_data[valid_minutes],'dH'))
                            D_H[valid_minutes]      = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key))-numpy.median(H_median[valid_minutes]))
                        if key =='Z':    
                            Z_sigma[valid_minutes]  = numpy.ravel(vectorize(qday_data[valid_minutes],'dZ'))
                            D_Z[valid_minutes]      = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key))-numpy.median(Z_median[valid_minutes]))
                        if key =='F':    
                            F_sigma[valid_minutes]  = numpy.ravel(vectorize(qday_data[valid_minutes],'dF'))
                            D_F[valid_minutes]      = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key))-numpy.median(F_median[valid_minutes]))
                        if key =='N':    
                            N_median[valid_minutes] =  numpy.ravel(H_median[valid_minutes])*numpy.tan(D_median[valid_minutes]*arc_secs_2rads)
                            N_sigma [valid_minutes] =  numpy.ravel(H_median[valid_minutes])*D_sigma[valid_minutes]*arc_secs_2rads/(numpy.cos(D_median[valid_minutes]*arc_secs_2rads))**2 + H_sigma[valid_minutes]*numpy.tan(D_median[valid_minutes]*arc_secs_2rads)
                            D_N[valid_minutes]      =  vectorize(magnetic_data[valid_minutes],'H') * numpy.tan(vectorize(magnetic_data[valid_minutes],'D')*arc_secs_2rads) - N_median[valid_minutes]
 

                else:
         
                    ### D  processs
                    key = 'D'
                    for indx in valid_minutes:
                        magnetic_data[indx][key] = total_magnetic_data[minutes_per_day*(N_days-1)+indx][key]

                    D_median[valid_minutes] = vectorize(qday_data[valid_minutes],key) - numpy.median(vectorize(qday_data[valid_minutes],key)) + numpy.median(magnetic_data['valid_minutes'],key)
                    D_sigma[valid_minutes ] = vectorize(qday_data[valid_minutes],'dD')
                    D_D[valid_minutes]   = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key)))-\
                                           (D_median[valid_minutes])
         
                    ### H  processs
                    key = 'H'
                    for indx in valid_minutes:
                        magnetic_data[indx][key] = total_magnetic_data[minutes_per_day*(N_days-1)+indx][key]
                        
                    H_median[valid_minutes] = vectorize(qday_data[valid_minutes],key) - numpy.median(vectorize(qday_data[valid_minutes],key)) + numpy.median(magnetic_data['valid_minutes'],key)
                    H_sigma[valid_minutes ] = vectorize(qday_data[valid_minutes],'dH')
                    D_H[valid_minutes]   = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key)))-\
                                           (H_median[valid_minutes])
         
                    ### Z  processs
                    key = 'Z'
                    for indx in valid_minutes:
                        magnetic_data[indx][key] = total_magnetic_data[minutes_per_day*(N_days-1)+indx][key]
                    Z_median[valid_minutes] = vectorize(qday_data[valid_minutes],key) - numpy.median(vectorize(qday_data[valid_minutes],key)) + numpy.median(magnetic_data['valid_minutes'],key)
                    Z_sigma[valid_minutes ] = vectorize(qday_data[valid_minutes],'dZ')
                    D_Z[valid_minutes]   = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key)))-\
                                           (Z_median[valid_minutes])
         
                    ### F  processs
                    key = 'F'
                    for indx in valid_minutes:
                        magnetic_data[indx][key] = total_magnetic_data[minutes_per_day*(N_days-1)+indx][key]
                    F_median[valid_minutes] = vectorize(qday_data[valid_minutes],key) - numpy.median(vectorize(qday_data[valid_minutes],key)) + numpy.median(magnetic_data['valid_minutes'],key)
                    F_sigma[valid_minutes ] = vectorize(qday_data[valid_minutes],'dF')
                    D_F[valid_minutes]   = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key)))-\
                                           (F_median[valid_minutes])
                   
                   
                    ### N  processs
                    key = 'N'
              
                    N_median[valid_minutes] = vectorize(qday_data[valid_minutes],key) - numpy.median(vectorize(qday_data[valid_minutes],key)) + numpy.median(magnetic_data['valid_minutes'],key)
                    N_sigma[valid_minutes ] = vectorize(qday_data[valid_minutes],'dN')
                    D_N[valid_minutes]   = (numpy.ravel(vectorize(magnetic_data[valid_minutes],key)))-\
                                           (N_median[valid_minutes])
         

                
                number_of_minutes = 5 

                H_max_jump = 800

                mask = numpy.abs(vectorize(magnetic_data,'H')) < 999990.00
                mask = mask.astype(bool)
                elements_of_no_gaps = numpy.count_nonzero(mask)
                
                no_gaps = numpy.where(mask)[0]

                nonmask = ~mask
                number_of_gaps = numpy.count_nonzero(nonmask)
             


                H_median_value = 0
                H_sigma_value = 0


                boolean_flag = numpy.empty(elements_of_no_gaps,dtype=int)

                boolean_flag.fill(1)

                mask = numpy.abs(F_sigma) < 999990.00
                mask = mask.astype(bool)

                datos_validos = numpy.where(mask)[0]
                datos_validos_count = numpy.count_nonzero(mask)
                

                if datos_validos_count > 1 :
                    mean_F_sigma = numpy.mean(F_sigma[datos_validos]) 
                else:
                    mean_F_sigma = 0



                if number_of_gaps != minutes_per_day:
                    for i in range(elements_of_no_gaps):
                        
                        if i < number_of_minutes and i+number_of_minutes <= elements_of_no_gaps -1:
                            if i !=0:

                                H_median_value = numpy.median(numpy.concatenate((D_H[no_gaps[:i]],D_H[no_gaps[i+1:i+1+number_of_minutes]])))
                                H_sigma_value = numpy.std(numpy.concatenate((D_H[no_gaps[:i]],D_H[no_gaps[i+1:i+1+number_of_minutes]])))
                            else:
                                H_median_value = numpy.median(D_H[no_gaps[i+1:i+1+number_of_minutes]])
                                H_sigma_value  = numpy.std(D_H[no_gaps[i+1:i+1+number_of_minutes]])

                        if i < number_of_minutes and i+number_of_minutes > elements_of_no_gaps-1:
                            if i !=0 and i != elements_of_no_gaps - 1:

                                H_median_value = numpy.median(numpy.concatenate((D_H[no_gaps[:i]],D_H[no_gaps[i+1:elements_of_no_gaps]])))
                                H_sigma_value  = numpy.std(numpy.concatenate((D_H[no_gaps[:i]],D_H[no_gaps[i+1:elements_of_no_gaps]])))

                            if i == 0 and i != elements_of_no_gaps -1 :

                                H_median_value = numpy.median(D_H[no_gaps[i+1:elements_of_no_gaps]])
                                H_sigma_value  = numpy.std(D_H[no_gaps[i+1:elements_of_no_gaps]])

                            if i != 0 and i == elements_of_no_gaps - 1 :
                                H_median_value = numpy.median(D_H[no_gaps[:elements_of_no_gaps]])
                                H_sigma_value  = numpy.std(D_H[no_gaps[:elements_of_no_gaps]])

                        
                        if i >= number_of_minutes and i + number_of_minutes <= elements_of_no_gaps - 1:
                            H_median_value = numpy.median(numpy.concatenate((D_H[no_gaps[i-number_of_minutes:i]],D_H[no_gaps[i+1:i+number_of_minutes+1]])))
                            H_sigma_value  = numpy.std(numpy.concatenate((D_H[no_gaps[i-number_of_minutes:i]],D_H[no_gaps[i+1:i+number_of_minutes+1]])))
                        

                        if i >= number_of_minutes and i+number_of_minutes > elements_of_no_gaps - 1 :
                            if i == elements_of_no_gaps-1:
                                H_median_value = numpy.median(D_H[no_gaps[i-number_of_minutes:elements_of_no_gaps]])
                                H_sigma_value  = numpy.std(D_H[no_gaps[i-number_of_minutes:elements_of_no_gaps]])

                            else:
                                H_median_value  = numpy.median(numpy.concatenate((D_H[no_gaps[(i-number_of_minutes):i]],D_H[no_gaps[i+1:elements_of_no_gaps]])))
                                H_sigma_value  = numpy.std(numpy.concatenate((D_H[no_gaps[(i-number_of_minutes):i]],D_H[no_gaps[i+1:elements_of_no_gaps]])))

 
                        
                        ##
                        # 
                        sigma_criteria = 4 

                         
                        if ((numpy.abs(D_H[no_gaps[i]]-H_median_value)) > sigma_criteria*H_sigma_value)  :                        
                            # (numpy.abs(D_H[no_gaps[i]])>H_max_jump):     or 
                            
                            boolean_flag[i] =0
                    
                        H_median_value = 0 
                        H_sigma_value  = 0
 
                if elements_of_no_gaps > 1 :
                    D_D [no_gaps] = (boolean_flag == 1).astype(int)  *D_D[no_gaps] + (boolean_flag!= 1).astype(int) *9999
                    D_H [no_gaps] = (boolean_flag == 1).astype(int)  *D_H[no_gaps] + (boolean_flag!= 1).astype(int) *999999.00
                    D_Z [no_gaps] = (boolean_flag == 1).astype(int)  *D_Z[no_gaps] + (boolean_flag!= 1).astype(int) *999999.00
                    D_F [no_gaps] = (boolean_flag == 1).astype(int)  *D_F[no_gaps] + (boolean_flag!= 1).astype(int) *999999.00
                    D_N [no_gaps] = (boolean_flag == 1).astype(int)  *D_N[no_gaps] + (boolean_flag!= 1).astype(int) *999999.00


            mask  = numpy.abs(D_D) < 9990
            mask2 = numpy.abs(D_N) < 999990

            mask = mask.astype(bool)
            mask2 = mask2.astype(bool)

            test_index = numpy.where(mask & mask2)[0]
            test_count = numpy.count_nonzero(mask & mask2)
   
            if test_count > 0:

                dd_median = numpy.median(D_D[test_index])
 
                bad_index = numpy.where((numpy.abs(D_D) > 9990).astype(bool) & (numpy.abs(D_N) > 999990).astype(bool) | (numpy.abs(D_sigma)>9990).astype(bool) )[0]
                bad_count = len(bad_index)

            else:
                bad_index = numpy.where((numpy.abs(D_D) > 9990).astype(bool) | (numpy.abs(D_N) > 999990).astype(bool) | (numpy.abs(D_sigma) > 9990).astype(bool))[0]
                bad_count = len(bad_index)
            
            if bad_count > 0 : 

                D_sigma[bad_index] = 9999
                D_D [bad_index] = 9999
                N_sigma[bad_index] = 999999
                D_N [bad_index] = 999999

            
            data_file = numpy.empty(minutes_per_day,dtype='object')

            for i in range(minutes_per_day):
                
                ##-------------generate chain------------------##
                subchain = ' {:9.2f}'
                subchain1 = "  {:7.2f}"+subchain*3
                subchain2 = "  {:7.2f}"+subchain*4
                chain = '{:4.0f} {:02.0f}:{:02.0f}'+subchain1+3*subchain2
                ################################################3

                data_file [i] = chain.format(i+1,i//60,i % 60 ,
                                            (magnetic_data[i]['D']),magnetic_data[i]['H'],magnetic_data[i]['Z'],magnetic_data[i]['F'], 
                                       D_median[i],H_median[i],Z_median[i],F_median[i], N_median[i], 
                                       D_sigma[i],H_sigma[i],Z_sigma[i],F_sigma[i], N_sigma[i], 
                                       D_D[i], D_H[i], D_Z[i], D_F[i], D_N[i])
                

            #------------------------------------ differences -----------------------------------------------------------------#


            data_per_day = int(24/3)
            minutes_in_3hours = 60*3

            differences_file = numpy.empty(int(data_per_day),dtype='object')

            max_D = numpy.empty(data_per_day,dtype=float)
            max_D.fill(9999)

            max_H = numpy.empty(data_per_day,dtype=float)
            max_H.fill(999999)

            max_Z = deepcopy(max_H)
            max_F = deepcopy(max_H)
            max_N = deepcopy(max_H)

            min_D = numpy.empty(data_per_day,dtype=float)
            min_D.fill(9999)

            min_H = numpy.empty(data_per_day,dtype=float)
            min_H.fill(999999)

            min_Z = deepcopy(min_H)
            min_F = deepcopy(min_H)
            min_N = deepcopy(min_H)
            
            delta_D = numpy.empty(data_per_day,dtype=float)
            delta_D.fill(9999)

            delta_H = numpy.empty(data_per_day,dtype=float)
            delta_H.fill(999999)

            delta_Z = deepcopy(delta_H)
            delta_F = deepcopy(delta_H)
            delta_N = deepcopy(delta_H)

            sigma_D = numpy.empty(data_per_day,dtype=float)
            sigma_D.fill(9999)
            
            sigma_H = deepcopy(delta_H)

            sigma_Z = deepcopy(max_H)
            sigma_F = deepcopy(max_H)
            sigma_N = deepcopy(max_H)

            for i in range(data_per_day):

                #------------------------------ Process D ------------------------------#
                values1 = vectorize(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours],'D')
                values2 = (D_D[i*minutes_in_3hours:(i+1)*minutes_in_3hours])

                mask1 = (numpy.abs(values1) < 9990).astype(bool)
                mask2 = (numpy.abs(values2) < 9990).astype(bool)

                mask = mask1 & mask2 
                                
                valid_data = numpy.array(numpy.where(mask)[0],dtype=int) + i*minutes_in_3hours

                valid_count = numpy.count_nonzero(mask)

                if valid_count > 0 :
                  
                    tmp = D_D [valid_data]

                    valid_data_tmp = numpy.where(numpy.abs(D_D[valid_data]) < 9990)[0]
                    tmp_count = len(valid_data_tmp)

                    max_D[i] = numpy.nanmax(tmp[valid_data_tmp])
                    min_D[i] = numpy.nanmin(tmp[valid_data_tmp])
            
                    delta_D[i] = numpy.abs(max_D[i]-min_D[i]) if (abs(max_D[i]) < 9990 and abs(min_D[i]) < 9990) else 9999
                    sigma_D[i] = numpy.std(tmp[valid_data_tmp]) if (abs(delta_D[i]) < 9990 and tmp_count >1) else 9999
               
                    
                #------------------------------ Process H------------------------------#
                values1 = vectorize(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours],'H')
                values2 = (D_H[i*minutes_in_3hours:(i+1)*minutes_in_3hours])

                mask1 = (numpy.abs(values1) < 999990).astype(bool)
                mask2 = (numpy.abs(values2) < 999990).astype(bool)

                mask = mask1 & mask2 
                                
                valid_data = numpy.array(numpy.where(mask)[0]) + i*minutes_in_3hours

                valid_count = numpy.count_nonzero(mask)

                if valid_count > 0 :

                    tmp = D_H [valid_data] 

                    valid_data_tmp = numpy.where(numpy.abs(D_H[valid_data]) < 999990)[0]
                    tmp_count = len(valid_data_tmp)

                    max_H[i] = numpy.nanmax(tmp[valid_data_tmp])
                    min_H[i] = numpy.nanmin(tmp[valid_data_tmp])
                    delta_H[i] = numpy.abs(max_H[i]-min_H[i]) if (abs(max_H[i]) < 999999 and abs(min_H[i]) < 999999) else 999999
                    sigma_H[i] = numpy.std(tmp[valid_data_tmp]) if (abs(delta_H[i]) < 999990 and tmp_count >1) else 999999
                
                #------------------------------ Process Z ------------------------------#
                values1 = vectorize(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours],'Z')
                values2 = (D_Z[i*minutes_in_3hours:(i+1)*minutes_in_3hours])

                mask1 = (numpy.abs(values1) < 999990).astype(bool)
                mask2 = (numpy.abs(values2) < 999990).astype(bool)

                mask = mask1 & mask2 
                                
                valid_data = numpy.array(numpy.where(mask)[0]) + i*minutes_in_3hours

                valid_count = numpy.count_nonzero(mask)

                if valid_count > 0 :

                    tmp = D_Z [valid_data] 

                    valid_data_tmp = numpy.where(numpy.abs(D_Z[valid_data]) < 999990)[0]
                    tmp_count = len(valid_data_tmp)

                    max_Z[i] = numpy.nanmax(tmp[valid_data_tmp])
                    min_Z[i] = numpy.nanmin(tmp[valid_data_tmp])
                    delta_Z[i] = numpy.abs(max_Z[i]-min_Z[i]) if (abs(max_Z[i]) < 999999 and abs(min_Z[i]) < 999999) else 999999
                    sigma_Z[i] = numpy.std(tmp[valid_data_tmp]) if (abs(delta_Z[i]) < 999999 and tmp_count >1) else 999999
                
                #------------------------------ Process F ------------------------------#
                values1 = vectorize(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours],'F')
                values2 = (D_F[i*minutes_in_3hours:(i+1)*minutes_in_3hours])

                mask1 = (numpy.abs(values1) < 999990).astype(bool)
                mask2 = (numpy.abs(values2) < 999990).astype(bool)

                mask = mask1 & mask2 
                                
                valid_data = numpy.array(numpy.where(mask)[0]) + i*minutes_in_3hours

                valid_count = numpy.count_nonzero(mask)

                if valid_count > 0 :

                    tmp = D_F [valid_data] 

                    valid_data_tmp = numpy.where(numpy.abs(D_F[valid_data]) < 999990)[0]
                    tmp_count = len(valid_data_tmp)

                    max_F[i] = numpy.nanmax(tmp[valid_data_tmp])
                    min_F[i] = numpy.nanmin(tmp[valid_data_tmp])
                    delta_F[i] = numpy.abs(max_F[i]-min_F[i]) if (abs(max_F[i]) < 999990 and abs(min_F[i]) < 999990) else 999999
                    sigma_F[i] = numpy.std(tmp[valid_data_tmp]) if (abs(delta_F[i]) < 999990 and tmp_count >1) else 999999

                #------------------------------ Process N ------------------------------#
                values1 = vectorize(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours],'D')
                values2 = (D_N[i*minutes_in_3hours:(i+1)*minutes_in_3hours])

                mask1 = (numpy.abs(values1) < 9990).astype(bool)
                mask2 = (numpy.abs(values2) < 9990).astype(bool)

                mask = mask1 & mask2 
                                
                valid_data = numpy.array(numpy.where(mask)[0]) + i*minutes_in_3hours

                valid_count = numpy.count_nonzero(mask)

                if valid_count > 0 :

                    tmp = D_N [valid_data] 

                    valid_data_tmp = numpy.where(numpy.abs(D_N[valid_data]) < 9990)[0]
                    tmp_count = len(valid_data_tmp)

                    max_N[i] = numpy.nanmax(tmp[valid_data_tmp])
                    min_N[i] = numpy.nanmin(tmp[valid_data_tmp])
                    delta_N[i] = numpy.abs(max_N[i]-min_N[i]) if (abs(max_N[i]) < 9990 and abs(min_N[i]) < 9990) else 9999
                    sigma_N[i] = numpy.std(tmp[valid_data_tmp]) if (abs(delta_N[i]) < 9990 and tmp_count >2) else 9999               
 
                #---------------------------------------------------------------------------------------------
                #---------------------------------------------------------------------------------------------
                #---------------------------------------------------------------------------------------------
                #
                subchain1 = 4*" {:7.2f}"
                subchain2 = 4*" {:9.2f}"
                subchain = subchain1 + subchain2*4
                chain = '{:02d}  '+subchain

                differences_file[i] = chain.format(i*24//data_per_day,  
                                       max_D[i], min_D[i], sigma_D[i], delta_D[i], 
                                       max_H[i], min_H[i], sigma_H[i], delta_H[i], 
                                       max_Z[i], min_Z[i], sigma_Z[i], delta_Z[i], 
                                       max_F[i], min_F[i], sigma_F[i], delta_F[i], 
                                       max_N[i], min_N[i], sigma_N[i], delta_N[i], )
            
                

            extention = '.early' if real_time else '.final'

            output_file = '{}_{:4.0f}{:02.0f}{:02.0f}'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)
            output_path = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])
            

            exist_dir = os.path.isdir(output_path)
            
            if not exist_dir:
                if verbose:
                    print("El directorio {} no existe, se creará el directorio.".format(output_path))
                
                os.makedirs(exist_dir)


            with open (os.path.join(output_path,output_file+'.data'+extention),'w') as file:
                file.writelines(line+'\n' for line in data_file)
            
            if verbose:
                print("Archivo guardado {}".format(output_file+'.data'+extention))


            with open (os.path.join(output_path,output_file+'.differences'+extention),'w') as file:
                file.writelines(line+'\n' for line in differences_file)

            if verbose:
                print("Archivo guardado {}".format(output_file+'.differences'+extention))       



            


 
                
 









          
 









 

 



            
    def __magneticdata_download(self,date_initial=None,date_final=None,**kwargs):
        
            #---------------------------
            station = kwargs.get("station",None)
            verbose = kwargs.get("verbose",False)
            force_all = kwargs.get("force_all",False)

        
   
            update_flag = True
            
            
            if date_initial is None:
                
                date_initial = datetime.now()
                
            if date_final is None:
                
                date_final = date_initial 
                
       
            check_dates(self,date_initial,date_final,station=station,verbose= verbose)
            
            # [YYYY, MM, DD] , initial date and time at which th
            if (self.GMS[self.system['gms']]['name'] == 'planetary'):
                
                fnumber = (date_final.year-date_initial.year)*12 + (date_final.month-date_initial.month)+1
            
            else:
                fnumber = JULDAY(date_final)-JULDAY(date_initial)+1
            
            
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
                    
                    
                    files_source_name_k [i] =  os.path.join(self.gms[self.system['gms']]['code'],"{:4.0f}{:2.0f}{:2.0f}.rK.min".format(tmp_y,tmp_m,tmp_d))
                    files_source_name_r [i] =  os.path.join(self.gms[self.system['gms']]['code'],"{:4.0f}{:2.0f}{:2.0f}.r.min".format(tmp_y,tmp_m,tmp_d))
                    
                    directories_source_name[i] = os.path.join(self.system['ssh_user']+"@"+self.system['ssh_address']+self.GMS[self.system['gms']]['code'],'{:4.0f}'.format(tmp_year))
                    directories_destiny_name[i] = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'])
                    
                    
                    
                    tmp_results = ''
                    tmp_errors = ''
                    
                    if verbose is True:
                        print("Copiando {:4.0f}{:02d}{:02d}".format(tmp_y,int(tmp_m)
                                                                         ,int(tmp_d)))
                        
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

                    date = CALDAT(JULDAY(date_initial)+i)
                    
                    months = ['jan','feb','mar','apr','may','jun',\
                              'jul','aug','sep','oct','nov','dec']
                    
                    tmp_y=date.year
                    tmp_m=date.month
                    tmp_d=date.day
                    
                    tmp_string = months[tmp_m-1]
                    
                    files_source_name_k[i] = os.path.join(self.GMS[self.system['gms']]['code'],'{:2.0f}{}.{:2.0f}'.format(tmp_d,tmp_string,tmp_y%1000) )
                                                          
                    directories_source_name[i]  = os.path.join(self.system['ftp_address'],'datamin',self.GMS[self.system['gms']]['name'],'{:4.0f}'.format(tmp_y))
                    
                    directories_destiny_name[i] = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'])
                                            
            
                    tmp_resultsm = ''
                    tmp_errorsm  = ''
                    tmp_resultsv = ''
                    tmp_errorsv = ''
                    
                    if verbose is True:
                        
                        print("Copiando archivos de {:4.0f}{:02d}{:02d}".format(tmp_y,int(tmp_m),int(tmp_d)))
                        
                    
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


                    files_source_name_k [i] = 'kp{:02.0f}{:02.0f}'.format(tmp_y%1000,tmp_m)
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

                    name = '{:02.0f}{:02.0f}.wdc'.format(tmp_y%1000,tmp_m)
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

 
    def __make_planetarymagneticdatafiles(self,**kwargs):
        #script -> geomagixs_magneticdata_download.pro
        #falta
 
            date = kwargs.get("date",None)
            station = kwargs.get("station", None)
            verbose = kwargs.get("verbose",False)
            force_all = kwargs.get("force_all",False)



            if self.GMS[self.system['gms']]['name'] != "planetary":
                return 
            
            
            initial_year = date.year
            initial_month = date.month
            initial_day = date.day
            
            file_name = "kp{:02.0f}{:02.0f}.wdc".format(initial_year %1000,initial_month)
            
            fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'])
            
            file_path = os.path.join(fpath,file_name)
            
            
            file = os.path.exists(file_path)
            
            if not file:
                if verbose:
                    ResourceWarning("Input Warning: Existe conflicto con el valor de fecha(s). Archivo\
                          perdido {}. Se reeemplazará los valores perdidos con datos nulos.".format(file_name))
                
                number_lines = JULDAY(datetime(initial_year,initial_month+1,1))
                
                magnetic_data = numpy.array(['{:02.0f}{:02.0f}{:02.0f}'.format(initial_year%1000,initial_month,x) for x in range(number_lines)],dtype='object')
     
            else:
                with open(file_name,'r') as archivo:
                    
                    buff_lines = archivo.read().splitlines() 
                    
                    magnetic_data = numpy.array(buff_lines,dtype='object')
                
            kp_data = numpy.empty(9)
            kp_data.fill(9999)
            
            ap_data = numpy.empty(9)
            ap_data.fill(9999)
            
            line = '{:02.0f}{:02.0f}{:02.0f}'.format(initial_year%1000,
                                               initial_month,
                                               initial_day)
            ind=0
            for n,value in enumerate(magnetic_data):
                if value.lower()[:6]==line.lower[:6]:
                    if n>0:
                        if len(value)>=62:
                            read_format = r'-?\d+\.?\d*'
                            temp = re.findall(read_format,value)
                            if len(temp)>0:

                                

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
            file_name = 'dst{:02.0f}{:02.0f}.dat'.format(initial_year%1000,initial_month)
            file_name = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],file_name)
            
            check = os.path.isfile(file_name)
            
            if not check:
                if verbose:
                    raise ResourceWarning('Conflicto con la entrada de datos. Archivo perdido {}, se\
                                     reemplazará con datos vacios.'.format(os.path.basename(file_name)))
                    
            else:
                #archivo existe 
                
                with (file_name,'r') as f:
                    
                    buff = f.read().splitlines() 
                    
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
                            
                            
                            string = 'DST {:02.0f}{:02.0f}*{:02.0f}RRX020   09999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999'.format(initial_year%1000,
                                                                                                                                                                                    initial_month,n+1)
                            magnetic_data[n]= string
            
            
            dst_data = numpy.empty(25,dtype=int) 
            
            dst_data.fill(9999)
            
            line ='DST {:02.0f}{:02.0f}*{:02.0f}'.format(initial_year % 1000,initial_month,initial_day)
            
            
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

                cadena = '{:04.0f}-{:02.0f}-{:02.0f} {:02.0f}:{:02.0f}:00.000 {:03.0f}   {:4.0f}     {:4.0f}  {:5.0f}    {:5.0f}   {:5.0f}     {:5.0f}'

                cadena = cadena.format(initial_year,initial_month,initial_day,(i-18),0,tmp_doy,\
                                       kp_data[int((i-18)/3)],kp_data[8],ap_data[int((i-18)/3)],ap_data[8],dst_data[i-18],dst_data[24])
                
                file_data[i] = cadena

            
            data_file_name = '{}{:04.0f}{:02.0f}{:02.0f}.rK.min'.format(self.GMS[self.system['gms']]['code'],initial_year,initial_month,initial_day)

            data_file_name = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],data_file_name)


            if not os.path.isfile(data_file_name):
                
                if not os.access(data_file_name,os.W_OK):
                    PermissionError("No se puede escribir en la ruta {}.".format(data_file_name))

                with open(data_file_name,'w') as f:
                    for data in file_data:
                        f.write(data)

                    if verbose:
                        print('Guardando:',data_file_name)
            


            

 
     
    
    
    
    def __making_magneticdatafile (self,date, station=None,verbose=False,force_all=False):
        
        #script -> geomagixs_magneticdata_download.pro
        #completado pero revisar lógica
        
 
            
            #months

            
            
            if (self.GMS[self.system['gms']]['name']=='planetary') or \
                (self.GMS[self.system['gms']]['name']=='teoloyucan'):
                    return 
            
            
            tmp_year = date.year
            tmp_month = date.month
            tmp_day   = date.day
            
            tmp_doy  = JULDAY(date)-JULDAY(datetime(tmp_year,1,1)+relativedelta(days=-1))
            
            tmp_string = months[tmp_month-1]
             
            fname =(self.GMS[self.system['gms']]['code']+'n_{:02.0f}{:02.0f}{:02.0f}.min'.format((tmp_year % 1000),tmp_month,tmp_day))
            
            fpath       = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],fname)
            fexists     = os.path.isfile(fpath)
            
            if fexists:
                if verbose:
                    print("Extrayendo datos de {}.".format(fname))


            else: 
                if verbose:
                    print('No se encontró el archivo {} en directorio{}.'.format(fname,os.path.dirname(fpath)))
                    return
            
            with open(fpath,'r') as f:
                
                buff = f.read().splitlines() 
                nlines = len(buff) 

                buff = numpy.array(buff,dtype='object')
           
                cabecera = 4  
                
                if nlines <= cabecera + 1:
                    if verbose is True or force_all is True:
                        
                        print('Warning: Conflicto con los archivos de datos. Se observan \
                               datos inconsistentes o invalidos en el archivo de datos {}. El\
                               archivo tiene longitud cero'.format(fname))
                    
                        return

                
                data = {'day':0,'month':0,'year':0,'hour':0,'minute':0,\
                        'D':0, 'H':0,'Z':0,'I':0,'F':0}
                

                key_array = ['day','month','year','hour','minute','D','H','Z','I','F']

                aux_lenght = len(buff[cabecera])
                
                aux_00 = numpy.sum(numpy.array(list(map(len,buff[cabecera:]))))
                aux_01 = (nlines - cabecera)*aux_lenght
                aux_02 = (nlines - cabecera)*62
                
                
                if aux_00 != aux_01:
                    buff_len   = list(map(len,buff[cabecera:]))
 
                    bad_indexes = [x != aux_lenght for x in buff_len]
 
                    bad_lines = numpy.array(buff,dtype='object')[bad_indexes]
                    
                    if verbose is True and force_all is False:
                        print("Warning: Conflictos con los archivos de entrada, formatos de datos\
                               es invalido. El archivo {} tiene {} lineas corruptas.".format(fname,bad_lines))
                 
         
          
                tmp = deepcopy(buff[cabecera:])
                for n,_ in enumerate(tmp):
                    tmp[n] = len(tmp[n])
           
                good_indexes = numpy.where(tmp==aux_lenght)[0]
                good_lines = buff[cabecera:][good_indexes]
 
               
                
                read_format = r'-?\d+\.?\d*'
               
                
                data_read = list()
                
                for lines in good_lines:
                    
                    temp = re.findall(read_format,lines)

                    if len(temp)>0:
                        
                        tmp_dict = deepcopy(data)
                        for n,(temp_value,key) in enumerate(zip(temp,key_array)):
                            
                            tmp_dict[key]=temp_value
                        
                        data_read.append(tmp_dict)
                            
                    else:
                        if verbose is True:
                            print("Error: Linea de archivo no leida.")
                            print("linea:",lines)
                        
 
            
            
            cabecera_final = 18
            
            size_data = good_lines.shape[0] 
            file_data = numpy.empty(size_data+cabecera_final,dtype='object')
            
            
            ######################
            # Rellenando datos
            ######################
            
            
            str_tmp1    =   ' '*(62-len(self.GMS[self.system['gms']]['name']))
            
            file_data[0]          =  ' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
            file_data[1]          =  ' Source of Data         Huancayo Magnetic Observatory, IGP                            |'
            file_data[2]          =  ' Station Name           {}{}'.format(self.GMS[self.system['gms']]['name'].upper(),str_tmp1)
            file_data[3]          =  ' IAGA CODE              {}{}'.format(self.GMS[self.system['gms']]['code'].upper(),'                                                           |'         )  
            file_data[4]          =  ' Geodetic Latitude      {:8.3f}{}'.format(self.GMS[self.system['gms']]['latitude'],'                                                      |')
            file_data[5]          =  ' Geodetic Longitude     {:8.3f}{}'.format(self.GMS[self.system['gms']]['longitude'],'                                                      |')
            file_data[6]          =  ' Elevation              {:6.1f}{}'.format(self.GMS[self.system['gms']]['elevation'],'                                                        |')
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
            
            for ix in range(len(data_read)):
                
                formato = '{:04.0f}-{:02.0f}-{:02.0f} {:02.0f}:{:02.0f}:00.000 {:03.0f}     {:8.2f}  {:8.2f}  {:8.2f}  {:8.2f}'
              
            
                payload = formato.format(float(data_read[ix]['year']),
                                         float(data_read[ix]['month']),
                                         float(data_read[ix]['day']),
                                         float(data_read[ix]['hour']),
                                         float(data_read[ix]['minute']),
                                         float(tmp_doy),
                                         float(data_read[ix]['D'])*60.,
                                         float(data_read[ix]['H']), 
                                         float(data_read[ix]['Z']),
                                        #  float(data_read[ix]['I']),
                                         float(data_read[ix]['F']))
                
         
                file_data[ix + cabecera_final]  = payload
                
            
            fname_data = self.GMS[self.system['gms']]['code']+'{:04.0f}{:02.0f}{:02.0f}.rK.min'.format(tmp_year,tmp_month,tmp_day)
            fpath = os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'],fname_data)
            
            exists_data_file = os.path.exists(fpath)
            
            if exists_data_file:
                
                #el archivo existe
                if verbose:
                    print("El archivo existe y va a ser sobreescrito.")
                
            else:
                
                if verbose:
                    print("El archivo se guarda en {}.".format(fpath))
                    
  
            indx = numpy.where(file_data!=None)[0]

            with open(fpath,'w') as file:
             
                file.writelines(line + '\n' for line in file_data[indx])
                        

 
            
                   
    def __quietdays_download(self,initial,final, **kwargs):
        #script -> geomagixs_quietdays_download.pro
        #listo

    
            update_flag=0
            
            station = kwargs.get("station",None)
            verbose = kwargs.get("verbose",False)
            force_all = kwargs.get("force_all",False)
            
            #########
            # En IDL:
            #[YYYY, MM, DD] , initial date and time at which the data is read from
            # En python es el objeto datetime
            initial_date  = initial
            
            final_date = final
            
            files_number = ((final_date.year % 1000)-(initial_date.year % 1000))//10 +1
            
            
            if verbose is True:
                print("Un total de {} archivos van a ser reescritos. \
                      Data previamente guardada será permanentemente borrado.".format(files_number) )
            
            proceed = 'Y'
            
            if proceed =='Y':
                
                files_source_name_k         =   numpy.empty(files_number,dtype='object')
                directories_source_name     =   numpy.empty(files_number,dtype='object')
                directories_destiny_name    =   numpy.empty(files_number,dtype='object')
                terminal_results_k          =   numpy.empty(files_number,dtype='object')
                terminal_errors_k           =   numpy.empty(files_number,dtype='object')
            
            count_saved = 0
            count_failed = 0
            
            buff_fsave = list()
            buff_year  = list()
            
            for i in range(files_number):
                
                
                tmp_millenium = int(initial_date.year/1000)*1000
                tmp_century   = int((initial_date.year % 1000)/100)*100
                tmp_decade    = int(((initial_date.year % 1000) % 100)/10+i)*10
                
                tmp_year   = tmp_millenium + tmp_century + tmp_decade 
                print(tmp_year)
                today_julian = JULDAY(self.system['today_date'])
                tmp_j0      =   JULDAY(datetime(tmp_year,1,1))
                tmp_j1      =   JULDAY(datetime(tmp_year+9,12,31))
                
                if ((today_julian >= tmp_j0) and (today_julian <= tmp_j1)):
                    
                    files_source_name_k [i] = 'qd{:4d}{:01.0f}x.txt'.format(int(tmp_year),int(tmp_decade/10))
                else:    
                    files_source_name_k [i] = 'qd{:4d}{:02.0f}.txt'.format(int(tmp_year),tmp_decade+9)

                directories_source_name[i]  = 'ftp://ftp.gfz-potsdam.de/pub/home/obs/kp-ap/quietdst/'
                directories_destiny_name[i] = self.system['qdays_dir']
                
                
                if verbose is True:
                    
                    print("Copiando archivo {}-decade.".format(tmp_year))
 
                fdownload = os.path.join(directories_source_name[i],files_source_name_k[i])
                fsave     = os.path.join(directories_destiny_name[i],files_source_name_k[i])
                
                
                
                try:
                    urllib.request.urlretrieve(fdownload, fsave)
                except :
                    count_failed+=1
                    print("Error descarga",fdownload)

                else:
                    count_saved+=1
                    buff_fsave.append(fsave)
                    buff_year.append(tmp_year)
                    print("Descarga exitosa")

                    
            
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
                return 
            
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
            
            
            patron = 'qd??????.txt'
            path = self.system['qdays_dir']

            fpath = os.path.join(path,patron)    

            qdays_files = searchforpatron(fpath)
            qdays_files_number = len(qdays_files)
            qdays_files_lines = FILE_LINES(qdays_files)
            qdays_files_stringlength = [len(os.path.basename(file)) for file in qdays_files]


            qdays_initial_year = int(os.path.basename(qdays_files[0])[2:-7])            
            qdays_final_year = int(os.path.basename(qdays_files[-1])[2:-7])        
            print('initial and final',qdays_initial_year,qdays_final_year)
            qdays_initial_year *=10
            qdays_final_year *=10    
            

            qdays_final_year = qdays_final_year + ((qdays_files_lines[-1]-4)//14)

            tmp_months = ((qdays_files_lines[-1]-4) % 14)

            if tmp_months < 8 :
                qdays_final_month = int(tmp_months)
            else:
                qdays_final_month = int(tmp_months-1)
            
            result = JULDAY(datetime(qdays_final_year,qdays_final_month,1)+relativedelta(days=-1)+relativedelta(months=+1))
            result = CALDAT(result)

            tmp_month = result.month
            qdays_final_day = result.day
            temporal_year = result.year

            index_dates [:3] = [qdays_initial_year,1,1]
            index_dates[3:] = [qdays_final_year,qdays_final_month,qdays_final_day]

            file = os.path.join(self.system['auxiliar_dir'],'qdays.dates')

            string_data = numpy.empty(2,dtype='object')

            string_data[0]  = '# File with available data for quiet days [YYYYMMDD]-[YYYYMMDD]:'


            chain0 = '{:04.0f}{:02.0f}{:02.0f}'.format(index_dates[0],index_dates[1],index_dates[2])
            chain1 = '{:04.0f}{:02.0f}{:02.0f}'.format(index_dates[3],index_dates[4],index_dates[5])

            string_data[1] = '{}-{}'.format(chain0,chain1)

            with open(file,'w') as f:
                
                f.writelines(line+'\n' for line in string_data)

            
            if verbose:
                print("Actualizado archivo qdays.dates")
                print(" Rango de datos: ['{}'-{}]".format(chain0,chain1))
             
            if verbose:
                print("Archivos q-days fueron actualizados.")

             
 
                
                
                    
                    

    def __setup_dates(self,**kwargs):
        #script -> geomagixs_setup_dates.pro
        #falta
        ###############################################
        ###variables
        ###
        ###############################################

        update_file = kwargs.get("update_file",False)
        verbose = kwargs.get("verbose",False)
        force_all = kwargs.get("force_all",False)
        station = kwargs.get("station",None)

        ###############################################################

        index_dates     =   numpy.zeros(6)
        index_dates_0   =   numpy.zeros(6)
        magnetic_dates  =   numpy.zeros(6)
        magnetic_dates1 =   numpy.zeros(6)
        magnetic_dates2 =   numpy.zeros(6)
        
        if ((self.Flag_dates is True) and (update_file is False) and (force_all is False)):
            return 
        
        fpath=os.path.join(self.system['auxiliar_dir'],self.GMS[self.system['gms']]['name']+'.dates')

        check_directory(fpath,verbose)



        fpath = self.system['auxiliar_dir']
        fname = self.GMS[self.system['gms']]['name']+'.dates'
        
        fpath = os.path.join(fpath,fname)
        
        exists = os.path.isfile(fpath)
        
        #revisar
        if exists and (update_file is not True):
            #archivo encontrado 
            
            buff_array=list()
            with open(fpath,'r') as f:
                for line in f.read().splitlines() :
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
                
            
            
            if verbose:
                print("Data cargada de {}.dates file".format(self.GMS[self.system['gms']]['name']))
        
        else:
            if (update_file is False):
                if verbose:
                    print("Warning: Imposible de leer archivos de datos GMS. {}.\
                        Se está intentando generar el archivo.".format(self.GMS[self.system['gms']]['name']))
                
                self.Error['value'][3]+=1
                self.Error['log']+= 'Input data file '+self.GMS[self.system['gms']]['name']+'.dates'+' not found or reading permission conflict. '
                
                    
            if (self.GMS[self.system['gms']]['name']!="planetary"):
                #############################################################################3
                #############################################################################3
                #############################################################################3
                fpath = os.path.join(self.system['indexes_dir'] ,self.GMS[self.system['gms']]['name'])
                fname = self.GMS[self.system['gms']]['code']+'_????????.k_index.early'
                
                fpath = os.path.join(fpath,fname) 
                #buscamos archivos con el mismo patron
                file0 = searchforpatron(fpath)
                total_files = len(file0)
 
                str_length1 = len(os.path.expanduser(os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name']))) + len('/'+self.GMS[self.system['gms']]['code']+'_')
                
                str_length2 = len('.k_index.early') + len(os.path.expanduser(os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])))+len("/"+self.GMS[self.system['gms']]['code']+'_')
        
                expected_number = 0

                if total_files > 0 :

                    
                    for n,file in enumerate([file0[0],file0[-1]]):
                        with open(file,'r') as file:
                            for linea in file.read().splitlines() :
                                valores = re.findall(r'-?\d+\.?\d*', linea)
                                # Convertir los valores a enteros o números de punto flotante según corresponda
                                valores = [int(v) if v.isdigit() else float(v) for v in valores]
                                if len(valores)>0:
                                    valor = valores[-1]

                                    index_dates[n*3]=int(valores[0])
                                    index_dates[n*3+1]=int(valores[0])
                                    index_dates[n*3+2]=int(valores[0])

                    # date1 = datetime(index_dates[3],index_dates[4],index_dates[5])
                    # date2 = datetime(index_dates[0],index_dates[1],index_dates[2])

                    expected_number=2

                    #expected_number = JULDAY(date1) - JULDAY(date2) + 1

                
                if total_files<0 or expected_number>total_files:

                    if verbose:
                        Warning("Es requerido actualizar 'early data' manualmente los index files para el GMS: {}".format(self.GMS[self.system['gms']]['name']))

                #############################################################################3
                #############################################################################3
                #############################################################################3
                
                fpath = os.path.join(self.system['indexes_dir'] ,self.GMS[self.system['gms']]['name'])
                fname = self.GMS[self.system['gms']]['code']+'_????????.k_index.final'
                
                fpath = os.path.join(fpath,fname) 
                #buscamos archivos con el mismo patron
                file0 = searchforpatron(fpath)
                total_files = len(file0)

                str_length1 = len(os.path.expanduser(os.path.join(self.system['indexes_dir'],
                                                                  self.GMS[self.system['gms']]['name']))) + \
                              len('/'+self.GMS[self.system['gms']]['code']+'_')
                
                str_length2 = len('.k_index.final') + len(os.path.expanduser(os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])))+len("/"+self.GMS[self.system['gms']]['code']+'_')
                
                if total_files > 0 :

                    
                    for n,file in enumerate([file0[0],file0[-1]]):
                        print("file",file)
                        with open(file,'r') as f:
                            for linea in f.read().splitlines() :
                                valores = re.findall(r'-?\d+\.?\d*', linea)
                                # Convertir los valores a enteros o números de punto flotante según corresponda
                                valores = [int(v) if v.isdigit() else float(v) for v in valores]
                                print(valores,'valores')
                                if len(valores)>0:

                                    valor = valores[-1]
                                    print("valor",valor)
                                    index_dates_0[n*3]=int(valores[0])
                                    index_dates_0[n*3+1]=int(valores[1])
                                    index_dates_0[n*3+2]=int(valores[2])
                    #falta
                    # date1 = datetime(index_dates_0[3],index_dates_0[4],index_dates_0[5])
                    # date2 = datetime(index_dates_0[0],index_dates_0[1],index_dates_0[2])

                    # expected_number = JULDAY(date1) - JULDAY(date2) + 1
                    expected_number = 10
                if total_files<0 or expected_number>total_files:

                    if verbose:
                        Warning("Es requerido actualizar 'early data' manualmente los index files para el GMS: {}".format(self.GMS[self.system['gms']]['name']))

                ##########################################################################
                fpath = os.path.join(self.system['datasource_dir'] ,self.GMS[self.system['gms']]['name'])
                fname = self.GMS[self.system['gms']]['code']+'_????????rmin.min'
                
                fpath = os.path.join(fpath,fname) 
                #buscamos archivos con el mismo patron
                file1 = searchforpatron(fpath)
                total_files = len(file1)

                str_length1 = len(os.path.expanduser(os.path.join(self.system['datasource_dir'],
                                                                  self.GMS[self.system['gms']]['name']))) + \
                                len('/'+self.GMS[self.system['gms']]['code'])
                
                str_length2 = len('rmin.min') + \
                              len(os.path.expanduser(os.path.join(self.system['datasource_dir'],
                                                                  self.GMS[self.system['gms']]['name'])))+ \
                              len("/"+self.GMS[self.system['gms']]['code'])
                
                if total_files > 0 :

                    
                    for n,file in enumerate([file1[0],file1[-1]]):
                        with open(file,'r') as f:
                            for linea in f.read().splitlines() :
                                re.findall(r'-?\d+\.?\d*', linea)
                                # Convertir los valores a enteros o números de punto flotante según corresponda
                                valores = [int(v) if v.isdigit() else float(v) for v in valores]

                                valor = valores[-1]

                                index_dates_0[n*3]=int(valor[:4])
                                index_dates_0[n*3+1]=int(valor[4:6])
                                index_dates_0[n*3+2]=int(valor[6:8])

                    date1 = datetime(index_dates_0[3],index_dates[4],index_dates_0[5])
                    date2 = datetime(index_dates_0[0],index_dates_0[1],index_dates_0[2])

                    expected_number = JULDAY(date1) - JULDAY(date2) + 1

                if total_files<0 or expected_number>total_files:

                    if verbose:
                        Warning("Es requerido actualizar 'early data' manualmente los index files para el GMS: {}".format(self.GMS[self.system['gms']]['name']))


                ########################index_dates###########################################################
                fpath = os.path.join(self.system['datasource_dir'] ,self.GMS[self.system['gms']]['name'])
                fname = self.GMS[self.system['gms']]['code']+'_????????.rK.min'
                
                fpath = os.path.join(fpath,fname) 
                #buscamos archivos con el mismo patron
                file2 = searchforpatron(fpath)
                total_files = len(file2)

                str_length1 = len(os.path.expanduser(os.path.join(self.system['datasource_dir'],
                                                                  self.GMS[self.system['gms']]['name']))) + \
                                len('/'+self.GMS[self.system['gms']]['code']+'_')
                
                str_length2 = len('.rK.min') + \
                              len(os.path.expanduser(os.path.join(self.system['datasource_dir'],
                                                                  self.GMS[self.system['gms']]['name'])))+ \
                              len("/"+self.GMS[self.system['gms']]['code'])
                
                if total_files > 0 :

                    
                    for n,file in enumerate([file2[0],file2[-1]]):
                        with open(file,'r') as f:
                            for linea in f.read().splitlines() :
                                re.findall(r'-?\d+\.?\d*', linea)
                                # Convertir los valores a enteros o números de punto flotante según corresponda
                                valores = [int(v) if v.isdigit() else float(v) for v in valores]

                                valor = valores[-1]

                                magnetic_dates2[n*3]=int(valor[:4])
                                magnetic_dates2[n*3+1]=int(valor[4:6])
                                magnetic_dates2[n*3+2]=int(valor[6:8])

                    date1 = datetime(magnetic_dates2[3],magnetic_dates2[4],magnetic_dates2[5])
                    date2 = datetime(magnetic_dates2[0],magnetic_dates2[1],magnetic_dates2[2])

                    expected_number = JULDAY(date1) - JULDAY(date2) + 1

                if total_files<0 or expected_number>total_files:

                    if verbose:
                        Warning("Es requerido actualizar 'early data' manualmente los index files para el GMS: {}".format(self.GMS[self.system['gms']]['name']))

            else:

                #####################################################################################

                fpath = os.path.join(self.system['datasource_dir'] ,self.GMS[self.system['gms']]['name'])
                fname = self.GMS[self.system['gms']]['code']+'_????????.rK.min'
                
                fpath = os.path.join(fpath,fname) 
                #buscamos archivos con el mismo patron
                file = searchforpatron(fpath)
                total_files = len(file)

                if total_files > 0 :
                    
                    tmp_pos = inverse_search(file[0],self.GMS[self.system['gms']]['code']+'_') + len(self.GMS[self.system['gms']]['code']+'_')
                    tmp_str1 = '{:0d }'.format(tmp_pos)

                    tmp_pos = inverse_search(file[-1],self.GMS[self.system['gms']]['code']+'_') + len(self.GMS[self.system['gms']]['code']+'_')+len('.k_index')
                    tmp_str2 = '{:0.0f} '.format(tmp_pos)
 
                    for n,line in enumerate([file[0],file[-1]]):
                        chain = line.split(" ")
                        valor = chain[-1]

                        index_dates[n*3] = int(valor[:4])
                        index_dates[n*3+1] = int(valor[4:6])
                        index_dates[n*3+2] = int(valor[6:8])
                    
                    date1 = datetime(index_dates[0],index_dates[1],index_dates[2])
                    date2 = datetime(index_dates[3],index_dates[4],index_dates[5])
                    expected_number = JULDAY(date2)-JULDAY(date1)+1
                

                index_dates_0 = index_dates
                expected_number1=0

                if total_files <=0 or expected_number>total_files:
                    if verbose:
                        print("Archivos incompletos para seleccionado GMS {}. Es requerido actualizar manualmente los archivos.".format(self.GMS[self.system['gms']]['name']))

                
                #####################################################################################
                #####################################################################################

                fpath = os.path.join(self.system['datasource_dir'] ,self.GMS[self.system['gms']]['name'])
                fname = os.path.join(self.GMS[self.system['gms']]['code'],'kp????.wdc')
                
                fpath = os.path.join(fpath,fname) 
                #buscamos archivos con el mismo patron
                file1 = searchforpatron(fpath)
                total_files1 = len(file1)

                if total_files > 0 :
                    tmp_mag_dates = numpy.zeros(4)

                    tmp_pos = inverse_search(file1[0],'kp') + len('kp')
                    tmp_str1 = '{:0d }'.format(tmp_pos)

                    tmp_pos = inverse_search(file1[-1],'kp') + len('kp.wdc')
                    tmp_str2 = '{:0.0f} '.format(tmp_pos)
 
                    for n,line in enumerate([file[0],file[-1]]):
                        chain = line.split(" ")
                        valor = chain[-1]

                        tmp_mag_dates[n*2]   = int(valor[:2])
                        tmp_mag_dates[n*2+1] = int(valor[2:4])

                    expected_number1 = (tmp_mag_dates[2]-tmp_mag_dates[0])*12 + tmp_mag_dates[3]-tmp_mag_dates[1]+1

                    magnetic_dates1[4] = tmp_mag_dates[3]
                    magnetic_dates1[3] = tmp_mag_dates[2]+2000
                    magnetic_dates1[1] = tmp_mag_dates[1]
                    magnetic_dates1[0] = tmp_mag_dates[0]+2000                    
                    
                    date1 = datetime(magnetic_dates1[0],magnetic_dates1[1]+1,1)+relativedelta(days=-1)
                    date2 = datetime(magnetic_dates1[0],magnetic_dates1[1],1)+relativedelta(days=-1)

                    magnetic_dates1[2] = JULDAY(date1)-JULDAY(date2)


                    date1 = datetime(magnetic_dates1[3],magnetic_dates1[4]+1,1)+relativedelta(days=-1)
                    date2 = datetime(magnetic_dates1[3],magnetic_dates1[4],1)+relativedelta(days=-1)

                    magnetic_dates1[5] = JULDAY(date1)-JULDAY(date2)
 
                #####################################################################################

                fpath = os.path.join(self.system['datasource_dir'] ,self.GMS[self.system['gms']]['name'])
                fname = 'dst????.dat'

              
                
                fpath = os.path.join(fpath,fname) 
                #buscamos archivos con el mismo patron
                file2 = glob.glob(fpath)
 
                total_files2 = len(file1)            
                

                if total_files2 >0:
                    tmp_mag_dates = numpy.zeros(4)

                    tmp_pos = inverse_search(file2[0],'dst') + len('dst')
                    tmp_str1 = '{:0.0f} '.format(tmp_pos)

                    tmp_pos = inverse_search(file2[-1],'dst') + len('dst') + len('.dat')
                    tmp_str2 = "{:0.0f} ".format(tmp_pos)

                    for n,line in enumerate([file[0],file[-1]]):
                        
                        line = line.split(" ")
                        valor = line[-1]

                        tmp_mag_dates[n*2] = int(valor[:2])
                        tmp_mag_dates[n*2+1] = int(valor[2:4])

                    
                    expected_number2 = (tmp_mag_dates[2]-tmp_mag_dates[0])*12 + \
                                      tmp_mag_dates[3] - tmp_mag_dates[1]+1
                    
                    magnetic_dates2[4] = tmp_mag_dates[3]
                    magnetic_dates2[3] = tmp_mag_dates[2]+2000
                    magnetic_dates2[1] = tmp_mag_dates[1]
                    magnetic_dates2[0] = tmp_mag_dates[0]+2000            

                    magnetic_dates2[2] = JULDAY(datetime(magnetic_dates2[0],magnetic_dates2[1],1)+\
                                                relativedelta(months=+1)+relativedelta(days=-1)) - JULDAY(datetime(magnetic_dates2[0],magnetic_dates2[1],1)+relativedelta(days=-1))      
                        



                if expected_number1 >total_files1 or total_files2<=0 or (expected_number2>total_files2):
                    if verbose:
                        print("Inconsistencia: Archivos incompletos de datos magneticos para seleccionado GMS {}. \
                              El sistema tomara como vacio los archivos perdidos.".format(self.GMS[self.system['gms']]['name']))
                        

                

                index_dates_0 = index_dates

                if total_files <=0 or expected_number>total_files:
                    if verbose:
                        print("Archivos incompletos para seleccionado GMS {}. Es requerido actualizar manualmente los archivos.".format(self.GMS[self.system['gms']]['name']))

                
                #####################################################################################

            if numpy.prod(magnetic_dates1)>0:
                magnetic_dates[3:6] = magnetic_dates2[3:6] if (JULDAY(datetime(magnetic_dates2[3],magnetic_dates2[4],magnetic_dates2[5]))> JULDAY(datetime(magnetic_dates2[3],magnetic_dates2[4],magnetic_dates2[5]))) else magnetic_dates1[3:5]
                magnetic_dates[0:3] = magnetic_dates2[:3] if (JULDAY(datetime(magnetic_dates2[0],magnetic_dates2[1],magnetic_dates2[2]))> JULDAY(datetime(magnetic_dates2[0],magnetic_dates2[1],magnetic_dates2[2]))) else magnetic_dates1[:3]

            else:
                magnetic_dates[-3:] = magnetic_dates2[-3:]
                magnetic_dates[:3]  = magnetic_dates2[:3]

            format_ = '{:4.0f}{:02.0f}{:02.0f}-{:4.0f}{:02.0f}{:02.0f}'
            file  =  os.path.join(self.system['auxiliar_dir'],self.GMS[self.system['gms']]['name']+'.dates')

            string_data = numpy.empty(5,dtype='object')

            string_data[0] = '# File with available date range for the GMS: 1st and 2nd rows are related with the early and final k-index files, respectively; and the 3rd row with the magnetic data files.'
            string_data[1] = '# the format is initial-final date [YYYYMMDD]'
     
            string_data[2] = format_.format(index_dates[0],index_dates[1],index_dates[2],
                                            index_dates[3],index_dates[4],index_dates[5])
            string_data[3] = format_.format(index_dates_0[0],index_dates_0[1],index_dates_0[2],
                                            index_dates_0[3],index_dates_0[4],index_dates_0[5])

            if not os.path.isfile(file):
                FileNotFoundError("No existe el archivo huancayo.dates en la ruta",os.path.dirname(file))
            else:
                with open(file,'w') as f:
                    
                    f.writelines(line+'\n' for line in string_data)
                    if verbose:
                        print("Actualizado {}.dates".format(self.GMS[self.system['gms']]))
        
        format_ = '{:4.0f}{:02.0f}{:02.0f}-{:4.0f}{:02.0f}{:02}'
        st1 = format_.format(index_dates[0],index_dates[1],index_dates[2],
                                            index_dates[3],index_dates[4],index_dates[5])
        st2 = format_.format(index_dates_0[0],index_dates_0[1],index_dates_0[2],
                                            index_dates_0[3],index_dates_0[4],index_dates_0[5])
        
        st3 = format_.format(magnetic_dates[0],magnetic_dates[1],magnetic_dates[2],
                                            magnetic_dates[3],magnetic_dates[4],magnetic_dates[5])
        

        if verbose:
            print("   Index[early] files date-range: {}".format(st1))
            print("   Index [final] files date-range: {}".format(st2))
            print("   Magnetic data data-range".format(st3))


        self.GMS[self.system['gms']]['dates_index'][0,:] = index_dates[:3]
        self.GMS[self.system['gms']]['dates_index'][1,:] = index_dates[3:6]
        self.GMS[self.system['gms']]['dates_index'][2,:] = index_dates_0[:3]
        self.GMS[self.system['gms']]['dates_index'][3,:] = index_dates_0[3:6]
        self.GMS[self.system['gms']]['dates_data'][0,:] = magnetic_dates[3:6]
        self.GMS[self.system['gms']]['dates_data'][1,:] = magnetic_dates[3:6]
        

        #####################################################################
        #### Quiet Days Section
        #####################################################################

        if update_file is False:

            fpath = os.path.join(self.system['auxiliar_dir'],'qdays.dates')

            if not os.access(fpath,os.R_OK) :
                if verbose:
                    print("Error critico, incapaz de leer archivos Q-days.")

                return
            else:
                file_qd  = os.path.join(self.system['auxiliar_dir'],'qdays.dates')
                print("path," ,file_qd)
                exists = os.path.isfile(file_qd)

            if exists:
                with open(file_qd,'r') as file: 

                    date_data =  numpy.array(file.read().splitlines() ,dtype='object')

                    buff = list()
                    for line in date_data:
                        if line[0]!='#':
                            buff.append(line)
                    value = buff[0].split("-")
                    
                    index_dates[0],index_dates[1],index_dates[2] = int(value[0][:4]),int(value[0][4:6]),int(value[0][6:8])
                    index_dates[3],index_dates[4],index_dates[5] = int(value[-1][:4]),int(value[-1][4:6]),int(value[-1][6:8])

                    if verbose:
                        print(" Data descargada de qdays.dates")

                    
            
            if verbose:

                print("Quiet Days date-range: {:4.0f}{:02.0f}{:02.0f}-{:4.0f}{:02.0f}{:02.0f}".format(index_dates[0],index_dates[1],index_dates[2],
                                                                                          index_dates[3],index_dates[4],index_dates[5]))
            
            print(index_dates[0])
            self.system['qdays_dates'][0] = datetime(int(index_dates[0]),
                                                       int(index_dates[1]),
                                                       int(index_dates[2]))
            
            self.system['qdays_dates'][1] = datetime(int(index_dates[3]),
                                                       int(index_dates[4]),
                                                       int(index_dates[5]))


        self.Flag_dates = True

        return 

                    


                
            

    def __check_gms(self,**kwargs):
        #script -> geomaxis_check_gms.pro
        #está listo
  
 
            station = kwargs.get("station",None)
            verbose = kwargs.get("verbose",False)
            force_all  = kwargs.get("force_all",False)

            #comprobamos que tipo es estacion

            if isinstance(station,str):
                station = [station]
            
            
            if station is None:
                station = self.GMS[self.system['gms']]['name']

                if verbose is True:
                    print('Configurando'+self.GMS[self.system['gms']]['name']+'como\
                          la estación GMS por defecto.')
                    
            else:
               
                
                if len(station)>0:
                    
                    for element in station:
                        
                        element = element.lower()

                        codes = numpy.array([dict_['code'] for dict_ in self.GMS],dtype='object')
                        names = numpy.array([dict_['name'] for dict_ in self.GMS],dtype='object')

                        ind1    =   numpy.where(codes==element)[0]
                        ind2    =   numpy.where(names==element)[0]

                        ind1 = ind1[0] if len(ind1)>0 else None
                        ind2 = ind2[0] if len(ind2)>0 else None

 

                        if ((ind1 is None) and (ind2 is None)) or (codes.shape[0]==0 and names.shape[0] ==0):
                            
                            raise RuntimeError("Error critico: GMS seleccionado no está disponible. Tambien es posible la lista no está disponible. Revise la lista.")
 
                        else:
                            station_number = ind1 if ind1 >= 0 else ind2

                            self.system['gms'] = station_number

                            station=self.GMS[self.system['gms']]['name']
                            
                            if (verbose is True) and (self.GMS[self.system['gms']]['check_flag']==0):

                                print('Configurando ',self.GMS[self.system['gms']]['name'], 'como estación GMS.')

            if (force_all is True) and (self.GMS[self.system['gms']]['check_flag']!=0):
                return 
            
            if self.GMS[self.system['gms']]['name']!= "planetary":
                fpath = os.path.join(self.system['auxiliar_dir'],self.GMS[self.system['gms']]['name']+".calibration")

                if os.access(fpath,os.R_OK) is False:

                    if verbose:

                        print("Error critico: Incapaz de leer archivo auxiliar {}. Es obligatorio otorgar los permisos de lectura.".format(self.GMS[self.system['gms']]['name']+".calibration"))



                    self.Error["value"][0]+=1
                    self.Error['log']+="Auxiliar file  "+self.GMS[self.system['gms']]['name']+ '.calibration'+" not found or read permissions conflict. "


                tmp_calibration = self.__ReadCalibration()
                self.GMS[self.system['gms']]['calibration']  = tmp_calibration

            

            ###########################################################################
            fpath=os.path.join(self.system['datasource_dir'],self.GMS[self.system['gms']]['name'])
            if os.access(fpath,os.R_OK) is False:
                if verbose:

                    print("Error crítico: Incapaz de leer el directorio {}. Es obligatorio permisos de lectura dentro del directorio.".format(fpath))
                
                self.Error['value'][0]+=1
                self.Error['log']+='Input directory  '+fpath+' not found or read permissions conflict. '
            

            ##

            fpath=os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])
            if os.access(fpath,os.W_OK) is False:
                if verbose:

                    print("Error crítico: Incapaz de escribir el directorio {}. Es obligatorio permisos de lectura dentro del directorio.".format(fpath))
                
                self.Error['value'][0]+=1
                self.Error['log']+='Output directory  '+fpath+' not found or read permissions conflict. '

            
            ##
            fpath=os.path.join(self.system['plots_dir'],self.GMS[self.system['gms']]['name'])

            if os.access(fpath,os.W_OK) is False:
                if verbose:

                    print("Error crítico: Incapaz de escribir el directorio {}. Es obligatorio permisos de lectura dentro del directorio.".format(fpath))
                
                self.Error['value'][0]+=1
                self.Error['log']+='Output directory  '+fpath+' not found or read permissions conflict. '

            ##
            fpath=os.path.join(self.system['indexes_dir'],self.GMS[self.system['gms']]['name'])
            
            if os.access(fpath,os.W_OK) is False:
                if verbose:

                    print("Error crítico: Incapaz de escribir el directorio {}. Es obligatorio permisos de lectura dentro del directorio.".format(fpath))
                
                self.Error['value'][0]+=1
                self.Error['log']+='Output directory  '+fpath+' not found or read permissions conflict. '
           

            self.GMS[self.system['gms']]['check_flag']=1
        

            if verbose:
                print("Estación geomagnetica {} está listo".format(self.GMS[self.system['gms']]['name']))

    





    def __check_system(self,**kwargs):
        # archivo ->geomagixs_check_system.pro
        # funcion -> geomagixs_check_system
        #Transcripcion completada

    
            verbose = kwargs.get("verbose",False)

            if(self.Flag_system == False):

                self.Flag_system = True

                if (self.system['geomagixs_dir'] == ''):
                    os.chdir(os.getcwd())
                    self.system['geomagixs_dir']=os.getcwd()
           

                if(self.system['setup_file'] == ''):
                    self.system['setup_file']='setup.config'


                if not os.path.isfile(os.path.join(self.system['geomagixs_dir'], self.system['setup_file'])) \
                      or not os.access(os.path.join(self.system['geomagixs_dir'], self.system['setup_file']), \
                                       os.R_OK):
                    
                    if verbose:
                        print(self.system['geomagixs_dir'],"directorio")
                        print("Error critico: setup file, {} no ha sido encontrado.",self.system['setup_file'],\
                              "Imposible leer system-congif data en la ruta",(os.path.join(self.system['geomagixs_dir'], self.system['setup_file'])))
                        
                    self.Error['value'][0]+=1
                    self.Error['log']+='Setup file '+self.system['setup_file']+' \
                                       not found or reading permission conflict. '
                    

                    return 

                   

                with open(os.path.join(self.system['geomagixs_dir'],self.system['setup_file']),'r') as file:
                        
                        buff_array= list()

                        if verbose is True:
                              
                            print("Leyendo datos del fichero: {}".format(self.system['setup_file']))
                        #modificacion, solo se lee las lineas que empiezan con "~"
                        for linea in file.read().splitlines() :
                            if ('~' in linea) and (not("#" in linea)):
                                #guardamos los tres archivos de configuración
                                buff_array.append(linea)

                            
                        #verificamos que se guardó 3 datos
               
                        if (len(buff_array)!=3):
                            if verbose is True:

                                print("Error critico: Revisar fichero {}, es imposible de leer datos\
                                       del archivo de configuracion.".format(self.system['setupfile']))
                                
                            self.Error['value'][0]+=1
                            self.Error['log']+="El formato de {} no está segun el estandar.".format(self.system['setupfile'])
                        
                        else:
                            
                            for n, _ in enumerate(buff_array):
                                buff_array[n] = os.path.expanduser(buff_array[n])

                            input_dir   = buff_array[0]
                            
                            if verbose is True:
                                print("Revisando arbol del directorio {}".format(input_dir))


                            key = check_directory(input_dir,verbose)

                            
                            if key: self.system['input_dir']=input_dir
 
                            #revisamos si tiene permisos la carpeta auxiliar

                            auxiliar_dir = buff_array[1]

                            key = check_directory(auxiliar_dir)

                            if key: self.system['auxiliar_dir'] = auxiliar_dir
 
                            ###datasource_dir

                            #Carpeta con datos magneticos
 

                            self.system['datasource_dir']=os.path.join(self.system['input_dir'],"data_source") \
                                                            if (self.system['datasource_dir'] == '') \
                                                            else  os.path.join(self.system['input_dir'],self.system['datasource_dir'])
                            

                            key = check_directory(self.system['datasource_dir'])

                            #file qdays
                        

                            self.system['qdays_dir']=os.path.join(self.system['datasource_dir'],"qdays") \
                                                            if (self.system['datasource_dir'] == '') \
                                                            else  os.path.join(self.system['datasource_dir'],self.system['qdays_dir'])
                            

                            check_directory(self.system['qdays_dir'])
                            #comprobamos permisos de escritura para el directorio de salida
                            # 
                            #     
                            output_dir = buff_array[2]


                            if verbose:
                                print('Revisando arbol del directorio de salida {}.'.format(self.system['output_dir']))


                            check_directory(output_dir,verbose)
                            
                            self.system['output_dir'] = output_dir

                            ####

                            self.system['indexes_dir']=os.path.join(self.system['output_dir'],"indexes") \
                                                            if (self.system['indexes_dir'] == '') \
                                                            else  os.path.join(self.system['output_dir'],self.system['indexes_dir'])

                            
                            check_directory(self.system['indexes_dir'])
                            ######

                            self.system['plots_dir']=os.path.join(self.system['output_dir'],"plots") \
                                                            if (self.system['plots_dir'] == '') \
                                                            else  os.path.join(self.system['output_dir'],self.system['plots_dir'])
                                
                            check_directory(self.system['plots_dir'],verbose,'w')
                            ######                            

                            self.system['processed_dir']=os.path.join(self.system['output_dir'],"processed") \
                                                            if (self.system['processed_dir'] == '') \
                                                            else  os.path.join(self.system['output_dir'],self.system['processed_dir'])
                                

                            check_directory(self.system['processed_dir'],verbose,'w')

                            ######################################################################################

                            if (self.system['gms'] == ''): self.system['gms']='gms.config'

                            pfile = os.path.join(self.system['geomagixs_dir'],self.system['gms_file'])

                            if not os.path.isfile(pfile):
                              
                                raise FileNotFoundError("El archivo {} no existe".format(os.path.basename(pfile)))
                            
                            else:

                                if os.access(pfile,os.R_OK) is False:

                                    if verbose:

                                        print("Error critico: Imposible de leer GMS data del \
                                            directorio '{}'. Es obligatorio conceder los permisos de \
                                            escritura del directorio 'plots'".format(self.system['gms_file']))
                                        
                                    self.Error['value'][0]+=1
                                    self.Error['log']+= 'GMS File'+self.system['gms_file']+' not found or reading permission conflict. '

                            
                                else:
                                    #abrimos archivo gms.config file

                                    with open(os.path.join(self.system['geomagixs_dir'],self.system['gms_file']),'r') as file:

                                        buff_array = list()

                                        for linea in file.read().splitlines() :
                                            
                                            if linea[0]!='#':
                                                buff_array.append(linea)
                                        

                                #el archivo acepta multiples configuraciones, en tuplas de 5 

                                if (len(buff_array) % 5 !=0):

                                    if verbose:
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
                                                'dates_index'  :  numpy.zeros((4,3)),
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
                                
                                if verbose:

                                    print("Critical Error: Conflicto con la data entrante. Data del FTP server\
                                          es inconsistente o invalido. Imposible de descargar data del servidor FTP.")
                                
                                self.Error['value'][0]+=1
                                self.Error['log']+='Missing user or/and address for FTP server; impossible to download data. '
                            
            
            else:
                return

 


    def __setup__commons(self,**kwargs):

        #archivo -> geomagixs_setup.pro
        #funcion -> PRO geomagixs_setup_commons, QUIET=quiet
   
        verbose = kwargs.get("verbose",False)

        if(self.Flag_setup == False):

            if (verbose):

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
                'qdays_dates'       : numpy.empty(2,dtype='object'), 
                'today_date'        : datetime.now(), 
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

           
            self.Flag_setup =True


        return 

    
        


        
