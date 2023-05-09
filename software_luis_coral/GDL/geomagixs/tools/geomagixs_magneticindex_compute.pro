;+
; NAME:
;       kmex_update_magneticindex
;
;
; PURPOSE:
;
;       ????????????????
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Instituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro
;       Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 15.i.mmxv
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       ?????????????????????
;
;       Description:
;       ???????????????????????
;
;
; PARAMETERS:
;       ???????    : ?????????????
;
; KEYWORD PARAMETERS:
;
;       /????????? : ?????????????
;
; DEPENDENCIAS:
;       ?????????? : ????????????
;
; ARCHIVOS ANALIZADOS:
;       ??????????
;
; ARCHIVOS DE SALIDA:
;
; HISTORIA:
;-


FUNCTION getting_deltab, initial, QUIET=quiet, $
                                  REAL_TIME=real_time
        On_error, 2
        COMPILE_OPT idl2
;##############################################################################
; initialize directories
;##############################################################################
        ;kmex_setup
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
        DataStruct  =  { hour : 0, $
                         Max_D : 0., Min_D : 0., sigma_D : 0., delta_D : 0., $
                         Max_H : 0., Min_H : 0., sigma_H : 0., delta_H : 0., $
                         Max_Z : 0., Min_Z : 0., sigma_Z : 0., delta_Z : 0., $
                         Max_F : 0., Min_F : 0., sigma_F : 0., delta_F : 0., $
                         Max_N : 0., Min_N : 0., sigma_N : 0., delta_N : 0. $
                        }
                         
        read_data   = REPLICATE(DataStruct, 8)
        
        read_data[*].hour  = [0,3,6,9,12,15,18,21]
        
        read_data[*].Max_D   = 9999.
        read_data[*].Min_D   = 9999.
        read_data[*].sigma_D = 9999.
        read_data[*].delta_D = 9999.
        
        read_data[*].Max_H   = 999999.
        read_data[*].Min_H   = 999999.
        read_data[*].sigma_H = 999999.
        read_data[*].delta_H = 999999.

        read_data[*].Max_Z   = 999999.
        read_data[*].Min_Z   = 999999.
        read_data[*].sigma_Z = 999999.
        read_data[*].delta_Z = 999999.

        read_data[*].Max_F   = 999999.
        read_data[*].Min_F   = 999999.
        read_data[*].sigma_F = 999999.
        read_data[*].delta_F = 999999.

        read_data[*].Max_N   = 999999.
        read_data[*].Min_N   = 999999.
        read_data[*].sigma_N = 999999.
        read_data[*].delta_N = 999999.

        ;file_number = (JULDAY(final_month, final_day, final_year) - JULDAY(initial_month, initial_day, initial_year))+1
        
        
        ;file_kind = 'final'
        ;IF keyword_set(real_time) THEN file_kind='early'
        file_kind = keyword_set(real_time) ? 'early' : 'final'


        file_name = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.differences.'+file_kind
        
        IF FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+file_name) THEN BEGIN
                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                        IF opened_files EQ 0 THEN MESSAGE, 'Error finding data files or directories!'
                
                number_of_lines = FILE_LINES(file)
                magnetic_data   = STRARR(number_of_lines)

                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[i]
                        READF, lun, magnetic_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun


                READS, magnetic_data, read_data, $
                        FORMAT= '(I2,2X,' + $
                                'X,F7,X,F7,X,F7,X,F7,' + $
                                'X,F9,X,F9,X,F9,X,F9,' + $
                                'X,F9,X,F9,X,F9,X,F9,' + $
                                'X,F9,X,F9,X,F9,X,F9,' + $
                                'X,F9,X,F9,X,F9,X,F9' + $
                                ')'
                tempvar = SIZE(TEMPORARY(magnetic_data)) ; liberar memoria de la info no usada
        ENDIF
        
        
        
        result = { hour              : INTARR(8), $
                   
                   delta_D           : FLTARR(8), $
                   sigma_D           : FLTARR(8), $
                   delta_H           : FLTARR(8), $
                   sigma_H           : FLTARR(8), $
                   delta_Z           : FLTARR(8), $
                   sigma_Z           : FLTARR(8), $
                   delta_F           : FLTARR(8), $
                   sigma_F           : FLTARR(8), $
                   delta_N           : FLTARR(8), $
                   sigma_N           : FLTARR(8) $
                 }


        result.hour[*]         = read_data[*].hour

        result.delta_D[*]      = read_data[*].delta_D
        result.sigma_D[*]      = read_data[*].sigma_D
        result.delta_H[*]      = read_data[*].delta_H
        result.sigma_H[*]      = read_data[*].sigma_H
        result.delta_Z[*]      = read_data[*].delta_Z
        result.sigma_Z[*]      = read_data[*].sigma_Z
        result.delta_F[*]      = read_data[*].delta_F
        result.sigma_F[*]      = read_data[*].sigma_F
        result.delta_N[*]      = read_data[*].delta_N
        result.sigma_N[*]      = read_data[*].sigma_N



        tempvar = SIZE(TEMPORARY(read_data)) ; liberar memoria de la info no usada
        return, result
END






FUNCTION getting_deltah, initial, QUIET=quiet, $
                                  REAL_TIME=real_time
        On_error, 2
        COMPILE_OPT idl2
;##############################################################################
; initialize directories
;##############################################################################
        ;kmex_setup
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
        DataStruct  =  { hour : 0, minute : 0, sigma_H : 0., d_H : 0. }
                         
        minutes_per_day = 60*24
        read_data   = REPLICATE(DataStruct, minutes_per_day)
        
        ;read_data[*].hour  = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]
        
        read_data[*].d_H       = 999999.
        read_data[*].sigma_H   = 999999.

        ;file_number = (JULDAY(final_month, final_day, final_year) - JULDAY(initial_month, initial_day, initial_year))+1
        
        
        ;file_kind = 'final'
        ;IF keyword_set(real_time) THEN file_kind='early'
        file_kind = keyword_set(real_time) ? 'early' : 'final'


        file_name = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.data.'+file_kind
        
        IF FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+file_name) THEN BEGIN
                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                        IF opened_files EQ 0 THEN MESSAGE, 'Error finding data files or directories!'
                
                number_of_lines = FILE_LINES(file)
                magnetic_data   = STRARR(number_of_lines)

                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[i]
                        READF, lun, magnetic_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun


                READS, magnetic_data, read_data, $
                       FORMAT='(' $
                                       +'5X,I2,X,I2, ' $
                                       +'39X, ' $
                                       +'49X, ' $
                                       +'10X, F9, 30X, ' $
                                       +'10X, F9, : )'

;                                       +'5X,I02,X,I02, ' $
;                                       +'2X, F7.2, 3(X, F9.2), ' $
;                                       +'2X, F7.2, 4(X, F9.2), ' $
;                                       +'2X, F7.2, 4(X, F9.2), ' $
;                                       +'2X, F7.2, 4(X, F9.2) ' $
;                                       +')')


                tempvar = SIZE(TEMPORARY(magnetic_data)) ; liberar memoria de la info no usada
        ENDIF
        
        
        
        result = { hour              : INTARR(24), $
                   
                   delta_H           : FLTARR(24), $
                   sigma_H           : FLTARR(24) $
                 }



        FOR i=0, 23 DO BEGIN
                result.hour[i]    = read_data[i*60].hour
                result.delta_H[i] = median(read_data[i*60:(i+1)*60-1].d_H)
                result.sigma_H[i] = median(read_data[i*60:(i+1)*60-1].sigma_H)
        ENDFOR


        tempvar = SIZE(TEMPORARY(read_data)) ; liberar memoria de la info no usada
        return, result
END




;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################


FUNCTION getting_magneticprofiles, initial, QUIET=quiet, $
                                   REAL_TIME=real_time
        On_error, 2
        COMPILE_OPT idl2
;##############################################################################
; initialize directories
;##############################################################################
        ;kmex_setup
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
        DataStruct  =  { hour : 0, minute : 0, D : 0., H : 0., Z : 0., F : 0. }
                         
        minutes_per_day = 60*24
        read_data   = REPLICATE(DataStruct, minutes_per_day)
        
        ;read_data[*].hour  = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]
        
        read_data[*].D   = 9999.
        read_data[*].H   = 999999.
        read_data[*].Z   = 999999.
        read_data[*].F   = 999999.

        FOR i=0, 23 DO BEGIN
                read_data[i].hour = i
                read_data[i*60:(i+1)*60-1].minute = indgen(60)
        ENDFOR
        ;file_number = (JULDAY(final_month, final_day, final_year) - JULDAY(initial_month, initial_day, initial_year))+1
        
        
        ;file_kind = 'final'
        ;IF keyword_set(real_time) THEN file_kind='early'
        file_kind = keyword_set(real_time) ? 'early' : 'final'


        file_name = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.data.'+file_kind
        
        IF FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+file_name) THEN BEGIN
                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                        IF opened_files EQ 0 THEN MESSAGE, 'Error finding data files or directories!'
                
                number_of_lines = FILE_LINES(file)
                magnetic_data   = STRARR(number_of_lines)

                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[i]
                        READF, lun, magnetic_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun

;print, magnetic_data
                READS, magnetic_data, read_data, $
                       FORMAT='(' $
                                       +'5X,I2,X,I2, ' $
                                       +'2X, F7, X, F9, X, F9, X, F9, : )' 

;                                       +'5X,I02,X,I02, ' $
;                                       +'2X, F7.2, 3(X, F9.2), ' $
;                                       +'2X, F7.2, 4(X, F9.2), ' $
;                                       +'2X, F7.2, 4(X, F9.2), ' $
;                                       +'2X, F7.2, 4(X, F9.2) ' $
;                                       +')')


                tempvar = SIZE(TEMPORARY(magnetic_data)) ; liberar memoria de la info no usada
        ENDIF
        
        data_per_hour = 10
        data_points   = 24*data_per_hour
        data_period   = 60/data_per_hour   ; WARNING needs to be integer
        
        result = { hour              : INTARR(data_points), $
                   minute            : INTARR(data_points), $

                   H           : FLTARR(data_points), $
                   D           : FLTARR(data_points), $
                   Z           : FLTARR(data_points), $
                   F           : FLTARR(data_points) $
                 }



        FOR i=0, data_points-1 DO BEGIN
                result.hour[i]    = read_data[i*data_period].hour
                result.minute[i]  = read_data[i*data_period].minute
                result.D[i]       = median(read_data[i*data_period:(i+1)*data_period-1].D)
                result.H[i]       = median(read_data[i*data_period:(i+1)*data_period-1].H)
                result.Z[i]       = median(read_data[i*data_period:(i+1)*data_period-1].Z)
                result.F[i]       = median(read_data[i*data_period:(i+1)*data_period-1].F)
        ENDFOR


        tempvar = SIZE(TEMPORARY(read_data)) ; liberar memoria de la info no usada
        return, result
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
FUNCTION kp2ap, k_tmp

        On_error, 2
        COMPILE_OPT idl2, hidden

        result = 0*(k_tmp EQ 0) + $
                 2*(k_tmp EQ 3) + $
                 3*(k_tmp EQ 7) + $
                 4*(k_tmp EQ 10) + $
                 5*(k_tmp EQ 13) + $
                 6*(k_tmp EQ 17) + $
                 7*(k_tmp EQ 20) + $
                 9*(k_tmp EQ 23) + $
                 12*(k_tmp EQ 27) + $
                 15*(k_tmp EQ 30) + $
                 18*(k_tmp EQ 33) + $
                 22*(k_tmp EQ 37) + $
                 27*(k_tmp EQ 40) + $
                 32*(k_tmp EQ 43) + $
                 39*(k_tmp EQ 47) + $
                 48*(k_tmp EQ 50) + $
                 56*(k_tmp EQ 53) + $
                 67*(k_tmp EQ 57) + $
                 80*(k_tmp EQ 6) + $
                 94*(k_tmp EQ 63) + $
                 111*(k_tmp EQ 67) + $
                 132*(k_tmp EQ 70) + $
                 154*(k_tmp EQ 73) + $
                 179*(k_tmp EQ 77) + $
                 207*(k_tmp EQ 80) + $
                 236*(k_tmp EQ 83) + $
                 300*(k_tmp EQ 87) + $
                 400*(k_tmp EQ 90) + $
                 999*(k_tmp EQ 999)

        RETURN, result
END






;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
FUNCTION dayly_kp, k_tmp

        On_error, 2
        COMPILE_OPT idl2, hidden

        tmp = where(k_tmp LT 999)
        
        IF tmp[0] EQ -1 THEN RETURN, 999 

        result = fix(TOTAL(k_tmp[tmp]))
        result = (result MOD 10 EQ 2) ? (result/10)*10 + 3 : result
        result = (result MOD 10 EQ 5) ? (result/10)*10 + 3 : result
        result = (result MOD 10 EQ 6) ? (result/10)*10 + 7 : result
        result = (result MOD 10 EQ 8) ? (result/10)*10 + 7 : result
        result = (result MOD 10 EQ 9) ? (result/10+1)*10 : result

        RETURN, result
END




;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
FUNCTION dayly_a, a_tmp

        On_error, 2
        COMPILE_OPT idl2, hidden

        tmp = where(a_tmp LT 999)
        
        IF tmp[0] EQ -1 THEN RETURN, 999
        
        RETURN, fix(MEAN(a_tmp[tmp]))
END




;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
FUNCTION dH2Kp, dH_tmp, dH_table

        On_error, 2
        COMPILE_OPT idl2, hidden
        
        MAX_dH = 1000.
        
        IF N_ELEMENTS(dH_table) NE 28 THEN dH_table = [ 4.7,  5.4,  6.4,  7.2,  8.2,  9.7, 11.0, $
                                                       12.5, 14.8, 16.8, 19.1, 22.6, 25.6, 29.1, $
                                                       34.4, 39.1, 44.4, 52.5, 59.6, 67.7, 80.1, $
                                                       90.9,103.2,122.2,138.7,157.5,186.4,211.6]

        result = 0*(dH_tmp LE dH_table[1]) + $
                 3*(dH_tmp GT dH_table[1] AND dH_tmp LE dH_table[2]) + $
                 7*(dH_tmp GT dH_table[2] AND dH_tmp LE dH_table[3]) + $
                 10*(dH_tmp GT dH_table[3] AND dH_tmp LE dH_table[4]) + $
                 13*(dH_tmp GT dH_table[4] AND dH_tmp LE dH_table[5]) + $
                 17*(dH_tmp GT dH_table[5] AND dH_tmp LE dH_table[6]) + $
                 20*(dH_tmp GT dH_table[6] AND dH_tmp LE dH_table[7]) + $
                 23*(dH_tmp GT dH_table[7] AND dH_tmp LE dH_table[8]) + $
                 27*(dH_tmp GT dH_table[8] AND dH_tmp LE dH_table[9]) + $
                 30*(dH_tmp GT dH_table[9] AND dH_tmp LE dH_table[10]) + $
                 33*(dH_tmp GT dH_table[10] AND dH_tmp LE dH_table[11]) + $
                 37*(dH_tmp GT dH_table[11] AND dH_tmp LE dH_table[12]) + $
                 40*(dH_tmp GT dH_table[12] AND dH_tmp LE dH_table[13]) + $
                 43*(dH_tmp GT dH_table[13] AND dH_tmp LE dH_table[14]) + $
                 47*(dH_tmp GT dH_table[14] AND dH_tmp LE dH_table[15]) + $
                 50*(dH_tmp GT dH_table[15] AND dH_tmp LE dH_table[16]) + $
                 53*(dH_tmp GT dH_table[16] AND dH_tmp LE dH_table[17]) + $
                 57*(dH_tmp GT dH_table[17] AND dH_tmp LE dH_table[18]) + $
                 60*(dH_tmp GT dH_table[18] AND dH_tmp LE dH_table[19]) + $
                 63*(dH_tmp GT dH_table[19] AND dH_tmp LE dH_table[20]) + $
                 67*(dH_tmp GT dH_table[20] AND dH_tmp LE dH_table[21]) + $
                 70*(dH_tmp GT dH_table[21] AND dH_tmp LE dH_table[22]) + $
                 73*(dH_tmp GT dH_table[22] AND dH_tmp LE dH_table[23]) + $
                 77*(dH_tmp GT dH_table[23] AND dH_tmp LE dH_table[24]) + $
                 80*(dH_tmp GT dH_table[24] AND dH_tmp LE dH_table[25]) + $
                 83*(dH_tmp GT dH_table[25] AND dH_tmp LE dH_table[26]) + $
                 87*(dH_tmp GT dH_table[26] AND dH_tmp LE dH_table[27]) + $
                 90*(dH_tmp GT dH_table[27] AND dH_tmp LT MAX_dH) + $
                 999*(dH_tmp GE MAX_dH)

        RETURN, result
END





;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
FUNCTION ReadCalibration_MAGIND

        On_error, 2
        COMPILE_OPT idl2
;##############################################################################
; initialize directories
;##############################################################################
        ;kmex_setup
        @geomagixs_commons

        calibration_name = system.auxiliar_dir+gms[system.gms].name+'.calibration'
        
        
        file = FILE_SEARCH(calibration_name, COUNT=opened_files)
                IF opened_files EQ 0 THEN MESSAGE, 'Error finding calibration files or directories!'
                
        number_of_lines  = FILE_LINES(file)
        calibration_data = STRARR(number_of_lines)

        OPENR, lun, file, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[0]
                READF, lun, calibration_data, FORMAT='(A)'
        CLOSE, lun
        FREE_LUN, lun


        result = { dH_table : FLTARR(28) }

        dat_str = { z : 0.}
        tmp_var = REPLICATE(dat_str,28)
        READS, calibration_data[12], tmp_var, FORMAT='(F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5)';'(27(F5,X), F5)'
        result.dH_table[*] = tmp_var[*].z
        
        ;print, result.dH_table[*]
        
        
        RETURN, result
END





;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
PRO getting_kindex, date, QUIET=quiet, $
                          REAL_TIME=real_time, $
                          STATION=station

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
        initial_year   = date[0]
        initial_month  = date[1]
        initial_day    = date[2]


;##############################################################################
; reading & processing data
;##############################################################################
        calibration = ReadCalibration_MAGIND()
        data        = getting_deltab(date, QUIET=quiet, REAL_TIME=real_time)
        ;print, data.delta_H[*]
        ;print, data.delta_H[*]



        K_mex       = dH2Kp(data.delta_H[*], calibration.dH_table[*])
        K_mex_max   = dH2Kp(data.delta_H[*]+data.sigma_H[*], calibration.dH_table[*])
        K_mex_min   = dH2Kp(data.delta_H[*]-data.sigma_H[*], calibration.dH_table[*])
        
        a_mex       = kp2ap(K_mex)
        a_mex_max   = kp2ap(K_mex_max)
        a_mex_min   = kp2ap(K_mex_min)
        
        
        FOR i=0, N_ELEMENTS(K_mex)-1 DO BEGIN
                IF i GT 1 THEN $
                        IF k_mex[i] EQ 90 AND k_mex[i-1] LE 37 THEN k_mex[i] = 999
                IF i LT N_ELEMENTS(K_mex)-1 THEN $
                        IF k_mex[i] EQ 90 AND k_mex[i+1] LE 57 THEN k_mex[i] = 999
        ENDFOR
        
                
        ;print, calibration.dH_table[*]
        ;print, K_mex[*]
        
        k_mex_data    = STRARR(6)
        k_mex_data[0] = string(K_mex, dayly_kp(K_mex), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[1] = string(a_mex, dayly_a(a_mex), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[2] = string(K_mex_max, dayly_kp(K_mex_max), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[3] = string(a_mex_max, dayly_a(a_mex_max), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[4] = string(K_mex_min, dayly_kp(K_mex_min), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[5] = string(a_mex_min, dayly_a(a_mex_min), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        ;print, data.delta_H[*]
        ;print, K_mex, dayly_kp(K_mex), FORMAT='(8(I03,X),I03)'
        ;print, a_mex, dayly_a(a_mex), FORMAT='(8(I03,X),I03)'
        ;tmp_data = getting_deltab([initial_year,initial_month,initial_day], QUIET=quiet, REAL_TIME=real_time)

;##############################################################################
; creating data file
;##############################################################################
        extention       = keyword_set(real_time) ? '.early' : '.final'
        ;output_datafile = station_code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_datafile = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.k_index'+extention
        output_path     = system.indexes_dir+gms[system.gms].name+'/'
        
        
        OPENW, lun, output_path+output_datafile, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing data file!
                PRINTF, lun, k_mex_data[0]
                PRINTF, lun, k_mex_data[1]
                PRINTF, lun, k_mex_data[2]
                PRINTF, lun, k_mex_data[3]
                PRINTF, lun, k_mex_data[4]
                PRINTF, lun, k_mex_data[5]
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN print, '        Saving: '+output_datafile
        ;IF not keyword_set(quiet) THEN print, ''


        return


END

;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
PRO getting_deltahindex, date, QUIET=quiet, $
                          REAL_TIME=real_time, $
                          STATION=station

        On_error, 2
        COMPILE_OPT idl2, hidden
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons

;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = date[0]
        initial_month  = date[1]
        initial_day    = date[2]

;##############################################################################
; reading & processing data
;##############################################################################
        data        = getting_deltah(date, QUIET=quiet, REAL_TIME=real_time)
        ;print, data.delta_H[*]
        ;print, data.delta_H[*]

        good_indexes = WHERE ( data.delta_H[*] LT 999990.0 )
        dH_mex_data   = STRARR(2)
        IF good_indexes[0] EQ -1 THEN BEGIN
                dh_mex_data[0] = string(data.delta_H[*], MEAN(data.delta_H[*]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
                dh_mex_data[1] = string(data.sigma_H[*], MEAN(data.sigma_H[*]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
        ENDIF ELSE BEGIN
                dh_mex_data[0] = string(data.delta_H[*], MEAN(data.delta_H[good_indexes]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
                dh_mex_data[1] = string(data.sigma_H[*], MEAN(data.sigma_H[good_indexes]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
        ENDELSE
        ;print, string(data.delta_H[*], MEAN(data.delta_H[*]), FORMAT='(25(X, F8.1))')
        ;print, dh_mex_data[0]
        ;print, dh_mex_data[1]
        ;print, K_mex, dayly_kp(K_mex), FORMAT='(8(I03,X),I03)'
        ;print, a_mex, dayly_a(a_mex), FORMAT='(8(I03,X),I03)'
        ;tmp_data = getting_deltab([initial_year,initial_month,initial_day], QUIET=quiet, REAL_TIME=real_time)

;##############################################################################
; creating data file
;##############################################################################
        extention       = keyword_set(real_time) ? '.early' : '.final'
        ;output_datafile = station_code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_datafile = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.delta_H'+extention
        output_path     = system.indexes_dir+gms[system.gms].name+'/'
        
        
        OPENW, lun, output_path+output_datafile, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing data file!
                PRINTF, lun, dh_mex_data[0]
                PRINTF, lun, dh_mex_data[1]
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN print, '        Saving: '+output_datafile
        ;IF not keyword_set(quiet) THEN print, ''


        return


RETURN
END





;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
PRO getting_profiles, date, QUIET=quiet, $
                          REAL_TIME=real_time, $
                          STATION=station

        On_error, 2
        COMPILE_OPT idl2, hidden
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons

;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = date[0]
        initial_month  = date[1]
        initial_day    = date[2]

;##############################################################################
; reading & processing data
;##############################################################################
        data        = getting_magneticprofiles(date, QUIET=quiet, REAL_TIME=real_time)
        ;print, data.delta_H[*]
        ;print, data.delta_H[*]

        good_indexes = WHERE ( data.H[*] LT 999990.0 )
        profile_data   = STRARR(N_ELEMENTS(data.H[*]))
        ;IF good_indexes[0] EQ -1 THEN BEGIN
        ;        dh_mex_data[0] = string(data.delta_H[*], MEAN(data.delta_H[*]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
        ;        dh_mex_data[1] = string(data.sigma_H[*], MEAN(data.sigma_H[*]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
        ;ENDIF ELSE BEGIN
        ;        dh_mex_data[0] = string(data.delta_H[*], MEAN(data.delta_H[good_indexes]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
        ;        dh_mex_data[1] = string(data.sigma_H[*], MEAN(data.sigma_H[good_indexes]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
        ;ENDELSE
        
        FOR i=0, N_ELEMENTS(data.H[*])-1 DO $
                profile_data[i] = STRING(data.hour[i], data.minute[i], $
                                         data.D[i], data.H[i], data.Z[i], data.F[i], $
                                         FORMAT='(I02,":",I02, 2X,'+$
                                                 '4(2X,F8.1))' )
        
        ;print, string(data.delta_H[*], MEAN(data.delta_H[*]), FORMAT='(25(X, F8.1))')
        ;print, dh_mex_data[0]
        ;print, dh_mex_data[1]
        ;print, K_mex, dayly_kp(K_mex), FORMAT='(8(I03,X),I03)'
        ;print, a_mex, dayly_a(a_mex), FORMAT='(8(I03,X),I03)'
        ;tmp_data = getting_deltab([initial_year,initial_month,initial_day], QUIET=quiet, REAL_TIME=real_time)

;##############################################################################
; creating data file
;##############################################################################
        extention       = keyword_set(real_time) ? '.early' : '.final'
        ;output_datafile = station_code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_datafile = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.profiles'+extention
        output_path     = system.indexes_dir+gms[system.gms].name+'/'
        
        
        OPENW, lun, output_path+output_datafile, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing data file!
                FOR i = 0, N_ELEMENTS(profile_data[*])-1 DO PRINTF, lun, profile_data[i]
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN print, '        Saving: '+output_datafile
        ;IF not keyword_set(quiet) THEN print, ''


        return


RETURN
END






PRO getting_kpindex, date, QUIET=quiet, $
                          REAL_TIME=real_time, $
                          STATION=station

        On_error, 2
        COMPILE_OPT idl2, hidden
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons

        COMMON planetary_commons, monthly_data
;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = date[0]
        initial_month  = date[1]
        initial_day    = date[2]

        string_date    = string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')
                ;data_file_name[i] = station_code+'_'+string_date[i]+'.dat'
        kmex_file_name = gms[system.gms].code+'_'+string_date+'.differences'

        exist_kmex_file = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+kmex_file_name)
        ;exist_data_file = FILE_TEST(kmex_magnetic_dir+station+'/1_min/'+data_file_name)

        IF exist_kmex_file THEN BEGIN
                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+kmex_file_name, COUNT=opened_files)
                IF opened_files EQ 0 AND not keyword_set(quiet) THEN BEGIN
                        MESSAGE, kmex_file_name+' file missed!'
                        RETURN
                ENDIF
                number_of_lines =FILE_LINES(file[0])
                tmp_data = STRARR(number_of_lines)
                
                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name
                        READF, lun, tmp_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun

                str_tmp       = {kp : 0 }
                
                kp_data  = REPLICATE(str_tmp, number_of_lines)
                
                READS, tmp_data, kp_data, FORMAT='(5X,I4,:)'
        ENDIF ELSE MESSAGE, 'Data file not found for the input date, use UPDATE_DATAFILE tool.'

        kmex_file_name = gms[system.gms].code+'_'+string_date+'.data'

        exist_kmex_file = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+kmex_file_name)
        ;exist_data_file = FILE_TEST(kmex_magnetic_dir+station+'/1_min/'+data_file_name)

        IF exist_kmex_file THEN BEGIN
                file = FILE_SEARCH(system.processed_dir+gms[system.gms].name+'/'+kmex_file_name, COUNT=opened_files)
                IF opened_files EQ 0 AND not keyword_set(quiet) THEN BEGIN
                        MESSAGE, kmex_file_name+' file missed!'
                        RETURN
                ENDIF
                number_of_lines =FILE_LINES(file[0])
                tmp_data = STRARR(number_of_lines)
                
                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name
                        READF, lun, tmp_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun

                str_tmp       = {Dst : 0 }
                
                dst_data  = REPLICATE(str_tmp, number_of_lines)
                
                READS, tmp_data, dst_data, FORMAT='(12X,I5,:)'
        ENDIF ELSE MESSAGE, 'Data file not found for the input date, use UPDATE_DATAFILE tool.'


        K_mex       = kp_data[*].kp
        K_mex_max   = K_mex*0
        K_mex_min   = K_mex*0
        
        a_mex       = kp2ap(K_mex)
        a_mex_max   = kp2ap(K_mex_max)
        a_mex_min   = kp2ap(K_mex_min)

        k_mex_data    = STRARR(6)
        k_mex_data[0] = string(K_mex, dayly_kp(K_mex), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[1] = string(a_mex, dayly_a(a_mex), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[2] = string(K_mex_max, dayly_kp(K_mex_max), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[3] = string(a_mex_max, dayly_a(a_mex_max), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[4] = string(K_mex_min, dayly_kp(K_mex_min), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        k_mex_data[5] = string(a_mex_min, dayly_a(a_mex_min), FORMAT='(I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03,X,I03)');'(8(I03,X),I03)')
        ;print, data.delta_H[*]
        ;print, K_mex, dayly_kp(K_mex), FORMAT='(8(I03,X),I03)'
        ;print, a_mex, dayly_a(a_mex), FORMAT='(8(I03,X),I03)'
        ;tmp_data = getting_deltab([initial_year,initial_month,initial_day], QUIET=quiet, REAL_TIME=real_time)

;##############################################################################
; creating data file
;##############################################################################
        extention       = ''
        ;output_datafile = station_code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_datafile = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.k_index'+extention
        output_path     = system.indexes_dir+gms[system.gms].name+'/'
        
        
        OPENW, lun, output_path+output_datafile, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing data file!
                PRINTF, lun, k_mex_data[0]
                PRINTF, lun, k_mex_data[1]
                PRINTF, lun, k_mex_data[2]
                PRINTF, lun, k_mex_data[3]
                PRINTF, lun, k_mex_data[4]
                PRINTF, lun, k_mex_data[5]
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN print, '        Saving: '+output_datafile


        data        = dst_data[*].Dst

        good_indexes = WHERE ( data[*] LT 9990 )
        dH_mex_data  = STRARR(2)
        tmp          = FLTARR(25)
        IF good_indexes[0] EQ -1 THEN BEGIN
                dh_mex_data[0] = string(data[*], MEAN(data[*]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
                dh_mex_data[1] = string(tmp, FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
        ENDIF ELSE BEGIN
                dh_mex_data[0] = string(data[*], MEAN(data[good_indexes]), FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
                dh_mex_data[1] = string(tmp, FORMAT='(25(X, F8.1))');'(8(I03,X),I03)')
        ENDELSE
        ;print, string(data.delta_H[*], MEAN(data.delta_H[*]), FORMAT='(25(X, F8.1))')
        ;print, dh_mex_data[0]
        ;print, dh_mex_data[1]
        ;print, K_mex, dayly_kp(K_mex), FORMAT='(8(I03,X),I03)'
        ;print, a_mex, dayly_a(a_mex), FORMAT='(8(I03,X),I03)'
        ;tmp_data = getting_deltab([initial_year,initial_month,initial_day], QUIET=quiet, REAL_TIME=real_time)

;##############################################################################
; creating data file
;##############################################################################
        extention       = ''
        ;output_datafile = station_code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_datafile = gms[system.gms].code+'_'+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'.delta_H'+extention
        output_path     = system.indexes_dir+gms[system.gms].name+'/'
        
        
        OPENW, lun, output_path+output_datafile, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing data file!
                PRINTF, lun, dh_mex_data[0]
                PRINTF, lun, dh_mex_data[1]
        CLOSE, lun
        FREE_LUN, lun

        IF not keyword_set(quiet) THEN print, '        Saving: '+output_datafile
        ;IF not keyword_set(quiet) THEN print, ''



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
PRO geomagixs_magneticindex_compute, initial, final, STATION=station, $
                                        QUIET=quiet, $
                                        FORCE_ALL=force_all, $
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
        ;years          = intarr(file_number)
        ;months         = intarr(file_number)
        ;days           = intarr(file_number)
        string_date    = strarr(file_number)
        ;exist_file     = intarr(file_number)
        IF STATION NE 'planetary' THEN $
                extention = keyword_set(real_time) ? '.early' : '.final' $
                ELSE extention = ''
       

        FOR i=0ll, file_number-1 DO BEGIN
                tmp_year    = 0
                tmp_month   = 0
                tmp_day     = 0
                tmp_julday  = JULDAY(initial_month, initial_day, initial_year)

                CALDAT, tmp_julday+i, tmp_month, tmp_day, tmp_year
                ;years[i]  = tmp_year
                ;months[i] = tmp_month
                ;days[i]   = tmp_day
                string_date[i]    = string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')
                ;data_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                data_file_name[i] = gms[system.gms].code+'_'+string_date[i]+'.differences'+extention
        ENDFOR



        ;print, data_file_name
        ;stop
        

        exist_data_file   = FILE_TEST(system.processed_dir+gms[system.gms].name+'/'+data_file_name)

        capable_to_update = N_ELEMENTS(where(exist_data_file EQ 1))
        IF capable_to_update LT 1 THEN BEGIN
                IF not (keyword_set(quiet) OR keyword_set(non_stop)) THEN BEGIN
                        PRINT, '        Data File Error: GMS_YYYYMMDD.differences'+extention+' files not found!'
                        PRINT, '        If proceed, data will be assumed as gaps.'
                        print, ''
                ENDIF
                proceed = 'Y'
                REPEAT BEGIN
                        IF not ( keyword_set(quiet) OR keyword_set(force_all) ) THEN READ, proceed, PROMPT='        Continue (Y/N)?: '
                        proceed=STRUPCASE(proceed)
                        IF proceed EQ 'N' OR proceed EQ 'NO' THEN RETURN
                ENDREP UNTIL proceed EQ 'Y' OR proceed EQ 'YES'
        ENDIF


        ;exist_result_file = FILE_TEST(kmex_processed_dir+station_code+'_'+string_date+'.data'+extention) AND not(keyword_set(force_all))
        exist_result_file = FILE_TEST(system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_'+string_date+'.k_index'+extention) AND not(keyword_set(force_all))

        ;exist_result_file2 = FILE_TEST(system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_'+string_date+'.delta_H'+extention) AND not(keyword_set(force_all))

        ;print, exist_data_file
        ;print, exist_result_file
        make_update_file = exist_data_file AND NOT(exist_result_file)
        ;print, make_update_file



        IF TOTAL(make_update_file) GT 0 THEN files_to_update = N_ELEMENTS(where(make_update_file EQ 1)) $
                                        ELSE files_to_update = 0
        ;print, where(make_update_file EQ 1)
        
        IF NOT keyword_set(quiet) THEN BEGIN
                IF TOTAL(files_to_update) GT 0 THEN PRINT, files_to_update, FORMAT='("        A total of ",I," file(s) need to be updated.")' $
                                       ELSE BEGIN
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
                        PRINT, '        Use the UPDATE_MAGNETICDATA tool for updating data base.'
                        PRINT, ''
                ENDIF

                proceed = 'Y'
                REPEAT BEGIN
                        IF not keyword_set(force_all) THEN READ, proceed, PROMPT='        Continue (Y/N)?: '
                        proceed=STRUPCASE(proceed)
                        IF proceed EQ 'N' OR proceed EQ 'NO' THEN RETURN
                ENDREP UNTIL proceed EQ 'Y' OR proceed EQ 'YES'

        ENDIF

;        print, ''
        
        FOR i = 0ll, N_ELEMENTS(make_update_file)-1 DO BEGIN
                IF make_update_file[i] EQ 1 THEN BEGIN
                        tmp_year    = 0
                        tmp_month   = 0
                        tmp_day     = 0
                        ;print, string_date[i]
                        READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                        ;print, tmp_year, tmp_month, tmp_day
                        
                        IF station NE 'planetary' THEN BEGIN
                                getting_kindex, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, REAL_TIME=real_time
                                getting_deltahindex, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, REAL_TIME=real_time
                                getting_profiles, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, REAL_TIME=real_time
                        ENDIF ELSE BEGIN
                                getting_kpindex, [tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, REAL_TIME=real_time
                        ENDELSE
                ENDIF
        ENDFOR

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Magnetic-Index files updated!'
        ENDIF

        return


END







