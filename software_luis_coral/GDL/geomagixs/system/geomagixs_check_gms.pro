;+
; NAME:
;       ????????????????
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
;       Mexico, 15.i.mmxxi
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


FUNCTION ReadCalibration

        On_error, 2
        COMPILE_OPT idl2, hidden
;##############################################################################
; initialize directories
;##############################################################################
        ;kmex_setup
        @geomagixs_commons

        ;file_kind       = keyword_set(no_standard) ? '' : '.standard'
        calibration_name = system.auxiliar_dir+gms[system.gms].name+'.calibration'

        file = FILE_SEARCH(calibration_name, COUNT=opened_files)
                IF opened_files EQ 0 THEN MESSAGE, 'Critical Error: calibration file not found!!!'
                
        number_of_lines  = FILE_LINES(file[0])
        calibration_data = STRARR(number_of_lines)


        OPENR, lun, file[0], /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error opening '+gms[system.gms].name
                READF, lun, calibration_data, FORMAT='(A)'
        CLOSE, lun
        FREE_LUN, lun


        result = FLTARR(28)

        
        dat_str = { z : 0.}
        tmp_var = REPLICATE(dat_str,28)
        READS, calibration_data[12], tmp_var, FORMAT='(F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5,X,F5)';'(27(F5,X), F5)'
        result[*] = tmp_var[*].z
        
        ;print, result.dH_table[*]
        
        
        RETURN, result
END



PRO geomagixs_check_gms, STATION=station, $
                         QUIET=quiet, $
                         FORCE_ALL = force_all

        On_error, 2
        COMPILE_OPT idl2, HIDDEN


;##############################################################################
; initialize directories
;##############################################################################
        ;seting up system variables
        geomagixs_setup_commons
        
        ;commons stantment        
        @geomagixs_commons
        
;##############################################################################
; checking gms name
;##############################################################################
        IF N_ELEMENTS(station) EQ 0 THEN BEGIN
                ;geomagixs_GMS      = 0
                station       = gms[system.gms].name
                IF not keyword_set(quiet) THEN PRINT, '        * Setting '+STRUPCASE(gms[system.gms].name)+' as default GMS station!'
        ENDIF ELSE BEGIN
                station = STRLOWCASE(station)
                IF N_ELEMENTS(station) EQ 1 THEN BEGIN
                        station_number1 = FIX(where(gms[*].code EQ station))
                        station_number2 = FIX(where(gms[*].name EQ station))
                        
                        IF (station_number1 LT 0 AND station_number2 LT 0) OR $
                           (station_number1 GE system.gms_total AND station_number2 GE system.gms_total) THEN BEGIN
                                IF NOT keyword_set(quiet) THEN BEGIN
                                        PRINT, FORMAT="('CRITICAL ERROR: Selected GMS [',A,'] is not available.')", station
                                        PRINT, FORMAT="('                check the list of available GMS.')"
                                ENDIF
                                error.value[2] += 1
                                error.log      += 'Selected GMS is not available or correctly installed. '
                                RETURN
                        ENDIF ELSE BEGIN
                                station_number = station_number1 GE 0 ? station_number1 : station_number2
                                system.gms = station_number
                                station  = gms[system.gms].name
                                IF not keyword_set(quiet) AND gms[system.gms].check_flag EQ 0 THEN PRINT, '        * Setting '+gms[system.gms].name+' as GMS station!'
                                
                        ENDELSE
                ENDIF
        ENDELSE

        IF not keyword_set(force_all) AND gms[system.gms].check_flag NE 0 THEN RETURN


;##############################################################################
; checking gms calibration
;##############################################################################
IF gms[system.gms].name NE 'planetary' THEN BEGIN
        IF FILE_TEST(system.auxiliar_dir+gms[system.gms].name+'.calibration', /READ) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read auxiliar file ', A, '.')", gms[system.gms].name+'.calibration'
                        PRINT, FORMAT="('                it is mandatory reding permissons on the file.')"
                ENDIF
        
                error.value[0] += 1
                error.log      += 'Auxiliar file  '+gms[system.gms].name+'.calibration'+' not found or read permissions conflict. '
                ;RETURN
        ENDIF

        tmp_callibration = ReadCalibration()
        gms[system.gms].calibration[*] = tmp_callibration[*]
ENDIF

        
;##############################################################################
; checking gms directories
;##############################################################################
        IF FILE_TEST(system.datasource_dir+gms[system.gms].name, /READ, /DIRECTORY) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read input directory ', A, '.')",system.datasource_dir+gms[system.gms].name
                        PRINT, FORMAT="('                it is mandatory reding permissons on the directory.')"
                ENDIF
        
                error.value[0] += 1
                error.log      += 'Input directory  '+system.datasource_dir+gms[system.gms].name+' not found or read permissions conflict. '
                ;RETURN
        ENDIF
        
        
        IF FILE_TEST(system.processed_dir+gms[system.gms].name, /WRITE, /DIRECTORY) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to write on output directory ', A, '.')",system.processed_dir+gms[system.gms].name
                        PRINT, FORMAT="('                it is mandatory writing permissons on the directory.')"
                ENDIF
        
                error.value[0] += 1
                error.log      += 'Output directory  '+system.processed_dir+gms[system.gms].name+' not found or write permissions conflict. '
                ;RETURN
        ENDIF
        
        
        IF FILE_TEST(system.plots_dir+gms[system.gms].name, /WRITE, /DIRECTORY) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to write on output directory ', A, '.')",system.plots_dir+gms[system.gms].name
                        PRINT, FORMAT="('                it is mandatory writing permissons on the directory.')"
                ENDIF
        
                error.value[0] += 1
                error.log      += 'Output directory  '+system.plots_dir+gms[system.gms].name+' not found or write permissions conflict. '
                ;RETURN
        ENDIF
        
        
        IF FILE_TEST(system.indexes_dir+gms[system.gms].name, /WRITE, /DIRECTORY) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to write on output directory ', A, '.')",system.indexes_dir+gms[system.gms].name
                        PRINT, FORMAT="('                it is mandatory writing permissons on the directory.')"
                ENDIF
        
                error.value[0] += 1
                error.log      += 'Output directory  '+system.indexes_dir+gms[system.gms].name+' not found or write permissions conflict. '
                ;RETURN
        ENDIF
        
        
        gms[system.gms].check_flag = 1
        
        
        IF not keyword_set(quiet) THEN PRINT, '        * Geomagnetic station '+STRUPCASE(gms[system.gms].name)+' ready.'
 

        RETURN
END


