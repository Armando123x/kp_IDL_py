from utils import *
from datetime import datetime 



class calibration(object):

    def __init__(self,**kwargs):
        self.calibration_dir = os.path.join(self.system['processed_dir'],self.GMS[self.system['gms']]['name'])

    def __getting_processeddata(self,initial,**kwargs):
        
        '''
        script-> geomagixs_get_processeddataday.pro
        
        '''

        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day

        string_date = '{:4d}{:02d}{:02d}'.format(initial_year,initial_month,initial_day)

        file_name = self.GMS[self.system['gms']]['code'] + '_'  + string_date + '.data.early'

        file = os.path.join(self.calibration_dir,file_name)

        exists = os.path.isfile(file)

        if exists:
        
            with open(file,'r') as f:

                magnetic_data = numpy.array(f.read().splitlines(),dtype=object)

            
            struct = {
                'dD':0,
                'dH':0,
                'dZ':0,
                'dF':0,
                'dN':0,
                  }

            resulting_data = numpy.empty(magnetic_data.shape[0],dtype= object)
            resulting_data = fill(resulting_data,struct)

            #revisar 
            #format '(146X, 2X, F7, X, F9, X, F9, X, F9, X, F9)'

            keys = ['dD','dH','dZ','dF','dN']


            for n,line in enumerate(magnetic_data):
                valores = re.findall(r'-?\d+\.?\d*', line)
                # Convertir los valores a enteros o números de punto flotante según corresponda
                valores = [int(v) if v.isdigit() else float(v) for v in valores]

                if len(valores>0):
                    for key,valor in zip(keys,valores):

                        resulting_data[n][key] = valor

            

            return resulting_data




    def __get_processeddataday(self,initial,**kwargs):
        

        '''
        
        script -> geomagixs_get_processeddataday.pro

        
        '''
        verbose = kwargs.get("verbose",False)
        real_time = kwargs.get("real_time",False)
        force_all = kwargs.get("force_all",False)
        station = kwargs.get("station",None)


        update_flag = False


        initial_date = initial

        tmp_year = initial_date.year
        tmp_month = initial_date.month
        tmp_day = initial_date.day

        tmp = self.__getting_processeddata(initial_date,**kwargs)


        return tmp





    def getitng_magneticdata(self,initial,**kwargs):

        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose",False)



        initial_year = initial.year
        initial_month = initial.month
        initial_day   = initial.day


        tmp_string = months[initial_month-1]

        chain = "{:02d}{}.{:02d}m"
        chain = chain.format(initial_day,tmp_string,initial_year%1000)

        file_name = self.GMS[self.system['gms']]['code'] + chain 

        file = os.path.join(self.calibration_dir,self.GMS[self.system['gms']]['name'],'DataMin',file_name)

        exists = os.path.isfile(file)


        if exists: 

            with open(file,'r') as f:
                magnetic_data = numpy.array(f.read().splitlines(),dtype=object)

        else:
            magnetic_data = numpy.empty(1,dtype=object)

        struct = {
            'day' : 0 ,
            'month':0,
            'year':0,
            'hour':0,
            'minute':0,
            'D':0,
            'H':0,
            'Z':0,
            'I':0,
            'F':0
        }
                        
        # FORMAT_1 = '(I2,X,I2,X,I4,X,I2,X,I2,X,F7,X,F7,X,F7,X,F7,X,F7)'
        # FORMAT_2 = '(I2,X,I2,X,I4,X,I2,X,I2,X,F8,X,F8,X,F8,X,F8,X,F8)'
  
        if (magnetic_data.shape[0] -4 >=1):
            resulting_data = numpy.empty(magnetic_data.shape[0]-4,dtype=object)

            resulting_data = fill(resulting_data,struct)

            #revisar si es necesario hacer el cambio de formato 

            for n,element in enumerate(magnetic_data[4:]):

                #revisar cual formato agregamos
                pass
                
        else:

            resulting_data = numpy.empty(1,dtype=object)
            resulting_data = fill(resulting_data,struct)

            resulting_data[0]['day'] = initial_day
            resulting_data[0]['month'] = initial_month
            resulting_data[0]['year'] = initial_year

            resulting_data[0]['hour'] = 0
            resulting_data[0]['minute'] = 0

            resulting_data[0]['D'] = 99.9999
            resulting_data[0]['H'] = 99999.9
            resulting_data[0]['Z'] = 99999.9
            resulting_data[0]['I'] = 99.9999
            resulting_data[0]['F'] = 99999.9

        
        return resulting_data
    

  
        

    def __getting_voltagedata(self,initial,**kwargs):

        '''
        
        Archivo geomagixs_get_voltagedataday.pro
        
        '''
        initial_year  = initial.year
        initial_month = initial.month
        initial_day = initial.day 


        tmp_string = months[initial_month-1]

        chain = "{:02d}{}.{:02d}v"

        file_name = self.GMS[self.system['gms']] + chain.format(initial_day,tmp_string,initial_year%1000)


        file = os.path.join(self.calibration_dir,self.GMS[self.system['gms']]['name'],'DataMin',file_name)

        exists = os.path.isfile(file)

        if not exists:

            print("Archivo {} no encontrado.".format(file_name))

            magnetic_data = numpy.empty(1,dtype=object)
        else:

            with open(file,'r') as file:

                magnetic_data = numpy.array(file.read().splitlines(),dtype=object)

        
        struct = {
                    'day' : 0 ,
                    'month' :0,
                    'year':0,
                    'hour':0,
                    'minute':0,
                    'H':0,
                    'D':0,
                    'Z':0,
                    'Tc':0,
                    'Ts':0
                                  }

        if (magnetic_data.shape[0] -5 >= 1):

            resulting_data = numpy.empty(magnetic_data.shape[0]-4,dtype=object)

            resulting_data = fill(resulting_data,struct)

            i = 4
            #revisar
            while(i<magnetic_data.shape[0]-1):
                #revisar
            
                valores = re.findall(r'-?\d+\.?\d*', linea)

                    # Convertir los valores a enteros o números de punto flotante según corresponda
                valores = [int(v) if v.isdigit() else float(v) for v in valores]
                
                #revisar como agregar los atributos
                #magnetic_data = 
                #linea 153

                i+=1
            
        else:
            resulting_data = numpy.empty(1,dtype=object)
            resulting_data = fill(resulting_data,struct)

            #--------- rellenamos con gaps--------------

            resulting_data[0]['day'] = initial_day
            resulting_data[0]['month'] = initial_month
            resulting_data[0]['year'] = initial_year

            resulting_data[0]['hour'] = 0
            resulting_data[0]['minute'] = 0
            
            resulting_data[0]['H'] = 9999.99
            resulting_data[0]['D'] = 9999.99
            resulting_data[0]['Z'] = 9999.99

            resulting_data[0]['Tc'] = 9999.99
            resulting_data[0]['Ts'] = 9999.99
        

        return resulting_data




    def __get_voltagedataday(self,initial=None,**kwargs):

        '''
        Script -> geomagixs_get_voltagedataday.pro 
        
        '''

        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose", False)
        force_all = kwargs.get("force_all",False)
        real_time = kwargs.get("real_time",False)



        update_flag= False


        if (initial is None):
            
            initial = self.system['today_date']

        
        initial_date = initial 

        tmp_year = initial_date.year
        tmp_month = initial_date.month
        tmp_day = initial_date.day


        tmp = self.__getting_voltagedata(initial_date,**kwargs)



        return tmp 
    






    def __fixing_magneticfile(self,file_date,**kwargs):

        ##
        #####
        ## file -> geomagixs_make_calibrationfile.pro

        '''
            ; DEPENDENCIAS:
            ;       omniweb_setup                                  : initilizes the directory tree
            ;
            ; ARCHIVOS ANALIZADOS:
            ;       teoYYYYMMDDrmin.min
            ;
            ; ARCHIVOS DE SALIDA:
            ;       YYYYMMDD_min.magnetic
        
        '''

        station = kwargs.get("station",None)

        verbose = kwargs.get("verbose",False)

        
        initial = file_date


        #------------------- reading data files -----------------------

        tmp_year  = 0
        tmp_month  = 0
        tmp_day = 0
        tmp_julday = JULDAY(initial)

        result = CALDAT(tmp_julday)

        tmp_year = result.year
        tmp_month = result.month
        tmp_day = result.day
        

        magnetic_data = self.__get_magneticdataday(datetime(tmp_year,tmp_month,tmp_day),**kwargs)
        

        data_number = vectorize(magnetic_data,'H').shape[0]



        hours_in_a_day = 24
        minutes_in_a_day = 60*hours_in_a_day


        final_file = numpy.empty(minutes_in_a_day,dtype=object)


        j_inicio = 0

        for i in range(minutes_in_a_day):
            chain = '{4d} {:02d} {:02d} {:02d}:{:02d} {:07.4f} {:07.1f} {:07.1f} {:07.4f} {:07.1f}'
            final_file[i] = chain.format(tmp_year,tmp_month,tmp_day,i//60,i%60,99.9999,  99999.9,  99999.9, 99.9999, 99999.9)

            while(j_inicio<data_number):
                j = j_inicio
                if ((i//60 == magnetic_data[j]['hour']) and (i%60 == magnetic_data[j]['minute'])):

                    chain = '{4d} {:02d} {:02d} {:02d}:{:02d} {:07.4f} {:07.1f} {:07.1f} {:07.4f} {:07.1f}'
                    final_file[i] = chain.format(tmp_year,tmp_month,tmp_day,i//60,i%60,
                                                 magnetic_data[j]['D'],magnetic_data[j]['H'],magnetic_data[j]['Z'],magnetic_data[j]['I'],magnetic_data[j]['F'])

                    j_inicio +=1
                    break
        
        return final_file
    

    def __fixing_voltagefile(self,file_date,**kwargs):

        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose",False)


        initial_year = file_date.year
        initial_month = file_date.month
        initial_day  = file_date.day
        initial_day


        #reading data files

        result = CALDAT(JULDAY(file_date))

        tmp_year = result.year
        tmp_month = result.month
        tmp_day = result.day


        voltage_data = self.__get_voltagedataday(file_date,**kwargs)

        data_number = numpy.ravel(vectorize(voltage_data,'H')).shape[0]


        hours_in_a_day = 24
        minutes_in_a_day = 60*hours_in_a_day


        final_file = numpy.empty(minutes_in_a_day,dtype=object)

        j_inicio = 0 

        for i in range(minutes_in_a_day):

            chain = '{:4d} {:02d} {:02d} {:02d}:{:02d}  {:09.3f} {:09.3f} {:09.3f} {:08.3f} {:08.3f}'
            final_file[i] = chain.format(tmp_year, tmp_month, tmp_day, i//60,i%60,9999.999,  9999.999,  9999.999, 9999.999, 9999.999)

            while(j_inicio<data_number):

                j = j_inicio
                if ((i//60 == voltage_data[j]['hour'])  and     (i%60 == voltage_data[j]['minute'])):
                    
                    chain = '{:4d} {:02d} {:02d} {:02d}:{:02d}  {:09.3f} {:09.3f} {:09.3f} {:08.3f} {:08.3f}'
                    
                    final_file[i] = chain.format(tmp_year, tmp_month, tmp_day, i//60, i % 60,
                                                voltage_data[j]['D'],voltage_data[j]['H'],
                                                 voltage_data[j]['Z'],voltage_data[j]['Tc'],voltage_data[j]['Ts'] )

                    j_inicio = j +1 

                    break
        

        return final_file

    def __make_calibrationfile(self,initial= None,final =None,**kwargs):
        

        '''
        script -> geomagixs_make_calibrationfile.pro
        
        '''
        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose",False)
        force_all = kwargs.get("force_all",False)


        if initial is None:
            initial = self.system['today_date']
        if final is None:
            final = initial

        #check dates

        self.__check_dates(initial,final,**kwargs)


        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day
        

        final_year = final.year
        final_month = final.month
        final_day = final.day


        #------------------------------------ reading data files -------------------------------#

        file_number = JULDAY(final) - JULDAY(initial) + 1

        hours_in_a_day = 24
        minutes_in_a_day = 60*hours_in_a_day

        processed_data = numpy.empty(file_number*minutes_in_a_day)

        string_date = numpy.empty(file_number,dtype=object)

        julday_tmp = JULDAY(initial)

        for i in range(file_number):

            date  = CALDAT(julday_tmp+i)
 

            tmp_string = self.__fixing_voltagefile(date,**kwargs)
            processed_data[minutes_in_a_day*i:minutes_in_a_day*(i+1)] = deepcopy(tmp_string)
        
        chain = '{:4d}{:02d}{:02d}-{:4d}{:02d}{:02d}'
        chain = chain.format(initial_year, initial_month, initial_day, final_year, final_month, final_day)
        
        file_name = self.GMS[self.system['code']] + '_' + chain + '.calibration.v'


        calibration_dir = os.expanduser('~/DATA/calibration')

        fpath = os.path.join(calibration_dir,file_name)

        with open(fpath,'w') as file:

            file.writelines(line + '\n' for line in  processed_data)

        if verbose:

            print("Archivo {} de calibración listo para cálculo.".format(file_name))

        processed_data = numpy.empty(file_number*minutes_in_a_day,dtype=object)

        for i in range(file_number*minutes_in_a_day):

            date = CALDAT(julday_tmp+i)

            tmp_string = self.__fixing_magneticfile(date,**kwargs)

            processed_data[minutes_in_a_day*i:minutes_in_a_day*(i+1)]  = deepcopy(tmp_string)

        chain = '{:4d}{:02d}{:02d}-{:4d}{:02d}{:02d}'
        chain = chain.format(initial_year, initial_month, initial_day, final_year, final_month, final_day)
        
        file_name = self.GMS[self.system['code']] + '_' + chain + '.calibration.m'

        fpath = os.path.join(calibration_dir,file_name)

        with open(fpath,'w') as file:

            file.writelines(line + '\n' for line in  processed_data)
        
        if verbose:
            print("Archivo de calibración {} listo para cálculo.".format(file_name))

        return 
    def __get_magneticdataday(self,initial,**kwargs):
        
        '''
        Script -> geomagixs_get_magneticdataday.pro
        '''
        tmp = self.getitng_magneticdata(initial,**kwargs)

        return tmp 
    

    def __getting_data (self,file_name):

        '''
        Script -> geomagixs_make_viewstation.pro 
        
        '''
        exist = os.path.isfile(file_name)

        if not exist:
            print("Archivo no encontrado {}".format(os.path.basename(file_name)))
            return 
        
        else:
            with open(file_name,'r') as file:

                file_data = numpy.array(file.read().splitlines(),dtype=object)
                number_of_lines = file_data.shape[0]

                if len(file_data[0]<=56):
                # format_for_reading = '(I4,X,I2,X,I2,X,I2,X,I2,X,F7,X,F7,X,F7,X,F7,X,F7)'

                    struct = {
                        'year':0,
                        'month':0,
                        'day':0,
                        'hour':0,
                        'minute':0,
                        'D':0,
                        'H':0,
                        'Z':0,
                        'I':0,
                        'F':0
                    }
                else:
                # format_for_reading = '(I4,X,I2,X,I2,X,I2,X,I2,2x,F9,X,F9,X,F9,X,F8,X,F8)'


                    struct = {
                        'year':0,
                        'month':0,
                        'day':0,
                        'hour':0,
                        'minute':0,
                        'D':0,
                        'H':0,
                        'Z':0,
                        'Tc':0,
                        'Ts':0
                    }
                

                data = numpy.empty(number_of_lines,dtype=object)
                data = fill(data,struct)

                #revisar 
                #falta formato 176
                return data
            

        
    def __make_viewstation(self,initial,final,**kwargs):

        '''
        script -> geomagixs_make_viewstation.pro
        
        '''
        H = kwargs.get('H',None)
        D = kwargs.get("D",None)
        Z = kwargs.get("Z",None)
        force_all = kwargs.get("force_all",False)
        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose",False)


        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day


        final_year = final.year
        final_month = final.month
        final_day = final.day

        number_of_days = JULDAY(final)- JULDAY(initial) + 1 

        time_array  = (numpy.arange(number_of_days*24*60)/(number_of_days*24*60-1)*(number_of_days*24*60)).astype(int)



        print("----------- -- MAKE_VIEWSTATION --------------------")
        print("WARNING:")
        print("     Este programa compara los valores de Auxiliar GMS con los valores de la estación seleccionada.")

        format_ = "{:4d}{:02d}{:02d}-{:4d}{:02d}{:02d}.calibration.*"
        
        date = format_.format(initial_year, initial_month, initial_day, final_year, final_month, final_day)

        file_name = self.GMS[self.system['gms']]['code'] + "_" + date

        file_name = os.path.join(self.calibration_dir,file_name)


        file_station = searchforpatron(file_name)

        file_station = numpy.array(file_station,dtype=object)


        if (file_station.shape[0] != 2 ):

            print("Error: Archivos de calibración perdidos {}".format(file_name))

            return 
        
        file_station = [os.path.join(self.calibration_dir,file ) for file in file_station]

        station_magnetic_data = self.__getting_data(file_station[0])
        station_voltage_data = self.__getting_data(file_station[1])


        print('   Base-line reference values: <H> [nT]    <D> [°]    <Z> [nT]')

        H_base = 27393.3
        D_base = 5.434
        Z_base = 29444.6

        format_ = '{:7.1f}'+space(6) +'{:5.3f}'+space(5) + '{:7.1f}'
        print(format_.format(H_base,D_base,Z_base))


        mask0 = (vectorize(station_magnetic_data,'H')<99990).astype(bool)
        mask1 = (vectorize(station_magnetic_data,'D')<90).astype(bool)
        mask2 = (vectorize(station_magnetic_data,'Z')<99990).astype(bool)
        

        mask3 = (numpy.abs(vectorize(station_magnetic_data,'H'))< 1500).astype(bool)
        mask4 = (numpy.abs(vectorize(station_magnetic_data,'D'))< 1500).astype(bool)
        mask5 = (numpy.abs(vectorize(station_magnetic_data,'Z'))< 1500).astype(bool)

        mask = mask0&mask1&mask2&mask3&mask4&mask5

        #falta implementar

        return 


    def __detrending (self,y,yd,detrending= None):
        

        '''
        
        script -> geomagixs_make_processcalibration.pro
        '''
        y = numpy.array(y)

        sz = y.shape
        n_points = sz[1]

        yd = numpy.empty(n_points,dtype=float)

        if detrending is None:
            yd = y 
            return numpy.array([0.])
        
        x = numpy.arange(n_points)

        if (detrending == 0):
            m_y = smooth(y,72*60,type='filter')
            y_d = y - m_y

            coeff = [0]
        elif (detrending == 1):
            
            result = POLY_FIT (x,y,n=1)
            coeff = result.result
            y_fitted  = result.tendency
            yd = y - y_fitted

        else:
            result = POLY_FIT(x,y,n=1)
            coeff = result.result
            y_fitted = result.tendency
            yd = y - y_fitted
        

        return coeff 


        




    def __make_processcalibration(self,initial,final,**kwargs):

        '''
        file-> geomagixs_make_processcalibration.pro
        
        '''
        
        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day

        final_year= final.year
        final_month = final.month
        final_day = final.day 


        number_of_days = JULDAY(final) - JULDAY(initial) +1 

        time_array = (numpy.arange(number_of_days*24*60)/(number_of_days*24*60-1) * (number_of_days*24*60)).astype(int)


        format_ = "{:4d}{:02d}{:02d}-{:4d}{:02d}{:02d}.calibration.*"
        date = format_.format(initial_year, initial_month, initial_day, final_year, final_month, final_day)
        
        file_name  = self.GMS[self.system['gms']]['code'] + '_' + date

        file = os.path.join(self.calibration_dir,file_name)

        files_station = searchforpatron(file)

        if (len(files_station!=2)):
            print("Error: Archivos de calibración perdidos {}".format(file))

        file_name  = 'aux_' + date

        file = os.path.join(self.calibration_dir,file_name)

        files_auxiliar = searchforpatron(file)

        if (files_auxiliar !=2):
            print("Error: Archivos de calibración perdidos {}".format(file))


        #revisar
        #si le corresponde 


        station_magnetic_data = self.__getting_data(files_station[0])
        station_voltage_data  = self.__getting_data(files_station[1])
        
        auxiliar_magnetic_data = self.__getting_data(files_auxiliar[0])
        auxiliar_voltage_data  = self.__getting_data(files_auxiliar[1])
        
        H_base = 27393.3
        D_base = 5.434
        Z_base = 29444.6

        mask0 = ((vectorize(station_magnetic_data,'H')<H_base*1.2).astype(bool) )
        mask1 = (vectorize(auxiliar_magnetic_data,'H')<H_base*1.2).astype(bool)
        
        mask2 = (vectorize(station_magnetic_data,'D')<D_base*1.2).astype(bool)
        mask3 = (vectorize(auxiliar_magnetic_data,'D')<D_base*1.2).astype(bool)

        mask4 = (vectorize(station_magnetic_data,'Z')<Z_base*1.2).astype(bool)
        mask5 = (vectorize(auxiliar_magnetic_data,'Z')<Z_base*1.2).astype(bool)


        # magnetic_indexes = 
        #falta

        return 
    
    
    def __getting_verification_data (self,file_name):
        
        '''
        script -> geomagixs_make_processverification.pro
        
        '''
        exist = os.path.isfile(file_name)

        if not exist:
            print("Archivo {} no encontrado.".format(os.path.basename(file_name)))
            return None
        else:

            with open(file_name,'r') as file:
                
                file_data = numpy.array(file.read().splitlines(),dtype=object)
                number_of_lines = file_data.shape[0]

            struct = {'year':0,
                      'month':0,
                      'day':0,
                      'hour':0,
                      'minute':0,
                      'D':0,
                      'H':0,
                      'Z':0,
                      'F':0}

            keys = ['year','month','day','hour','minute','D','H','Z','F']

            data = numpy.empty(number_of_lines,dtype=object)

            data = fill(data,struct)
            #format_for_reading = '(I4,X,I2,X,I2,X,I2,X,I2,2X,F7,X,F9,X,F9,X,F9)'
            #REVISAR

            for n,line in enumerate(file_data):
                valores = re.findall(r'-?\d+\.?\d*', line)

                for key,value in zip(keys,valores):
                    data[n][key] = value 
            
            return data 
        
    def __make_processverification(self,initial,final,**kwargs):
        
        '''
        script-> geomagixs_make_processverification.pro
        '''
        station = kwargs.get("station",None)
        force_all = kwargs.get("force_all",False)
        verbose = kwargs.get("verbose",False)

        H = kwargs.get("H",None)
        D = kwargs.get("D",None)
        Z = kwargs.get("Z",None)
        T = kwargs.get("T",None)

        detrending = kwargs.get("detrending",None)

        #-------------------- initializing dates and hours ---------------------#

        initial_year = initial.year
        initial_month = initial.month
        initial_day = initial.day

        final_year = final.year
        final_month = final.month
        final_day = final.day

        number_of_days = JULDAY(final) - JULDAY(initial) + 1

        time_array = numpy.arange(number_of_days*24*60)/(number_of_days*24*60-1) * (number_of_days*24*60)

        time_array = time_array.astype(int)
        
        calibration_dir = '~/DATA/calibration'
        # PRINT, 'WARNING:'
        # PRINT, '        This program compares the processed values of AUXILIAR gms with those'
        # PRINT, '        processed values from the selected station ['+STRUPCASE(gms[system.gms].name)+'].'
        # PRINT, ''
        # PRINT, '        The purpose of this comparisson is to verify the previous inter-callibration'
        # PRINT, '        process during the given period between the selected GMS.'
        # PRINT, ''
        # PRINT, '   Serching for the files:'
        # PRINT, '      '+'aux_'+STRING(initial_year, initial_month, initial_day, final_year, final_month, final_day, $
        #                               FORMAT='(I4,I02,I02,"-",I4,I02,I02)')+'.verification.m'
        # PRINT, '      '+gms[system.gms].code+'_'+STRING(initial_year, initial_month, initial_day, final_year, final_month, final_day, $
        #                               FORMAT='(I4,I02,I02,"-",I4,I02,I02)')+'.verification.m'
        # PRINT, '   at the directory: '+calibration_dir
        

        #revisar
        #falta

        return 

                