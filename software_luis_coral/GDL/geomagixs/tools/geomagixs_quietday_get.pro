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
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
; FUNCION AUXILIAR

;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
FUNCTION getting_magneticdata, initial, STATION=station, $
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



;##############################################################################
; reading data files
;##############################################################################
        file_number = 1
        file_name = ''
        
                file_name = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.clean.dat'

                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                IF opened_files NE N_ELEMENTS(file_name) THEN MESSAGE, ' * Critical Error: '+file_name+' not found.'
        
                number_of_lines = FILE_LINES(file)
                ;total_of_data   = total(number_of_lines)
                ;temporal_data   = STRARR(total(number_of_lines))
                magnetic_data   = STRARR(number_of_lines)

;print, number_of_lines

                ;tmp_data = STRARR(number_of_lines)

                OPENR, lun, file, /GET_LUN, ERROR=err
                        READF, lun, magnetic_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun


;##############################################################################
; extracting data
;##############################################################################
        DataStruct  =  { year : 0, month : 0, day : 0, $
                         hour : 0, minute : 0, $
                         D : 0., H : 0., Z : 0., F : 0. }
                         

        resulting_data = REPLICATE(DataStruct, number_of_lines)

        READS, magnetic_data[0:number_of_lines-1], resulting_data, $
               FORMAT='(I4,X,I2,X,I2,X,I2,X,I2,16X,F7,X,F9,X,F9,X,F9)'
        tempvar = SIZE(TEMPORARY(magnetic_data)) ; liberar memoria de la info no usada




        ;tempvar = SIZE(TEMPORARY(resulting_data)) ; liberar memoria de la info no usada
        return, resulting_data


END








FUNCTION reading_kmex_data, date, STATION=station, $
                               REAL_TIME=real_time, $
                               QUIET=quiet

        On_error, 2
        COMPILE_OPT idl2

;##############################################################################
; initialize directories
;##############################################################################
        ;kmex_setup
        @geomagixs_commons

        extention       = keyword_set(real_time) ? '.early' : '.final'
        extention       = STATION EQ 'planetary' ? '' : extention
        string_date     = string(date[0], date[1], date[2], FORMAT='(I4,I02,I02)')

        
        file_name       = system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_'+string_date+'.k_index'+extention

        file = FILE_SEARCH(file_name, COUNT=opened_files)
        
        
        
        dat_str = { z : [0,0,0,0,0,0,0,0], y : 0}
        tmp_var = REPLICATE(dat_str,6)

        result = { $
                  K_mex        : INTARR(8), $
                  K_SUM        : 0, $
                  a_mex        : INTARR(8), $ 
                  A_median     : 0, $
                  K_mex_max    : INTARR(8), $
                  K_SUM_max    : 0, $
                  a_mex_max    : INTARR(8), $ 
                  A_median_max : 0, $
                  K_mex_min    : INTARR(8), $
                  K_SUM_min    : 0, $
                  a_mex_min    : INTARR(8), $ 
                  A_median_min : 0 $
                 }

        
        IF opened_files GT 0 THEN BEGIN
                number_of_lines  = FILE_LINES(file)
                k_index_data = STRARR(number_of_lines)
                
                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[0]
                        READF, lun, k_index_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun

                READS, k_index_data, tmp_var, FORMAT='(I3,X,I3,X,I3,X,I3,X,I3,X,I3,X,I3,X,I3,X,I3)';'(8(I3,X), I3)'
        ENDIF ELSE BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('Input Warning: Missing index file: ',A,'.')", gms[system.gms].code+'_'+string_date+'.k_index'+extention
                        PRINT, FORMAT="('               Proceeding with fulfilling gaps file.')"
                ENDIF
                error.value[3] += 1
                error.log      += 'Missing index file '+gms[system.gms].code+'_'+string_date+'.k_index'+extention+'. Proceeding by fulfilling with datagaps. '

                result.K_mex[*] = 999
                result.a_mex[*] = 999
                result.K_SUM    = 999
                result.A_median = 999
                result.K_mex_max[*] = 999
                result.a_mex_max[*] = 999
                result.K_SUM_max    = 999
                result.A_median_max = 999
                result.K_mex_min[*] = 999
                result.a_mex_min[*] = 999
                result.K_SUM_min    = 999
                result.A_median_min = 999
        ENDELSE

        
        result.K_mex[*] = tmp_var[0].z
        result.a_mex[*] = tmp_var[1].z
        result.K_SUM    = tmp_var[0].y
        result.A_median = tmp_var[1].y
        result.K_mex_max[*] = tmp_var[2].z
        result.a_mex_max[*] = tmp_var[3].z
        result.K_SUM_max    = tmp_var[2].y
        result.A_median_max = tmp_var[3].y
        result.K_mex_min[*] = tmp_var[4].z
        result.a_mex_min[*] = tmp_var[5].z
        result.K_SUM_min    = tmp_var[4].y
        result.A_median_min = tmp_var[5].y

RETURN, result

END






;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
FUNCTION getting_local_qdays, initial, STATION=station, $
                                       QUIET=quiet, $
                                       REAL_TIME = real_time

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
;print, ':', initial_month 
        days_for_qdays =  NOT keyword_set(real_time) ? JULDAY(initial_month+1, 0, initial_year)-JULDAY(initial_month, 1, initial_year) : $
                                                       JULDAY(initial_month, 0, initial_year)-JULDAY(initial_month-1, 1, initial_year)

        julday_tmp = NOT keyword_set(real_time) ? JULDAY(initial_month+1, 0, initial_year) : JULDAY(initial_month, 0, initial_year)
        ;julday_tmp = JULDAY(initial_month+1, 0, initial_year) 
        ;print, '!',initial_month, 1, initial_year
;print, 
;IF JULDAY(gms[system.gms].dates_index[1,1],gms[system.gms].dates_index[1,2],gms[system.gms].dates_index[1,0]) LE julday_tmp THEN BEGIN

        tmp_m = 0
        tmp_d = 0
        tmp_y = 0
        
        str_tmp = { year:0, month:0, day:0, $
                    total_k : 0., total_k2 : 0., max_k : 0. $
                  }
                  
        data_qd = REPLICATE(str_tmp, days_for_qdays)
        ;print, days_for_qdays
        FOR i=1, days_for_qdays DO BEGIN
                CALDAT, julday_tmp-i, tmp_m, tmp_d, tmp_y
                data_qd[i-1].year  = tmp_y
                data_qd[i-1].month = tmp_m
                data_qd[i-1].day   = tmp_d
;print, i-1,tmp_y,tmp_m,tmp_d
                tmp = reading_kmex_data([tmp_y,tmp_m,tmp_d], STATION=station, QUIET=quiet, REAL_TIME=real_time)
                
                data_qd[i-1].total_k  = FLOAT(tmp.K_SUM)
                good_indexes          = WHERE(tmp.K_mex[*] LT 99, good_indexes_count)
                IF good_indexes_count LE 0 THEN BEGIN
                        data_qd[i-1].total_k2 = 999.0^2*8.
                        data_qd[i-1].max_k    = 999.0
                ENDIF ELSE BEGIN
                        data_qd[i-1].total_k2 = TOTAL(FLOAT(tmp.K_mex[good_indexes])^2)
                        data_qd[i-1].max_k    = MAX(FLOAT(tmp.K_mex[good_indexes]))
                ENDELSE
        ENDFOR

        

        sorting1 = SORT(data_qd[*].total_k)
;        print, '*', data_qd[sorting1].month
        data_qd[*] = data_qd[sorting1]
;        print, '**', data_qd[*].month
        
        FOR i=0, days_for_qdays-1 DO BEGIN
                
                indexes_equals1 = WHERE( data_qd[*].total_k EQ data_qd[i].total_k )
                ;PRINT, 'i=', i, N_ELEMENTS(indexes_equals1)
                ;PRINT, '     ', data_qd[i].total_k, data_qd[i].total_k2, data_qd[i].max_k
                
                ;print, indexes_equals1, data_qd[indexes_equals1].total_k
                ;print,'???'
                IF N_ELEMENTS(indexes_equals1) GT 1 THEN BEGIN
                        tmp_struct1 = data_qd[indexes_equals1]
                        sorting2 = SORT(tmp_struct1[*].total_k2)
                        tmp_struct1 = tmp_struct1[sorting2]
                        
                        FOR j = 0, N_ELEMENTS(sorting2)-1 DO BEGIN
                                indexes_equals2 = WHERE( tmp_struct1[*].total_k2 EQ tmp_struct1[j].total_k2 )
                                ;print, '!!!', indexes_equals2, '!!!'
                                ;PRINT, data_qd[indexes_equals1[sorting2]].total_k2, data_qd[indexes_equals1[sorting2[j]]].total_k2
                                IF N_ELEMENTS(indexes_equals2) GT 1 THEN BEGIN
                                        tmp_struct2 = tmp_struct1[indexes_equals2]
                                        sorting3 = SORT(tmp_struct2[*].max_k)
                                        tmp_struct1[indexes_equals2]=tmp_struct2[sorting3]
                                        j += N_ELEMENTS(indexes_equals2)-1
                                ENDIF
                        ENDFOR
                        data_qd[indexes_equals1] = tmp_struct1[*]
                                
                ;PRINT, '    nuevo i=', i, data_qd[indexes_equals1].total_k2, data_qd[indexes_equals1].max_k
                                ;print, data_qd[indexes_equals2[sorting3]].max_k, data_qd[indexes_equals2[sorting3]].max_k
                        i += N_ELEMENTS(indexes_equals1)-1
                        ;print, tmp_struct0
                        ;IF N_ELEMENTS(indexes_equals2) GT 1 THEN print, '!'
                ENDIF
        ENDFOR

        valid_days = WHERE(data_qd[*].total_k LT 990. AND data_qd[*].total_k2 LT 990.^2*8. AND data_qd[*].max_k LT 999., valid_days_count)

;print, N_ELEMENTS(valid_days)
;FOR i=0, N_ELEMENTS(valid_days)-1 DO print, data_qd[valid_days[i]].total_k, data_qd[valid_days[i]].total_k2, data_qd[valid_days[i]].max_k

IF valid_days_count GE 10 THEN BEGIN ;MESSAGE, 'Critial error: Less than 10 local Q-days found!'


        IF NOT keyword_set(quiet) THEN BEGIN
;print, data_qd[0].month
;print, valid_days[0]
;print, data_qd[valid_days[0]].month
                tmp_month = data_qd[valid_days[0]].month

                CASE 1 OF
                        tmp_month EQ 1  : tmp_string = 'Jan'
                        tmp_month EQ 2  : tmp_string = 'Feb'
                        tmp_month EQ 3  : tmp_string = 'Mar'
                        tmp_month EQ 4  : tmp_string = 'Apr'
                        tmp_month EQ 5  : tmp_string = 'May'
                        tmp_month EQ 6  : tmp_string = 'Jun'
                        tmp_month EQ 7  : tmp_string = 'Jul'
                        tmp_month EQ 8  : tmp_string = 'Aug'
                        tmp_month EQ 9  : tmp_string = 'Sep'
                        tmp_month EQ 10 : tmp_string = 'Oct'
                        tmp_month EQ 11 : tmp_string = 'Nov'
                        tmp_month EQ 12 : tmp_string = 'Dec'
                        ELSE: MESSAGE, 'Critial error'
                ENDCASE

                IF N_ELEMENTS(valid_days) LT 15 THEN $
                        str_result = ' '+tmp_string+' '+STRING(data_qd[valid_days[0]].year, $
                                                                data_qd[valid_days[0:4]].day, $
                                                                data_qd[valid_days[5:9]].day, $
                                                                FORMAT='(I4,X,5(2X,I2),2X,5(2X,I2))') $
                ELSE $
                        str_result = ' '+tmp_string+' '+STRING(data_qd[valid_days[0]].year, $
                                                                data_qd[valid_days[0:4]].day, $
                                                                data_qd[valid_days[5:9]].day, $ 
                                                                data_qd[valid_days[N_ELEMENTS(valid_days)-5:N_ELEMENTS(valid_days)-1]].day, $
                                                                FORMAT='(I4,X,5(2X,I2),2X,5(2X,I2),2X,5(2X,I2))')
                
                tmp_string = keyword_set(real_time) ? ' [early]' : ' [final]'
                PRINT, ''
                PRINT, ' * Local'+tmp_string+' Q & D days for '+gms[system.gms].name+' GMS.'
                PRINT, ' MMM YYYY   Q1  Q2  Q3  Q4  Q5    Q6  Q7  Q8  Q9  Q10   D1  D2  D3  D4  D5'
                PRINT, str_result
                PRINT, ''

        ENDIF

        resultado = { year:0, month:0, day : INTARR(10) }
        resultado.day[*] = data_qd[valid_days[0:9]].day
        resultado.year   = data_qd[valid_days[0]].year
        resultado.month  = data_qd[valid_days[0]].month
ENDIF ELSE BEGIN
        resultado = { year:0, month:0, day : INTARR(10) }
        resultado.day[*] = 99
        resultado.year   = initial_year
        resultado.month  = initial_month
ENDELSE
;FOR i=0, 10-1 DO print, data_qd[valid_days[i]].total_k, data_qd[valid_days[i]].day, data_qd[valid_days[i]].month, data_qd[valid_days[i]].year
;print, ''
;FOR i=N_ELEMENTS(valid_days)-5, N_ELEMENTS(valid_days)-1 DO print, data_qd[valid_days[i]].total_k, data_qd[valid_days[i]].day, data_qd[valid_days[i]].month, data_qd[valid_days[i]].year

RETURN, resultado
END




;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################


FUNCTION getting_statistic_quietday, initial, STATION=station, $
                                     QUIET=quiet, $
                                     REAL_TIME=real_time, $
                                     LOCAL=local


        On_error, 2
        COMPILE_OPT idl2, HIDDEN
        
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        ;geomagixs_check_dates, initial, /ONE_DATE, STATION=station, QUIET=quiet
        ;COMMON Q_days_commons
;##############################################################################
; depuring inputs
;##############################################################################
        

;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = initial[0]
        initial_month  = initial[1]
        initial_day    = initial[2]

        ;IF keyword_set(real_time) THEN $
        ;        CALDAT, JULDAY(initial[1], 0, initial[0]), initial_month, initial_day, initial_year
;print, initial_year, initial_month, initial_day
;##############################################################################
; reading data files
;##############################################################################
        kmex_days_for_median = 28
        quadratic_limit      = 7
        statistic_limit      = 5
        file_number    = kmex_days_for_median+1
        data_file_name = strarr(file_number)
        kmex_file_name = strarr(file_number)
        string_date    = strarr(file_number)
        tmp_julday     = JULDAY(initial_month, initial_day, initial_year)-(kmex_days_for_median)
        ;print, JULDAY(initial_month, initial_day, initial_year), (kmex_days_for_median+1)
        minutes_per_day = 24*60


        D_values = FLTARR(kmex_days_for_median, minutes_per_day)+9999.0
        H_values = FLTARR(kmex_days_for_median, minutes_per_day)+999999.0
        Z_values = FLTARR(kmex_days_for_median, minutes_per_day)+999999.0
        F_values = FLTARR(kmex_days_for_median, minutes_per_day)+999999.0

        FOR i=0, file_number-1 DO BEGIN
                tmp_year    = 0
                tmp_month   = 0
                tmp_day     = 0

                CALDAT, tmp_julday+i, tmp_month, tmp_day, tmp_year
                string_date[i]    = string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')
                ;kmex_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                kmex_file_name[i] = gms[system.gms].code+'_'+string_date[i]+'.clean.dat'
                ;print, i+1, '  ', string_date[i], '  ', kmex_file_name[i], ' / ', gms[system.gms].code
        ENDFOR

        exist_kmex_file = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+kmex_file_name)
        
        ;IF exist_kmex_file[kmex_days_for_median] THEN magnetic_data=getting_magneticdata(initial,STATION=station, QUIET=quiet)
        
        FOR i=0, kmex_days_for_median-1 DO $
                IF exist_kmex_file[i] EQ 1 THEN BEGIN
                        tmp_year  = 0
                        tmp_month = 0
                        tmp_day   = 0
                        
                        CALDAT, tmp_julday+i, tmp_month, tmp_day, tmp_year
                        tmp_data = getting_magneticdata([tmp_year,tmp_month,tmp_day], STATION=station, QUIET=quiet)
                        D_values[i,*] = tmp_data[*].D
                        H_values[i,*] = tmp_data[*].H
                        Z_values[i,*] = tmp_data[*].Z
                        F_values[i,*] = tmp_data[*].F
                ENDIF ;ELSE BEGIN

;##############################################################################
; calculating medians
;##############################################################################
        D_median = FLTARR(minutes_per_day)+9999.00
        D_sigma  = D_median
        H_median = FLTARR(minutes_per_day)+999999.00
        Z_median = H_median
        F_median = H_median
        N_median = H_median
        H_sigma  = H_median
        Z_sigma  = H_median
        F_sigma  = H_median
        N_sigma  = H_median
        
        number_of_data = INTARR(minutes_per_day)
        ;total_of_data  = INTARR(minutes_per_day)
        arc_secs_2rads = !Pi / (60.*180.)

        DataStruct1 =  { year : 0, month : 0, day : 0, $
                         hour : 0, minute : 0, $
                         D : 0., H : 0., Z : 0., F : 0., $ 
                         dD : 0., dH : 0., dZ : 0., dF : 0.}
                         
        qday       = REPLICATE(DataStruct1, minutes_per_day)

        time_days = FINDGEN(kmex_days_for_median)+1.

        FOR i=0, minutes_per_day-1 DO BEGIN
                ;print, i+1, WHERE(D_values[0:2*kmex_days_for_median-1,i] LT 9999.00 )
                valid_days = WHERE(H_values[0:kmex_days_for_median-1,i] LT 999990.00, COUNT )
                ;print, COUNT
                ;total_of_data[i] = kmex_days_for_median
                number_of_data[i] = COUNT ;valid_days[0] GE 0 ? N_ELEMENTS(valid_days) : 0

                IF number_of_data[i] GE statistic_limit THEN BEGIN
                        status_result = 1
                        
                        IF number_of_data[i] GE quadratic_limit THEN result = POLY_FIT( time_days[valid_days], D_values[valid_days,i], 2, STATUS=status_result, YFIT=tendency, SIGMA=delta )
;print, status_result, result, delta, FORMAT="(7(F,X))"
                        IF status_result GT 0 OR number_of_data[i] LT quadratic_limit THEN BEGIN
                                status_result = 0
                                result = LINFIT( time_days[valid_days], D_values[valid_days,i], YFIT=tendency, SIGMA=delta )
                                IF result[1]/delta[1] LE 0.5 AND finite(result[1], /NAN)+finite(delta[1], /NAN) LT 1 THEN status_result = 1
                                ;print, status_result, result, delta, result[1]/delta[1], finite(result[1], /NAN)+finite(delta[1], /NAN), FORMAT="(7(F,X))"
                        ENDIF
;print, status_result
                        IF status_result GT 0 THEN BEGIN
                                ;print, N_ELEMENTS(valid_days), status_result;, D_values[valid_days,i]
                                qday[i].D   = MEDIAN( D_values[valid_days,i])
                                qday[i].dD  = VARIANCE( D_values[valid_days,i])
                                ;print, qday[i].D, qday[i].dD
                        ENDIF ELSE BEGIN
                                qday[i].D   = MEDIAN( D_values[valid_days,i] - tendency )  + INTERPOL( tendency, time_days[valid_days],  time_days[valid_days[number_of_data[i]-1]]+1 )
                                qday[i].dD  = VARIANCE( D_values[valid_days,i] - tendency )
                                ;print, qday[i].D, qday[i].dD, FORMAT="(2(F,X))"
                        ENDELSE


                        status_result = 1
                        
                        IF number_of_data[i] GE quadratic_limit THEN result = POLY_FIT( time_days[valid_days], H_values[valid_days,i], 2, STATUS=status_result, YFIT=tendency, SIGMA=delta )
;print, status_result, result, delta, FORMAT="(7(F,X))"
                        IF status_result GT 0 OR number_of_data[i] LT quadratic_limit THEN BEGIN
                                status_result = 0
                                result = LINFIT( time_days[valid_days], H_values[valid_days,i], YFIT=tendency, SIGMA=delta )
                                IF result[1]/delta[1] LE 0.5 AND finite(result[1], /NAN)+finite(delta[1], /NAN) LT 1 THEN status_result = 1
                                ;print, status_result, result, delta, result[1]/delta[1], finite(result[1], /NAN)+finite(delta[1], /NAN), FORMAT="(7(F,X))"
                        ENDIF
;print, status_result
                        IF status_result GT 0 THEN BEGIN
                                ;print, N_ELEMENTS(valid_days), status_result;, D_values[valid_days,i]
                                qday[i].H   = MEDIAN( H_values[valid_days,i])
                                qday[i].dH  = VARIANCE( H_values[valid_days,i])
                                ;print, qday[i].D, qday[i].dD
                        ENDIF ELSE BEGIN
                                qday[i].H   = MEDIAN( H_values[valid_days,i] - tendency )  + INTERPOL( tendency, time_days[valid_days],  time_days[valid_days[number_of_data[i]-1]]+1 )
                                qday[i].dH  = VARIANCE( H_values[valid_days,i] - tendency )
                                ;print, qday[i].H, qday[i].dH, FORMAT="(2(F,X))"
                        ENDELSE


                        status_result = 1
                        
                        IF number_of_data[i] GE quadratic_limit THEN result = POLY_FIT( time_days[valid_days], Z_values[valid_days,i], 2, STATUS=status_result, YFIT=tendency, SIGMA=delta )
;print, status_result, result, delta, FORMAT="(7(F,X))"
                        IF status_result GT 0 OR number_of_data[i] LT quadratic_limit THEN BEGIN
                                status_result = 0
                                result = LINFIT( time_days[valid_days], Z_values[valid_days,i], YFIT=tendency, SIGMA=delta )
                                IF result[1]/delta[1] LE 0.5 AND finite(result[1], /NAN)+finite(delta[1], /NAN) LT 1 THEN status_result = 1
                                ;print, status_result, result, delta, result[1]/delta[1], finite(result[1], /NAN)+finite(delta[1], /NAN), FORMAT="(7(F,X))"
                        ENDIF
;print, status_result
                        IF status_result GT 0 THEN BEGIN
                                ;print, N_ELEMENTS(valid_days), status_result;, D_values[valid_days,i]
                                qday[i].Z   = MEDIAN( Z_values[valid_days,i])
                                qday[i].dZ  = VARIANCE( Z_values[valid_days,i])
                                ;print, qday[i].D, qday[i].dD
                        ENDIF ELSE BEGIN
                                qday[i].Z   = MEDIAN( Z_values[valid_days,i] - tendency )  + INTERPOL( tendency, time_days[valid_days],  time_days[valid_days[number_of_data[i]-1]]+1 )
                                qday[i].dZ  = VARIANCE( Z_values[valid_days,i] - tendency )
                                ;print, qday[i].Z, qday[i].dZ, FORMAT="(2(F,X))"
                        ENDELSE


                        status_result = 1
                        
                        IF number_of_data[i] GE quadratic_limit THEN result = POLY_FIT( time_days[valid_days], F_values[valid_days,i], 2, STATUS=status_result, YFIT=tendency, SIGMA=delta )
;print, status_result, result, delta, FORMAT="(7(F,X))"
                        IF status_result GT 0 OR number_of_data[i] LT quadratic_limit THEN BEGIN
                                status_result = 0
                                result = LINFIT( time_days[valid_days], F_values[valid_days,i], YFIT=tendency, SIGMA=delta )
                                IF result[1]/delta[1] LE 0.5 AND finite(result[1], /NAN)+finite(delta[1], /NAN) LT 1 THEN status_result = 1
                                ;print, status_result, result, delta, result[1]/delta[1], finite(result[1], /NAN)+finite(delta[1], /NAN), FORMAT="(7(F,X))"
                        ENDIF
;print, status_result
                        IF status_result GT 0 THEN BEGIN
                                ;print, N_ELEMENTS(valid_days), status_result;, D_values[valid_days,i]
                                qday[i].F   = MEDIAN( F_values[valid_days,i])
                                qday[i].dF  = VARIANCE( F_values[valid_days,i])
                                ;print, qday[i].D, qday[i].dD
                        ENDIF ELSE BEGIN
                                qday[i].F   = MEDIAN( F_values[valid_days,i] - tendency )  + INTERPOL( tendency, time_days[valid_days],  time_days[valid_days[number_of_data[i]-1]]+1 )
                                qday[i].dF  = VARIANCE( F_values[valid_days,i] - tendency )
                                ;print, qday[i].F, qday[i].dF, FORMAT="(2(F,X))"
                        ENDELSE
                ENDIF ELSE BEGIN
                        ;IF NOT keyword_set(quiet) THEN BEGIN
                        ;        PRINT, FORMAT="('Input Warning: Not enough data to compute QDay.')"
                        ;        PRINT, FORMAT="('               Proceeding by fulfilling with gaps.')"
                        ;ENDIF
                        ;error.value[3] += 1
                        ;error.log      += 'Missing magnetic data from data file . Proceeding by fulfilling with datagaps. '

                        qday[i].D   = 9999.0
                        qday[i].dD  = 9999.0
                        
                        qday[i].H   = 999999.0
                        qday[i].dH  = 999999.0
                        
                        qday[i].Z   = 999999.0
                        qday[i].dZ  = 999999.0
                        
                        qday[i].F   = 999999.0
                        qday[i].dF  = 999999.0
                ENDELSE

        ENDFOR

        ;D_sigma = D_sigma*(D_sigma LT 9990.00) + 9999.00*(D_sigma GE 9990.00)

        qday[*].year   = initial[0]
        qday[*].month  = initial[1]
        qday[*].day    = initial[2]
        qday[*].hour   = tmp_data[*].hour
        qday[*].minute = tmp_data[*].minute

        
        clean_indexes = WHERE( qday[*].dH GT 0.05*qday[*].H OR qday[*].dH GT 4.*median(qday[*].dH), clean_count )
        ;keep_indexes = WHERE( qday[*].dH LE 0.05*qday[*].H AND qday[*].dH LE 4.*median(qday[*].dH), keep_count )
        ;FOR i = 0, N_ELEMENTS(qday[*].dH)-1 DO print, qday[i].dD, qday[i].dH, qday[i].dZ, qday[i].dF, FORMAT='(F,F,F,F)'
        ;print, clean_count
        ;IF clean_count GT 0 THEN FOR i = 0, clean_count-1 DO print,i, qday[clean_indexes[i]].dH, qday[clean_indexes[i]].dH/(0.05*qday[clean_indexes[i]].H), qday[clean_indexes[i]].dH / (4.*median(qday[*].dH)), FORMAT='(I, F,F,F,F)'

        ;IF keep_count_count GT 0 THEN BEGIN
                        ;qday[clean_indexes].D  = !VALUES.F_NAN ;9999.0
                        ;qday[clean_indexes].dD = !VALUES.F_NAN ;9999.0
                        ;qday[clean_indexes].H  = !VALUES.F_NAN ;999999.00
                        ;qday[clean_indexes].dH = !VALUES.F_NAN ;999999.00
                        ;qday[clean_indexes].Z  = !VALUES.F_NAN ;999999.00
                        ;qday[clean_indexes].dZ = !VALUES.F_NAN ;999999.00
                        ;qday[clean_indexes].F  = !VALUES.F_NAN ;999999.00
                        ;qday[clean_indexes].dF = !VALUES.F_NAN ;999999.00
        ;ENDIF
        ;FOR i = 0, N_ELEMENTS(qday[*].dH)-1 DO print, qday[i].D, qday[i].H, qday[i].Z, qday[i].F, FORMAT='(F,F,F,F)'

        ;plot, qday[*].H , MAX_VALUE=999990., YRANGE=[27340.,27380.]
        ;oplot, qday[*].H+0.1*qday[*].dH
        ;plot, qday[*].dH , MAX_VALUE=999990., /Ylog;, YRANGE=[27370.,27400.]
        ;FOR i=0, N_ELEMENTS(qday[*].dH)-1 DO PRINT, i, median(qday[*].dH), qday[i].dH
        tmp_arr = fft(qday[*].H,1)
        tmp_arr_median = median(ABS(tmp_arr[*]))
;###############################################################################
;###############################################################################
;###############################################################################
        smoothing_period = 15. ; [minutes]
        smoothing_index  = (60*24)/FIX(smoothing_period)
        ;index_smoothing = WHERE(ABS(tmp_arr[*]) LE smooth_cretieria*tmp_arr_median)
;###############################################################################
;###############################################################################
;###############################################################################
        tmp_arr[smoothing_index:60*24-1-smoothing_index] = 0. ; eliminates frequencies above periods of smoothing_period
        ;print, index_smoothing[0], index_smoothing[N_ELEMENTS(index_smoothing)-1]
        ;print, smoothing_index, 60*24-1-smoothing_index
        ;print, initial;, index_smoothing[0]/(60.*24.), (60.*24.)/index_smoothing[0]
        tmp_arr_2 = fft(tmp_arr[*], -1)

        qday[*].H = tmp_arr_2[*]

        ; suvizado por +/-30 minutos
        smooth_steps = 30
        smooth_width = 10
        n_elemtns = N_ELEMENTS(qday[*].H)
        
        smoothed_array = [qday[n_elemtns-smooth_steps:n_elemtns-1].H,qday[0:smooth_steps-1].H]
        smoothed_array = SMOOTH(smoothed_array[*],smooth_width)
        qday[n_elemtns-smooth_steps:n_elemtns-1].H = smoothed_array[0:smooth_steps-1]
        qday[0:smooth_steps-1].H                   = smoothed_array[smooth_steps:2*smooth_steps-1]

        smoothed_array = [qday[n_elemtns-smooth_steps:n_elemtns-1].D,qday[0:smooth_steps-1].D]
        smoothed_array = SMOOTH(smoothed_array[*],smooth_width)
        qday[n_elemtns-smooth_steps:n_elemtns-1].D = smoothed_array[0:smooth_steps-1]
        qday[0:smooth_steps-1].D                   = smoothed_array[smooth_steps:2*smooth_steps-1]

        smoothed_array = [qday[n_elemtns-smooth_steps:n_elemtns-1].F,qday[0:smooth_steps-1].F]
        smoothed_array = SMOOTH(smoothed_array[*],smooth_width)
        qday[n_elemtns-smooth_steps:n_elemtns-1].F = smoothed_array[0:smooth_steps-1]
        qday[0:smooth_steps-1].F                   = smoothed_array[smooth_steps:2*smooth_steps-1]

        smoothed_array = [qday[n_elemtns-smooth_steps:n_elemtns-1].Z,qday[0:smooth_steps-1].Z]
        smoothed_array = SMOOTH(smoothed_array[*],smooth_width)
        qday[n_elemtns-smooth_steps:n_elemtns-1].Z = smoothed_array[0:smooth_steps-1]
        qday[0:smooth_steps-1].Z                   = smoothed_array[smooth_steps:2*smooth_steps-1]

;##############################################################################
; preparing data for storing
;##############################################################################

        ;FOR i = 0, N_ELEMENTS(qday[*].dH)-1 DO print, qday[i].D, qday[i].H, qday[i].Z, qday[i].F, FORMAT='(F,F,F,F)'



RETURN, qday
END


;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################


FUNCTION getting_quietday, initial, STATION=station, $
                                     QUIET=quiet, $
                                     REAL_TIME=real_time, $
                                     LOCAL=local


        On_error, 2
        COMPILE_OPT idl2, HIDDEN
        
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        ;geomagixs_check_dates, initial, /ONE_DATE, STATION=station, QUIET=quiet
        ;COMMON Q_days_commons
;##############################################################################
; depuring inputs
;##############################################################################
        

;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_date = initial

;print, initial_date
        IF keyword_set(real_time) THEN BEGIN
                ;qday =  getting_statistic_quietday (initial, STATION=station, QUIET=quiet)
                ;RETURN, qd
                CALDAT, JULDAY(initial[1], 0, initial[0]), tmp_month, tmp_day, tmp_year
                initial_date = [tmp_year,tmp_month, initial[2]]
;print, initial_date
        ENDIF

;##############################################################################
; reading data files
;##############################################################################


;        IF keyword_set(real_time) THEN BEGIN
;                tmp_julian = JULDAY(initial_date[1]-1, 1, initial_date[0])
;                CALDAT, tmp_julian, tmp_month, tmp_day, tmp_year
;                tmp_year0=tmp_year
                ;print, tmp_year, tmp_month, tmp_day
                ;initial_date[1]=tmp_month
;        ENDIF ELSE BEGIN
        tmp_julian = JULDAY(initial_date[1], 1, initial_date[0])
        CALDAT, tmp_julian, tmp_month, tmp_day, tmp_year
        tmp_year0=tmp_year
;        ENDELSE
;print, tmp_year, tmp_month, tmp_day
        tmp_millenium = (tmp_year/1000)*1000
        tmp_century   = (((tmp_year MOD 1000) / 100))*100
        tmp_decade    = (((tmp_year MOD 1000) MOD 100)/10)*10
        tmp_year      = tmp_millenium+tmp_century+tmp_decade
        
        tmp_today_year = (system.today_date[0]/1000)*1000+(((system.today_date[0] MOD 1000) / 100))*100 + $
                         (((system.today_date[0] MOD 1000) MOD 100)/10)*10
        tmp_julian     = JULDAY(tmp_month, 1, initial_date[0])
        tmp_julian_1   = JULDAY(1, 1, tmp_today_year)
        tmp_julian_2   = JULDAY(12, 31, tmp_today_year+9)
        
        
        
        CASE 1 OF
                tmp_julian LT tmp_julian_1      : file_name = 'qd'+string(tmp_year, tmp_decade+9, FORMAT='(I4,I02)')+'.txt'
                tmp_julian GE tmp_julian_1 AND $
                tmp_julian LE tmp_julian_2      : file_name  = 'qd'+string(tmp_year, tmp_decade/10, FORMAT='(I4,I01)')+'x.txt'
                ELSE                            : MESSAGE, 'Error with INPUT date!!!'
        ENDCASE
        ;IF tmp_julian GE tmp_julian_1 AND tmp_julian LE tmp_julian_2 THEN $
        ;        file_name  = 'qd'+string(tmp_year, tmp_decade/10, FORMAT='(I4,I01)')+'x.txt' $
        ;ELSE file_name = 'qd'+string(tmp_year, tmp_decade+9, FORMAT='(I4,I02)')+'.txt'


        file = FILE_SEARCH(system.qdays_dir+file_name, COUNT=opened_files)
                IF opened_files EQ 0 THEN MESSAGE, 'Error finding quiet days list file!'

        qds_list_data = STRARR(FILE_LINES(file))

        OPENR, lun, file, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[0]
                READF, lun, qds_list_data, FORMAT='(A)'
        CLOSE, lun
        FREE_LUN, lun

        ; buscar la línea donde está la fecha deseada!



        tmp_year = tmp_year0
        tmp_doy    = JULDAY(tmp_month, tmp_day, tmp_year)-JULDAY(1, 0, tmp_year)

        CASE 1 OF
                tmp_month EQ 1  : tmp_string = 'Jan'
                tmp_month EQ 2  : tmp_string = 'Feb'
                tmp_month EQ 3  : tmp_string = 'Mar'
                tmp_month EQ 4  : tmp_string = 'Apr'
                tmp_month EQ 5  : tmp_string = 'May'
                tmp_month EQ 6  : tmp_string = 'Jun'
                tmp_month EQ 7  : tmp_string = 'Jul'
                tmp_month EQ 8  : tmp_string = 'Aug'
                tmp_month EQ 9  : tmp_string = 'Sep'
                tmp_month EQ 10 : tmp_string = 'Oct'
                tmp_month EQ 11 : tmp_string = 'Nov'
                tmp_month EQ 12 : tmp_string = 'Dec'
                ELSE: MESSAGE, 'Critial error'
        ENDCASE

        date_str = ' '+tmp_string+' '+STRING(tmp_year, FORMAT='(I4)')
;print, date_str
;print, 'hola', qds_list_data[*]
        valid_line = WHERE(STRCMP(date_str, qds_list_data[*], 9, /fold_case) GT 0)
        
        tmp_str = { quiet_day : INTARR(10) }
        standard_day_list = REPLICATE(tmp_str,1)
        IF valid_line GE 0 AND NOT keyword_set(local) THEN BEGIN
                ;print, qds_list_data[valid_line]
                READS, qds_list_data[valid_line], standard_day_list, $
                        FORMAT='(12X,I2,2X,I2,2X,I2,2X,I2,2X,I2,4X,I2,2X,I2,2X,I2,2X,I2,2X,I2,:)'
                ;for i=0, 9 DO print, standard_day_list.quiet_day[i]
;print, standard_day_list
        ENDIF ELSE BEGIN
                ;qdays_exist = 0
                IF NOT keyword_set(local) THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: Invalid or missing values of planetary Q-days.')"
                                PRINT, FORMAT="('               Proceeding with LOCAL/[early] Q-days.')"
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Missing planetary Q-days. Proceeding computings with local ['+gms[system.gms].name+'] Q-days. '
                ENDIF
;print, initial
;print, tmp_year, tmp_month, tmp_day
                
                qd_tmp    = getting_local_qdays(initial, STATION=station, QUIET=quiet, REAL_TIME=real_time)
                tmp_month = qd_tmp.month
                tmp_year  = qd_tmp.year
                standard_day_list[*].quiet_day = qd_tmp.day[*]
                
                IF qd_tmp.day[0] GE 99 THEN BEGIN
                        qday = getting_statistic_quietday(initial, STATION=station, QUIET=quiet, REAL_TIME=real_time)
                        RETURN, qday
                END
                ;print, qd_tmp.month, qd_tmp.year
        ENDELSE

        minutes_per_day = 1440
        DataStruct  =  { year : INTARR(minutes_per_day), month : INTARR(minutes_per_day), day : INTARR(minutes_per_day), $
                         hour : INTARR(minutes_per_day), minute : INTARR(minutes_per_day), $
                         D : FLTARR(minutes_per_day)+9999., H : FLTARR(minutes_per_day)+999999., $
                         Z : FLTARR(minutes_per_day)+999999., F : FLTARR(minutes_per_day)+999999., $
                         D_median : 9999., H_median : 999999., Z_median : 999999., F_median : 999999. }

        qd_data    = REPLICATE(DataStruct, N_ELEMENTS(standard_day_list.quiet_day[*]))

        DataStruct1 =  { year : 0, month : 0, day : 0, $
                         hour : 0, minute : 0, $
                         D : 9999.0, H : 999999.0, Z : 999999.0, F : 999999.0, $ 
                         dD : 9999.0, dH : 999999.0, dZ : 999999.0, dF : 999999.0}
                         
        qday       = REPLICATE(DataStruct1, minutes_per_day)
        
        data_file_list = STRARR(N_ELEMENTS(standard_day_list.quiet_day[*]))
        ;print, standard_day_list.quiet_day[*]

        FOR i = 0, N_ELEMENTS(standard_day_list.quiet_day[*])-1 DO BEGIN
;print, [tmp_year,tmp_month, standard_day_list.quiet_day[i]]
                ;data_file_list[i] = gms[system.gms].code+'_'+STRING(tmp_year,tmp_month, standard_day_list.quiet_day[i], FORMAT='(I4,I02,I02)')+'.clean.dat'
                tmp        = getting_magneticdata([tmp_year,tmp_month, standard_day_list.quiet_day[i]], STATION=station, QUIET=quiet)
                qd_data[i].year[*] = tmp.year[*]
                qd_data[i].month[*] = tmp.month[*]
                qd_data[i].day[*] = tmp.day[*]
                qd_data[i].hour[*] = tmp.hour[*]
                qd_data[i].minute[*] = tmp.minute[*]
                qd_data[i].D[*] = tmp.D[*]
                qd_data[i].H[*] = tmp.H[*]
                ;qd_data[i].H[*] = (N_ELEMENTS(WHERE(tmp.H[*] LT 999990.00))/1440. GE 0.80) ? tmp.H[*] : 999999.00
                qd_data[i].Z[*] = tmp.Z[*]
                qd_data[i].F[*] = tmp.F[*]
                
                indexes = WHERE( qd_data[i].H[*] LT 999990.00 AND qd_data[i].H[*] GT 0., Count )
                ;print, i, standard_day_list.quiet_day[i], count
                IF Count GE 1 THEN BEGIN
                        qd_data[i].D_median = MEDIAN(qd_data[i].D[indexes])
                        qd_data[i].H_median = MEDIAN(qd_data[i].H[indexes])
                        qd_data[i].Z_median = MEDIAN(qd_data[i].Z[indexes])
                        qd_data[i].F_median = MEDIAN(qd_data[i].F[indexes])
                        
                        qd_data[i].D[indexes] -= qd_data[i].D_median
                        qd_data[i].H[indexes] -= qd_data[i].H_median
                        qd_data[i].Z[indexes] -= qd_data[i].Z_median
                        qd_data[i].F[indexes] -= qd_data[i].F_median
                        
                        ;indexes_1 = WHERE(ABS(qd_data[i].H[*]) GT 4.*STDDEV(qd_data[i].H[indexes]) + MEDIAN(qd_data[i].H[indexes]), Count_1)
                        ;IF Count_1 GE 1 THEN BEGIN
                        ;        qd_data[i].D[indexes_1] = 9999.0
                        ;        qd_data[i].H[indexes_1] = 999999.0
                        ;        qd_data[i].Z[indexes_1] = 999999.0
                        ;        qd_data[i].F[indexes_1] = 999999.0
                        ;ENDIF
                ENDIF ;ELSE BEGIN
               ;  
        ENDFOR
;stop
        ;print, data_file_list
        qday[*].year   = initial_date[0]
        qday[*].month  = initial_date[1]
        qday[*].day    = 1
        qday[*].hour   = qd_data[0].hour[*]
        qday[*].minute = qd_data[0].minute[*]
        ;print, initial_date[0], initial_date[1]
        FOR i=0, minutes_per_day-1 DO BEGIN
                indexes = WHERE( qd_data[*].H[i] LT 999990.00 , COUNT )

                IF COUNT GE 2 AND COUNT LT 5 THEN BEGIN
                        qday[i].D  = MEAN(qd_data[indexes].D[i])+MEDIAN(qd_data[indexes].D_median)
                        qday[i].dD = STDDEV(qd_data[indexes].D[i])
                        qday[i].H  = MEAN(qd_data[indexes].H[i])+MEDIAN(qd_data[indexes].H_median)
                        qday[i].dH = STDDEV(qd_data[indexes].H[i])
                        qday[i].Z  = MEAN(qd_data[indexes].Z[i])+MEDIAN(qd_data[indexes].Z_median)
                        qday[i].dZ = STDDEV(qd_data[indexes].Z[i])
                        qday[i].F  = MEAN(qd_data[indexes].F[i])+MEDIAN(qd_data[indexes].F_median)
                        qday[i].dF = STDDEV(qd_data[indexes].F[i])
;print, i, N_ELEMENTS(indexes), MEAN(qd_data[indexes].H[i]), MEAN(qd_data[indexes].H_median), STDDEV(qd_data[indexes].H[i]), ABS(STDDEV(qd_data[indexes[0:4]].H[i])/MEAN(qd_data[indexes[0:4]].H[i]))
;print, i, N_ELEMENTS(indexes), qday[i].H -median(qday[*].H),median(qday[*].H) , qday[i].dH- median(qday[*].dH)
                ;print, i+1, COUNT, indexes, qday[i].H;, FORMAT='(I4,X,I2,X,10(I02,X), F,X, F)'
                ENDIF

                IF COUNT GE 5 THEN BEGIN
                        qday[i].D  = MEAN(qd_data[indexes[0:4]].D[i])+MEDIAN(qd_data[indexes[0:4]].D_median)
                        qday[i].dD = STDDEV(qd_data[indexes[0:4]].D[i])
                        qday[i].H  = MEAN(qd_data[indexes[0:4]].H[i])+MEDIAN(qd_data[indexes[0:4]].H_median)
                        qday[i].dH = STDDEV(qd_data[indexes[0:4]].H[i])
                        qday[i].Z  = MEAN(qd_data[indexes[0:4]].Z[i])+MEDIAN(qd_data[indexes[0:4]].Z_median)
                        qday[i].dZ = STDDEV(qd_data[indexes[0:4]].Z[i])
                        qday[i].F  = MEAN(qd_data[indexes[0:4]].F[i])+MEDIAN(qd_data[indexes[0:4]].F_median)
                        qday[i].dF = STDDEV(qd_data[indexes[0:4]].F[i])
;print, i, N_ELEMENTS(indexes), MEAN(qd_data[indexes[0:4]].H[i]), MEAN(qd_data[indexes[0:4]].H_median), STDDEV(qd_data[indexes[0:4]].H[i]), ABS(STDDEV(qd_data[indexes[0:4]].H[i])/MEAN(qd_data[indexes[0:4]].H[i]))
;print, i, N_ELEMENTS(indexes), qday[i].H- median(qday[*].H),median(qday[*].H), qday[i].dH- median(qday[*].dH)
                ;print, i+1, COUNT, indexes[0:4], qday[i].H;, FORMAT='(I4,X,I2,X,10(I02,X), F,X, F)'
                ENDIF
;print, qday[700:720].H

                ;IF N_ELEMENTS(indexes) LE 0 THEN MESSAGE, 'No qdays available to perform computings.'
        ENDFOR
        tempvar = SIZE(TEMPORARY(qd_data)) ; liberar memoria de la info no usada
;indexes = where(qday[*].H LT 999990.0, count)
;plot, qday[*].H- median(qday[*].H);, MAX_VALUE=999990.0
        ;oplot, qday[*].H+qday[*].dH
        ;oplot, qday[*].H-qday[*].dH
        ;print, median(qday[*].dH)
        ;print, WHERE( qday[*].dH GT 2.*median(qday[*].dH) )
        
        ;clean_indexes = WHERE( qday[*].dH GT 4.*median(qday[*].dH) )
;print,  max(qday[*].dH  / qday[*].H)*100.,min(qday[*].dH  / qday[*].H)*100.
;stop
;print, median(qday[*].dH  / qday[*].H)*100., STDDEV(qday[*].dH  / qday[*].H)*100., median(qday[*].dH  / qday[*].H)*100.+2.5*STDDEV(qday[*].dH  / qday[*].H)*100.
        TS_oddnumber  = 11
        TS_N_ELEMENTS =N_ELEMENTS(qday[*].H)

        temp_H        = FLTARR(3*TS_N_ELEMENTS)
        temp_D        = temp_H
        temp_Z        = temp_H
        temp_F        = temp_H
        
        ;temp_H [0:TS_N_ELEMENTS-1]                 = qday[*].H-tmp_median
        ;temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]   = qday[*].H-tmp_median
        ;temp_H [2*TS_N_ELEMENTS:3*TS_N_ELEMENTS-1] = qday[*].H-tmp_median
        temp_H [0:TS_N_ELEMENTS-1]                 = qday[*].H
        temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]   = qday[*].H
        temp_H [2*TS_N_ELEMENTS:3*TS_N_ELEMENTS-1] = qday[*].H
        tmp_valid_indexes                          = WHERE(temp_H[*] LT 999990.0, tmp_valid_indexes_count)
                IF tmp_valid_indexes_count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
        tmp_median                                 = median(temp_H[tmp_valid_indexes])
        temp_H[tmp_valid_indexes]                 -= tmp_median
        
        temp_D [0:TS_N_ELEMENTS-1]                 = qday[*].D
        temp_D [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]   = qday[*].D
        temp_D [2*TS_N_ELEMENTS:3*TS_N_ELEMENTS-1] = qday[*].D
        tmp_valid_indexes                          = WHERE(temp_D[*] LT 9990.0, tmp_valid_indexes_count)
                IF tmp_valid_indexes_count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
        tmp_median                                 = median(temp_D[tmp_valid_indexes])
        temp_D[tmp_valid_indexes]                 -= tmp_median

        temp_Z [0:TS_N_ELEMENTS-1]                 = qday[*].Z
        temp_Z [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]   = qday[*].Z
        temp_Z [2*TS_N_ELEMENTS:3*TS_N_ELEMENTS-1] = qday[*].Z
        tmp_valid_indexes                          = WHERE(temp_Z[*] LT 999990.0, tmp_valid_indexes_count)
                IF tmp_valid_indexes_count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
        tmp_median                                 = median(temp_Z[tmp_valid_indexes])
        temp_Z[tmp_valid_indexes]                 -= tmp_median

        temp_F [0:TS_N_ELEMENTS-1]                 = qday[*].F
        temp_F [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]   = qday[*].F
        temp_F [2*TS_N_ELEMENTS:3*TS_N_ELEMENTS-1] = qday[*].F
        tmp_valid_indexes                          = WHERE(temp_F[*] LT 999990.0, tmp_valid_indexes_count)
                IF tmp_valid_indexes_count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
        tmp_median                                 = median(temp_F[tmp_valid_indexes])
        temp_D[tmp_valid_indexes]                 -= tmp_median


        half_hour = 30
        one_hour  = 60
        one_day   = 24*one_hour
        one_hour_arr   = FINDGEN(one_hour);*one_hour/(one_hour-1)
        three_days_arr = FINDGEN(TS_N_ELEMENTS)
        deviation_criteria = 0.5
        FOR i = 0, 51-1 DO BEGIN
        ;#######################################################################
        ; H-section
                tmp_vector    = temp_H[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour-1]
                valid_indexes = WHERE(tmp_vector LT 999990.0, Count)
                        IF Count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
                ;interpolation = INTERPOL( tmp_vector, one_hour_arr, one_hour_arr, /LSQUADRATIC )
                result        = POLY_FIT( one_hour_arr[valid_indexes], tmp_vector[valid_indexes], 2, STATUS=status_result, YFIT=tendency )
                
                IF status_result GT 0 THEN BEGIN
                        status_result = 0
                        result = LINFIT( one_hour_arr[valid_indexes], tmp_vector[valid_indexes], YFIT=tendency, SIGMA=delta )
                                
                        IF result[1]/delta[1] LE 0.5 THEN status_result = 1
                ENDIF
                
                IF status_result GT 0 THEN tendency = INTERPOL( tmp_vector[valid_indexes], one_hour_arr[valid_indexes], one_hour_arr, /LSQUADRATIC )
                
                
                deviation     = STDDEV(tmp_vector[valid_indexes]-tendency[valid_indexes])
                median_value  = MEDIAN(ABS(tmp_vector[valid_indexes]-tendency[valid_indexes]))
                bad_indexes = WHERE(ABS(tmp_vector-tendency) GT median_value+deviation_criteria*deviation, bad_indexes_count)
;print, i, median_value, deviation, median_value+deviation_criteria*deviation
;print, ABS(tmp_vector[valid_indexes]-tendency[valid_indexes])
                IF bad_indexes_count GT 0 THEN $ ;BEGIN
                        temp_H[bad_indexes+TS_N_ELEMENTS-one_hour+i*half_hour]=tendency[bad_indexes]
                        ;print, bad_indexes_count, '***', tmp_vector[bad_indexes]
                        ;print, bad_indexes_count, '***', tendency[bad_indexes]
                ;ENDIF
        ;#######################################################################
                
        ;#######################################################################
        ; D-section
                tmp_vector    = temp_D[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour-1]
                valid_indexes = WHERE(tmp_vector LT 999990.0, Count)
                        IF Count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'

                result        = POLY_FIT( one_hour_arr[valid_indexes], tmp_vector[valid_indexes], 2, STATUS=status_result, YFIT=tendency )
                
                IF status_result GT 0 THEN BEGIN
                        status_result = 0
                        result = LINFIT( one_hour_arr[valid_indexes], tmp_vector[valid_indexes], YFIT=tendency, SIGMA=delta )
                                
                        IF result[1]/delta[1] LE 0.5 THEN status_result = 1
                ENDIF
                
                IF status_result GT 0 THEN tendency = INTERPOL( tmp_vector[valid_indexes], one_hour_arr[valid_indexes], one_hour_arr, /LSQUADRATIC )
                
                
                deviation     = STDDEV(tmp_vector[valid_indexes]-tendency[valid_indexes])
                median_value  = MEDIAN(ABS(tmp_vector[valid_indexes]-tendency[valid_indexes]))
                bad_indexes = WHERE(ABS(tmp_vector-tendency) GT median_value+deviation_criteria*deviation, bad_indexes_count)

                IF bad_indexes_count GT 0 THEN $ ;BEGIN
                        temp_D[bad_indexes+TS_N_ELEMENTS-one_hour+i*half_hour]=tendency[bad_indexes]
        ;#######################################################################
                
        ;#######################################################################
        ; Z-section
                tmp_vector    = temp_Z[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour-1]
                valid_indexes = WHERE(tmp_vector LT 999990.0, Count)
                        IF Count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'

                result        = POLY_FIT( one_hour_arr[valid_indexes], tmp_vector[valid_indexes], 2, STATUS=status_result, YFIT=tendency )
                
                IF status_result GT 0 THEN BEGIN
                        status_result = 0
                        result = LINFIT( one_hour_arr[valid_indexes], tmp_vector[valid_indexes], YFIT=tendency, SIGMA=delta )
                                
                        IF result[1]/delta[1] LE 0.5 THEN status_result = 1
                ENDIF
                
                IF status_result GT 0 THEN tendency = INTERPOL( tmp_vector[valid_indexes], one_hour_arr[valid_indexes], one_hour_arr, /LSQUADRATIC )
                
                
                deviation     = STDDEV(tmp_vector[valid_indexes]-tendency[valid_indexes])
                median_value  = MEDIAN(ABS(tmp_vector[valid_indexes]-tendency[valid_indexes]))
                bad_indexes = WHERE(ABS(tmp_vector-tendency) GT median_value+deviation_criteria*deviation, bad_indexes_count)

                IF bad_indexes_count GT 0 THEN $ ;BEGIN
                        temp_Z[bad_indexes+TS_N_ELEMENTS-one_hour+i*half_hour]=tendency[bad_indexes]
        ;#######################################################################
                
        ;#######################################################################
        ; F-section
                tmp_vector    = temp_F[TS_N_ELEMENTS-one_hour+i*half_hour:TS_N_ELEMENTS+i*half_hour-1]
                valid_indexes = WHERE(tmp_vector LT 999990.0, Count)
                        IF Count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'

                result        = POLY_FIT( one_hour_arr[valid_indexes], tmp_vector[valid_indexes], 2, STATUS=status_result, YFIT=tendency )
                
                IF status_result GT 0 THEN BEGIN
                        status_result = 0
                        result = LINFIT( one_hour_arr[valid_indexes], tmp_vector[valid_indexes], YFIT=tendency, SIGMA=delta )
                                
                        IF result[1]/delta[1] LE 0.5 THEN status_result = 1
                ENDIF
                
                IF status_result GT 0 THEN tendency = INTERPOL( tmp_vector[valid_indexes], one_hour_arr[valid_indexes], one_hour_arr, /LSQUADRATIC )
                
                
                deviation     = STDDEV(tmp_vector[valid_indexes]-tendency[valid_indexes])
                median_value  = MEDIAN(ABS(tmp_vector[valid_indexes]-tendency[valid_indexes]))
                bad_indexes = WHERE(ABS(tmp_vector-tendency) GT median_value+deviation_criteria*deviation, bad_indexes_count)

                IF bad_indexes_count GT 0 THEN $ ;BEGIN
                        temp_F[bad_indexes+TS_N_ELEMENTS-one_hour+i*half_hour]=tendency[bad_indexes]
        ;#######################################################################
                
        ENDFOR
        
        two_hour_arr          = FINDGEN(2*one_hour);*one_hour/(one_hour-1)
        Delta_time            = 40 ; minutes to be ignored at the day's boundaries
        minutes_for_smoothing = 11
        
        ;#######################################################################
        ; H-section
        tmp_valid_indexes = WHERE(qday[*].H LT 999990.0, tmp_valid_indexes_count)
        IF tmp_valid_indexes_count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
        tmp_median        = MEDIAN(qday[tmp_valid_indexes].H)
        
        tendency = INTERPOL( [temp_H[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_H[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]], [two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]], two_hour_arr, /SPLINE )
        temp_H[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_H[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]
        ;plot, qday[*].H-tmp_median
        qday[*].H = TS_SMOOTH( temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1], minutes_for_smoothing)+tmp_median
        ;oplot, qday[*].H-tmp_median
        ;#######################################################################
        ; D-section
        tmp_valid_indexes = WHERE(qday[*].D LT 9990.0, tmp_valid_indexes_count)
        IF tmp_valid_indexes_count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
        tmp_median        = MEDIAN(qday[tmp_valid_indexes].D)
        
        tendency = INTERPOL( [temp_D[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_D[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]], [two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]], two_hour_arr, /SPLINE )
        temp_D[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_D[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]
        qday[*].D = TS_SMOOTH( temp_D [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1], minutes_for_smoothing)+tmp_median

        ;#######################################################################
        ; Z-section
        tmp_valid_indexes = WHERE(qday[*].Z LT 999990.0, tmp_valid_indexes_count)
        IF tmp_valid_indexes_count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
        tmp_median        = MEDIAN(qday[tmp_valid_indexes].Z)
        
        tendency = INTERPOL( [temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_Z[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]], [two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]], two_hour_arr, /SPLINE )
        temp_Z[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_Z[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]
        qday[*].Z = TS_SMOOTH( temp_Z [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1], minutes_for_smoothing)+tmp_median

        ;#######################################################################
        ; F-section
        tmp_valid_indexes = WHERE(qday[*].F LT 999990.0, tmp_valid_indexes_count)
        IF tmp_valid_indexes_count LE 0 THEN MESSAGE, 'Critical Error: No data to compute Quiet Day!'
        tmp_median        = MEDIAN(qday[tmp_valid_indexes].F)
        
        tendency = INTERPOL( [temp_F[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_F[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]], [two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]], two_hour_arr, /SPLINE )
        temp_F[TS_N_ELEMENTS:TS_N_ELEMENTS+one_hour-1]     = tendency[one_hour:2*one_hour-1]
        temp_F[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1] = tendency[0:one_hour-1]
        qday[*].F = TS_SMOOTH( temp_F [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1], minutes_for_smoothing)+tmp_median

        ;plot, result-MEDIAN(result), MAX_VALUE=999990.0
        ;oplot, qday[*].F- median(qday[*].F)
        
        
        ;result        = POLY_FIT( [temp_H[2*TS_N_ELEMENTS+half_hour:2*TS_N_ELEMENTS+one_hour-1], temp_H[TS_N_ELEMENTS+half_hour:TS_N_ELEMENTS+one_hour-1]], [two_hour_arr[0:30-1], two_hour_arr[90:120-1]], 3, STATUS=status_result, YFIT=tendency )
        
;plot, [two_hour_arr[0:one_hour-Delta_time-1], two_hour_arr[one_hour+Delta_time:2*one_hour-1]], [temp_H[2*TS_N_ELEMENTS-one_hour:2*TS_N_ELEMENTS-1-Delta_time], temp_H[TS_N_ELEMENTS+Delta_time:TS_N_ELEMENTS+one_hour-1]]
;oplot, two_hour_arr, tendency;-MEDIAN(tendency)
;plot, temp_H [TS_N_ELEMENTS+half_hour:2*TS_N_ELEMENTS-1-half_hour]- median(temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]);, MAX_VALUE=999990.0
;oplot, qday[*].H- median(qday[*].H)


;plot, temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]- median(temp_H [TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]);, MAX_VALUE=999990.0

goto, jump

;stop

        smoothed_H   = TS_SMOOTH(temp_H[*], TS_oddnumber)
        smoothed_D   = TS_SMOOTH(temp_D[*], TS_oddnumber)
        smoothed_Z   = TS_SMOOTH(temp_Z[*], TS_oddnumber)
        smoothed_F   = TS_SMOOTH(temp_F[*], TS_oddnumber)
        smoothed_dH  = TS_SMOOTH(qday[*].dH, TS_oddnumber)
        smoothed_dD  = TS_SMOOTH(qday[*].dD, TS_oddnumber)
        smoothed_dZ  = TS_SMOOTH(qday[*].dZ, TS_oddnumber)
        smoothed_dF  = TS_SMOOTH(qday[*].dF, TS_oddnumber)
        
        TS_limit     = median(ABS(temp_H[*] - smoothed_H))+0.25*STDDEV(ABS(temp_H[*] - smoothed_H))
;print, ABS(qday[*].H-median(qday[*].H) - TS_SMOOTH(qday[*].H-median(qday[*].H), TS_oddnumber))
;print, median(ABS(qday[*].H-median(qday[*].H) - TS_SMOOTH(qday[*].H-median(qday[*].H), TS_oddnumber))), STDDEV(ABS(qday[*].H-median(qday[*].H) - TS_SMOOTH(qday[*].H-median(qday[*].H), TS_oddnumber)))
        ;clean_indexes = WHERE( qday[*].dH/qday[*].H GE 0.005, clean_count )

        ;clean_indexes = WHERE( ABS(qday[*].H-median(qday[*].H)- TS_SMOOTH(qday[*].H-median(qday[*].H), TS_oddnumber)) GT TS_limit, clean_count )
        clean_indexes = WHERE( ABS(temp_H[TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]- smoothed_H[TS_N_ELEMENTS:2*TS_N_ELEMENTS-1]) GT TS_limit, clean_count )
;print, qday[clean_indexes].dH
;print, smoothed_dH[clean_indexes]
;print, qday[0:9].H-median(qday[*].H)
;print, qday[1430:1439].H-median(qday[*].H)
;plot, qday[*].H-median(qday[*].H)
;oplot, smoothed_H[*], linestyle=1
        IF clean_count GE 0 THEN BEGIN
;print, clean_count
;print, clean_indexes
;print, qday[clean_indexes].H-median(qday[*].H)
;print, smoothed_H[clean_indexes+TS_N_ELEMENTS]
                        qday[clean_indexes].D  = smoothed_D[clean_indexes+TS_N_ELEMENTS]+median(qday[*].D)
                        qday[clean_indexes].dD = smoothed_dD[clean_indexes]
                        qday[clean_indexes].H  = smoothed_H[clean_indexes+TS_N_ELEMENTS]+median(qday[*].H)
                        qday[clean_indexes].dH = smoothed_dH[clean_indexes]
                        qday[clean_indexes].Z  = smoothed_Z[clean_indexes+TS_N_ELEMENTS]+median(qday[*].Z)
                        qday[clean_indexes].dZ = smoothed_dZ[clean_indexes]
                        qday[clean_indexes].F  = smoothed_F[clean_indexes+TS_N_ELEMENTS]+median(qday[*].F)
                        qday[clean_indexes].dF = smoothed_dF[clean_indexes]

                        qday[clean_indexes].D  = !VALUES.F_NAN
                        qday[clean_indexes].dD = smoothed_dD[clean_indexes]
                        qday[clean_indexes].H  = !VALUES.F_NAN
                        qday[clean_indexes].dH = smoothed_dH[clean_indexes]
                        qday[clean_indexes].Z  = !VALUES.F_NAN
                        qday[clean_indexes].dZ = smoothed_dZ[clean_indexes]
                        qday[clean_indexes].F  = !VALUES.F_NAN
                        qday[clean_indexes].dF = smoothed_dF[clean_indexes]

;print, qday[clean_indexes].H-median(qday[*].H)
        ENDIF
print, qday[0:50].H-median(qday[*].H)
;plot, qday[*].H-median(qday[*].H)
;stop
;print,    clean_indexes
;print,  qday[clean_indexes].dH, median(qday[*].dH)
;print,  qday[clean_indexes].H, max(qday[*].H), min(qday[*].H)
        TS_oddnumber = 15
        TS_limit     = median(ABS(qday[*].H-median(qday[*].H) - TS_SMOOTH(qday[*].H-median(qday[*].H), TS_oddnumber)))+STDDEV(ABS(qday[*].H-median(qday[*].H) - TS_SMOOTH(qday[*].H-median(qday[*].H), TS_oddnumber)))
        smoothed_H   = TS_SMOOTH(qday[*].H-median(qday[*].H), TS_oddnumber)
        smoothed_D   = TS_SMOOTH(qday[*].D-median(qday[*].D), TS_oddnumber)
        smoothed_Z   = TS_SMOOTH(qday[*].Z-median(qday[*].Z), TS_oddnumber)
        smoothed_F   = TS_SMOOTH(qday[*].F-median(qday[*].F), TS_oddnumber)
        smoothed_dH  = TS_SMOOTH(qday[*].dH, TS_oddnumber)
        smoothed_dD  = TS_SMOOTH(qday[*].dD, TS_oddnumber)
        smoothed_dZ  = TS_SMOOTH(qday[*].dZ, TS_oddnumber)
        smoothed_dF  = TS_SMOOTH(qday[*].dF, TS_oddnumber)

        clean_indexes = WHERE( ABS(qday[*].H-median(qday[*].H)- smoothed_H[*]) GT TS_limit, clean_count )

print, clean_count
print, clean_indexes
print, qday[clean_indexes].H-median(qday[*].H)
print, smoothed_H[clean_indexes]


        IF clean_count GE 0 THEN BEGIN
                        qday[clean_indexes].D  = smoothed_D[clean_indexes]+median(qday[*].D)
                        qday[clean_indexes].dD = smoothed_dD[clean_indexes]
                        qday[clean_indexes].H  = smoothed_H[clean_indexes]+median(qday[*].H)
                        qday[clean_indexes].dH = smoothed_dH[clean_indexes]
                        qday[clean_indexes].Z  = smoothed_Z[clean_indexes]+median(qday[*].Z)
                        qday[clean_indexes].dZ = smoothed_dZ[clean_indexes]
                        qday[clean_indexes].F  = smoothed_dF[clean_indexes]+median(qday[*].F)
                        qday[clean_indexes].dF = smoothed_dF[clean_indexes]
        ENDIF

;plot, qday[*].H-median(qday[*].H)




        ;plot, qday[*].H , MAX_VALUE=999990., YRANGE=[27340.,27380.]
        ;oplot, qday[*].H+0.1*qday[*].dH
        ;plot, qday[*].dH , MAX_VALUE=999990., /Ylog;, YRANGE=[27370.,27400.]
        ;FOR i=0, N_ELEMENTS(qday[*].dH)-1 DO PRINT, i, median(qday[*].dH), qday[i].dH
        tmp_arr = fft(qday[*].H,1)
        tmp_arr_median = median(ABS(tmp_arr[*]))
;###############################################################################
;###############################################################################
;###############################################################################
        smoothing_period = 15. ; [minutes]
        smoothing_index  = (60*24)/FIX(smoothing_period)
        ;index_smoothing = WHERE(ABS(tmp_arr[*]) LE smooth_cretieria*tmp_arr_median)
;###############################################################################
;###############################################################################
;###############################################################################
        tmp_arr[smoothing_index:60*24-1-smoothing_index] = 0. ; eliminates frequencies above periods of smoothing_period
        ;print, index_smoothing[0], index_smoothing[N_ELEMENTS(index_smoothing)-1]
        ;print, smoothing_index, 60*24-1-smoothing_index
        ;print, initial;, index_smoothing[0]/(60.*24.), (60.*24.)/index_smoothing[0]
        tmp_arr_2 = fft(tmp_arr[*], -1)
plot, qday[*].H-median(qday[*].H)
        qday[*].H = tmp_arr_2[*]
;oplot, qday[*].H-median(qday[*].H), linestyle=1

        ; suvizado por +/-30 minutos
        smooth_steps = 30
        smooth_width = 10
        n_elemtns = N_ELEMENTS(qday[*].H)
        
        smoothed_array = [qday[n_elemtns-smooth_steps:n_elemtns-1].H,qday[0:smooth_steps-1].H]
        smoothed_array = SMOOTH(smoothed_array[*],smooth_width)
        qday[n_elemtns-smooth_steps:n_elemtns-1].H = smoothed_array[0:smooth_steps-1]
        qday[0:smooth_steps-1].H                   = smoothed_array[smooth_steps:2*smooth_steps-1]

        smoothed_array = [qday[n_elemtns-smooth_steps:n_elemtns-1].D,qday[0:smooth_steps-1].D]
        smoothed_array = SMOOTH(smoothed_array[*],smooth_width)
        qday[n_elemtns-smooth_steps:n_elemtns-1].D = smoothed_array[0:smooth_steps-1]
        qday[0:smooth_steps-1].D                   = smoothed_array[smooth_steps:2*smooth_steps-1]

        smoothed_array = [qday[n_elemtns-smooth_steps:n_elemtns-1].F,qday[0:smooth_steps-1].F]
        smoothed_array = SMOOTH(smoothed_array[*],smooth_width)
        qday[n_elemtns-smooth_steps:n_elemtns-1].F = smoothed_array[0:smooth_steps-1]
        qday[0:smooth_steps-1].F                   = smoothed_array[smooth_steps:2*smooth_steps-1]

        smoothed_array = [qday[n_elemtns-smooth_steps:n_elemtns-1].Z,qday[0:smooth_steps-1].Z]
        smoothed_array = SMOOTH(smoothed_array[*],smooth_width)
        qday[n_elemtns-smooth_steps:n_elemtns-1].Z = smoothed_array[0:smooth_steps-1]
        qday[0:smooth_steps-1].Z                   = smoothed_array[smooth_steps:2*smooth_steps-1]

        ;plot, qday[*].H-median(qday[*].H) , MAX_VALUE=999990.;, YRANGE=[27000.,27500.], YStyle=1
        ;plot, qday[*].H , MAX_VALUE=999990., YRANGE=[27370.,27400.], XRANGE=[-10.,1450.], XStyle=1
;print, mean(qday[*].H)

        ;plot, SMOOTH(qday[*].H,60) , MAX_VALUE=999999., YRANGE=[27300.,27400.], Ystyle=1, XRANGE=[900.,1100.]
        ;for i=900, 1000 DO print, i, qday[i].H
jump:

RETURN, qday
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


FUNCTION geomagixs_quietday_get, initial, STATION=station, $
                                     QUIET=quiet, $
                                     REAL_TIME=real_time, $
                                     FORCE_ALL=force_all, $
                                     LOCAL=local, $
                                     STATISTIC_QD=statistic_qd

        On_error, 2
        COMPILE_OPT idl2, HIDDEN
        
        ;COMMON Q_days_commons, qdays_exist
        
        ;qdays_exist = 1         ; marks out if planetary qdays are available [=1] or not [=0]
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        geomagixs_setup_commons, /QUIET
        geomagixs_check_system, /QUIET
        geomagixs_setup_dates, STATION=station, /QUIET
        ;geomagixs_check_dates, initial, /ONE_DATE, STATION=station, QUIET=quiet
        
;##############################################################################
; depuring inputs
;##############################################################################

        IF STATION EQ 'planetary' THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('INCONSISTENCY WARNING: the requested conditions may compromise the computed results.')"
                        PRINT, FORMAT="('                       impossible/innecesary to calculate Q-day for Planetary GMS.')"
                ENDIF
                error.value[4] += 1
                error.log      += 'Impossible and innecesary to calculate Q-day for Planetary GMS. '
                RETURN, 0
        ENDIF

        update_flag = 0
        ;IF keyword_set(force_all) BEGIN
        CASE 1 OF
                N_PARAMS() EQ 0 : BEGIN
                                        initial = system.today_date
                                  END
                N_PARAMS() EQ 1 : BREAK
                ELSE            : BEGIN
                                        IF NOT keyword_set(quiet) THEN BEGIN
                                                PRINT, FORMAT="('CRITICAL ERROR: conflict with input date(s), data inconsistent or invalid.')"
                                                PRINT, FORMAT="('                impossible to proceed with an ambiguoss range of dates.')"
                                        ENDIF
                                        error.value[2] += 1
                                        error.log      += 'Ambiguous range of dates, it is required only one input date to define a day. '
                                        RETURN, 0
                                  END
        ENDCASE

                
        ;ENDIF
        

;##############################################################################
; initializing dates and hours
;##############################################################################
        CALDAT, JULDAY(initial[1],initial[2],initial[0]), tmp_month, tmp_day, tmp_year
        initial_tmp = [tmp_year, tmp_month, tmp_day]


        ;qday = getting_quietday(initial_tmp, STATION=station, QUIET=quiet, REAL_TIME=real_time, LOCAL=local)
        ;help, qday
        ;print, initial_tmp
        ;print, qday
        
;        IF qdays_exist NE 1 AND NOT keyword_set(local) THEN BEGIN
;                CALDAT, JULDAY(initial[1]-1,initial[2],initial[0]), tmp_month, tmp_day, tmp_year
;                initial_tmp = [tmp_year, tmp_month, tmp_day]
;                qday = getting_quietday(initial_tmp, STATION=station, QUIET=quiet, REAL_TIME=real_time, LOCAL=local)
;                
;                CALDAT, JULDAY(initial_tmp[1]-1,1,initial_tmp[0]), tmp_month, tmp_day, tmp_year
;                qday0 = getting_quietday([tmp_year, tmp_month,1], STATION=station, QUIET=quiet, REAL_TIME=real_time, LOCAL=local)
;                
;                N_days0    = JULDAY(initial_tmp[1]-1,0,initial_tmp[0]) - JULDAY(initial_tmp[1]-2,0,initial_tmp[0])
;                N_days1    = JULDAY(initial_tmp[1]+1,0,initial_tmp[0]) - JULDAY(initial_tmp[1],0,initial_tmp[0])
;                N_days2    = JULDAY(initial_tmp[1]+2,0,initial_tmp[0]) - JULDAY(initial_tmp[1]+1,0,initial_tmp[0])
;                N_days3    = JULDAY(initial_tmp[1]+2,0,initial_tmp[0]) - JULDAY(initial_tmp[1]+1,0,initial_tmp[0])
;        ENDIF
        
        
        IF keyword_set(real_time) THEN $
                IF NOT keyword_set(statistic_qd) THEN $
                        qday = getting_quietday ([tmp_year, tmp_month, tmp_day], STATION=station, QUIET=quiet, REAL_TIME=real_time, LOCAL=local) $
                        ELSE qday = getting_statistic_quietday ([tmp_year, tmp_month, tmp_day], STATION=station, QUIET=quiet, REAL_TIME=real_time, LOCAL=local) $
                
                ;CALDAT, JULDAY(initial_tmp[1]-2,1,initial_tmp[0]), tmp_month, tmp_day, tmp_year
                ;qday0   = getting_quietday([tmp_year, tmp_month,1], STATION=station, QUIET=quiet, REAL_TIME=real_time, LOCAL=local)
                ;N_days0 = JULDAY(initial_tmp[1]-1,0,initial_tmp[0]) - JULDAY(initial_tmp[1]-2,0,initial_tmp[0])

                ;CALDAT, JULDAY(initial[1]-1,1,initial[0]), tmp_month, tmp_day, tmp_year
                ;qday    = getting_quietday([tmp_year, tmp_month, tmp_day], STATION=station, QUIET=quiet, REAL_TIME=real_time, LOCAL=local)
                ;qday1   = getting_quietday([tmp_year, tmp_month, tmp_day], STATION=station, QUIET=quiet, REAL_TIME=real_time, LOCAL=local)
                ;N_days1 = JULDAY(initial_tmp[1],0,initial_tmp[0]) - JULDAY(initial_tmp[1]-1,0,initial_tmp[0])

                ;N_days2 = JULDAY(initial_tmp[1],initial_tmp[2],initial_tmp[0]) - JULDAY(initial_tmp[1],0,initial_tmp[0])
                ;delta_H = median(qday1[*].H-qday0[*].H)
                ;delta_D = median(qday1[*].D-qday0[*].D)
                ;delta_Z = median(qday1[*].Z-qday0[*].Z)
                ;delta_F = median(qday1[*].F-qday0[*].F)
                
                ;julday_tmp = JULDAY(initial_tmp[1]-1,1,initial_tmp[0])
                ;print, N_days0, N_days1, N_days2
                
                ;v       = [N_days0/2.,N_days0+N_days1/2.]
                ;w       = [N_days0+N_days1+1.*N_days2]
                
                ;N_days3 = JULDAY(initial_tmp[1]+1,0,initial_tmp[0]) - JULDAY(initial_tmp[1],0,initial_tmp[0])
                
                ;qday[*].H += delta_H*((N_days1*0.5+N_days2)/(0.5*(N_days1+N_days3)))
                ;qday[*].D += delta_D*((N_days1*0.5+N_days2)/(0.5*(N_days1+N_days3)))
                ;qday[*].Z += delta_Z*((N_days1*0.5+N_days2)/(0.5*(N_days1+N_days3)))
                ;qday[*].F += delta_F*((N_days1*0.5+N_days2)/(0.5*(N_days1+N_days3)))
                
                ;qday[*].year  = initial_tmp[0]
                ;qday[*].month = initial_tmp[1]
                
                ;        print, v, w
        ELSE BEGIN
                CALDAT, JULDAY(initial_tmp[1],0,initial_tmp[0]), tmp_month, tmp_day, tmp_year
                qday0   = getting_quietday([tmp_year, tmp_month,1], STATION=station, QUIET=quiet, LOCAL=local)
                N_days0 = JULDAY(initial_tmp[1],0,initial_tmp[0]) - JULDAY(initial_tmp[1]-1,0,initial_tmp[0])

                CALDAT, JULDAY(initial[1],1,initial[0]), tmp_month, tmp_day, tmp_year
                qday1   = getting_quietday([tmp_year, tmp_month, tmp_day], STATION=station, QUIET=quiet, LOCAL=local)
                N_days1 = JULDAY(initial_tmp[1]+1,0,initial_tmp[0]) - JULDAY(initial_tmp[1],0,initial_tmp[0])

                CALDAT, JULDAY(initial[1]+1,1,initial[0]), tmp_month, tmp_day, tmp_year
                qday2   = getting_quietday([tmp_year, tmp_month, tmp_day], STATION=station, QUIET=quiet, LOCAL=local)
                N_days2 = JULDAY(initial_tmp[1]+2,0,initial_tmp[0]) - JULDAY(initial_tmp[1]+1,0,initial_tmp[0])

                N_days  = JULDAY(initial_tmp[1],initial_tmp[2],initial_tmp[0]) - JULDAY(initial_tmp[1],0,initial_tmp[0])

                v       = [N_days0/2.,N_days0+N_days1/2., N_days0+N_days1+N_days2/2.]
                w       = [N_days0+1.*N_days]
                
                qday = qday1
                FOR i=0, N_ELEMENTS(qday1[*].H)-1 DO BEGIN
                        DH      = interpol([qday0[i].H,qday1[i].H,qday2[i].H], v, w)
                        DD      = interpol([qday0[i].D,qday1[i].D,qday1[i].D], v, w)
                        DZ      = interpol([qday0[i].Z,qday1[i].Z,qday1[i].Z], v, w)
                        DF      = interpol([qday0[i].F,qday1[i].F,qday1[i].F], v, w)
                        
                        qday[i].H = DH
                        qday[i].D = DD
                        qday[i].Z = DZ
                        qday[i].F = DF
                        
                        ;qday[i].year  = initial_tmp[0]
                        ;qday[i].month = initial_tmp[1]
                        qday[i].day   = initial_tmp[2]
                ENDFOR
        ENDELSE
        
        ;plot, qday[*].H- median (qday[*].H);, MAX_VALUE=999990., YRANGE=[27100.,27450.], YStyle=1
        ;print, qday[0].H- median (qday[*].H), qday[N_ELEMENTS(qday[*].H)-1].H- median (qday[*].H)
        ;print, median (qday[*].H), mean (qday[*].H)
        ;oplot, qday0[*].H, linestyle=4
        
        
;GOTO, jump
;jump:

                ;print, [tmp_year, tmp_month,1]
                ;H_media = [median(qday0[*].H), median(qday[*].H)]
                ;D_media = [median(qday0[*].D), median(qday[*].D)]
                ;Z_media = [median(qday0[*].Z), median(qday[*].Z)]
                ;F_media = [median(qday0[*].F), median(qday[*].F)]
                
                ;DH      = interpol(H_media, [0,1], [0,1,2])
                ;DD      = interpol(D_media, [0,1], [0,1,2])
                ;DZ      = interpol(Z_media, [0,1], [0,1,2])
                ;DF      = interpol(F_media, [0,1], [0,1,2])
                
                ;v       = [N_days0/2.,N_days0+N_days1/2.]
                ;w       = [N_days0+N_days1+1.*N_days2]
                ;print, v
                ;print, w
                ;DH      = interpol(H_media, v, w)
                ;DD      = interpol(D_media, v, w)
                ;DZ      = interpol(Z_media, v, w)
                ;DF      = interpol(F_media, v, w)

                ;qday[*].H = qday[*].H - H_media[1] + DH[2]
                ;qday[*].D = qday[*].D - D_media[1] + DD[2]
                ;qday[*].Z = qday[*].Z - Z_media[1] + DZ[2]
                ;qday[*].F = qday[*].F - F_media[1] + DF[2]

                ;qday[*].H = qday[*].H - H_media[1] + DH[0]
                ;qday[*].D = qday[*].D - D_media[1] + DD[0]
                ;qday[*].Z = qday[*].Z - Z_media[1] + DZ[0]
                ;qday[*].F = qday[*].F - F_media[1] + DF[0]

        ;oplot, qday[*].H, linestyle=1

        ;ENDIF

        ;print, qday0[0].year, qday0[0].month, qday0[0].day    
        ;print, qday[0].year, qday[0].month, qday[0].day    


        ;plot, qday[*].H , MAX_VALUE=999990., YRANGE=[27100.,27400.], YStyle=1
        ;oplot, qday0[*].H, linestyle=1
        ;oplot, qday1[*].H, linestyle=2
        ;plot, qday1[*].H-qday0[*].H
        ;print, median(qday1[*].H-qday0[*].H)
        ;plot, qday[*].H , MAX_VALUE=999990., YRANGE=[27370.,27400.], XRANGE=[-10.,1450.], XStyle=1
;print, mean(qday[*].H)

        ;plot, SMOOTH(qday[*].H,60) , MAX_VALUE=999999., YRANGE=[27300.,27400.], Ystyle=1, XRANGE=[900.,1100.]
        ;for i=900, 1000 DO print, i, qday[i].H

RETURN, qday

END




