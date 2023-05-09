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
PRO making_magneticdatafile, date, STATION=station, $
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
        IF (gms[system.gms].name EQ 'planetary') OR (gms[system.gms].name EQ 'teoloyucan') THEN RETURN
        
        
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

        
        file_source_name      = gms[system.gms].code+'n_'+string(tmp_year mod 1000, FORMAT='(I02)')+string(tmp_month, FORMAT='(I02)')+string(tmp_day, FORMAT='(I02)')+'.'+'min'

        exist_source_file     = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+file_source_name)

        IF exist_source_file GT 0 THEN BEGIN
                IF not keyword_set(quiet) THEN  print, '        Extracting data from: '+file_source_name
                file = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/'+file_source_name, COUNT=opened_files)
                IF opened_files EQ 0 AND not keyword_set(quiet) THEN MESSAGE, 'Error finding data files or directories!'

                number_of_lines = FILE_LINES(file[0])
                number_of_lines = number_of_lines[0]
                cabecera    = 4ll

                IF number_of_lines LE cabecera+1 THEN BEGIN
                        IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: conflict with input file(s), data inconsistent or invalid.')"
                                PRINT, FORMAT="('               data file ', A,' is zero lenght.')", file_source_name
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
                
                ;cabecera    = 4ll
                
                ;aux_value   = 0
                ;FOR i = cabecera, number_of_lines-1 DO $
                ;        IF (STRLEN(tmp_data[i]) GT 61) OR (STRLEN(tmp_data[i]) LT 56) THEN aux_value +=1
                
                aux_line_lenght = STRLEN(tmp_data[cabecera])
                aux_value_00 = TOTAL( STRLEN(tmp_data[cabecera:number_of_lines-1] ) )
                aux_value_01 = (number_of_lines-cabecera)*aux_line_lenght
                aux_value_02 = (number_of_lines-cabecera)*62
                ;print, aux_value_00,aux_value_01,aux_value_02,(number_of_lines-cabecera)
                ;IF aux_value_00 LT aux_value_01 OR aux_value_00 GT aux_value_02 THEN aux_value   = 1
                ;IF aux_value_00 NE aux_value_01 THEN aux_value   = 1
                
                IF aux_value_00 NE aux_value_01 THEN BEGIN
                        bad_indexes = WHERE( STRLEN(tmp_data[cabecera:number_of_lines-1] ) NE aux_line_lenght, bad_lines )
                        
                        IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: conflict with input file(s), data format inconsistent or invalid.')"
                                PRINT, FORMAT="('               data file ', A,' has ', I0,' corrupted line(s).')", file_source_name, bad_lines
                                PRINT, ''
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Corrpted data file. '
                        
                        
                        ;print, good_indexes
                        ;RETURN
                
                ENDIF
                
                good_indexes = WHERE( STRLEN(tmp_data[cabecera:number_of_lines-1] ) EQ aux_line_lenght, good_lines )
                
                read_format = (STRLEN(tmp_data[cabecera]) EQ 62) ? '(X,I2,X,I2,X,I4,X,I2,X,I2,2X,F7,2X,F7,3X,F6,2X,F7,2X,F7)' : $
                                                                   '(X,I2,X,I2,X,I4,X,I2,X,I2,2X,F7,2X,F7,3X,F6,2X,F7,2X,F7)'
                
                ;data_read   = REPLICATE(DataStruct, number_of_lines-cabecera)
                data_read   = REPLICATE(DataStruct, good_lines)
                ;READS, tmp_data[cabecera:number_of_lines-1], data_read, $
                READS, tmp_data[cabecera+good_indexes], data_read, $
                       FORMAT=read_format
                tempvar = SIZE(TEMPORARY(tmp_data)) ; liberar memoria de la info no usada

        ENDIF ELSE BEGIN
                IF NOT keyword_set(quiet) OR keyword_set(force_all) THEN BEGIN
                        PRINT, FORMAT="('Input Warning: conflict with input date(s), data inconsistent or invalid.')"
                        PRINT, FORMAT="('               data file ', A,' not available.')", file_source_name
                ENDIF
                error.value[3] += 1
                error.log      += 'Data file not available or invalid range of dates. '
                RETURN
        ENDELSE


        cabecera_final        = 18LL
        
        file_data             =STRARR(good_lines+cabecera_final)
;help, file_data

        file_data[0]          =' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
        file_data[1]          =' Source of Data         Huancayo Magnetic Observatory, IGP                            |'
        str_tmp1 = ''
        for i = 0, 62 - STRLEN(gms[system.gms].name) DO str_tmp1+=' '
        file_data[2]          =' Station Name           '+ STRUPCASE(gms[system.gms].name)+str_tmp1+'|'
        file_data[3]          =' IAGA CODE              '+STRUPCASE(gms[system.gms].code)+'                                                           |'
        file_data[4]          =' Geodetic Latitude      '+STRING(gms[system.gms].latitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[5]          =' Geodetic Longitude     '+STRING(gms[system.gms].longitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[6]          =' Elevation              '+STRING(gms[system.gms].elevation,FORMAT='(F6.1)')+'                                                        |'
        file_data[7]          =' Reported               DHZF                                                          |'
        file_data[8]          =' Sensor Orientation     variation:DHZF                                                |'
        file_data[9]          =' Digital Sampling       1 seconds                                                     |'
        file_data[10]         =' Data Interval Type     Filtered 1-minute (00:00 - 00:59)                             |'
        file_data[11]         =' Data Type              Reported                                                      |'
        file_data[12]         =' # Element              Geomagnetic field                                             |'
        file_data[13]         =' # Unit                 D(eastward+):minute, H:nT, Z(downward+):nT, F:nT              |'
        file_data[14]         =' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
        file_data[15]         =' # URL                  http://www.lance.unam.mx                                      |'
        file_data[16]         =' # Last Modified        Jan 25 2021                                                   |'

        tmp_code              = STRUPCASE(gms[system.gms].code)
        file_data[17]         ='DATE       TIME         DOY      '+tmp_code+'D     '+tmp_code+'H       '+tmp_code+'Z     '+tmp_code+'F                    |'

        FOR i = 0ll, good_lines-1 DO BEGIN
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
                IF STRLEN( valid_line ) GE 62 THEN BEGIN
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


        cabecera_final        = 18LL
        file_data             =STRARR(24+cabecera_final)
        
        file_data[0]          =' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
        file_data[1]          =' Source of Data         Kp/Ap: GFZ Helmholtz Centre & Dst: WDC for Geomagnetism       |'
        str_tmp1 = ''
        for i = 0, 62 - STRLEN(gms[system.gms].name) DO str_tmp1+=' '
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
        file_data[15]         =' # URL                  http://www.sciesmex.unam.mx                                   |'
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


PRO geomagixs_magneticdata_download, initial, final, STATION=station, $
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

        ;IF kmex_GMS GT 99 THEN BEGIN
        ;                        MESSAGE, 'Read manuals for help.'
        ;                        RETURN
        ;ENDIF

        geomagixs_setup_dates, STATION=station, QUIET=quiet

        update_flag = 0
        ;IF keyword_set(force_all) BEGIN
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

                
        ;ENDIF
        

;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_date = initial
        final_date   = final



        ;initial_year   = initial[0]
        ;initial_month  = initial[1]
        ;initial_day    = initial[2]

        ;final_year     = final[0]
        ;final_month    = final[1]
        ;final_day      = final[2]




;##############################################################################
; reading data files
;##############################################################################
        IF gms[system.gms].name EQ 'planetary' THEN files_number = (final_date[0]-initial_date[0])*12+(final_date[1]-initial_date[1])+1 $
                ELSE files_number = JULDAY(final_date[1],final_date[2],final_date[0])-JULDAY(initial_date[1],initial_date[2],initial_date[0])+1

        IF not keyword_set(quiet) THEN BEGIN
                IF update_flag EQ 0 THEN BEGIN
                        print, ''
                        PRINT, files_number, FORMAT='("        A total of ",I," days of data-file(s) are going to be rewriten.")'
                        PRINT, '        WARNING: Previous data will be PERMANENTLY lost if proceed!'
                ENDIF ELSE BEGIN
                        PRINT, files_number, FORMAT='("        A total of ",I," data-file(s) are going to be updated.")' 
                        print, ''
                ENDELSE
        ENDIF

        proceed = 'Y'
        REPEAT BEGIN
                IF not (keyword_set(quiet) OR keyword_set(force_all)) THEN READ, proceed, PROMPT='        Continue (Y/N)?: '
                proceed=STRUPCASE(proceed)
                IF proceed EQ 'N' OR proceed EQ 'NO' THEN RETURN
                ;PRINT, ''
        ENDREP UNTIL proceed EQ 'Y' OR proceed EQ 'YES'


        files_source_name_k      = STRARR(files_number)
        files_source_name_r      = STRARR(files_number)
        directories_source_name  = STRARR(files_number)
        files_destiny_name       = STRARR(files_number)
        directories_destiny_name = STRARR(files_number)
        terminal_results_k       = STRARR(files_number)+''
        terminal_errors_k        = STRARR(files_number)+''
        terminal_results_r       = STRARR(files_number)+''
        terminal_errors_r        = STRARR(files_number)+''

;###############################################################################
;###############################################################################
;###############################################################################
IF gms[system.gms].name EQ 'teoloyucan' THEN BEGIN

        for i=0, files_number-1 DO BEGIN
                tmp_y = 0
                tmp_m = 0
                tmp_d = 0
                CALDAT, JULDAY(initial_date[1],initial_date[2],initial_date[0])+i, tmp_m, tmp_d, tmp_y
                
                files_source_name_k[i]        = gms[system.gms].code+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'rK.min'
                files_source_name_r[i]        = gms[system.gms].code+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'rmin.min'
                ;directories_source_name[i]    = system.ssh_user+'@www.rice.unam.mx:/vol0/kpmex/'+gms[system.gms].code+'/'+string(tmp_y, FORMAT='(I4)')+'/'
                directories_source_name[i]    = system.ssh_user+'@'+system.ssh_address+gms[system.gms].code+'/'+string(tmp_y, FORMAT='(I4)')+'/'

                ;files_destiny_name[i]       = gms[system.gms].code+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'rmin.min'
                directories_destiny_name[i] = system.datasource_dir+gms[system.gms].name+'/'
                
                tmp_results = ''
                tmp_errors  = ''
                
                IF not keyword_set(quiet) THEN BEGIN
                        PRINT, ''
                        PRINT, tmp_y, tmp_m, tmp_d, FORMAT='("        Copying ", I04,I02,I02, " data files.")'
                ENDIF

                spawn, 'sshpass -p '+system.ssh_password+' scp '+directories_source_name[i]+files_source_name_k[i]+' '+directories_destiny_name[i]+files_source_name_k[i], tmp_results, tmp_errors
                terminal_results_k[i] = tmp_results
                terminal_errors_k[i]  = tmp_errors


                spawn, 'sshpass -p '+system.ssh_password+' scp '+directories_source_name[i]+files_source_name_r[i]+' '+directories_destiny_name[i]+files_source_name_r[i], tmp_results, tmp_errors
                terminal_results_r[i] = tmp_results
                terminal_errors_r[i]  = tmp_errors
                ;print, STRLEN(terminal_results_k[i]), STRLEN(terminal_errors_k[i]), STRLEN(terminal_results_r[i]), STRLEN(terminal_errors_r[i])
                ;IF terminal_errors_r[i] GT '' THEN print, 'hola'
                ;print, directories_source_name[i]+files_source_name[i]+' '+directories_destiny_name[i]+files_destiny_name[i], terminal_results[i], terminal_errors[i]
                IF not keyword_set(quiet) THEN BEGIN
                        IF (terminal_errors_r[i] EQ '') OR (terminal_errors_k[i] EQ '') THEN PRINT, '                At least one data-file was correctly stored.' $
                        ELSE PRINT, '                Errors during adquisition or storing data-files!'
                ENDIF
        ENDFOR

        failed_kfiles = WHERE(terminal_errors_k GT '')
        failed_rfiles = WHERE(terminal_errors_r GT '')

        IF TOTAL(failed_kfiles) GT 0 THEN failed_knumber = N_ELEMENTS(failed_kfiles) $
                ELSE failed_knumber = 0
                
        IF TOTAL(failed_rfiles) GT 0 THEN failed_rnumber = N_ELEMENTS(failed_rfiles) $
                ELSE failed_rnumber = 0

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, files_number-failed_knumber, files_number-failed_rnumber, FORMAT='("        A total of ", I," [RK.MIN] and ", I, " [RMIN-MIN] files were saved.")'
                PRINT, ''
                IF failed_knumber GT 0 THEN PRINT, failed_knumber, gms[system.gms].code, FORMAT='("                Missing ", I," ", A,"YYYYMMDDrk.min files!")'
                IF failed_rnumber GT 0 THEN PRINT, failed_rnumber, gms[system.gms].code, FORMAT='("                Missing ", I," ", A,"YYYYMMDDrmin.min files!")'
        ENDIF
ENDIF

;###############################################################################
;###############################################################################
;###############################################################################
IF gms[system.gms].name NE 'planetary' AND gms[system.gms].name NE 'teoloyucan' THEN BEGIN

        for i=0, files_number-1 DO BEGIN
                tmp_y = 0
                tmp_m = 0
                tmp_d = 0
                CALDAT, JULDAY(initial_date[1],initial_date[2],initial_date[0])+i, tmp_m, tmp_d, tmp_y
                
                CASE 1 OF
                        tmp_m EQ 1  : tmp_string = 'jan'
                        tmp_m EQ 2  : tmp_string = 'feb'
                        tmp_m EQ 3  : tmp_string = 'mar'
                        tmp_m EQ 4  : tmp_string = 'apr'
                        tmp_m EQ 5  : tmp_string = 'may'
                        tmp_m EQ 6  : tmp_string = 'jun'
                        tmp_m EQ 7  : tmp_string = 'jul'
                        tmp_m EQ 8  : tmp_string = 'aug'
                        tmp_m EQ 9  : tmp_string = 'sep'
                        tmp_m EQ 10 : tmp_string = 'oct'
                        tmp_m EQ 11 : tmp_string = 'nov'
                        tmp_m EQ 12 : tmp_string = 'dec'
                        ELSE: MESSAGE, 'Critial error'
                ENDCASE
                
                
                files_source_name_k[i]      = gms[system.gms].code+string(tmp_d, FORMAT='(I02)')+tmp_string+'.'+string(tmp_y MOD 1000, FORMAT='(I02)');+'m'
                ;directories_source_name[i]  = 'ftp://132.248.208.46/magnetic_data/'+gms[system.gms].name+'/'+string(tmp_y, FORMAT='(I4)')+'/'
                directories_source_name[i]  = system.ftp_address+'datamin/'+gms[system.gms].name+'/'+string(tmp_y, FORMAT='(I4)')+'/';'/DataMin/'
                
; ##############################################################################
;       NOTA
; 
                
                ;files_destiny_name[i]       = gms[system.gms].code+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'rmin.min'
                directories_destiny_name[i] = system.datasource_dir+gms[system.gms].name+'/'
                
                tmp_results  = ''
                tmp_errors   = ''
                tmp_resultsv = ''
                tmp_errorsv  = ''
                
                IF not keyword_set(quiet) THEN BEGIN
                        PRINT, ''
                        PRINT, tmp_y, tmp_m, tmp_d, FORMAT='("        Copying ", I04,I02,I02, " data files.")'
                ENDIF

                ;spawn, 'wget --user='+system.ftp_user+' --password='+system.ftp_password+' '+ directories_source_name[i]+files_source_name_k[i]+' -O '+directories_destiny_name[i]+files_source_name_k[i], tmp_results, tmp_errors
                SPAWN, 'curl -u '+system.ftp_user+':'+system.ftp_password+' -f '+ directories_source_name[i]+files_source_name_k[i]+'v'+' -o '+directories_destiny_name[i]+files_source_name_k[i]+'v', tmp_resultsv, tmp_errorsv
                SPAWN, 'curl -u '+system.ftp_user+':'+system.ftp_password+' -f '+ directories_source_name[i]+files_source_name_k[i]+'m'+' -o '+directories_destiny_name[i]+files_source_name_k[i]+'m', tmp_results, tmp_errors
;print, 'curl -u '+system.ftp_user+':'+system.ftp_password+' -f '+ directories_source_name[i]+files_source_name_k[i]+'v'+' -o '+directories_destiny_name[i]+files_source_name_k[i]+'v'
;stop                ;print, 'curl -u '+system.ftp_user+':'+system.ftp_password+' -f '+ directories_source_name[i]+files_source_name_k[i]+' -o '+directories_destiny_name[i]+files_source_name_k[i]
                ;print, '1: '+tmp_results
                ;print, '2: '+tmp_errors
                ;print, tmp_results
                ;print, tmp_errors
                ;curl -f http://nonexistent/file.jpg -o localfile.jpg
                ;curl -u user:password 'ftp://mysite/%2fusers/myfolder/myfile/raw' -o ~/Downloads/myfile.raw
                ;wget -q --spider http://www.tmp.org
                ;echo $?
                
                
                ;print, 'wget --user=regmex --password=r3gm3x-m0r3l14 '+ directories_source_name[i]+files_source_name_k[i]+' '+directories_destiny_name[i]+files_source_name_k[i]

                making_magneticdatafile, [tmp_y, tmp_m, tmp_d], STATION=station, QUIET=quiet, FORCE_ALL=force_all

                IF N_ELEMENTS(tmp_errors) GT 1 THEN BEGIN
                        tmp_errs = ''
                        FOR j=0, N_ELEMENTS(tmp_errors)-1 DO tmp_errs += tmp_errors[j]+' '
                        tmp_errors = tmp_errs
                ENDIF
                
                IF N_ELEMENTS(tmp_errorsv) GT 1 THEN BEGIN
                        tmp_errs = ''
                        FOR j=0, N_ELEMENTS(tmp_errorsv)-1 DO tmp_errs += tmp_errorsv[j]+' '
                        tmp_errors += tmp_errs
                ENDIF
                
                IF N_ELEMENTS(tmp_results) GT 1 THEN BEGIN
                        tmp_res = ''
                        FOR j=0, N_ELEMENTS(tmp_results)-1 DO tmp_res += tmp_results[j]+' '
                        tmp_results = tmp_res
                ENDIF
                
                IF N_ELEMENTS(tmp_resultsv) GT 1 THEN BEGIN
                        tmp_res = ''
                        FOR j=0, N_ELEMENTS(tmp_resultsv)-1 DO tmp_res += tmp_resultsv[j]+' '
                        tmp_results += tmp_res
                ENDIF

                terminal_results_k[i] = tmp_results
                terminal_errors_k[i]  = tmp_errors
;print, terminal_results_k[i]
;print, terminal_errors_k[i]
                failed_kfiles = STRPOS(strupcase(terminal_errors_k[i]), 'RETR')+STRPOS(strupcase(terminal_errors_k[i]), 'DENIED')

                ;print, STRLEN(terminal_results_k[i]), STRLEN(terminal_errors_k[i]), STRLEN(terminal_results_r[i]), STRLEN(terminal_errors_r[i])
                ;IF terminal_errors_r[i] GT '' THEN print, 'hola'
                ;print, directories_source_name[i]+files_source_name[i]+' '+directories_destiny_name[i]+files_destiny_name[i], terminal_results[i], terminal_errors[i]
                IF not keyword_set(quiet) THEN BEGIN
                        IF (failed_kfiles LT 0) THEN PRINT, '                The data-file was correctly stored.' $
                        ELSE PRINT, '                Errors during adquisition, file not available!'
                ENDIF
        ENDFOR
        failed_kfiles = STRPOS(strupcase(terminal_errors_k), 'RETR')
        failed_kfiles = WHERE(failed_kfiles GE 0)

        IF TOTAL(failed_kfiles) GT 0 THEN failed_knumber = N_ELEMENTS(failed_kfiles) $
                ELSE failed_knumber = 0
                

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, 2*(files_number-failed_knumber), FORMAT='("        A total of ", I," [gms_YYMMDD.min] files were saved.")'
                IF failed_knumber GT 0 THEN PRINT, 2*failed_knumber, FORMAT='("                Missing ", I,"gms_YYMMDD.min files!")'
        ENDIF
ENDIF



;###############################################################################
;###############################################################################
;###############################################################################
IF gms[system.gms].name EQ 'planetary' THEN BEGIN

        for i=0, files_number-1 DO BEGIN
                tmp_y = 0
                tmp_m = 0
                tmp_d = 0
                CALDAT, JULDAY(initial_date[1]+i,1,initial_date[0]), tmp_m, tmp_d, tmp_y
                ;tmp_string = string(tmp_y MOD 1000, tmp_m, FORMAT='(I02,I02)')
                
                files_source_name_k[i]      = 'kp'+string(tmp_y MOD 1000, tmp_m, FORMAT='(I02,I02)')+'.wdc'
                
                directories_source_name[i]  = 'ftp://ftp.gfz-potsdam.de/pub/home/obs/kp-ap/wdc/'
                
                 IF JULDAY(initial_date[1]+i,1,initial_date[0]) EQ JULDAY(system.today_date[1],1,system.today_date[0]) THEN BEGIN
                        directories_source_name[i]  = 'http://www-app3.gfz-potsdam.de/kp_index/'
                        files_source_name_k[i]      = 'qlyymm.wdc'
                        ;print, 'si'
                 ENDIF
                
                 IF JULDAY(initial_date[1]+i+1,1,initial_date[0]) EQ JULDAY(system.today_date[1],1,system.today_date[0]) THEN BEGIN
                        directories_source_name[i]  = 'http://www-app3.gfz-potsdam.de/kp_index/'
                        files_source_name_k[i]      = 'pqlyymm.wdc'
                 ENDIF

                ;files_destiny_name[i]       = gms[system.gms].code+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'rmin.min'
                directories_destiny_name[i] = system.datasource_dir+gms[system.gms].name+'/'
                
                tmp_results = ''
                tmp_errors  = ''
                
                IF not keyword_set(quiet) THEN BEGIN
                        PRINT, ''
                        PRINT, tmp_y, tmp_m, FORMAT='("        Copying ", I04,I02, " data files.")'
                ENDIF

                
                ;IF JULDAY(initial_date[1]+i,1,initial_date[0]) EQ JULDAY(system.today_date[1],1,system.today_date[0]) THEN BEGIN
                ;        directories_source_name[i]  = 'http://www-app3.gfz-potsdam.de/kp_index/'
                ;        spawn, 'wget '+directories_source_name[i]+'qlyymm.wdc'+' -O '+directories_destiny_name[i]+files_source_name_k[i], tmp_results, tmp_errors
                ;ENDIF ELSE spawn, 'wget '+directories_source_name[i]+files_source_name_k[i]+' -O '+directories_destiny_name[i]+files_source_name_k[i], tmp_results, tmp_errors
                ;spawn, 'wget '+directories_source_name[i]+files_source_name_k[i]+' -O '+directories_destiny_name[i]+files_source_name_k[i], tmp_results, tmp_errors


                spawn, 'wget '+directories_source_name[i]+files_source_name_k[i]+' -O '+directories_destiny_name[i]+'kp'+string(tmp_y MOD 1000, tmp_m, FORMAT='(I02,I02)')+'.wdc', tmp_results, tmp_errors

                IF N_ELEMENTS(tmp_errors) GT 1 THEN BEGIN
                        tmp_errs = ''
                        FOR j=0, N_ELEMENTS(tmp_errors)-1 DO tmp_errs += tmp_errors[j]+' '
                        tmp_errors = tmp_errs
                ENDIF
                
                IF N_ELEMENTS(tmp_results) GT 1 THEN BEGIN
                        tmp_res = ''
                        FOR j=0, N_ELEMENTS(tmp_results)-1 DO tmp_res += tmp_results[j]+' '
                        tmp_results = tmp_res
                ENDIF

                terminal_results_k[i] = tmp_results
                terminal_errors_k[i]  = tmp_errors


                files_source_name_r[i]      = 'dst'+string(tmp_y MOD 1000, tmp_m, FORMAT='(I02,I02)')
                directories_source_name[i]  = 'http://wdc.kugi.kyoto-u.ac.jp/dst_realtime/'+string(tmp_y, tmp_m, FORMAT='(I04,I02)')+'/'

                spawn, 'wget '+directories_source_name[i]+files_source_name_r[i]+'.for.request -O '+directories_destiny_name[i]+files_source_name_r[i]+'.dat', tmp_results, tmp_errors

                IF N_ELEMENTS(tmp_errors) GT 1 THEN BEGIN
                        tmp_errs = ''
                        FOR j=0, N_ELEMENTS(tmp_errors)-1 DO tmp_errs += tmp_errors[j]+' '
                        tmp_errors = tmp_errs
                ENDIF
                
                IF N_ELEMENTS(tmp_results) GT 1 THEN BEGIN
                        tmp_res = ''
                        FOR j=0, N_ELEMENTS(tmp_results)-1 DO tmp_res += tmp_results[j]+' '
                        tmp_results = tmp_res
                ENDIF

                terminal_results_r[i] = tmp_results
                terminal_errors_r[i]  = tmp_errors





                IF not keyword_set(quiet) THEN BEGIN
                        IF (terminal_errors_r[i] EQ '') OR (terminal_errors_k[i] EQ '') THEN PRINT, '                At least one data-file was correctly stored.' $
                        ELSE PRINT, '                Errors during adquisition or storing data-files!'
                ENDIF
        ENDFOR

        failed_kfiles = STRPOS(strupcase(terminal_errors_k), 'NO EXIST')
        failed_kfiles = WHERE(failed_kfiles GE 0)
        failed_rfiles = STRPOS(strupcase(terminal_errors_r), 'ERROR')
        failed_rfiles = WHERE(failed_kfiles GE 0)


        IF TOTAL(failed_kfiles) GE 0 THEN failed_knumber = N_ELEMENTS(failed_kfiles) $
                ELSE failed_knumber = 0
                
        IF TOTAL(failed_rfiles) GE 0 THEN failed_rnumber = N_ELEMENTS(failed_rfiles) $
                ELSE failed_rnumber = 0



        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, files_number-failed_knumber, files_number-failed_rnumber, FORMAT='("        A total of ", I," [kpYYMM.wdc] and ", I, " [dstYYMM.dat] files were saved.")'
                IF failed_knumber GT 0 THEN PRINT, failed_knumber, FORMAT='("                Missing ", I," kpYYMM.wdc files!")'
                IF failed_rnumber GT 0 THEN PRINT, failed_rnumber, FORMAT='("                Missing ", I," dstYYMM.dat files!")'
        ENDIF

        files_number = JULDAY(final_date[1],final_date[2],final_date[0])-JULDAY(initial_date[1],initial_date[2],initial_date[0])+1

        for i=0, files_number-1 DO BEGIN
                tmp_y = 0
                tmp_m = 0
                tmp_d = 0
                CALDAT, JULDAY(initial_date[1],initial_date[2],initial_date[0])+i, tmp_m, tmp_d, tmp_y
                
                make_planetarymagneticdatafiles, [tmp_y, tmp_m, tmp_d], STATION=station, QUIET=quiet, /force_all
                ;geomagixs_make_iagadatafiles, [tmp_y, tmp_m, tmp_d], [tmp_y, tmp_m, tmp_d], STATION=station, QUIET=quiet, /force_all

        ENDFOR


ENDIF


        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Magnetic data files updated!'
        ENDIF

        return


END




