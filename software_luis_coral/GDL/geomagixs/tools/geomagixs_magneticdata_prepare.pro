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
;       kmex_update_datafile, initial_date, final_date [, STATION=GMS_name, OFFSET=offset /QUIET, /FORCE_ALL]
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
;       OFFSET                                         : an 3-float array with offsets for D, H, and Z
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
FUNCTION getting_magneticdata_forcleaning, initial, STATION=station, $
                                                    QUIET=quiet
        On_error, 2
        COMPILE_OPT idl2, hidden
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        

;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = initial[0]
        initial_month  = initial[1]
        initial_day    = initial[2]


        IF N_ELEMENTS(initial) EQ 5 THEN BEGIN
                initial_hour   = initial[3]
                initial_minute = initial[4]
        ENDIF ELSE BEGIN
                initial_hour   = 0
                initial_minute = 0
        ENDELSE



;##############################################################################
; reading data files
;##############################################################################
                ;file_name = station_code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.dat'
                file_name = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.dat'

                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                IF opened_files NE N_ELEMENTS(file_name) THEN MESSAGE, 'Error finding data files or directories!'
        
                number_of_lines = FILE_LINES(file)
                magnetic_data   = STRARR(number_of_lines)

;print, number_of_lines

                ;tmp_data = STRARR(number_of_lines)

                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name
                        READF, lun, magnetic_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun

;##############################################################################
; extracting data
;##############################################################################
        DataStruct  =  { year : 0, month : 0, day : 0, $
                         hour : 0, minute : 0, doy : 0, $
                         D : 0., H : 0., Z : 0., F : 0. }
                         
        ;minutes_per_day = 24*60
        ;initial_minutes = initial_hour*60+initial_minute
        ;final_minutes   = final_hour*60+final_minute 
        ;data_number     = fix(total_of_data-initial_minutes-minutes_per_day+final_minutes)

        resulting_data = REPLICATE(DataStruct, number_of_lines)

        READS, magnetic_data[0:number_of_lines-1], resulting_data, $
               FORMAT='(I4,X,I2,X,I2,X,I2,X,I2,8X,I3,6X,F7,X,F9,X,F9,X,F9)'
        tempvar = SIZE(TEMPORARY(magnetic_data)) ; liberar memoria de la info no usada




        ;tempvar = SIZE(TEMPORARY(resulting_data)) ; liberar memoria de la info no usada
        return, resulting_data


END



;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
; FUNCION AUXILIAR
PRO fixing_datafile, file_date, STATION=station, $
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
        file_name = ''
        tmp_year    = 0
        tmp_month   = 0
        tmp_day     = 0
        tmp_julday  = JULDAY(initial_month, initial_day, initial_year)
                
        CALDAT, tmp_julday, tmp_month, tmp_day, tmp_year
        
        
;        if station EQ 1 THEN BEGIN
                cabecera    = 18LL
                ;file_name = station_code+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'rmin.min'
        
                file_name   = gms[system.gms].code+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'rK.min'

                file_exists = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+file_name)
                IF not file_exists THEN BEGIN
                        file_name = gms[system.gms].code+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'rmin.min'
                        file_exists = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+file_name)
                ENDIF
                

                ;file_exists = FILE_TEST(kmex_magnetic_dir+station+'/1_min/'+file_name)
                

                IF file_exists THEN BEGIN
                        IF not keyword_set(quiet) THEN  print, '        Extracting data from: '+file_name
                        file = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                                IF opened_files EQ 0 AND not keyword_set(quiet) THEN MESSAGE, 'Error finding data files or directories!'
        
                        number_of_lines =FILE_LINES(file)
                ;temporal_data   = STRARR(total(number_of_lines))

;print, number_of_lines
                        tmp_data = STRARR(number_of_lines)

                        OPENR, lun, file, /GET_LUN, ERROR=err
                                IF err NE 0 THEN MESSAGE, 'Error opening '+file_name
                                READF, lun, tmp_data, FORMAT='(A)'
                        CLOSE, lun
                        FREE_LUN, lun
                ENDIF ELSE BEGIN
                        IF not keyword_set(quiet) THEN PRINT, '        Data file not found!'
                ENDELSE



;for i=0, N_ELEMENTS(tmp_data)-1 DO print, tmp_data[i]
;        ENDIF
;##############################################################################
; extracting and mixing data
;##############################################################################
        minutes_in_a_day = 60*24
        hours_in_a_day   = 24
        
        
        
        
IF STATION EQ 'planetary' THEN BEGIN
        final_file = STRARR(hours_in_a_day)
        
        j_inicio=cabecera-1
        
        FOR i=0, hours_in_a_day-1 DO BEGIN
                final_file[i] = string(tmp_year, tmp_month, tmp_day,i, 0, JULDAY(initial_month, initial_day, initial_year)-JULDAY(1, 0, initial_year), $
                                       999, 999, 999, 999, 9999, 9999, $
                                       FORMAT='(I4,"-",I02,"-",I02, X, I02, ":", I02, ":00.000 ", I03, 3X, ' + $
                                               'I4,5x,I4,2x,I5,4x,I5,3X,I5,5x,I5)')
                IF file_exists THEN $
                        FOR j=j_inicio, number_of_lines[0]-1 DO BEGIN
                                IF STRMID(tmp_data[j], 11,5) EQ STRMID(final_file[i], 11,5) THEN BEGIN
                                        string_tmp=tmp_data[j]
                                        final_file[i]=string_tmp
                                        ;print, i, final_file[i]
                                        j_inicio=j+1
                                        break
                                ENDIF
                        ENDFOR

        ENDFOR
ENDIF ELSE BEGIN
        final_file = STRARR(minutes_in_a_day)
        
        ;help, number_of_lines
        
        j_inicio=cabecera-1
        FOR i=0ll, minutes_in_a_day-1 DO BEGIN
                ;print, i mod 60, i/60
                final_file[i] = string(tmp_year, tmp_month, tmp_day, i/60, i mod 60, JULDAY(initial_month, initial_day, initial_year)-JULDAY(1, 0, initial_year), $
                                       9999.00, 999999.00, 999999.00, 999999.00, $
                                       FORMAT='(I4,"-",I02,"-",I02, X, I02, ":", I02, ":00.000 ", I03, 6X, F7.2, X, F9.2, X, F9.2, X, F9.2 )')
                IF file_exists THEN $
                        FOR j=j_inicio, number_of_lines[0]-1 DO BEGIN
                                IF STRMID(tmp_data[j], 11,5) EQ STRMID(final_file[i], 11,5) THEN BEGIN
                                        string_tmp=tmp_data[j]
                                        final_file[i]=string_tmp
                                        j_inicio=j+1
                                        ;print, i, j_inicio, (j_inicio-i), ' -- ', final_file[i]
                                        break
                                ENDIF
                        ENDFOR
        ENDFOR
ENDELSE

;##############################################################################
; creating data file
;##############################################################################
        ;output_datafile = station_code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_datafile = gms[system.gms].code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_path     = system.processed_dir+gms[system.gms].name+'/'
        
        exist_dir = FILE_TEST(output_path, /DIRECTORY)
        
        IF not(exist_dir) THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('Critical Error: Missing system directory ', A,'. ')", output_path
                        PRINT, FORMAT="('                Check out the directory tree.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'System directory '+output_path+' not found. Impossible to continue. '
                RETURN
        ENDIF 
        ;print, output_path+output_datafile
        OPENW, lun, output_path+output_datafile, /GET_LUN, ERROR=err
                IF err EQ 0 THEN BEGIN
                        IF STATION EQ 'planetary' THEN FOR i=0ll, hours_in_a_day-1 DO PRINTF, lun, final_file[i] $
                                ELSE FOR i=0ll, minutes_in_a_day-1 DO PRINTF, lun, final_file[i]
                ENDIF ELSE MESSAGE, 'Error while writing data file!
                
                                     
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN BEGIN
                print, '        - Saving: '+output_datafile
        ENDIF


return
END




;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
; funcion auxiliar
PRO cleaning_datafile, initial, STATION=station, $
                                QUIET=quiet, $
                                REAL_TIME=real_time, $
                                OFFSET=offset

        On_error, 2
        COMPILE_OPT idl2, hidden
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        

;##############################################################################
; data for criteria
;##############################################################################
        sigma_criteria    = 4.  ; number of standard deviations a data needs to surprise
                                ; to be taken as an invalid data
        number_of_minutes = 10  ; half of the minutes used to calculate the median


;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = initial[0]
        initial_month  = initial[1]
        initial_day    = initial[2]


;##############################################################################
; reading data files
;##############################################################################
        ;file_number = 2*kmex_days_for_median+1
        data_file_name = '';strarr(file_number)
        string_date    = '';strarr(file_number)
        ;tmp_julday  = JULDAY(initial_month, initial_day, initial_year)-(kmex_days_for_median)
        ;print, JULDAY(initial_month, initial_day, initial_year), (kmex_days_for_median+1)
        minutes_per_day = 24*60


        D_values = FLTARR(minutes_per_day)+9999.00
        H_values = FLTARR(minutes_per_day)+999999.00
        Z_values = FLTARR(minutes_per_day)+999999.00
        F_values = FLTARR(minutes_per_day)+999999.00


        ;CALDAT, tmp_julday, tmp_month, tmp_day, tmp_year
        string_date    = string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')
                ;data_file_name[i] = station_code+'_'+string_date[i]+'.dat'
        data_file_name = gms[system.gms].code+'_'+string_date+'.dat'
                ;print, i+1, '  ', string_date[i], '  ', data_file_name[i]
        ;ENDFOR

        exist_data_file = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+data_file_name)
        ;exist_data_file = FILE_TEST(kmex_magnetic_dir+station+'/1_min/'+data_file_name)
        
        IF STATION EQ 'planetary' THEN BEGIN
                IF exist_data_file THEN BEGIN
                        IF not keyword_set(quiet) THEN  print, '        Extracting data from: '+ data_file_name
                        file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+data_file_name, COUNT=opened_files)
                        IF opened_files EQ 0 THEN BEGIN
                                IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                                        PRINT, FORMAT="('Critical Error: Impossible to read input file ',A,'.')", data_file_name
                                        PRINT, FORMAT="('                missing directories or permissions conflict.')"
                                ENDIF
                                error.value[1] += 1
                                error.log      += 'Impossible to read input file '+data_file_name+'. Impossible to preceed. '
                                RETURN
                        ENDIF
                        
                        number_of_lines =FILE_LINES(file[0])

                        tmp_data = STRARR(number_of_lines)

                        OPENR, lun, file, /GET_LUN, ERROR=err
                                IF err NE 0 THEN MESSAGE, 'Error opening '+file_name
                                READF, lun, tmp_data, FORMAT='(A)'
                        CLOSE, lun
                        FREE_LUN, lun

                        output_datafile = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.clean.dat'
                        output_path     = system.processed_dir+gms[system.gms].name+'/'
                        
                        exist_dir = FILE_TEST(output_path, /DIRECTORY)
                        
                        IF not(exist_dir) THEN BEGIN
                                IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                                        PRINT, FORMAT="('Critical Error: Impossible to read system directory ',A,'.')", output_path
                                        PRINT, FORMAT="('                missing directory or permissions conflict.')"
                                ENDIF
                                error.value[1] += 1
                                error.log      += 'Impossible to read system directory '+output_path+'. Impossible to preceed. '
                                RETURN
                        ENDIF 
                        ;print, output_path+output_datafile
                        OPENW, lun, output_path+output_datafile, /GET_LUN, ERROR=err
                                IF err EQ 0 THEN $
                                        FOR i=0, number_of_lines-1 DO PRINTF, lun, tmp_data[i] $
                                ELSE MESSAGE, 'Error while writing data file!
                        CLOSE, lun
                        FREE_LUN, lun
                
                        IF not keyword_set(quiet) THEN BEGIN
                                print, '        - Saving: '+output_datafile
                        ENDIF
                        
                        RETURN
                ENDIF ELSE BEGIN
                        IF not keyword_set(quiet) THEN PRINT, '        Data file '+ data_file_name +' not found!'
                        RETURN
                ENDELSE
        ENDIF
        
        
        IF exist_data_file THEN tmp_data = getting_magneticdata_forcleaning(initial,STATION=station, QUIET=quiet) $
                ELSE BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Inconsistency Warning: missed data file, the requested conditions may compromise the computed results.')"
                                PRINT, FORMAT="('                       Data file ', A,' not found. Proceeding with predefined (gaps) values.')", data_file_name
                        ENDIF
                        error.value[4] += 1
                        error.log      += 'Data file '+data_file_name+' not found. Proceeding with predefined (gaps) values. '

                ENDELSE
        
        ;data_to_analize = REPLICATE(magnetic_data, 2*kmex_days_for_median)
        
        ;for i=0, file_number-1 DO print, i+1, '  ', data_file_name[i], '  ', exist_data_file[i]

        IF exist_data_file EQ 1 THEN BEGIN
                D_values[*] = tmp_data[*].D
                H_values[*] = tmp_data[*].H
                Z_values[*] = tmp_data[*].Z
                F_values[*] = tmp_data[*].F
        ENDIF

        no_gaps        = where(H_values LT 999990.00, no_gaps_count)
        number_of_gaps = N_ELEMENTS(where(H_values GE 999990.00, gaps_count))
        ;print, gaps_count

	IF no_gaps_count GT 0 AND N_ELEMENTS(offset) EQ 3 THEN BEGIN
        	IF offset[0] NE 0 THEN D_values[no_gaps] += offset[0]
        	IF offset[1] NE 0 THEN H_values[no_gaps] += offset[1]
	        IF offset[2] NE 0 THEN Z_values[no_gaps] += offset[2]
        	IF offset[1] NE 0 OR offset[2] NE 0 THEN F_values[no_gaps] = sqrt(( H_values[no_gaps] )^2+( Z_values[no_gaps] )^2)
	ENDIF

;print, no_gaps
;print, number_of_gaps, where(H_values GE 999990.00)

        ;#######################################################################
        ; COMMENT :
        ; The forthcoming analysis focuses solely on H component and magnitude [F]
        ; because: 1) H is the most important component for computing of geomagnetic
        ; indexes; and 2) Based upon experience, H and F are the most affected
        ; values by the "spike" artiffact.

        ;number_of_minutes = (N_ELEMENTS(no_gaps)/4 GT number_of_minutes) ? number_of_minutes : N_ELEMENTS(no_gaps)/4
        H_median_value    = 0   ; variable to store the calculated median
        H_sigma_value     = 0   ; variable to store the calculated standard deviation
        F_median_value    = 0   ; variable to store the calculated median
        F_sigma_value     = 0   ; variable to store the calculated standard deviation
        
        elements_of_no_gaps = N_ELEMENTS(no_gaps)
        boolean_flag        = INTARR(elements_of_no_gaps)+1

        IF exist_data_file EQ 1 AND number_of_gaps NE minutes_per_day THEN $
        FOR i=0, elements_of_no_gaps-1 DO BEGIN
                IF i LT number_of_minutes AND i+number_of_minutes LE elements_of_no_gaps-1 THEN BEGIN
                        IF i NE 0 THEN BEGIN
                                H_median_value = median( [H_values[no_gaps[0:i-1]], H_values[no_gaps[i+1:i+1+number_of_minutes-1]]] )
                                H_sigma_value  = STDDEV( [H_values[no_gaps[0:i-1]], H_values[no_gaps[i+1:i+1+number_of_minutes-1]]]-H_median_value )

                                F_median_value = median( [F_values[no_gaps[0:i-1]], F_values[no_gaps[i+1:i+1+number_of_minutes-1]]] )
                                F_sigma_value  = STDDEV( [F_values[no_gaps[0:i-1]], F_values[no_gaps[i+1:i+1+number_of_minutes-1]]]-F_median_value )
                        ENDIF ELSE BEGIN
                                H_median_value = median( H_values[no_gaps[i+1:i+1+number_of_minutes]] )
                                H_sigma_value  = STDDEV( H_values[no_gaps[i+1:i+1+number_of_minutes]]-H_median_value )

                                F_median_value = median( F_values[no_gaps[i+1:i+1+number_of_minutes]] )
                                F_sigma_value  = STDDEV( F_values[no_gaps[i+1:i+1+number_of_minutes]]-F_median_value )
                        ENDELSE
                ENDIF

                IF i LT number_of_minutes AND i+number_of_minutes GT elements_of_no_gaps-1 THEN BEGIN
                        IF i NE 0 AND i NE elements_of_no_gaps-1 THEN BEGIN
                                H_median_value = median( [H_values[no_gaps[0:i-1]], H_values[no_gaps[i+1:elements_of_no_gaps-1]]] )
                                H_sigma_value  = STDDEV( [H_values[no_gaps[0:i-1]], H_values[no_gaps[i+1:elements_of_no_gaps-1]]]-H_median_value )

                                F_median_value = median( [F_values[no_gaps[0:i-1]], F_values[no_gaps[i+1:elements_of_no_gaps-1]]] )
                                F_sigma_value  = STDDEV( [F_values[no_gaps[0:i-1]], F_values[no_gaps[i+1:elements_of_no_gaps-1]]]-F_median_value )
                        ENDIF
                        IF i EQ 0 AND i NE elements_of_no_gaps-1 THEN BEGIN
                                H_median_value = median( H_values[no_gaps[i+1:elements_of_no_gaps-1]] )
                                H_sigma_value  = STDDEV( H_values[no_gaps[i+1:elements_of_no_gaps-1]]-H_median_value )

                                F_median_value = median( F_values[no_gaps[i+1:elements_of_no_gaps-1]] )
                                F_sigma_value  = STDDEV( F_values[no_gaps[i+1:elements_of_no_gaps-1]]-F_median_value )
                        ENDIF
                        IF i NE 0 AND i EQ elements_of_no_gaps-1 THEN BEGIN
                                H_median_value = median( H_values[no_gaps[0:elements_of_no_gaps-2]] )
                                H_sigma_value  = STDDEV( H_values[no_gaps[0:elements_of_no_gaps-2]]-H_median_value )

                                F_median_value = median( F_values[no_gaps[0:elements_of_no_gaps-2]] )
                                F_sigma_value  = STDDEV( F_values[no_gaps[0:elements_of_no_gaps-2]]-F_median_value )
                        ENDIF
                        ;IF i NE 0 AND i EQ N_ELEMENTS(no_gaps)-1 THEN BEGIN
                        ;        this is equivalent to N_ELEMENTS(no_gaps)-1 EQ 0
                        ;        what means that no_gaps is an empty array
                        ;        for such a case, the for loop would not run
                        ;ENDIF
                ENDIF

                IF i GE number_of_minutes AND i+number_of_minutes LE elements_of_no_gaps-1 THEN BEGIN
                        H_median_value = median( [H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:i+number_of_minutes]]] )
                        H_sigma_value  = STDDEV( [H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:i+number_of_minutes]]]-H_median_value )

                        F_median_value = median( [F_values[no_gaps[i-number_of_minutes:i-1]], F_values[no_gaps[i+1:i+number_of_minutes]]] )
                        F_sigma_value  = STDDEV( [F_values[no_gaps[i-number_of_minutes:i-1]], F_values[no_gaps[i+1:i+number_of_minutes]]]-F_median_value )
                        ;IF no_gaps[i] LT 1065 AND no_gaps[i] GT 1060 THEN BEGIN
                        ;        print, no_gaps[i]+1, H_median_value, H_sigma_value , F_median_value, F_sigma_value
                        ;        print, '      ', [no_gaps[i-number_of_minutes:i-1],no_gaps[i+1:i+number_of_minutes]]
                        ;        print, [H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:i+number_of_minutes]]]
                        ;ENDIF
                ENDIF


                IF i GE number_of_minutes AND i+number_of_minutes GT elements_of_no_gaps-1 THEN BEGIN
                        IF i EQ elements_of_no_gaps-1 THEN BEGIN
                                H_median_value = median( H_values[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]] )
                                H_sigma_value  = STDDEV( H_values[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]]-H_median_value )
                                
                                F_median_value = median( F_values[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]] )
                                F_sigma_value  = STDDEV( F_values[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]]-F_median_value )
                        ENDIF ELSE BEGIN
                                
                                H_median_value = median( [H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:elements_of_no_gaps-1]]] )
                                H_sigma_value  = STDDEV( [H_values[no_gaps[i-number_of_minutes:i-1]], H_values[no_gaps[i+1:elements_of_no_gaps-1]]]-H_median_value )
                                
                                F_median_value = median( [F_values[no_gaps[i-number_of_minutes:i-1]], F_values[no_gaps[i+1:elements_of_no_gaps-1]]] )
                                F_sigma_value  = STDDEV( [F_values[no_gaps[i-number_of_minutes:i-1]], F_values[no_gaps[i+1:elements_of_no_gaps-1]]]-F_median_value )
                        ENDELSE
                ENDIF



                IF (ABS(H_values[no_gaps[i]]-H_median_value) GT sigma_criteria*H_sigma_value) OR (ABS(F_values[no_gaps[i]]-F_median_value) GT sigma_criteria*F_sigma_value) THEN BEGIN
                        boolean_flag[i] = 0
;print, i, boolean_flag[i], ABS(H_values[no_gaps[i]]-H_median_value), H_sigma_value, ABS(F_values[no_gaps[i]]-F_median_value), F_sigma_value
                ENDIF

                H_median_value    = 0   ; variable to store the calculated median
                H_sigma_value     = 0   ; variable to store the calculated standard deviation
                F_median_value    = 0   ; variable to store the calculated median
                F_sigma_value     = 0   ; variable to store the calculated standard deviation

        ENDFOR

        IF elements_of_no_gaps GT 1 THEN BEGIN
                D_values[no_gaps] = (boolean_flag EQ 1)*(D_values[no_gaps]) + (boolean_flag NE 1)*9999.00
                H_values[no_gaps] = (boolean_flag EQ 1)*(H_values[no_gaps]) + (boolean_flag NE 1)*999999.00
                Z_values[no_gaps] = (boolean_flag EQ 1)*(Z_values[no_gaps]) + (boolean_flag NE 1)*999999.00
                F_values[no_gaps] = (boolean_flag EQ 1)*(F_values[no_gaps]) + (boolean_flag NE 1)*999999.00
        ENDIF

;print, where(H_values GE 999990.00)

;###############################################################################
;###############################################################################
;###############################################################################
        ;IF no_gaps[0] GE 0 THEN $
        cleaning_count=0
        IF no_gaps_count GT 0 THEN $
                ;cleaning_indexes = WHERE( ABS(H_values[*]-median(H_values[no_gaps]))/median(H_values[no_gaps]) GE 0.03, cleaning_count) $
                cleaning_indexes = WHERE( ABS(H_values[no_gaps]-median(H_values[no_gaps]))/median(H_values[no_gaps]) GE 0.005, cleaning_count) $
                ELSE cleaning_indexes = -1
;print, cleaning_indexes
;###############################################################################
;###############################################################################
;###############################################################################
        ;print, N_ELEMENTS(cleaning_indexes)
        
        ;FOR i=0,  N_ELEMENTS(H_values[*])-1 DO print, i, ABS(H_values[i]-median(H_values[no_gaps]))/median(H_values[no_gaps]), STDDEV(H_values[no_gaps]), H_values[i]
;print,  cleaning_indexes[0]       
        ;IF cleaning_indexes[0] GE 0 THEN BEGIN
        IF cleaning_count GT 0 THEN BEGIN
                        D_values[cleaning_indexes] = 9999.0
                        H_values[cleaning_indexes] = 999999.0
                        Z_values[cleaning_indexes] = 999999.00
                        F_values[cleaning_indexes] = 999999.00
                        ;print, 'hola'
        ENDIF
        ;FOR i=0,  N_ELEMENTS(H_values[*])-1 DO print, i, H_values[i], ABS(H_values[i]-median(H_values[no_gaps]))/median(H_values[no_gaps]), STDDEV(H_values[no_gaps])

        


        new_no_gaps = where(H_values[*] LT 999990.00, new_no_gaps_count)
;print,    where(H_values[*] GE 999990.00)     
        ;FOR i=0,  N_ELEMENTS(H_values[*])-1 DO print, i, ABS(H_values[i]-median(H_values[new_no_gaps]))/median(H_values[new_no_gaps]), STDDEV(H_values[new_no_gaps]), H_values[i]
        
        
        ;print, N_ELEMENTS(new_no_gaps), N_ELEMENTS(no_gaps)



;##############################################################################
; COMPLETING MISSING ¡¡¡MINUTES!!! BY INTERPOLATE VALUES
;
; this process must be taken with must of cares. the aim of this section is to
; complete missing values that "CLEARLY" can be estimated by the rest of data.
; to ensure this, we make a fractal-line inspecction of file.
;##############################################################################

        bad_minutes_indexes  = where(H_values[*] GE 999990.00, bad_minutes_number)
        good_minutes_indexes = where(H_values[*] LT 999990.00, good_minutes_number)
        total_minutes       = N_ELEMENTS(H_values[*])
        
        criteria_up   = 0.85 ; [2hr 24min left]
        criteria_0    = 0.025;0.10
        ;criteria_1    = 2.*criteria_0
        fixed_minutes = 0

        IF (good_minutes_number GT criteria_up*total_minutes) AND $
           (good_minutes_number LT total_minutes) AND $
           NOT keyword_set(real_time) THEN BEGIN

                tmp_D = D_values[*]
                tmp_H = H_values[*]
                tmp_Z = Z_values[*]
                tmp_F = F_values[*]
                tmp_t = tmp_data[*].hour*60+tmp_data[*].minute

                
;###############24 hours window (1 process, 2.5%-36min [36min])
;###############12 hours window (2 process, 5.0%-36min [1hr 12min])
;###############8 hours window (3 process, 7.5%-36min [1hr 42min])
;###############6 hours window (4 process, 10.0%-36min [2hrs 24min])
;###############4 hours window (6 process, 15.0%-36min [3hrs 24min])
                process_number = [1,2,3,4,6,8]
                j=0

                REPEAT BEGIN
                ;FOR j = 0, N_ELEMENTS(process_number)-1 DO BEGIN
                        n_processes          = process_number[j]
                        delta_time           = minutes_per_day/n_processes
                        i=0

                        REPEAT BEGIN
                        ;FOR i = 0, n_processes-1 DO BEGIN
                                low_limit            = i*delta_time
                                up_limit             = (i+1)*delta_time-1
                                bad_minutes_indexes  = where(H_values[low_limit:up_limit] GE 999990.00, bad_minutes_number)
                                good_minutes_indexes = where(H_values[low_limit:up_limit] LT 999990.00, good_minutes_number)
                                ;print, i+1, n_processes, '----', bad_minutes_number, n_processes*criteria_0*good_minutes_number, good_minutes_number
                                IF bad_minutes_number GT 0 AND bad_minutes_number LT n_processes*criteria_0*good_minutes_number THEN BEGIN
                                        ;print, i+1, n_processes, FORMAT="('        - Process: ', I0,'/',I0)" 
                                        tmp_H = INTERPOL( H_values[low_limit+good_minutes_indexes], tmp_t[low_limit+good_minutes_indexes], tmp_t[*], /SPLINE )
                                        H_values [low_limit+bad_minutes_indexes] = tmp_H [low_limit+bad_minutes_indexes]
                                        tmp_D = INTERPOL( D_values[low_limit+good_minutes_indexes], tmp_t[low_limit+good_minutes_indexes], tmp_t[*], /SPLINE )
                                        D_values [low_limit+bad_minutes_indexes] = tmp_D [low_limit+bad_minutes_indexes]
                                        tmp_Z = INTERPOL( Z_values[low_limit+good_minutes_indexes], tmp_t[low_limit+good_minutes_indexes], tmp_t[*], /SPLINE )
                                        Z_values [low_limit+bad_minutes_indexes] = tmp_Z [low_limit+bad_minutes_indexes]
                                        tmp_F = INTERPOL( F_values[low_limit+good_minutes_indexes], tmp_t[low_limit+good_minutes_indexes], tmp_t[*], /SPLINE )
                                        F_values [low_limit+bad_minutes_indexes] = tmp_F [low_limit+bad_minutes_indexes]
                                        fixed_minutes += bad_minutes_number
                                ENDIF
                                bad_minutes_indexes  = where(H_values[*] GE 999990.00, bad_minutes_number)
                                i+=1
                        ;ENDFOR
                        ENDREP UNTIL (bad_minutes_number LE 0) OR (i GE n_processes)
                        j+=1
                ;ENDFOR
                ENDREP UNTIL (bad_minutes_number LE 0) OR (j GE N_ELEMENTS(process_number))
        ENDIF





;##############################################################################
; preparing data for storing
;##############################################################################
        
        
        data_file = STRARR(minutes_per_day)

        FOR i=0, minutes_per_day-1 DO BEGIN
                ;print, i mod 60, i/60
                ;print, i,H_values[i]
                
                data_file[i] = string( tmp_data[i].year, tmp_data[i].month, tmp_data[i].day, $
                                       tmp_data[i].hour, tmp_data[i].minute, tmp_data[i].doy, $
                                       D_values[i], H_values[i], Z_values[i], F_values[i], $
                                       FORMAT='(' $
                                       +'I4,"-",I02,"-",I02,X,' $ 
                                       +'I02,":",I02,":00.000 ",I03,5X,' $
                                       +'F7.2,X,F9.2,X,F9.2,X,F9.2' $
                                       +')')
                                       
                ;print, i, '  ', data_file[i]
        ENDFOR

        output_path     = system.processed_dir+gms[system.gms].name+'/'

        
        
        cleaned_data_file_name = gms[system.gms].code+'_'+string_date+'.clean.dat'

        OPENW, lun, output_path+cleaned_data_file_name, /GET_LUN, ERROR=err
                IF err EQ 0 THEN BEGIN
                        FOR i=0ll, minutes_per_day-1 DO PRINTF, lun, data_file[i]
                ENDIF ELSE BEGIN
                        IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Missing directories or permissions conflict.')"
                                PRINT, FORMAT="('                Impossible to save output file: ',A,'.')", cleaned_data_file_name
                                PRINT, ''
                        ENDIF
                        error.value[1] += 1
                        error.log      += 'Impossible to save output file '+cleaned_data_file_name+'. '
                ENDELSE
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN BEGIN
                print, '        - Saving: '+cleaned_data_file_name
                IF N_ELEMENTS(offset) EQ 3 THEN PRINT, offset[0], offset[1], offset[2], FORMAT='("          With a data-offset of ",I4," on D, ",I4," on H, and ", I4," on Z.")'
                IF (new_no_gaps_count LT minutes_per_day) THEN PRINT, ABS(minutes_per_day - new_no_gaps_count), FORMAT='("          Original data-file missed ",I4," minutes of data.")'
                IF (new_no_gaps_count LT no_gaps_count) THEN PRINT, ABS(no_gaps_count - new_no_gaps_count), FORMAT='("          Additionally, ",I4," minutes of original-data were discarted.")'
                IF (fixed_minutes GT 0) THEN PRINT, fixed_minutes, FORMAT='("          Finally, ",I4," minutes of original-data were capable to interpolate.")'
                print, ''
        ENDIF


RETURN
END


;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
; FUNCION AUXILIAR
PRO fixing_voltagefile, file_date, STATION=station, $
                                   QUIET=quiet

; PURPOSE:
;
;       complete gaps in raw data files from REGMEX GMS
;       and removes their headers
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Insituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro, Morelia, Michoacan
;       piter.cr@gmail.com
;       Mexico, 23.viii.mmxxii
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       fixing_voltagefile, date [, STATION=station, QUIET=quiet
;
;       Description:
;       retrives row data as measured by GMS.
;
;
; PARAMETERS:
;       date                                   : [YYYY, MM, DD] , date (year, month and day) for which the data is read from, array of integers
;
; KEYWORD PARAMETERS:
;
;       STATION                                : magnetic station where the data is taken from
;       QUIET                                  : sets messages off
;
; DEPENDENCIAS:
;       geomagixs system
;
; ARCHIVOS ANALIZADOS:
;       GMSYYYYMMDD[rmin/rk].min
;       GMSYYYYMMDD[rmin/rk].min
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
        file_name = ''
        tmp_year    = 0
        tmp_month   = 0
        tmp_day     = 0
        tmp_julday  = JULDAY(initial_month, initial_day, initial_year)
                
        CALDAT, tmp_julday, tmp_month, tmp_day, tmp_year
        
        
;        if station EQ 1 THEN BEGIN
                cabecera    = 18LL
                ;file_name = station_code+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'rmin.min'
        
                file_name   = gms[system.gms].code+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'rK.min'

                file_exists = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+file_name)
                IF not file_exists THEN BEGIN
                        file_name = gms[system.gms].code+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'rmin.min'
                        file_exists = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+file_name)
                ENDIF
                

                ;file_exists = FILE_TEST(kmex_magnetic_dir+station+'/1_min/'+file_name)
                

                IF file_exists THEN BEGIN
                        IF not keyword_set(quiet) THEN  print, '        Extracting data from: '+file_name
                        file = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                                IF opened_files EQ 0 AND not keyword_set(quiet) THEN MESSAGE, 'Error finding data files or directories!'
        
                        number_of_lines =FILE_LINES(file)
                ;temporal_data   = STRARR(total(number_of_lines))

;print, number_of_lines
                        tmp_data = STRARR(number_of_lines)

                        OPENR, lun, file, /GET_LUN, ERROR=err
                                IF err NE 0 THEN MESSAGE, 'Error opening '+file_name
                                READF, lun, tmp_data, FORMAT='(A)'
                        CLOSE, lun
                        FREE_LUN, lun
                ENDIF ELSE BEGIN
                        IF not keyword_set(quiet) THEN PRINT, '        Data file not found!'
                ENDELSE



;for i=0, N_ELEMENTS(tmp_data)-1 DO print, tmp_data[i]
;        ENDIF
;##############################################################################
; extracting and mixing data
;##############################################################################
        minutes_in_a_day = 60*24
        hours_in_a_day   = 24
        
        
        
        
IF STATION EQ 'planetary' THEN BEGIN
        final_file = STRARR(hours_in_a_day)
        
        j_inicio=cabecera-1
        
        FOR i=0, hours_in_a_day-1 DO BEGIN
                final_file[i] = string(tmp_year, tmp_month, tmp_day,i, 0, JULDAY(initial_month, initial_day, initial_year)-JULDAY(1, 0, initial_year), $
                                       999, 999, 999, 999, 9999, 9999, $
                                       FORMAT='(I4,"-",I02,"-",I02, X, I02, ":", I02, ":00.000 ", I03, 3X, ' + $
                                               'I4,5x,I4,2x,I5,4x,I5,3X,I5,5x,I5)')
                IF file_exists THEN $
                        FOR j=j_inicio, number_of_lines[0]-1 DO BEGIN
                                IF STRMID(tmp_data[j], 11,5) EQ STRMID(final_file[i], 11,5) THEN BEGIN
                                        string_tmp=tmp_data[j]
                                        final_file[i]=string_tmp
                                        ;print, i, final_file[i]
                                        j_inicio=j+1
                                        break
                                ENDIF
                        ENDFOR

        ENDFOR
ENDIF ELSE BEGIN
        final_file = STRARR(minutes_in_a_day)
        
        ;help, number_of_lines
        
        j_inicio=cabecera-1
        FOR i=0ll, minutes_in_a_day-1 DO BEGIN
                ;print, i mod 60, i/60
                final_file[i] = string(tmp_year, tmp_month, tmp_day, i/60, i mod 60, JULDAY(initial_month, initial_day, initial_year)-JULDAY(1, 0, initial_year), $
                                       9999.00, 999999.00, 999999.00, 999999.00, $
                                       FORMAT='(I4,"-",I02,"-",I02, X, I02, ":", I02, ":00.000 ", I03, 5X, F7.2, X, F9.2, X, F9.2, X, F9.2)')
                IF file_exists THEN $
                        FOR j=j_inicio, number_of_lines[0]-1 DO BEGIN
                                IF STRMID(tmp_data[j], 11,5) EQ STRMID(final_file[i], 11,5) THEN BEGIN
                                        string_tmp=tmp_data[j]
                                        final_file[i]=string_tmp
                                        j_inicio=j+1
                                        ;print, i, j_inicio, (j_inicio-i), ' -- ', final_file[i]
                                        break
                                ENDIF
                        ENDFOR
        ENDFOR
ENDELSE

;##############################################################################
; creating data file
;##############################################################################
        ;output_datafile = station_code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_datafile = gms[system.gms].code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_path     = system.processed_dir+gms[system.gms].name+'/'
        
        exist_dir = FILE_TEST(output_path, /DIRECTORY)
        
        IF not(exist_dir) THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('Critical Error: Missing system directory ', A,'. ')", output_path
                        PRINT, FORMAT="('                Check out the directory tree.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'System directory '+output_path+' not found. Impossible to continue. '
                RETURN
        ENDIF 
        ;print, output_path+output_datafile
        OPENW, lun, output_path+output_datafile, /GET_LUN, ERROR=err
                IF err EQ 0 THEN BEGIN
                        IF STATION EQ 'planetary' THEN FOR i=0ll, hours_in_a_day-1 DO PRINTF, lun, final_file[i] $
                                ELSE FOR i=0ll, minutes_in_a_day-1 DO PRINTF, lun, final_file[i]
                ENDIF ELSE MESSAGE, 'Error while writing data file!
                
                                     
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN BEGIN
                print, '        - Saving: '+output_datafile
        ENDIF


return
END




















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


PRO geomagixs_magneticdata_prepare, initial, final, STATION=station, $
                                              QUIET=quiet, $
                                              REAL_TIME=real_time, $
                                              FORCE_ALL=force_all, $
                                              OFFSET = offset

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

;print, offset

        IF N_ELEMENTS(offset) GT 0 THEN $
                IF N_ELEMENTS(offset) NE 3 THEN MESSAGE, 'CRITICAL ERROR: inconsistent values or invalid definition of OFFSET!!!'
;print, offset
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
        data_file_name      = strarr(file_number)
        processed_file_name = strarr(file_number)
        string_date         = strarr(file_number)
        ;exist_file     = intarr(file_number)
        
        FOR i=0ll, file_number-1 DO BEGIN
                tmp_year    = 0
                tmp_month   = 0
                tmp_day     = 0
                tmp_julday  = JULDAY(initial_month, initial_day, initial_year)

                CALDAT, tmp_julday+i, tmp_month, tmp_day, tmp_year
                string_date[i]    = string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')
                
                        ;data_file_name[i] = station_code+string_date[i]+'rmin.min'
                        ;processed_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                data_file_name[i] = gms[system.gms].code+string_date[i]+'rk.min'
                processed_file_name[i] = gms[system.gms].code+'_'+string_date[i]+'.dat'
                ;print, i+1, '  ', string_date[i], '  ', processed_file_name[i]
        ENDFOR

        exist_processed_file = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+processed_file_name) AND not(keyword_set(force_all))
        exist_data_file      = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+data_file_name)

        IF N_ELEMENTS(where(exist_processed_file EQ 0)) GT 1 THEN updating_files = N_ELEMENTS(where(exist_processed_file EQ 0)) $
                ELSE IF where(exist_processed_file EQ 0) GE 0 THEN updating_files = N_ELEMENTS(where(exist_processed_file EQ 0)) $
                        ELSE updating_files = 0
;print, data_file_name[where(exist_data_file EQ 0)]

        IF not keyword_set(quiet) THEN BEGIN
                IF updating_files GT 0 THEN BEGIN
                        PRINT, ''
                        PRINT, updating_files, FORMAT='("        A total of ",I," file(s) need to be updated.")' 
                ENDIF ELSE BEGIN
                        PRINT, "        No file requires to be updated."
                        RETURN
                ENDELSE
        
                IF updating_files NE N_ELEMENTS(exist_processed_file) THEN BEGIN
                        PRINT, N_ELEMENTS(exist_processed_file)-updating_files, FORMAT='("        There are still ",I," file(s) that can be updated.")'
                        PRINT, '        Use the /FORCE_ALL keyword to force the updating of all files.'
                        PRINT, ''
                ENDIF
        ENDIF

      
        
        proceed = 'Y'
        REPEAT BEGIN
                IF not (keyword_set(quiet) OR keyword_set(force_all)) THEN READ, proceed, PROMPT='        Continue (Y/N)?: '
                proceed=STRUPCASE(proceed)
                IF proceed EQ 'N' OR proceed EQ 'NO' THEN RETURN
        ENDREP UNTIL proceed EQ 'Y' OR proceed EQ 'YES'

        FOR i = 0ll, N_ELEMENTS(exist_processed_file)-1 DO BEGIN
                IF exist_processed_file[i] EQ 0 THEN BEGIN
                        tmp_year    = 0
                        tmp_month   = 0
                        tmp_day     = 0
                        READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                        ;print, tmp_year, tmp_month, tmp_day
                        fixing_datafile, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station
                        cleaning_datafile, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, OFFSET=offset, REAL_TIME=real_time
                ENDIF
        ENDFOR

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Data-file(s) ready for computing!'
        ENDIF

RETURN


END




