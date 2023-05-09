#geomagixs_setup_commons.pro
import geomagixs_commons
import numpy
import os 

from copy import deepcopy
from datetime import datetime



#######################################################################333
##### Parametro quiet en IDL  es practicamente verbose en Python
#####
#####
#####
########################################################################

def geomagixs_setup_commons(quiet=False):

    try:

        
        #
        if (Flag_setup)
    except:

        return 
    

def file_search(filename, directory):
    for root, dirs, files in os.walk(directory):
        if filename in files:
            return os.path.join(root, filename)


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
        try:
            #falta imprimir el tiempo 
            #
            #
            #
            #

            ################################################


            quiet= kwargs.get('quiet',False)

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






        except:

            raise AttributeError("Algo salio mal en el inicio del programa.")
        
    

    def __setup_dates(self,update_file=None,station=None, quiet=False, force_all=False):
        #script -> geomagixs_setup_dates.pro
        
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
                                                'dates_data'  : numpy.zeros((2,3)),
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
            


            self. Flag_setup =True


         #final 

    
        


        
