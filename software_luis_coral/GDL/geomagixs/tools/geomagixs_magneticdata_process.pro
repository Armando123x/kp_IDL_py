;+
; NAME:
;       kmex_update_processdata.pro
;
;
; PURPOSE:
;
;       make magnetic datafiles from Mexican Magnetic Service fixed daily data-files
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Insituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro, Morelia, Michoacan
;       piter.cr@gmail.com
;       Mexico, 28.iii.mmxvii
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       kmex_make_magneticdata, initial_date, final_date [, station='string', /QUIET]
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
;       resolution                                     : resolution of data files. the available resolutions are RESOLUTION=1 [minutes]
;
; DEPENDENCIAS:
;       omniweb_setup                                  : initilizes the directory tree
;
; ARCHIVOS ANALIZADOS:
;       teoYYYYMMDDrmin.min
;
; ARCHIVOS DE SALIDA:
;
; HISTORIA:
;       28 march 2017   Begins development.
;       18 may 2017     Added the rutine to cancle pikes
;       12 june 2017    Modifying rutine of pikes with medians and standard deviations
;-




;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
FUNCTION getting_magneticdata, initial, STATION=station, QUIET=quiet

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
                file_name = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.clean.dat'

                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                IF opened_files NE N_ELEMENTS(file_name) THEN MESSAGE, file_name+' not found.'
        
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

;2022-07-07 23:18:00.000 188      329.23  27250.80  29514.90  40171.40
;  I4XI2XI2XI2XI2XXXXXXXXXXXXXXXXF7     XF9       XF9       XF9       

        ;tempvar = SIZE(TEMPORARY(resulting_data)) ; liberar memoria de la info no usada
        return, resulting_data


END


;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
PRO making_processeddatafiles, initial, STATION=station, $
                                        QUIET=quiet, $
                                        REAL_TIME=real_time, $
                                        TENDENCY_DAYS = tendency_days, $
                                        STATISTIC_QD=statistic_qd

        On_error, 2
        COMPILE_OPT idl2, hidden
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        

;##############################################################################
; depuring inputs
;##############################################################################


;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = initial[0]
        initial_month  = initial[1]
        initial_day    = initial[2]


;##############################################################################
; reading data files
;##############################################################################
        data_file_name = ''
        kmex_file_name = ''
        string_date    = ''
        ;print, JULDAY(initial_month, initial_day, initial_year), (kmex_days_for_median+1)
        minutes_per_day = 24*60
        N_days         = 5
        IF N_ELEMENTS(tendency_days) EQ 1 THEN $
                IF tendency_days GE 1 AND tendency_days LE 15 THEN N_days = tendency_days

        kmex_file_name = STRARR(N_days)

        DataStruct  =  { year : 0, month : 0, day : 0, $
                         hour : 0, minute : 0, $
                         D : 9999., H : 999999., Z : 999999., F : 999999. }
                         

        total_magnetic_data  = REPLICATE(DataStruct, minutes_per_day*N_days)
        
        magnetic_data        = REPLICATE(DataStruct, minutes_per_day)
        
        total_time           = FINDGEN(minutes_per_day*N_days)
        
        
        IF not keyword_set(quiet) THEN BEGIN
                print, initial_year, initial_month, initial_day, FORMAT='("        Gathering data for ",I04,"/",I02,"/",I02,":")'
                IF keyword_set(real_time) THEN print, FORMAT='("                      EARLY MODE: using data from previous month.")' $
                                          ELSE print, FORMAT='("                      FINAL MODE: using data from working month.")'
        ENDIF

        FOR j = N_days-1, 0, -1 DO BEGIN
                CALDAT, JULDAY(initial_month, initial_day-j, initial_year), tmp_M, tmp_D, tmp_Y
                string_date                 = string(tmp_Y, tmp_M, tmp_D, FORMAT='(I4,I02,I02)')
                kmex_file_name              = gms[system.gms].code+'_'+string_date+'.clean.dat'
                exist_kmex_file             = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+kmex_file_name)
                
                IF exist_kmex_file THEN BEGIN
                        ;magnetic_data_tmp = geomagixs_get_magneticday([tmp_Y, tmp_M, tmp_D], STATION=station, QUIET=quiet, /FORCE_ALL)
                        magnetic_data_tmp = getting_magneticdata([tmp_Y, tmp_M, tmp_D], STATION=station, QUIET=quiet)
                
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].D = magnetic_data_tmp[*].D
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].H = magnetic_data_tmp[*].H
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].Z = magnetic_data_tmp[*].Z
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].F = magnetic_data_tmp[*].F
                
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].year   = magnetic_data_tmp[*].year
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].month  = magnetic_data_tmp[*].month
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].day    = magnetic_data_tmp[*].day
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].hour   = magnetic_data_tmp[*].hour
                        total_magnetic_data[minutes_per_day*(N_days-1-j):minutes_per_day*(N_days-j)-1].minute = magnetic_data_tmp[*].minute
                ENDIF ELSE BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Impossible to read data file ', A,'. ')", kmex_file_name
                                PRINT, FORMAT="('                Missing file directories or permissions conflict.')"
                        ENDIF
                        error.value[1] += 1
                        error.log      += 'Data file '+kmex_file_name+' not found, make manual UPDATE. Impossible to continue. '
                        RETURN
                ENDELSE

        ENDFOR
        ;FOR j = 0, 24*60-1 DO $
        ;        print, total_magnetic_data[minutes_per_day*(N_days-1)+j].F
        
        D_D = FLTARR(minutes_per_day)+9999.00
        D_H = FLTARR(minutes_per_day)+999999.00
        D_Z = D_H
        D_F = D_H
        D_N = D_H
        magnetic_data_N = D_H
        
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
        arc_secs_2rads = !Pi / (60.*180.)
        
        qday_data     = geomagixs_quietday_get(initial, STATION=station, QUIET=quiet, REAL_TIME=real_time)
        ;qd_median_D   = MEDIAN(qday_data[*].D)
        ;qd_stddev_D    = STDDEV(qday_data[*].D)
        valid_days    = WHERE(total_magnetic_data[*].H LT 999990.00, days_COUNT )
        valid_minutes = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].H LT 999990.00, COUNT ); AND ABS(qday_data[*].D-qd_median_D) LT 1.5*qd_stddev_D, COUNT )
        
;print, count, days_COUNT
IF COUNT GE 2 THEN BEGIN
        IF days_COUNT GT minutes_per_day*N_days*0.6 THEN BEGIN
        ;#######################################################################
        ; D process ############################################################
        ;#######################################################################
                result = POLY_FIT( total_time[valid_days], total_magnetic_data[valid_days].D, 2, STATUS=status_result, YFIT=tendency )
                        
                IF status_result GT 0 THEN BEGIN
                        status_result = 0
                        result = LINFIT( total_time[valid_days], total_magnetic_data[valid_days].D, YFIT=tendency, SIGMA=delta )
                                
                        IF result[1]/delta[1] LE 0.5 THEN status_result = 1
                ENDIF

                
                IF status_result EQ 0 THEN BEGIN
                        total_tendency                     = total_magnetic_data[*].D
                        total_tendency[valid_days]         = tendency
                        total_magnetic_data[valid_days].D -= tendency
                        ;valid_minutes                      = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].H LT 999990.00, COUNT )
                        ;print, valid_minutes
                        magnetic_data[valid_minutes].D = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].D + total_tendency[minutes_per_day*(N_days-1)+valid_minutes]
                        D_median[valid_minutes]        = qday_data[valid_minutes].D - MEDIAN(qday_data[valid_minutes].D) + total_tendency[minutes_per_day*(N_days-1)+valid_minutes]
                ENDIF ELSE BEGIN
                        ;valid_minutes                  = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].H LT 999990.00, COUNT )
                        
                        magnetic_data[valid_minutes].D = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].D
                        D_median[valid_minutes]        = qday_data[valid_minutes].D - MEDIAN(qday_data[valid_minutes].D) + MEDIAN(magnetic_data[valid_minutes].D)
                ENDELSE
                D_sigma[valid_minutes]         = qday_data[valid_minutes].dD
                D_D[valid_minutes]             = (magnetic_data[valid_minutes].D - D_median[valid_minutes])

        ;#######################################################################
        ; H process ############################################################
        ;#######################################################################
                result = POLY_FIT( total_time[valid_days], total_magnetic_data[valid_days].H, 2, STATUS=status_result, YFIT=tendency )
                        
                IF status_result GT 0 THEN BEGIN
                        status_result = 0
                        result = LINFIT( total_time[valid_days], total_magnetic_data[valid_days].H, YFIT=tendency, SIGMA=delta )
                                
                        IF result[1]/delta[1] LE 0.5 THEN status_result = 1
                ENDIF
                
                IF status_result EQ 0 THEN BEGIN
                        total_tendency                     = total_magnetic_data[*].H
                        total_tendency[valid_days]         = tendency
                        total_magnetic_data[valid_days].H -= tendency
                        valid_minutes                      = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].H LT 999990.00, COUNT )
                        
                        magnetic_data[valid_minutes].H = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].H + total_tendency[minutes_per_day*(N_days-1)+valid_minutes]
                        H_median[valid_minutes]        = qday_data[valid_minutes].H - MEDIAN(qday_data[valid_minutes].H) + total_tendency[minutes_per_day*(N_days-1)+valid_minutes]
                ENDIF ELSE BEGIN
                        valid_minutes                  = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].H LT 999990.00, COUNT )
                        
                        magnetic_data[valid_minutes].H = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].H
                        H_median[valid_minutes]        = qday_data[valid_minutes].H - MEDIAN(qday_data[valid_minutes].H) + MEDIAN(magnetic_data[valid_minutes].H)
                ENDELSE
                H_sigma[valid_minutes]         = qday_data[valid_minutes].dH
                D_H[valid_minutes]             = (magnetic_data[valid_minutes].H - H_median[valid_minutes])
;for j=0, N_ELEMENTS(valid_minutes)-1 DO $
;        print, magnetic_data[valid_minutes[j]].H, H_median[valid_minutes[j]], qday_data[valid_minutes[j]].H,qday_data[valid_minutes[j]].dH
        ;#######################################################################
        ; Z process ############################################################
        ;#######################################################################
                result = POLY_FIT( total_time[valid_days], total_magnetic_data[valid_days].Z, 2, STATUS=status_result, YFIT=tendency )
                        
                IF status_result GT 0 THEN BEGIN
                        status_result = 0
                        result = LINFIT( total_time[valid_days], total_magnetic_data[valid_days].Z, YFIT=tendency, SIGMA=delta )
                                
                        IF result[1]/delta[1] LE 0.5 THEN status_result = 1
                ENDIF
                
                IF status_result EQ 0 THEN BEGIN
                        total_tendency                     = total_magnetic_data[*].Z
                        total_tendency[valid_days]         = tendency
                        total_magnetic_data[valid_days].Z -= tendency
                        valid_minutes                      = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].Z LT 999990.00, COUNT )
                        
                        magnetic_data[valid_minutes].Z = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].Z + total_tendency[minutes_per_day*(N_days-1)+valid_minutes]
                        Z_median[valid_minutes]        = qday_data[valid_minutes].Z - MEDIAN(qday_data[valid_minutes].Z) + total_tendency[minutes_per_day*(N_days-1)+valid_minutes]
                ENDIF ELSE BEGIN
                        valid_minutes                  = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].H LT 999990.00, COUNT )
                        
                        magnetic_data[valid_minutes].Z = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].Z
                        Z_median[valid_minutes]        = qday_data[valid_minutes].Z - MEDIAN(qday_data[valid_minutes].Z) + MEDIAN(magnetic_data[valid_minutes].Z)
                ENDELSE
                Z_sigma[valid_minutes]         = qday_data[valid_minutes].dZ
                D_Z[valid_minutes]             = (magnetic_data[valid_minutes].Z - Z_median[valid_minutes])

        ;#######################################################################
        ; F process ############################################################
        ;#######################################################################
                result = POLY_FIT( total_time[valid_days], total_magnetic_data[valid_days].F, 2, STATUS=status_result, YFIT=tendency )
                        
                IF status_result GT 0 THEN BEGIN
                        status_result = 0
                        result = LINFIT( total_time[valid_days], total_magnetic_data[valid_days].F, YFIT=tendency, SIGMA=delta )
                                
                        IF result[1]/delta[1] LE 0.5 THEN status_result = 1
                ENDIF
                
                IF status_result EQ 0 THEN BEGIN
                        total_tendency                     = total_magnetic_data[*].F
                        total_tendency[valid_days]         = tendency
                        total_magnetic_data[valid_days].F -= tendency
                        valid_minutes                      = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].F LT 999990.00, COUNT )
                        
                        magnetic_data[valid_minutes].F = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].F + total_tendency[minutes_per_day*(N_days-1)+valid_minutes]
                        F_median[valid_minutes]        = qday_data[valid_minutes].F - MEDIAN(qday_data[valid_minutes].F) + total_tendency[minutes_per_day*(N_days-1)+valid_minutes]
                ENDIF ELSE BEGIN
                        valid_minutes                  = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].F LT 999990.00, COUNT )
                        
                        magnetic_data[valid_minutes].F = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].F
                        F_median[valid_minutes]        = qday_data[valid_minutes].F - MEDIAN(qday_data[valid_minutes].F) + MEDIAN(magnetic_data[valid_minutes].F)
                ENDELSE
                F_sigma[valid_minutes]         = qday_data[valid_minutes].dF
                D_F[valid_minutes]             = (magnetic_data[valid_minutes].F - F_median[valid_minutes])




        ;#######################################################################
        ; N process ############################################################
        ;#######################################################################
                ;valid_minutes                  = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].F LT 999990.00, COUNT )
                        
                N_median[valid_minutes] = H_median[valid_minutes]*TAN(D_median[valid_minutes]*arc_secs_2rads)
                N_sigma[valid_minutes]  = H_median[valid_minutes]*D_sigma[valid_minutes]*arc_secs_2rads/(COS(D_median[valid_minutes]*arc_secs_2rads))^2 + H_sigma[valid_minutes]*TAN(D_median[valid_minutes]*arc_secs_2rads)

                D_N[valid_minutes]             = magnetic_data[valid_minutes].H*TAN(magnetic_data[valid_minutes].D*arc_secs_2rads) - N_median[valid_minutes]
        ENDIF ELSE BEGIN
                ;valid_minutes                  = WHERE(total_magnetic_data[minutes_per_day*(N_days-1):minutes_per_day*(N_days)-1].H LT 999990.00, COUNT )
                
        ;#######################################################################
        ; D process ############################################################
        ;#######################################################################
                magnetic_data[valid_minutes].D = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].D
                D_median[valid_minutes]        = qday_data[valid_minutes].D - MEDIAN(qday_data[valid_minutes].D) + MEDIAN(magnetic_data[valid_minutes].D)
                D_sigma[valid_minutes]         = qday_data[valid_minutes].dD
                D_D[valid_minutes]             = (magnetic_data[valid_minutes].D - D_median[valid_minutes])
                
        ;#######################################################################
        ; H process ############################################################
        ;#######################################################################
                magnetic_data[valid_minutes].H = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].H
                H_median[valid_minutes]        = qday_data[valid_minutes].H - MEDIAN(qday_data[valid_minutes].H) + MEDIAN(magnetic_data[valid_minutes].H)
                H_sigma[valid_minutes]         = qday_data[valid_minutes].dH
                D_H[valid_minutes]             = (magnetic_data[valid_minutes].H - H_median[valid_minutes])

        ;#######################################################################
        ; Z process ############################################################
        ;#######################################################################
                magnetic_data[valid_minutes].Z = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].Z
                Z_median[valid_minutes]        = qday_data[valid_minutes].Z - MEDIAN(qday_data[valid_minutes].Z) + MEDIAN(magnetic_data[valid_minutes].Z)
                Z_sigma[valid_minutes]         = qday_data[valid_minutes].dZ
                D_Z[valid_minutes]             = (magnetic_data[valid_minutes].Z - Z_median[valid_minutes])

        ;#######################################################################
        ; F process ############################################################
        ;#######################################################################
                magnetic_data[valid_minutes].F = total_magnetic_data[minutes_per_day*(N_days-1)+valid_minutes].F
                F_median[valid_minutes]        = qday_data[valid_minutes].F - MEDIAN(qday_data[valid_minutes].F) + MEDIAN(magnetic_data[valid_minutes].F)
                F_sigma[valid_minutes]         = qday_data[valid_minutes].dF
                D_F[valid_minutes]             = (magnetic_data[valid_minutes].F - F_median[valid_minutes])

        ;#######################################################################
        ; N process ############################################################
        ;#######################################################################
                N_median[valid_minutes] = H_median[valid_minutes]*TAN(D_median[valid_minutes]*arc_secs_2rads)
                N_sigma[valid_minutes]  = H_median[valid_minutes]*D_sigma[valid_minutes]*arc_secs_2rads/(COS(D_median[valid_minutes]*arc_secs_2rads))^2 + H_sigma[valid_minutes]*TAN(D_median[valid_minutes]*arc_secs_2rads)

                D_N[valid_minutes]      = magnetic_data[valid_minutes].H*TAN(magnetic_data[valid_minutes].D*arc_secs_2rads) - N_median[valid_minutes]
        ENDELSE


        ;bad_indexes = where(flag_for_indexes EQ 1)
        
        ;#######################################################################
        ; COMMENT:
        ; \Delta H spontaneously variates, specilly with geomagnetic perturbations.
        ; For these cases, the changes of \Delta H could be fast for very intense
        ; events; however, such variations are visible during periods of hours.
        ; Thus, variations of few minutes (say 5 min.) are more likely an artifact
        ; from the instrument or due to the data deliverer system.
        
        ;##############################################################################
        ; data for criteria
        ;##############################################################################
        sigma_criteria    = 4.;1.5;20.   ; number of standard deviations a data needs to surprise
                                      ; to be taken as an invalid data
        number_of_minutes = 5        ; half of the minutes used to calculate the median
        
        H_max_jump = 800.             ; upper limit variations on H component
        ;no_gaps = where(D_H LT 999999.00)
        no_gaps = where(magnetic_data[*].H LT 999990.00, elements_of_no_gaps); AND ABS(qday_data[*].D-qd_median_D) LT 1.5*qd_stddev_D, elements_of_no_gaps)
        ;number_of_gaps = N_ELEMENTS(where(D_H GE 999999.00))
        tmp = N_ELEMENTS(where(magnetic_data[*].H GE 999990.00, number_of_gaps));  ABS(qday_data[*].D-qd_median_D) GE 1.5*qd_stddev_D, number_of_gaps))
;print, number_of_gaps        ;gaps    = where(D_values GE 9999.00)
        ;print, number_of_gaps
        ;number_of_minutes = (N_ELEMENTS(no_gaps)/4 GT number_of_minutes) ? number_of_minutes : N_ELEMENTS(no_gaps)/4
        H_median_value    = 0   ; variable to store the calculated median
        H_sigma_value     = 0   ; variable to store the calculated standard deviation

        ;elements_of_no_gaps = N_ELEMENTS(no_gaps)
        boolean_flag        = INTARR(elements_of_no_gaps)+1

        datos_validos = WHERE(F_sigma LT 999990.00, datos_validos_count)
        IF datos_validos_count GT 1 THEN mean_F_sigma = MEAN( F_sigma[datos_validos] ) ELSE mean_F_sigma=0.
        ;print, mean_F_sigma
        ;print, number_of_gaps;, minutes_per_day, N_ELEMENTS(D_D)
        IF number_of_gaps NE minutes_per_day THEN BEGIN
                FOR i=0, elements_of_no_gaps-1 DO BEGIN
                        ;print, no_gaps[i], D_H[no_gaps[i]]
                        IF i LT number_of_minutes AND i+number_of_minutes LE elements_of_no_gaps-1 THEN BEGIN
                                IF i NE 0 THEN BEGIN
                                        H_median_value = median( [D_H[no_gaps[0:i-1]], D_H[no_gaps[i+1:i+1+number_of_minutes-1]]] )
                                        H_sigma_value  = STDDEV( [D_H[no_gaps[0:i-1]], D_H[no_gaps[i+1:i+1+number_of_minutes-1]]] )
                                ENDIF ELSE BEGIN
                                        H_median_value = median( D_H[no_gaps[i+1:i+1+number_of_minutes-1]] )
                                        H_sigma_value  = STDDEV( D_H[no_gaps[i+1:i+1+number_of_minutes-1]] )
                                ENDELSE
                        ENDIF
                        
                        IF i LT number_of_minutes AND i+number_of_minutes GT elements_of_no_gaps-1 THEN BEGIN
                                IF i NE 0 AND i NE elements_of_no_gaps-1 THEN BEGIN
                                        H_median_value = median( [D_H[no_gaps[0:i-1]], D_H[no_gaps[i+1:elements_of_no_gaps-1]]] )
                                        H_sigma_value  = STDDEV( [D_H[no_gaps[0:i-1]], D_H[no_gaps[i+1:elements_of_no_gaps-1]]] )
                                ENDIF
                                IF i EQ 0 AND i NE elements_of_no_gaps-1 THEN BEGIN
                                        H_median_value = median( D_H[no_gaps[i+1:elements_of_no_gaps-1]] )
                                        H_sigma_value  = STDDEV( D_H[no_gaps[i+1:elements_of_no_gaps-1]] )
                                ENDIF
                                IF i NE 0 AND i EQ elements_of_no_gaps-1 THEN BEGIN
                                        H_median_value = median( D_H[no_gaps[0:elements_of_no_gaps-2]] )
                                        H_sigma_value  = STDDEV( D_H[no_gaps[0:elements_of_no_gaps-2]] )
                                ENDIF
                        ENDIF
                        
                        IF i GE number_of_minutes AND i+number_of_minutes LE elements_of_no_gaps-1 THEN BEGIN
                                H_median_value = median( [D_H[no_gaps[i-number_of_minutes:i-1]], D_H[no_gaps[i+1:i+number_of_minutes]]] )
                                H_sigma_value  = STDDEV( [D_H[no_gaps[i-number_of_minutes:i-1]], D_H[no_gaps[i+1:i+number_of_minutes]]] )
                                ;if no_gaps[i] EQ 1161 then begin
                                ;        print, [no_gaps[i-number_of_minutes:i-1], no_gaps[i+1:i+number_of_minutes]]
                                ;        print, [D_H[no_gaps[i-number_of_minutes:i-1]], D_H[no_gaps[i+1:i+number_of_minutes]]]
                                ;        print, median( [D_H[no_gaps[i-number_of_minutes:i-1]], D_H[no_gaps[i+1:i+number_of_minutes]]] ), H_median_value
                                ;        print, STDDEV( [D_H[no_gaps[i-number_of_minutes:i-1]], D_H[no_gaps[i+1:i+number_of_minutes]]] ), H_sigma_value
                                ;endif
                        ENDIF
                        
                        IF i GE number_of_minutes AND i+number_of_minutes GT elements_of_no_gaps-1 THEN BEGIN
                                IF i EQ elements_of_no_gaps-1 THEN BEGIN
                                        H_median_value = median( D_H[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]] )
                                        H_sigma_value  = STDDEV( D_H[no_gaps[i-number_of_minutes:elements_of_no_gaps-2]] )
                                ENDIF ELSE BEGIN
                                        H_median_value = median( [D_H[no_gaps[i-number_of_minutes:i-1]], D_H[no_gaps[i+1:elements_of_no_gaps-1]]] )
                                        H_sigma_value  = STDDEV( [D_H[no_gaps[i-number_of_minutes:i-1]], D_H[no_gaps[i+1:elements_of_no_gaps-1]]] )
                                ENDELSE
                        ENDIF
                        
                        ;print, i, N_ELEMENTS(no_gaps), N_ELEMENTS(D_H), no_gaps[i]
                        ;print, i+1, D_H[no_gaps[i]], H_median_value, H_sigma_value
                        
                        ;IF no_gaps[i] EQ 1161 THEN begin
                        ;        print, ''
                        ;        print, no_gaps[i], D_H[no_gaps[i]], H_median_value, H_sigma_value
                        ;        print, D_H[no_gaps[i-5:i-1]],D_H[no_gaps[i+1:i+5]]
                        ;ENDIF
                        
                        ;IF (ABS(D_H[no_gaps[i]]-H_median_value) GT sigma_criteria*H_sigma_value) THEN BEGIN
                        ;IF (ABS(D_H[no_gaps[i]]-H_median_value) GT sigma_criteria*H_sigma_value) OR (D_F[no_gaps[i]] GT sigma_criteria*mean_F_sigma) OR (ABS(D_H[no_gaps[i]]) GT H_max_jump) THEN BEGIN
                        IF (ABS(D_H[no_gaps[i]]-H_median_value) GT sigma_criteria*H_sigma_value) OR (ABS(D_H[no_gaps[i]]) GT H_max_jump) THEN BEGIN
                                boolean_flag[i] = 0
                                ;print, D_H[no_gaps[i]], H_median_value, D_H[no_gaps[i]]-H_median_value, H_sigma_value
                                ;print, D_H[no_gaps[i]], H_max_jump
                        ENDIF
                        
                        ;print, no_gaps[i], D_H[no_gaps[i]]

                        H_median_value    = 0
                        H_sigma_value     = 0
                ENDFOR
        ENDIF
 
        IF elements_of_no_gaps GT 1 THEN BEGIN
                D_D[no_gaps] = (boolean_flag EQ 1)*D_D[no_gaps] + (boolean_flag NE 1)*9999.00
                D_H[no_gaps] = (boolean_flag EQ 1)*D_H[no_gaps] + (boolean_flag NE 1)*999999.00
                D_Z[no_gaps] = (boolean_flag EQ 1)*D_Z[no_gaps] + (boolean_flag NE 1)*999999.00
                D_F[no_gaps] = (boolean_flag EQ 1)*D_F[no_gaps] + (boolean_flag NE 1)*999999.00
                D_N[no_gaps] = (boolean_flag EQ 1)*D_N[no_gaps] + (boolean_flag NE 1)*999999.00
        ENDIF

ENDIF

        test_index = WHERE(D_D[*] LT 9990.0 AND D_N[*] LT 999990.0, test_count)
        IF test_count GT 0 THEN BEGIN
                ;print, test_count
                ;dn_median  = MEDIAN(D_N[test_index])
                ;dn_stddev  = STDDEV(D_N[test_index])
                ;print, dn_median, dn_stddev
                
                dd_median  = MEDIAN(D_D[test_index])
                ;dd_stddev  = STDDEV(D_D[test_index])
                ;print, dd_median, dd_stddev
                
                
                bad_index  = WHERE(D_D[*] GT 9990.0 OR D_N[*] GT 999990.0 OR $
                                   ;ABS(qday_data[*].D-qd_median_D) GE 1.5*qd_stddev_D OR $
                                   D_sigma[*] GT 9990., $; OR $
                                   ;ABS(D_D[*] - dd_median) GE  30.*dd_median OR $;1.5*dd_stddev OR ABS(D_N[*] - dn_median) GE 1.5*dn_stddev OR $
                                   ;ABS(qday_data[*].D-qd_median_D) GE 1.5*qd_stddev_D, $
                                   bad_count)
        ENDIF ELSE bad_index  = WHERE(D_D[*] GT 9990.0 OR D_N[*] GT 999990.0 OR D_sigma[*] GT 9990., bad_count) ;OR ABS(qday_data[*].D-qd_median_D) GE 1.5*qd_stddev_D, bad_count)
        IF bad_count GT 0 THEN BEGIN
        ;print, bad_count
                D_sigma[bad_index] = 9999.0
                D_D[bad_index]     = 9999.0
                N_sigma[bad_index] = 999999.0
                D_N[bad_index]     = 999999.0
        ENDIF

        data_file = STRARR(minutes_per_day)

        FOR i=0, minutes_per_day-1 DO BEGIN
                ;print, i mod 60, i/60
                
                data_file[i] = string(i+1, i/60, i mod 60, $
                                       magnetic_data[i].D,magnetic_data[i].H,magnetic_data[i].Z,magnetic_data[i].F, $
                                       D_median[i],H_median[i],Z_median[i],F_median[i], N_median[i], $
                                       D_sigma[i],H_sigma[i],Z_sigma[i],F_sigma[i], N_sigma[i], $
                                       D_D[i], D_H[i], D_Z[i], D_F[i], D_N[i], $
                                       FORMAT='(' $
                                       +'I04,X,I02,":",I02, ' $
                                       +'2X, F7.2, 3(X, F9.2), ' $
                                       +'2X, F7.2, 4(X, F9.2), ' $
                                       +'2X, F7.2, 4(X, F9.2), ' $
                                       +'2X, F7.2, 4(X, F9.2) ' $
                                       +')')
                
                ;j_inicio=j

                ;ENDFOR
                ;print, i, '  ', data_file[i]
        ENDFOR



        ;##############################################################################
        ; differences section
        ;##############################################################################
        data_per_day = 24/3
        minutes_in_3hours = 60*3
        differences_file=STRARR(data_per_day)
        
        max_D = FLTARR(data_per_day)+9999.00
        max_H = FLTARR(data_per_day)+999999.00
        max_Z = max_H
        max_F = max_H
        max_N = max_H
        min_D = FLTARR(data_per_day)+9999.00
        min_H = FLTARR(data_per_day)+999999.00
        min_Z = min_H
        min_F = min_H
        min_N = min_H
        delta_D = FLTARR(data_per_day)+9999.00
        delta_H = FLTARR(data_per_day)+999999.00
        delta_Z = delta_H
        delta_F = delta_H
        delta_N = delta_H
        sigma_D = FLTARR(data_per_day)+9999.00
        sigma_H = FLTARR(data_per_day)+999999.00
        sigma_Z = max_H
        sigma_F = max_H
        sigma_N = max_H

        FOR i =0, data_per_day-1 DO BEGIN
                ;print, N_ELEMENTS(magnetic_data[*].H), N_ELEMENTS(D_H[*])
                ;valid_data = WHERE(D_D[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1] LT 9999.00)+i*minutes_in_3hours

                valid_data = WHERE(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1].D LT 9990.00 AND D_D[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1] LT 9990.00, valid_count)+i*minutes_in_3hours
                IF valid_count GT 0 THEN BEGIN
                        tmp            = D_D[valid_data]
                        valid_data_tmp = WHERE(D_D[valid_data] LT 9990.0, tmp_count)
                        
                        ;tmp        = D_D[valid_data]
                        max_D[i]   = MAX( tmp[valid_data_tmp] )
                        min_D[i]   = MIN( tmp[valid_data_tmp] )
                        delta_D[i] = (max_D[i] LT 9999.0 AND min_D[i] LT 9999.0) ? ABS(max_D[i]-min_D[i]) : 9999.00
                        sigma_D[i] = (delta_D[i] LT 9999.0) AND tmp_count GT 2 ? STDDEV( tmp[valid_data_tmp] ) : 9999.0
                ENDIF
                
                valid_data = WHERE(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1].H LT 999990.00 AND D_H[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1] LT 999990.00, valid_count)+i*minutes_in_3hours
                IF valid_count GT 0 THEN BEGIN
                        tmp            = D_H[valid_data]
                        valid_data_tmp = WHERE(D_H[valid_data] LT 999990.0, tmp_count)
                        
                        ;tmp        = D_H[valid_data]
                        max_H[i]   = MAX( tmp[valid_data_tmp] )
                        min_H[i]   = MIN( tmp[valid_data_tmp] )
                        delta_H[i] = (max_H[i] LT 999999.0 AND min_H[i] LT 999999.0) ? ABS(max_H[i]-min_H[i]) : 999999.00
                        sigma_H[i] = (delta_H[i] LT 999999.0) AND tmp_count GT 2 ? STDDEV( tmp[valid_data_tmp] ) : 999999.0
                ENDIF
                
                valid_data = WHERE(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1].Z LT 999990.00 AND D_Z[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1] LT 999990.00, valid_count)+i*minutes_in_3hours
                IF valid_count GT 0 THEN BEGIN
                        tmp            = D_Z[valid_data]
                        valid_data_tmp = WHERE(D_Z[valid_data] LT 999990.0, tmp_count)
                        
                        ;tmp        = D_Z[valid_data]
                        max_Z[i]   = MAX( tmp[valid_data_tmp] )
                        min_Z[i]   = MIN( tmp[valid_data_tmp] )
                        delta_Z[i] = (max_Z[i] LT 999999.0 AND min_Z[i] LT 999999.0) ? ABS(max_Z[i]-min_Z[i]) : 999999.00
                        sigma_Z[i] = (delta_Z[i] LT 999999.0) AND tmp_count GT 2 ? STDDEV( tmp[valid_data_tmp] ) : 999999.0
                ENDIF
                
                valid_data = WHERE(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1].F LT 999990.00 AND D_F[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1] LT 999990.00, valid_count)+i*minutes_in_3hours
                IF valid_count GT 0 THEN BEGIN
                        tmp            = D_F[valid_data]
                        valid_data_tmp = WHERE(D_F[valid_data] LT 999990.0, tmp_count)
                        
                        ;tmp        = D_F[valid_data]
                        max_F[i]   = MAX( tmp[valid_data_tmp] )
                        min_F[i]   = MIN( tmp[valid_data_tmp] )
                        delta_F[i] = (max_F[i] LT 999999.0 AND min_F[i] LT 999999.0) ? ABS(max_F[i]-min_F[i]) : 999999.00
                        sigma_F[i] = (delta_F[i] LT 999999.0) AND tmp_count GT 2 ? STDDEV( tmp[valid_data_tmp] ) : 999999.0
                ENDIF
                
                valid_data = WHERE(magnetic_data[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1].D LT 9990.00 AND D_N[i*minutes_in_3hours:(i+1)*minutes_in_3hours-1] LT 999990.00, valid_count)+i*minutes_in_3hours
                IF valid_count GT 0 THEN BEGIN
                        tmp            = D_N[valid_data]
                        valid_data_tmp = WHERE(D_N[valid_data] LT 999990.0, tmp_count)
                        
                        ;tmp        = D_N[valid_data]
                        max_N[i]   = MAX( tmp[valid_data_tmp] )
                        min_N[i]   = MIN( tmp[valid_data_tmp] )
                        delta_N[i] = (max_N[i] LT 999999.0 AND min_N[i] LT 999999.0) ? ABS(max_N[i]-min_N[i]) : 999999.00
                        sigma_N[i] = (delta_N[i] LT 999999.0) AND tmp_count GT 2 ? STDDEV( tmp[valid_data_tmp] ) : 999999.0
                ENDIF
GOTO, jump
                IF N_ELEMENTS(valid_data) GT 1 THEN BEGIN
                        IF N_ELEMENTS(WHERE(D_H[valid_data] LT 999999.0)) GT 1 THEN BEGIN
                                tmp            = D_H[valid_data]
                                valid_data_tmp = WHERE(D_H[valid_data] LT 999999.0)
                                ;print, STDDEV(tmp[valid_data_tmp])
                                
                                tmp        = D_D[valid_data]
                                max_D[i]   = MAX( tmp[valid_data_tmp] )
                                min_D[i]   = MIN( tmp[valid_data_tmp] )
                                delta_D[i] = (max_D[i] LT 9999.0 AND min_D[i] LT 9999.0) ? ABS(max_D[i]-min_D[i]) : 9999.00
                                sigma_D[i] = (delta_D[i] LT 9999.0) ? STDDEV( tmp[valid_data_tmp] ) : 9999.0
                                ;sigma_D[i] = (sigma_D[i] LT 100.) ? sigma_D[i] : 9999.00
        
                                tmp        = D_H[valid_data]
                                max_H[i]   = MAX( tmp[valid_data_tmp] )
                                min_H[i]   = MIN( tmp[valid_data_tmp] )
                                delta_H[i] = ABS(max_H[i]-min_H[i])
                                sigma_H[i] = STDDEV( tmp[valid_data_tmp] )
                                sigma_H[i] = (sigma_H[i] LT 1000.) ? sigma_H[i] : 999999.00
                                ;print, i+1, sigma_H[i]
                                ;print, MAX( D_H[valid_data] )
                                ;print, MIN( D_H[valid_data] )
        
                                tmp        = D_Z[valid_data]
                                max_Z[i]   = MAX( tmp[valid_data_tmp] )
                                min_Z[i]   = MIN( tmp[valid_data_tmp] )
                                delta_Z[i] = ABS(max_Z[i]-min_Z[i])
                                sigma_Z[i] = STDDEV( tmp[valid_data_tmp] )
                                sigma_Z[i] = (sigma_Z[i] LT 1000.) ? sigma_Z[i] : 999999.00
        
                                tmp        = D_F[valid_data]
                                max_F[i]   = MAX( tmp[valid_data_tmp] )
                                min_F[i]   = MIN( tmp[valid_data_tmp] )
                                delta_F[i] = ABS(max_F[i]-min_F[i])
                                sigma_F[i] = STDDEV( tmp[valid_data_tmp] )
                                sigma_F[i] = (sigma_F[i] LT 1000.) ? sigma_F[i] : 999999.00
        
                                tmp        = D_N[valid_data]
                                max_N[i]   = MAX( tmp[valid_data_tmp] )
                                min_N[i]   = MIN( tmp[valid_data_tmp] )
                                delta_N[i] = ABS(max_N[i]-min_N[i])
                                sigma_N[i] = STDDEV( tmp[valid_data_tmp] )
                                sigma_N[i] = (sigma_N[i] LT 1000.) ? sigma_N[i] : 999999.00
                                
                                ;print, max_H[i], min_H[i], delta_H[i], sigma_H[i]
                                ;print, ''
        
                        ENDIF
                ENDIF
jump:                
                
                
                
                
                ;print, max_H[i], min_H[i], delta_H[i], sigma_H[i], '##', max_F[i], min_F[i], delta_F[i], sigma_F[i]
                differences_file[i] = string(i*24/data_per_day,  $
                                       max_D[i], min_D[i], sigma_D[i], delta_D[i], $
                                       max_H[i], min_H[i], sigma_H[i], delta_H[i], $
                                       max_Z[i], min_Z[i], sigma_Z[i], delta_Z[i], $
                                       max_F[i], min_F[i], sigma_F[i], delta_F[i], $
                                       max_N[i], min_N[i], sigma_N[i], delta_N[i], $
                                       FORMAT='(' $
                                       +'I02,2X,' $
                                       +'4(X, F7.2), ' $
                                       +'4(X, F9.2), ' $
                                       +'4(X, F9.2), ' $
                                       +'4(X, F9.2), ' $
                                       +'4(X, F9.2)' $
                                       +')')
                ;print, differences_file[i]
        ENDFOR


        ;FOR i=0, minutes_per_day-1 DO BEGIN
                ;print, i mod 60, i/60

                ;final_file[i] = final_file[i] $
                ;                + string(max_D[i], min_D[i], max_H[i], min_H[i], max_Z[i], min_Z[i], max_F[i], min_F[i], max_N[i], min_N[i], $
                ;                       FORMAT='(' $
                ;                       +'X, 10(X, F9.2) ' $
                ;                       +')')
                
                ;j_inicio=j

                ;ENDFOR
                ;print, final_file[i]
        ;ENDFOR

;plot, delta_h, Yrange=[-500.,100.], Ystyle=1

;stop

;##############################################################################
; creating data files
;##############################################################################
        extention       = keyword_set(real_time) ? '.early' : '.final'
        ;output_file     = station_code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')
        output_file     = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')
        output_path     = system.processed_dir+gms[system.gms].name+'/'
        
        exist_dir       = FILE_TEST(output_path, /DIRECTORY)

        IF not(exist_dir) THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('Critical Error: Missing system directory ', A,'. ')", output_path
                        PRINT, FORMAT="('                Check out the directory tree.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'System directory '+output_path+' not found. Impossible to continue. '
                RETURN
        ENDIF 
        
        OPENW, lunn, output_path+output_file+'.data'+extention, /GET_LUN, ERROR=err
                IF err EQ 0 THEN BEGIN
                        FOR i=0, N_ELEMENTS(data_file)-1 DO PRINTF, lunn, data_file[i]
                ENDIF ELSE MESSAGE, 'Error while writing '+output_file+'.data'+extention+' output file.'
        CLOSE, lunn
        FREE_LUN, lunn


        IF not keyword_set(quiet) THEN print, '        Saving: '+output_path+output_file+'.data'+extention

        OPENW, lun, output_path+output_file+'.differences'+extention, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing '+output_file+'.differences'+extention+' output file.'
                FOR i=0, N_ELEMENTS(differences_file)-1 DO $
                        PRINTF, lun, differences_file[i]
        CLOSE, lun
        FREE_LUN, lun


        IF not keyword_set(quiet) THEN print, '        Saving: '+output_path+output_file+'.differences'+extention



        IF not keyword_set(quiet) THEN print, ''
RETURN
END








PRO making_processedplanetarydatafiles, initial, STATION=station, $
                                        QUIET=quiet, $
                                        REAL_TIME=real_time

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

        string_date    = string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')
                ;data_file_name[i] = station_code+'_'+string_date[i]+'.dat'
        kmex_file_name = gms[system.gms].code+'_'+string_date+'.clean.dat'
        extention      = ''

        
        exist_kmex_file = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+kmex_file_name)
        ;exist_data_file = FILE_TEST(kmex_magnetic_dir+station+'/1_min/'+data_file_name)

        IF exist_kmex_file THEN BEGIN

                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+kmex_file_name, COUNT=opened_files)
                IF opened_files EQ 0 AND not keyword_set(quiet) THEN MESSAGE, kmex_file_name+' file missed!'

                number_of_lines =FILE_LINES(file[0])
                tmp_data = STRARR(number_of_lines)
                
                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name
                        READF, lun, tmp_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun

                str_tmp       = {kp : 0, total_kp : 0, $
                                 Ap : 0, average_Ap : 0, $
                                 dst : 0, average_dst : 0 $
                                }
                
                index_data  = REPLICATE(str_tmp, number_of_lines)
                
                READS, tmp_data, index_data, FORMAT='(30X,I4,5x,I4,2x,I5,4x,I5,3X,I5,5x,I5)'

        ENDIF ELSE BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('Critical Error: Impossible to read data file ', A,'. ')", kmex_file_name
                        PRINT, FORMAT="('                Missing file directories or permissions conflict.')"
                ENDIF
                error.value[1] += 1
                error.log      += 'Data file '+kmex_file_name+' not found, make manual UPDATE. Impossible to continue. '
                RETURN
        ENDELSE
        ;data_to_analize = REPLICATE(magnetic_data, 2*kmex_days_for_median)
        
        ;for i=0, file_number-1 DO print, i+1, '  ', kmex_file_name[i], '  ', exist_kmex_file[i]
        IF not keyword_set(quiet) THEN print, initial_year, initial_month, initial_day, FORMAT='("        Gathering data for ",I04,"/",I02,"/",I02,":")'

        file_data = STRARR(24)
        file_differences = STRARR(8)
        
        FOR i = 0, 23 DO $
                file_data[i] = STRING(i, i,0, index_data[i].dst, index_data[i].average_dst, $
                                      FORMAT = '(I03, X, I02,":",I02,3X,I5,3X,I5)')

        FOR i = 0, 7 DO $
                file_differences[i] = STRING(i*3, index_data[i*3].kp, index_data[i*3].total_kp, $
                                               index_data[i*3].kp, index_data[i*3].average_Ap, $
                                               FORMAT = '(I02, 3X,I4,3X,I4,3X,I5,3x,I5)')


        output_file     = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')
        output_path     = system.processed_dir+gms[system.gms].name+'/'
        
        exist_dir       = FILE_TEST(output_path, /DIRECTORY)

        IF not(exist_dir) THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('Critical Error: Missing system directory ', A,'. ')", output_path
                        PRINT, FORMAT="('                Check out the directory tree.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'System directory '+output_path+' not found. Impossible to continue. '
                RETURN
        ENDIF 
        
        OPENW, lunn, output_path+output_file+'.data'+extention, /GET_LUN, ERROR=err
                IF err EQ 0 THEN BEGIN
                        FOR i=0, N_ELEMENTS(file_data)-1 DO PRINTF, lunn, file_data[i]
                ENDIF ELSE MESSAGE, 'Error while writing '+output_file+'.data'+extention+' output file.'
        CLOSE, lunn
        FREE_LUN, lunn

        IF not keyword_set(quiet) THEN print, '        Saving: '+output_path+output_file+'.data'+extention


        OPENW, lun, output_path+output_file+'.differences'+extention, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing '+output_file+'.differences'+extention+' output file.'
                FOR i=0, N_ELEMENTS(file_differences)-1 DO $
                        PRINTF, lun, file_differences[i]
        CLOSE, lun
        FREE_LUN, lun


        IF not keyword_set(quiet) THEN print, '        Saving: '+output_path+output_file+'.differences'+extention



        IF not keyword_set(quiet) THEN print, ''


RETURN
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
PRO geomagixs_magneticdata_process, initial, final, STATION=station, $
                                              QUIET=quiet, $
                                              FORCE_ALL=force_all, $
                                              STATISTIC_QD=statistic_qd, $
                                              REAL_TIME=real_time

        On_error, 2
        COMPILE_OPT idl2, hidden
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        geomagixs_setup_commons, /QUIET
        geomagixs_check_system, /QUIET
        geomagixs_setup_dates, STATION=station, /QUIET, /force_all
        geomagixs_check_dates, initial, final, STATION=station, /QUIET
        

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
        file_number    = (JULDAY(final_month, final_day, final_year) - JULDAY(initial_month, initial_day, initial_year))+1
        data_file_name = strarr(file_number)

        string_date    = strarr(file_number)
        ;exist_file     = intarr(file_number)
        extention       = keyword_set(real_time) ? '.early' : '.final'
       
        tmp_year    = 0
        tmp_month   = 0
        tmp_day     = 0
        tmp_julday  = JULDAY(initial_month, initial_day, initial_year)
        FOR i=0ll, file_number-1 DO BEGIN
                CALDAT, tmp_julday+i, tmp_month, tmp_day, tmp_year
                ;years[i]  = tmp_year
                ;months[i] = tmp_month
                ;days[i]   = tmp_day
                string_date[i]    = string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')
                ;data_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                data_file_name[i] = gms[system.gms].code+'_'+string_date[i]+'.clean.dat'
                ;kmex_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                ;print, i+1, '  ', data_file_name[i]
        ENDFOR

        exist_data_file   = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+data_file_name)

        capable_to_update = N_ELEMENTS(where(exist_data_file EQ 1))

        IF not keyword_set(quiet) THEN BEGIN
                IF capable_to_update LT 1 THEN BEGIN
                        PRINT, '        Data File Error: GMS_YYYYMMDD.celan.dat files not found!'
                        PRINT, '        If proceed, data will be assumed as gaps.'
                        proceed = 'Y'
                        REPEAT BEGIN
                                IF not (keyword_set(force_all)) THEN READ, proceed, PROMPT='        Continue (Y/N)?: '
                                proceed=STRUPCASE(proceed)
                                IF proceed EQ 'N' OR proceed EQ 'NO' THEN RETURN
                        ENDREP UNTIL proceed EQ 'Y' OR proceed EQ 'YES'
                        print, ''
                ENDIF
        ENDIF
        

        exist_result_file = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_'+string_date+'.data'+extention) AND not(keyword_set(force_all))

        make_update_file = exist_data_file AND NOT(exist_result_file)


        IF TOTAL(make_update_file) GT 0 THEN files_to_update = N_ELEMENTS(where(make_update_file EQ 1)) $
                                        ELSE files_to_update = 0
        ;print, TOTAL(make_update_file), files_to_update
        
        
        IF not keyword_set(quiet) THEN BEGIN
                IF TOTAL(files_to_update) GT 0 THEN BEGIN
                        print, ''
                        PRINT, files_to_update, FORMAT='("        A total of ",I," file(s) need to be updated.")' 
                        PRINT, ''
                ENDIF ELSE BEGIN
                        PRINT, "        No file requires to be updated."
                        RETURN
                ENDELSE
        
                IF capable_to_update GT files_to_update THEN BEGIN
                        PRINT, capable_to_update-files_to_update, FORMAT='("        There are still ",I," file(s) that can be updated.")'
                        PRINT, '        Use the /FORCE_ALL keyword to force the updating of all files.'
                        PRINT, ''
                ENDIF

                IF N_ELEMENTS(exist_data_file) GT capable_to_update THEN BEGIN
                        PRINT, N_ELEMENTS(exist_data_file) - capable_to_update, FORMAT='("        There are ",I," file(s) that are unable to be updated.")'
                        PRINT, '        Use the MAKE_DATAFILES tool for updating data base.'
                        PRINT, ''
                ENDIF

                proceed = 'Y'
                REPEAT BEGIN
                        IF not keyword_set(force_all) THEN READ, proceed, PROMPT='        Continue (Y/N)?: '
                        proceed=STRUPCASE(proceed)
                        IF proceed EQ 'N' OR proceed EQ 'NO' THEN RETURN
                ENDREP UNTIL proceed EQ 'Y' OR proceed EQ 'YES'
        ENDIF


        FOR i = 0ll, N_ELEMENTS(make_update_file)-1 DO BEGIN
                IF make_update_file[i] EQ 1 THEN BEGIN
                        tmp_year    = 0
                        tmp_month   = 0
                        tmp_day     = 0
                        READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                        ;print, tmp_year, tmp_month, tmp_day
                        ;print, station
                        IF station NE 'planetary' THEN making_processeddatafiles, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, REAL_TIME=real_time, STATISTIC_QD=statistic_qd $
                                                  ELSE making_processedplanetarydatafiles, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, REAL_TIME=real_time
                ENDIF
        ENDFOR

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Data files processed!'
        ENDIF

        return


END






