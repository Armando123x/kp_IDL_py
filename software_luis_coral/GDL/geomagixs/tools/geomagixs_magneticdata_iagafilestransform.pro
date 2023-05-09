;+
; NAME:
;       kmex_update_magneticdatafiles
;
;
; PURPOSE:
;
;       make IAGA-2002x-format data files from raw data of geomagnetic stations
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Instituto de Geofisica, UNAM
;       Tzinztuntzan 310, Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 25.i.mmxxi
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       kmex_update_magneticdatafiles, initial, final [, STATION=station, QUIET=quiet, FORCE_ALL=force_all]
;
;       Description:
;       generates data files
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
;       none
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






;PRO kmex_update_magneticdatafiles, initial, final, STATION=station, $
;                                              QUIET=quiet, $
;                                              FORCE_ALL=force_all


PRO make_magneticdatafiles, date, STATION=station, $
                                         QUIET=quiet, $
                                         FORCE_ALL=force_all



        On_error, 2
        COMPILE_OPT idl2, HIDDEN
        
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        

;##############################################################################
; depuring inputs
;##############################################################################
;        kmex_check_GMS, STATION=station, QUIET=quiet

;        kmex_check_dates, initial, final, STATION=station, QUIET=quiet, ERROR_CODE=error, ERROR_MESSAGE=mensaje
        IF gms[system.gms].name EQ 'planetary' THEN RETURN
        
        
        tmp_year   = date[0]
        tmp_month  = date[1]
        tmp_day    = date[2]
        tmp_doy    = JULDAY(tmp_month, tmp_day, tmp_year)-JULDAY(1, 0, tmp_year)

        CASE 1 OF
                tmp_month EQ 1  : tmp_string = 'jan'
                tmp_month EQ 2  : tmp_string = 'feb'
                tmp_month EQ 3  : tmp_string = 'mar'
                tmp_month EQ 4  : tmp_string = 'apr'
                tmp_month EQ 5  : tmp_string = 'may'
                tmp_month EQ 6  : tmp_string = 'jun'
                tmp_month EQ 7  : tmp_string = 'jul'
                tmp_month EQ 8  : tmp_string = 'aug'
                tmp_month EQ 9  : tmp_string = 'sep'
                tmp_month EQ 10 : tmp_string = 'oct'
                tmp_month EQ 11 : tmp_string = 'nov'
                tmp_month EQ 12 : tmp_string = 'dec'
                ELSE: MESSAGE, 'Critial error'
        ENDCASE

        
        file_source_name      = gms[system.gms].code+string(tmp_day, FORMAT='(I02)')+tmp_string+'.'+string(tmp_year mod 1000, FORMAT='(I02)')+'m'

        exist_source_file     = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+file_source_name)

        IF exist_source_file[0] THEN BEGIN
                IF not keyword_set(quiet) THEN  print, '        Extracting data from: '+file_source_name
                file = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/'+file_source_name, COUNT=opened_files)
                IF opened_files EQ 0 AND not keyword_set(quiet) THEN MESSAGE, 'Error finding data files or directories!'

                number_of_lines = FILE_LINES(file[0])
                number_of_lines = number_of_lines[0]

                IF number_of_lines LE 0 THEN BEGIN
                        IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: conflict with input date(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('               data file', A,' is zero lenght.')", file_source_name
                                PRINT, ''
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Invalid data file of zero lenght. '
                        RETURN
                
                ENDIF

                tmp_data = STRARR(number_of_lines)

                OPENR, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_source_name
                        READF, lun, tmp_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun
                
                DataStruct  =  { day : 0, month : 0, year : 0, $
                                hour : 0, minute : 0, $
                                D : 0., H : 0., Z : 0., I:0., F : 0. }
                
                cabecera    = 4ll
                data_read   = REPLICATE(DataStruct, number_of_lines-cabecera)
                
                read_format = ''
                CASE 1 OF
                        STRLEN(tmp_data[cabecera]) LT 57 : read_format =  '(I2,X,I2,X,I4, X,I2,X,I2, X,F7,X,F7,X,F7,X,F7,X,F7)'
                        STRLEN(tmp_data[cabecera]) EQ 59 : read_format ='(X,I2,X,I2,X,I4,2X,I2,X,I2,2X,F7,X,F7,X,F7,X,F7,X,F7)'
                        STRLEN(tmp_data[cabecera]) EQ 61 : read_format =  '(I2,X,I2,X,I4, X,I2,X,I2, X,F8,X,F8,X,F8,X,F8,X,F8)'
                        ELSE                             : MESSAGE, 'Error in reading FORMAT'
                ENDCASE

                        ;read_format = (STRLEN(tmp_data[cabecera]) EQ 61) ? '(I2,X,I2,X,I4,X,I2,X,I2,X,F8,X,F8,X,F8,X,F8,X,F8)' : $
                        ;                                                   '(I2,X,I2,X,I4,X,I2,X,I2,X,F7,X,F7,X,F7,X,F7,X,F7)'
                IF STRLEN(read_format) GT 0 THEN READS, tmp_data[cabecera:number_of_lines-1], data_read, FORMAT=read_format

                tempvar = SIZE(TEMPORARY(tmp_data)) ; liberar memoria de la info no usada
        ENDIF ELSE BEGIN
                IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                        PRINT, FORMAT="('Input Warning: conflict with input date(s), data inconsistent or invalid.')"
                        PRINT, FORMAT="('               data file', A,' not available.')", file_source_name
                ENDIF
                error.value[3] += 1
                error.log      += 'Data file not available or invalid range of dates. '
                RETURN
        ENDELSE


        cabecera_final        = 18LL
        
        file_data             =STRARR(number_of_lines-cabecera+cabecera_final)
;help, file_data

        file_data[0]          =' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
        file_data[1]          =' Source of Data         Space Weather National Laboratory, UNAM                       |'
        str_tmp1 = ''
        for i = 0, 61 - STRLEN(gms[system.gms].name) DO str_tmp1+=' '
        file_data[2]          =' Station Name           '+ STRUPCASE(gms[system.gms].name)+str_tmp1+'|'
        file_data[3]          =' IAGA CODE              '+STRUPCASE(gms[system.gms].code)+'                                                           |'
        file_data[4]          =' Geodetic Latitude      '+STRING(gms[system.gms].latitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[5]          =' Geodetic Longitude     '+STRING(gms[system.gms].longitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[6]          =' Elevation              '+STRING(gms[system.gms].elevation,FORMAT='(F6.1)')+'                                                        |'
        file_data[7]          =' Reported               DHZF                                                          |'
        file_data[8]          =' Sensor Orientation     variation:DHZIF                                               |'
        file_data[9]          =' Digital Sampling       1 seconds                                                     |'
        file_data[10]         =' Data Interval Type     Filtered 1-minute (00:00:00 - 00:00:59)                       |'
        file_data[11]         =' Data Type              Reported                                                      |'
        file_data[12]         =' # Element              Geomagnetic field                                             |'
        file_data[13]         =' # Unit                 D(eastward+):minute, H:nT, Z(downward+):nT, F:nT              |'
        file_data[14]         =' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
        file_data[15]         =' # URL                  http://www.lance.unam.mx                                      |'
        file_data[16]         =' # Last Modified        Jan 25 2021                                                   |'

        tmp_code              = STRUPCASE(gms[system.gms].code)
        file_data[17]         ='DATE       TIME         DOY     '+tmp_code+'D      '+tmp_code+'H      '+tmp_code+'Z      '+tmp_code+'F                    |'

        FOR i = 0ll, number_of_lines-cabecera-1 DO BEGIN
                file_data[i+cabecera_final] = STRING(data_read[i].year,data_read[i].month,data_read[i].day, $
                                                     data_read[i].hour,data_read[i].minute,tmp_doy, $
                                                     data_read[i].D*60.,data_read[i].H, $
                                                     data_read[i].Z,data_read[i].F, $
                                                     FORMAT = '(I4,"-",I02,"-",I02,X,I02,":",I02,":00.000",X,I03,5X,'+ $
                                                               'F8.2,2x,F8.2,2x,F8.2,2x,F8.2,2x,F8.2)')
        ENDFOR



        data_file_name        = gms[system.gms].code+string(tmp_year,tmp_month,tmp_day, FORMAT='(I4,I02,I02)')+'rK.min'
        exist_data_file       = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+data_file_name)

        ;for i = 0LL, 18-1 DO PRINT, file_data[i]
        IF NOT exist_data_file OR keyword_set(force_all) THEN BEGIN
                OPENW, lun, system.datasource_dir+gms[system.gms].name+'/'+data_file_name, /GET_LUN, ERROR=err
                        IF err NE 0 THEN BEGIN
                IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Impossible to save output file ', A'.')", data_file_name
                                PRINT, FORMAT="('                missing directories or permissions conflict.')"
                        ENDIF
                        error.value[1] += 1
                        error.log      += 'Impossible to save output magnetic data file. '
                        RETURN
                ENDIF
                        
                FOR i=0LL, N_ELEMENTS(file_data)-1 DO PRINTF, lun, file_data[i]
                CLOSE, lun
                FREE_LUN, lun
                
                IF not keyword_set(quiet) THEN BEGIN
                        print, '        Saving: '+system.datasource_dir+gms[system.gms].name+'/'+data_file_name
                        print, ''
                ENDIF
        ENDIF

RETURN
END





PRO make_planetarymagneticdatafiles, date, STATION=station, $
                                           QUIET=quiet, $
                                           FORCE_ALL=force_all



        On_error, 2
        COMPILE_OPT idl2, HIDDEN
        
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons

        IF gms[system.gms].name NE 'planetary' THEN RETURN

;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_year   = date[0]
        initial_month  = date[1]
        initial_day    = date[2]

        string_date    = string(initial_year MOD 1000, initial_month, FORMAT='(I02,I02)')
        ;#######################################################################
        ; KP
        file_name      = 'kp'+string_date+'.wdc'

        file = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                IF opened_files NE N_ELEMENTS(file_name) THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('INPUT WARNING: conflict with input date(s), missed data file: ',A,'.')", file_name
                                PRINT, FORMAT="('               replacing missed values by data gaps.')"
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Invalid range of dates, replacing conflictive values with data gaps. '
                ENDIF
        ;print, opened_files
        
        IF opened_files GT 0 THEN BEGIN
                number_of_lines = FILE_LINES(file[0])
                magnetic_data   = STRARR(number_of_lines)

                OPENR, lun, file, /GET_LUN, ERROR=err
                        READF, lun, magnetic_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun
        ENDIF ELSE BEGIN
                number_of_lines = JULDAY(initial_month+1,0, initial_year) - JULDAY(initial_month,0, initial_year)
                magnetic_data   = STRARR(number_of_lines)
                FOR i = 0, number_of_lines-1 DO $
                        magnetic_data[i] = STRING(initial_year MOD 1000, initial_month, i+1, FORMAT='(I2,I2,I2)') + $
                                           '99999999999999999999999999999999999999999999999999999.99'
        ENDELSE
        
        Kp_data = INTARR(9)+999
        Ap_data = INTARR(9)+999

        line_string = STRING(initial_year MOD 1000, initial_month, initial_day, FORMAT='(I2,I2,I2)')
        
        valid_line = WHERE((STRCMP(line_string, magnetic_data[*], 6, /fold_case) GT 0))
        
        IF valid_line GE 0 THEN BEGIN
                IF STRLEN( valid_line ) GE 61 THEN BEGIN
                        READS, magnetic_data[valid_line], Kp_data, FORMAT='(12X, 8(I2), I3,:)'
                        READS, magnetic_data[valid_line], Ap_data, FORMAT='(31X, 9(I3), :)'
                ENDIF ELSE BEGIN
                        TMP_KP = INTARR(8)
                        READS, magnetic_data[valid_line], TMP_KP, FORMAT='(12X, 8(I2),:)'
                        Kp_data[0:7]=TMP_KP
                ENDELSE
                
                gaps_index = WHERE(Kp_data[0:7] GT 90)
                ;print, gaps_index
                IF gaps_index[0] GE 0 THEN BEGIN

                        Kp_data[gaps_index] = 999
                        Ap_data[gaps_index] = 999
                        
                        IF N_ELEMENTS(gaps_index) EQ 8 THEN BEGIN
                                Kp_data[8] = 999
                                Ap_data[8] = 999
                        ENDIF
                ENDIF
        ENDIF



        ;#######################################################################
        ; DST
        file_name      = '/dst'+string_date+'.dat'

        file = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/'+file_name, COUNT=opened_files)
                IF opened_files NE N_ELEMENTS(file_name) THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('INPUT WARNING: conflict with input date(s), missed data file: ',A,'.')", file_name
                                PRINT, FORMAT="('               replacing missed values by data gaps.')"
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Invalid range of dates, replacing conflictive values with data gaps. '
                ENDIF
        ;print, opened_files
        
        IF opened_files GT 0 THEN BEGIN
                number_of_lines = FILE_LINES(file[0])
                IF number_of_lines GT 0 THEN BEGIN
                        magnetic_data   = STRARR(number_of_lines)

                        OPENR, lun, file, /GET_LUN, ERROR=err
                        READF, lun, magnetic_data, FORMAT='(A)'
                        CLOSE, lun
                        FREE_LUN, lun
                        number_of_lines = JULDAY(initial_month+1,0, initial_year) - JULDAY(initial_month,0, initial_year)
                ENDIF
        ENDIF

        IF opened_files LE 0 OR number_of_lines LE 0 THEN BEGIN
                IF number_of_lines LE 0 THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('INCONSISTENCY WARNING: the requested conditions may compromise the computed results.')"
                                PRINT, FORMAT="('                       corrupted data file ', A, ' replacing corrupted data with gaps.')", file_name
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Corrupted data file '+file_name+', replacing conflictive values with data gaps. '
                ENDIF
                number_of_lines = JULDAY(initial_month+1,0, initial_year) - JULDAY(initial_month,0, initial_year)
                magnetic_data   = STRARR(number_of_lines)
                FOR i = 0, number_of_lines-1 DO $
                        magnetic_data[i] = 'DST'+STRING(initial_year MOD 1000, initial_month,'*',i+1, FORMAT='(I02,I02,A,I02)') + $
                                           'RRX020   0' + $
                                           '99999999999999999999999999999999999999999999999999'+ $
                                           '99999999999999999999999999999999999999999999999999'
        ENDIF

        Dst_data = INTARR(25) + 9999

        line_string = 'DST'+STRING(initial_year MOD 1000, initial_month, '*',initial_day, FORMAT='(I02,I02,A,I02)')
        
        valid_line = WHERE(STRCMP(line_string, magnetic_data[*], 10, /fold_case) GT 0)

        IF valid_line GE 0 THEN READS, magnetic_data[valid_line], Dst_data, FORMAT='(20X, 25(I4),:)'


;21 131255713 7 0 0 0 0 0 0 7 13  3  0  0  0  0  0  0  3  10.00
;21 4 1999999 999999999999999999 99 99 99 99 99 99 99 99  99.99

;print, kp_data
;print, ap_data

        ;READS, magnetic_data[initial_day-1]
        ;help, magnetic_data
;FOR i = 0, number_of_lines[0]-1 DO print, magnetic_data[i]
;print, initial_day+1
;print, magnetic_data[initial_day-1]
        cabecera_final        = 18LL
        file_data             =STRARR(24+cabecera_final)
        
        file_data[0]          =' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
        file_data[1]          =' Source of Data         Kp/Ap: GFZ Helmholtz Centre & Dst: WDC for Geomagnetism       |'
        str_tmp1 = ''
        for i = 0, 61 - STRLEN(gms[system.gms].name) DO str_tmp1+=' '
        file_data[2]          =' Station Name           '+STRUPCASE(gms[system.gms].name)+str_tmp1+'|'
        file_data[3]          =' IAGA CODE              '+STRUPCASE(gms[system.gms].code)+'                                                           |'
        file_data[4]          =' Geodetic Latitude      '+STRING(gms[system.gms].latitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[5]          =' Geodetic Longitude     '+STRING(gms[system.gms].longitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[6]          =' Elevation              '+STRING(gms[system.gms].elevation,FORMAT='(F6.1)')+'                                                        |'
        file_data[7]          =' Reported               [Kp][Sum(Kp)_24h][Ap][<Ap>_24h][Dst][<Dst>_24h]               |'
        file_data[8]          =' Sensor Orientation     variation: N/A                                                |'
        file_data[9]          =' Digital Sampling       3 hours/3 hours/1 hour                                        |'
        file_data[10]         =' Data Interval Type     Filtered hours [X=0,2] (00:00 - 0X:59)                        |'
        file_data[11]         =' Data Type              Reported                                                      |'
        file_data[12]         =' # Element              Planetary Indexes of Geomagnetic Activity                     |'
        file_data[13]         =' # Unit                 Kp [N/A] Ap [nT] Dst [nT]                                     |'
        file_data[14]         =' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
        file_data[15]         =' # URL                  http://www.lance.unam.mx                                      |'
        file_data[16]         =' # Last Modified        Mar 25 2021                                                   |'

        tmp_code              = STRUPCASE(gms[system.gms].code)
        file_data[17]         ='DATE       TIME         DOY     Kp    S(Kp)     Ap     <Ap>     Dst     <Dst>         |'

        tmp_doy    = JULDAY(initial_month, initial_day, initial_year)-JULDAY(1, 0, initial_year)
        
        for i = 18, 17+24 DO file_data[i] = STRING(initial_year, initial_month, initial_day, (i-18), 0, tmp_doy, $
                                    Kp_data[(i-18) / 3], Kp_data[8], Ap_data[(i-18) / 3], Ap_data[8], Dst_data[(i-18)], Dst_data[24], $
                                    FORMAT = '(I4,"-",I02,"-",I02,X,I02,":",I02,":00.000",X,I03,3X,'+ $
                                             'I4,5x,I4,2x,I5,4x,I5,3X,I5,5x,I5)')

;for i=0, N_ELEMENTS(file_data)-1 DO PRINT, file_data[i]

        data_file_name        = gms[system.gms].code+string(initial_year,initial_month,initial_day, FORMAT='(I4,I02,I02)')+'rK.min'
        exist_data_file       = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+data_file_name)

        ;for i = 0LL, 18-1 DO PRINT, file_data[i]
        IF NOT exist_data_file OR keyword_set(force_all) THEN BEGIN
                OPENW, lun, system.datasource_dir+gms[system.gms].name+'/'+data_file_name, /GET_LUN, ERROR=err
                        IF err NE 0 THEN BEGIN
                IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Impossible to save output file ', A'.')", data_file_name
                                PRINT, FORMAT="('                missing directories or permissions conflict.')"
                        ENDIF
                        error.value[1] += 1
                        error.log      += 'Impossible to save output magnetic data file. '
                        RETURN
                ENDIF
                        
                FOR i=0LL, N_ELEMENTS(file_data)-1 DO PRINTF, lun, file_data[i]
                CLOSE, lun
                FREE_LUN, lun
                
                IF not keyword_set(quiet) THEN BEGIN
                        print, '        Saving: '+system.datasource_dir+gms[system.gms].name+'/'+data_file_name
                        print, ''
                ENDIF
        ENDIF




RETURN
END

;DATE       TIME         DOY     PLAKp     PLAAp     PLADst                            |




;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
PRO geomagixs_magneticdata_iagafilestransform, initial_date, final_date, STATION=station, $
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

        ;kmex_setup_dates, STATION=station, QUIET=quiet
IF gms[system.gms].name NE 'planetary' THEN BEGIN
        files_number = JULDAY(final_date[1],final_date[2],final_date[0])-JULDAY(initial_date[1],initial_date[2],initial_date[0])+1
        
        init = JULDAY(initial_date[1],initial_date[2],initial_date[0])
        fin  = JULDAY(final_date[1],final_date[2],final_date[0])
        FOR i=init, fin DO BEGIN
                tmp_y = 0
                tmp_m = 0
                tmp_d = 0
                CALDAT, i, tmp_m, tmp_d, tmp_y
                
                make_magneticdatafiles, [tmp_y, tmp_m, tmp_d], STATION=station, QUIET=quiet, FORCE_ALL=force_all
        ENDFOR
ENDIF



IF gms[system.gms].name EQ 'planetary' THEN BEGIN
        files_number = JULDAY(final_date[1],final_date[2],final_date[0])-JULDAY(initial_date[1],initial_date[2],initial_date[0])+1
        
        init = JULDAY(initial_date[1],initial_date[2],initial_date[0])
        fin  = JULDAY(final_date[1],final_date[2],final_date[0])
        FOR i=init, fin DO BEGIN
                tmp_y = 0
                tmp_m = 0
                tmp_d = 0
                CALDAT, i, tmp_m, tmp_d, tmp_y
                
                make_planetarymagneticdatafiles, [tmp_y, tmp_m, tmp_d], STATION=station, QUIET=quiet, FORCE_ALL=force_all
        ENDFOR
ENDIF



RETURN
END
