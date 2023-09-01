
import deepcopy
from utils import *
from dateutil.relativedelta import relativedelta

class calibration(object):
    
    def __init__(self,**kwargs):

        self.calibration_dir  = None 


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


    def __get_deltab(self,year,**kwargs):
        '''
        file -> kmex_get_kpdata.pro
        
        '''

        station = kwargs.get("station",None)
        verbose = kwargs.get("verbose",False)
        real_time = kwargs.get("real_time",False)


        # kmex_check_GMS, STATION=station, QUIET=quiet

        # IF kmex_GMS GT 99 THEN BEGIN
        #                         MESSAGE, 'Read manuals for help.'
        #                         RETURN, 0
        # ENDIF


        if (year<2000):

            raise ValueError("Año debe ser mayor o igual a 2000.")}
        
        number_of_days = JULDAY(datetime(year,12,31)) - JULDAY(datetime(year,1,1)) + 1

        data_number = number_of_days * 8


        result = {

            'number_of_data':0,
            'initial_date': numpy.empty(3,dtype=int),
            'initial_time': numpy.empty(2,dtype=int),
            'final_date':   numpy.empty(3,dtype=int),
            'final_time':   numpy.empty(2,dtype=int),
            'description': '',
            'help':'',
            'year':numpy.empty(data_number,dtype=int),
            'month':numpy.empty(data_number,dtype=int),
            'day':numpy.empty(data_number,dtype=int),
            'hour':numpy.empty(data_number,dtype=int),
            'doy': numpy.empty(data_number,dtype=float),
            'Delta_D': numpy.empty(data_number,dtype=float), 
            'sigma_D': numpy.empty(data_number,dtype=float), 
            'Delta_H': numpy.empty(data_number,dtype=float), 
            'sigma_H': numpy.empty(data_number,dtype=float), 
            'Delta_Z': numpy.empty(data_number,dtype=float), 
            'sigma_Z': numpy.empty(data_number,dtype=float), 
            'Delta_F': numpy.empty(data_number,dtype=float), 
            'sigma_F': numpy.empty(data_number,dtype=float), 
            'Delta_N': numpy.empty(data_number,dtype=float), 
            'sigma_N': numpy.empty(data_number,dtype=float)
        }

        result['description'] = "Valores de Delta B son calculados de datos proporcionados por Geomagnetic Services en UNAM.\
                                "
    
        result['help']= ""

        result['number_of_data'] = data_number
        result['initial_date'] = datetime(year,1,1)
        result['initial_time'] = [0,0]
        result['final_date'] = datetime(year,12,31)
        result['final_time'] = [21,0]

        for n,_ in enumerate(result['year']):
            result['year'][n] = year
        
        tmp_month = 0
        tmp_day = 0 

        for i in range(number_of_days):

            date = CALDAT(JULDAY(datetime(year,1,1)+relativedelta(days=-1))+i+1)

            tmp_year = date.year
            tmp_month = date.month
            tmp_day = date.day

            tmp_data =  self.__getting_deltab(datetime(year,tmp_month,tmp_day),**kwargs)

            result['month'][i*8:i*8+8] = tmp_month
            result['day'][i*8:(i+1)*8] = tmp_day
            result['hour'][i*8:(i+1)*8] = tmp_data['hour']
            result['doy']               = float(i) + tmp_data['hour']/24

            result['Delta_D'][i*8:(i+1)*8] = tmp_data['delta_D']
            result['Delta_H'][i*8:(i+1)*8] = tmp_data['delta_H']
            result['Delta_Z'][i*8:(i+1)*8] = tmp_data['delta_Z']
            result['Delta_F'][i*8:(i+1)*8] = tmp_data['delta_F']
            result['Delta_N'][i*8:(i+1)*8] = tmp_data['delta_N']

            result['sigma_D'][i*8:(i+1)*8] = tmp_data['sigma_D']
            result['sigma_H'][i*8:(i+1)*8] = tmp_data['sigma_H']
            result['sigma_Z'][i*8:(i+1)*8] = tmp_data['sigma_Z']
            result['sigma_F'][i*8:(i+1)*8] = tmp_data['sigma_F']
            result['sigma_N'][i*8:(i+1)*8] = tmp_data['sigma_N']


        return result 
    
    def __get_kpdata(self,initial,**kwargs):

        verbose = kwargs.get("verbose",False)

        initial_year = initial.year
        initial_hour = initial.hour
        initial_minute = initial.minute


        number_of_days = 365


        file_name = '{4d}'.format(initial_year)
        
        fpath = os.path.join(self.calibration_dir,'Kp_Ap',file_name)

        exists = os.path.isfile(fpath)

        if exists:

            with open(fpath,'r') as file:

                kp_data = numpy.array(file.read().splitlines(),dtype=object)

                number_of_lines = kp_data.shape[0]

            keys = ['year','month','day','k_0','k_3','k_6','k_9','k_12','k_15','k_18','k_21','k_T',
                    'a_0','a_3','a_6','a_9','a_12','a_15','a_18','a_21','a_T']
        
            struct = dict.fromkeys(keys,0)

            tmp_data = numpy.empty(number_of_lines,dtype=object)

            tmp_data = fill(tmp_data,struct)

            for n,line in enumerate(kp_data):
                valores = re.findall(r'-?\d+\.?\d*', line)
                # Convertir los valores a enteros o números de punto flotante según corresponda
                valores = [int(v) if v.isdigit() else float(v) for v in valores]

                if len(valores)>0:

                    for key,valor in zip(keys,valores):

                        tmp_data[n][key] = valor
            

            #--------------------------------------------

            number_of_days = JULDAY(initial_year,12,31) - JULDAY(initial_year,1,1) + 1

            data_number = number_of_days * 8 


            result ={
                'number_of_data':0,
                'initial_date':None,
                'initial_time':None,
                'final_date': None,
                'final_time':None,

                'description': '',
                'help':'',
                'year':numpy.empty(data_number,dtype=int),
                'month':numpy.empty(data_number,dtype=int),
                'day':numpy.empty(data_number,dtype=int),
                'hour':numpy.empty(data_number,dtype=int),
                'doy':numpy.empty(data_number,dtype=float),
                'Kp':numpy.empty(data_number,dtype=int),
                'Kp_dayly':numpy.empty(data_number,dtype=int),
                'Ap':numpy.empty(data_number,dtype=int),
                'Ap_dayly':numpy.empty(data_number,dtype=int),
                
                
                            
                                        }


            result['number_of_data'] = data_number
            result['initial_date'] = datetime(initial_year,1,1)
            result['initial_time'] = datetime.time(0,0)
            result['final_date']  = datetime(initial_year,12,31)
            result['final_time'] = datetime.time(21,0)


            for n,_ in enumerate(result['year']):
                result['year'][n]  = initial_year
            
            number_of_lines_8 = number_of_lines * 8


            for i in range(number_of_days):

                date = CALDAT(JULDAY(datetime(initial_year,1,1)+relativedelta(days=+i)))

                tmp_year = date.year
                tmp_month = date.month
                tmp_day = date.day

                result['hour'][i*8:(i+1)*8] = 3*numpy.arange(8)

                #faltaaaa
                #aqui me quede