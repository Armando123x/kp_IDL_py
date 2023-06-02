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
            self.__magneticdata_download(date_initial=initial_date,date_final=final_date,verbose=verbose,station=station)
            #self.__magneticdata_

 
        #script -> geomagixs_quietdays_download.pro
            #falta codigo 170-173
            #falta
            #falta
        
        



        except:

            raise AttributeError("Algo salio mal en el inicio del programa.")
        

    # def __getting_magneticdata(self,initial,station,verbose=False):

    #     #####################################
    #     #Iniciando fechas y horas
    #     # 
    #     initial_year = initial.year
    #     initial_month = initial.month
    #     initial_day = initial.day


    #     name = '{:4d}{:02d}{:02d}.clean.dat'.format(initial_year,initial_month,initial_day)
    #     file_name = '{}_{}'.format(self.GMS[self.system['gms']]['code'],name)


    #     if not os.path.isfile(file_name):
    #         print("Archivo {} no encontrado".format(os.path.basename(file_name)))
        
    #         return
    #     else: 
    #         with open(file_name,'r') as file:
                
    #             magnetic_data = file.readlines()

    #             magnetic_data = numpy.array(magnetic_data,dtype='object')

        
    #     keys =  ['year','month','day','hour','minute','D','H','Z','F']
    #     struct = dict.fromkeys(keys,0)

    #     result_data = numpy.empty(magnetic_data.shape[0],dtype='object')
    #     result_data.fill(struct)

    #     #falta patron regular  linea 114


    #     return result_data

    def __getting_magneticdata(self,initial,station=None,verbose=None):
        # script geomagixs_quietday_get.pro
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

            ##falta idle patron re 
            #lineas 130,132


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
 

            for i in range(days_for_qdays):
                
                flatten = numpy.array([data['total_k'] for data in data_qd])
                indexes_equals1 = numpy.where(flatten==data_qd[i]['total_k'])[0]


                if len(indexes_equals1)>1:

                    tmp_struct1 = data_qd[indexes_equals1]
                    
                    sort = numpy.array([data['total_k2']for data in tmp_struct1])
                    argsort = numpy.argsort(sort)

                    for j in range(argsort.shape[0]):
                        temp = numpy.array([data['total_k2'] for data in tmp_struct1])
                        indexes_equals2 = numpy.where(temp)

                        for j,value in enumerate(temp):
                            
                            indexes_equals2 = numpy.where(temp==value)[0]
                            if len(indexes_equals2)>1:
                                tmp_struct2 = tmp_struct1[indexes_equals2]
                                
                                temp = numpy.array([data['max_k']for data in tmp_struct2])
                                argsort3 = numpy.argsort(temp)

                                tmp_struct1 [indexes_equals2] = tmp_struct2[argsort3]
                                j+=len(indexes_equals2)-1

                            


                    
 





        except:

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

    
        


        
