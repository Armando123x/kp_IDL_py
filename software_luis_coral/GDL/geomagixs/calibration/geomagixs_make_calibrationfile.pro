;+
; NAME:
;       kmex_update_datafile.pro
;
;
; PURPOSE:
;
;       update the files of magnetic_data directory with the data from Mexican
;       Geomagnetic Service
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Insituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro, Morelia, Michoacan
;       piter.cr@gmail.com
;       Mexico, 22.iii.mmxvii
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       kmex_update_datafile, initial_date, final_date [, STATION=GMS_name, /QUIET, /FORCE_ALL]
;
;       Description:
;       update magnetic data
;
;
; PARAMETERS:
;       initial_date                                   : [YYYY, MM, DD] , initial date and time at which the data is read from, array of integers
;       final_date                                     : [YYYY, MM, DD] , final date and time at which the data is read from, array of integers
;
; KEYWORD PARAMETERS:
;
;       STATION                                        : a string with the geomagnetic station (GMS) name where the data is taken from
;       QUIET                                          : sets messages from the program off
;       FORCE:ALL                                      : force to generate the *.dat files despite there are not the original data-files.
;                                                        for the case of abset data, the resulting *.dat will be filled with data-gaps.
;
; DEPENDENCIES:
;       omniweb_setup                                  : initilizes the directory tree
;
; INPUT FILES:
;       GMSYYYYMMDDrmin.min     [original geomagnetic service data files]
;
; OUTPUT FILES:
;       GMS_YYYYMMDD.dat        [mangetic service data to use in SCIESMEX analysis]
;
; HISTORIA:
;               22/03/2017      First succesfully running code
;               27/04/2017      Version 1.0 ready
;
;-

;##############################################################################
;##############################################################################
;##############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
; FUNCION AUXILIAR
FUNCTION fixing_magneticfile, file_date, STATION=station, $
                                         QUIET=quiet

; PURPOSE:
;
;       complete gaps in data files from Mexican Magnetic Service
;       and removes the their headers
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Insituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro, Morelia, Michoacan
;       piter.cr@gmail.com
;       Mexico, 15.iii.mmxvii
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       DATA = kmex_getdata(initial_date, final_date [, RESOLUTION=resolution])
;
;       Description:
;       retrives magnetic data as measured by magnetic observatories from data files.
;
;
; PARAMETERS:
;       initial_date                                   : [YYYY, MM, DD, HH, mm] , initial date and time at which the data is read from, array of integers
;       final_date                                     : [YYYY, MM, DD, HH, mm] , final date and time at which the data is read from, array of integers
;
; KEYWORD PARAMETERS:
;
;       ESTACION                                       : magnetic station where the data is taken from
;       QUIET                                          : sets messages off
;
; DEPENDENCIAS:
;       omniweb_setup                                  : initilizes the directory tree
;
; ARCHIVOS ANALIZADOS:
;       teoYYYYMMDDrmin.min
;
; ARCHIVOS DE SALIDA:
;       YYYYMMDD_min.magnetic
;
; HISTORIA:
;               0.1     independent function
;               1.0     added as an auxiliary procedure in kmex_update_datafile 23/mar/2017
                



        On_error, 2
        COMPILE_OPT idl2
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        

;##############################################################################
; depuring inputs
;##############################################################################
        ;IF (resolution EQ 1 AND kmex_1min_file_number LT 1) THEN MESSAGE, 'No data files available!'


;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = file_date[0]
        initial_month  = file_date[1]
        initial_day    = file_date[2]


;##############################################################################
; reading data files
;##############################################################################
        tmp_year    = 0
        tmp_month   = 0
        tmp_day     = 0
        tmp_julday  = JULDAY(initial_month, initial_day, initial_year)
                
        CALDAT, tmp_julday, tmp_month, tmp_day, tmp_year
        
        
;        if station EQ 1 THEN BEGIN
        magnetic_data = geomagixs_get_magneticdataday([tmp_year,tmp_month,tmp_day], STATION=station)
        data_number = N_ELEMENTS(magnetic_data[*].H)


;for i=0, N_ELEMENTS(tmp_data)-1 DO print, tmp_data[i]
;        ENDIF
;##############################################################################
; extracting and mixing data
;##############################################################################
        hours_in_a_day   = 24
        minutes_in_a_day = 60*hours_in_a_day
        
        
        
        
        final_file = STRARR(minutes_in_a_day)
        
        ;help, number_of_lines
        
        j_inicio=0
        FOR i=0, minutes_in_a_day-1 DO BEGIN
                ;print, i mod 60, i/60
                
                final_file[i] = string(tmp_year, tmp_month, tmp_day, i/60, i mod 60, $
                                       99.9999,  99999.9,  99999.9, 99.9999, 99999.9, $
                                       FORMAT='(I4," ",I02," ",I02, X, I02, ":", I02, X, F07.4,X,F07.1,X,F07.1,X,F07.4,X,F07.1)')
                
                FOR j=j_inicio, data_number-1 DO BEGIN
                        IF i/60 EQ magnetic_data[j].hour AND i MOD 60 EQ magnetic_data[j].minute THEN BEGIN
                                final_file[i]=string(tmp_year, tmp_month, tmp_day, i/60, i mod 60, $
                                       magnetic_data[j].D, magnetic_data[j].H, magnetic_data[j].Z, magnetic_data[j].I, magnetic_data[j].F, $
                                       FORMAT='(I4," ",I02," ",I02, X, I02, ":", I02, X, F07.4,X,F07.1,X,F07.1,X,F07.4,X,F07.1)')
                                ;print, i, final_file[i]
                                j_inicio=j+1
                                break
                        ENDIF
                ENDFOR
        ENDFOR



        Return, final_file
END


;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
; FUNCION AUXILIAR
FUNCTION fixing_voltagefile, file_date, STATION=station, $
                                        QUIET=quiet

; PURPOSE:
;
;       complete gaps in data files from Mexican Magnetic Service
;       and removes the their headers
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Insituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro, Morelia, Michoacan
;       piter.cr@gmail.com
;       Mexico, 15.iii.mmxvii
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       DATA = kmex_getdata(initial_date, final_date [, RESOLUTION=resolution])
;
;       Description:
;       retrives magnetic data as measured by magnetic observatories from data files.
;
;
; PARAMETERS:
;       initial_date                                   : [YYYY, MM, DD, HH, mm] , initial date and time at which the data is read from, array of integers
;       final_date                                     : [YYYY, MM, DD, HH, mm] , final date and time at which the data is read from, array of integers
;
; KEYWORD PARAMETERS:
;
;       ESTACION                                       : magnetic station where the data is taken from
;       QUIET                                          : sets messages off
;
; DEPENDENCIAS:
;       omniweb_setup                                  : initilizes the directory tree
;
; ARCHIVOS ANALIZADOS:
;       teoYYYYMMDDrmin.min
;
; ARCHIVOS DE SALIDA:
;       YYYYMMDD_min.magnetic
;
; HISTORIA:
;               0.1     independent function
;               1.0     added as an auxiliary procedure in kmex_update_datafile 23/mar/2017
                



        On_error, 2
        COMPILE_OPT idl2
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        

;##############################################################################
; depuring inputs
;##############################################################################
        ;IF (resolution EQ 1 AND kmex_1min_file_number LT 1) THEN MESSAGE, 'No data files available!'


;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = file_date[0]
        initial_month  = file_date[1]
        initial_day    = file_date[2]


;##############################################################################
; reading data files
;##############################################################################
        tmp_year    = 0
        tmp_month   = 0
        tmp_day     = 0
        tmp_julday  = JULDAY(initial_month, initial_day, initial_year)
                
        CALDAT, tmp_julday, tmp_month, tmp_day, tmp_year
        
        
;        if station EQ 1 THEN BEGIN
        voltage_data = geomagixs_get_voltagedataday([tmp_year,tmp_month,tmp_day], STATION=station)
        data_number = N_ELEMENTS(voltage_data[*].H)


;for i=0, N_ELEMENTS(tmp_data)-1 DO print, tmp_data[i]
;        ENDIF
;##############################################################################
; extracting and mixing data
;##############################################################################
        hours_in_a_day   = 24
        minutes_in_a_day = 60*hours_in_a_day
        
        
        
        
        final_file = STRARR(minutes_in_a_day)
        
        ;help, number_of_lines
        
        j_inicio=0
        FOR i=0, minutes_in_a_day-1 DO BEGIN
                ;print, i mod 60, i/60
                
                final_file[i] = string(tmp_year, tmp_month, tmp_day, i/60, i mod 60, $
                                       9999.999,  9999.999,  9999.999, 9999.999, 9999.999, $
                                       FORMAT='(I4," ",I02," ",I02, X, I02, ":", I02, 2x, F09.3,X,F09.3,X,F09.3,X,F08.3,X,F08.3)')
                
                FOR j=j_inicio, data_number-1 DO BEGIN
                        IF i/60 EQ voltage_data[j].hour AND i MOD 60 EQ voltage_data[j].minute THEN BEGIN
                                final_file[i]=string(tmp_year, tmp_month, tmp_day, i/60, i mod 60, $
                                       voltage_data[j].D, voltage_data[j].H, voltage_data[j].Z, voltage_data[j].Tc, voltage_data[j].Ts, $
                                       FORMAT='(I4," ",I02," ",I02, X, I02, ":", I02, 2x, F09.3,X,F09.3,X,F09.3,X,F08.3,X,F08.3)')
                                ;print, i, final_file[i]
                                j_inicio=j+1
                                break
                        ENDIF
                ENDFOR
        ENDFOR



        Return, final_file
END




;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################

















;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;SECUENCIA PRINCIPAL


PRO geomagixs_make_calibrationfile, initial, final, STATION=station, $
                                              QUIET=quiet, $
                                              FORCE_ALL=force_all

        On_error, 2
        COMPILE_OPT idl2, HIDDEN
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        geomagixs_setup_commons, QUIET=quiet
        geomagixs_check_system, QUIET=quiet

;##############################################################################
; depuring inputs
;##############################################################################
        geomagixs_check_gms, STATION=station, QUIET=quiet

        CASE 1 OF
                N_PARAMS() EQ 0 : BEGIN
                                        initial = system.today_date
                                        final   = initial
                                  END
                N_PARAMS() EQ 1 : final = initial
                N_PARAMS() EQ 2 : geomagixs_check_dates, initial, final, STATION=station, QUIET=quiet
                ELSE            : BEGIN
                                        IF NOT keyword_set(quiet) THEN BEGIN
                                                PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                                                PRINT, FORMAT="('                impossible to proceed with an ambiguoss range of dates.')"
                                        ENDIF
                                        error.value[2] += 1
                                        error.log      += 'Ambiguous range of dates, it is required only two input dates to define a time period. '
                                        RETURN
                                  END
        ENDCASE


;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = initial[0]
        initial_month  = initial[1]
        initial_day    = initial[2]

        final_year     = final[0]
        final_month    = final[1]
        final_day      = final[2]




;##############################################################################
; reading data files
;##############################################################################
        file_number         = (JULDAY(final_month, final_day, final_year) - JULDAY(initial_month, initial_day, initial_year))+1
        hours_in_a_day   = 24
        minutes_in_a_day = 60*hours_in_a_day
        processed_data  = strarr(file_number*minutes_in_a_day)
        string_date         = strarr(file_number)
        ;exist_file     = intarr(file_number)
        
        julday_tmp = JULDAY(initial_month, initial_day, initial_year)
        FOR i = 0ll, file_number-1 DO BEGIN
                CALDAT, julday_tmp+i, tmp_month,tmp_day,tmp_year
                ;READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                ;print, tmp_year, tmp_month, tmp_day
                tmp_string=fixing_voltagefile([tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station)
                processed_data[minutes_in_a_day*i:minutes_in_a_day*(i+1)-1] = tmp_string[*]
                ;cleaning_datafile, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station
        ENDFOR

        file_name = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, final_year, final_month, final_day, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')+'.calibration.v'

        calibration_dir = '~/DATA/calibration'
        
        
        
        OPENW, lun, calibration_dir+'/'+file_name, /GET_LUN, ERROR=err
                IF err EQ 0 THEN BEGIN
                        FOR i=0ll, file_number*minutes_in_a_day-1 DO PRINTF, lun, processed_data[i]
                ENDIF ELSE MESSAGE, 'Error while writing data file!
                
                                     
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Calibration-file '+file_name+' ready for computing!'
        ENDIF

        processed_data  = strarr(file_number*minutes_in_a_day)
        FOR i = 0ll, file_number-1 DO BEGIN
                CALDAT, julday_tmp+i, tmp_month,tmp_day,tmp_year
                ;READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                ;print, tmp_year, tmp_month, tmp_day
                tmp_string=fixing_magneticfile([tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station)
                processed_data[minutes_in_a_day*i:minutes_in_a_day*(i+1)-1] = tmp_string[*]
                ;cleaning_datafile, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station
        ENDFOR

        file_name = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, final_year, final_month, final_day, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')+'.calibration.m'

        calibration_dir = '~/DATA/calibration'
        
        
        
        OPENW, lun, calibration_dir+'/'+file_name, /GET_LUN, ERROR=err
                IF err EQ 0 THEN BEGIN
                        FOR i=0ll, file_number*minutes_in_a_day-1 DO PRINTF, lun, processed_data[i]
                ENDIF ELSE MESSAGE, 'Error while writing data file!
                
                                     
        CLOSE, lun
        FREE_LUN, lun



        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Calibration-file '+file_name+' ready for computing!'
        ENDIF

RETURN


END




