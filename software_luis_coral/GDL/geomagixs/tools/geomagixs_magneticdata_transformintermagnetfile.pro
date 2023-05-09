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
FUNCTION getting_magneticdata_intermagnet, initial, STATION=station, $
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
                file_name = gms[system.gms].code+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'dmin.min'

                file = FILE_SEARCH(system.input_dir+'tmp/'+file_name, COUNT=opened_files)
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
                         hour : 0, minute : 0, DOY : 0, $
                         X : 0., Y : 0., Z : 0., F : 0. }
                         
        ;minutes_per_day = 24*60
        ;initial_minutes = initial_hour*60+initial_minute
        ;final_minutes   = final_hour*60+final_minute 
        ;data_number     = fix(total_of_data-initial_minutes-minutes_per_day+final_minutes)

        header         = 26
        ;print, number_of_lines-header
        resulting_data = REPLICATE(DataStruct, number_of_lines-header)

        READS, magnetic_data[header:number_of_lines-1], resulting_data, $
               FORMAT='(I4,X,I2,X,I2,X,I2,X,I2,8X,I3,5X,F8,2X,F8,2X,F8,2X,F8)'
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
PRO fixing_intermagnetfile, file_date, STATION=station, $
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
                header         = 18LL
                header_striing = STRARR(header)
                
                header_striing[0] =  ' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
                header_striing[1] =  ' Source of Data         Teoloyucan Magnetic Observatory, UNAM                         |'
                header_striing[2] =  ' Station Name           Teoloyucan                                                    |'
                header_striing[3] =  ' IAGA CODE              TEO                                                           |'
                header_striing[4] =  ' Geodetic Latitude      19.746                                                        |'
                header_striing[5] =  ' Geodetic Longitude     -99.193                                                       |'
                header_striing[6] =  ' Elevation              2280.0                                                        |'
                header_striing[7] =  ' Reported               DHZF                                                          |'
                header_striing[8] =  ' Sensor Orientation     absolute:DIF, variation:DFIF                                  |'
                header_striing[9] =  ' Digital Sampling       5 seconds                                                     |'
                header_striing[10] = ' Data Interval Type     Filtered 1-minute (00:15 - 01:45)                             |'
                header_striing[11] = ' Data Type              Reported                                                      |'
                header_striing[12] = ' # Element              Geomagnetic field                                             |'
                header_striing[13] = ' # Unit                 D(eastward+):minute, H:nT, Z(downward+):nT, F:nT              |'
                header_striing[14] = ' # Issued by            Instituto de Geofísica, UNAM, MÉXICO                          |'
                header_striing[15] = ' # URL                  http://132.248.6.186/                                         |'
                header_striing[16] = ' # Last Modified        Mar 31 2014                                                   |
                header_striing[17] = 'DATE       TIME         DOY     TEOD      TEOH      TEOZ      TEOF                    |

                ;file_name = station_code+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'rmin.min'
        
                source_file = gms[system.gms].code+string(initial_year, initial_month, initial_day, FORMAT='(I4,I02,I02)')+'dmin.min'

                file_exists = FILE_TEST(system.input_dir+'tmp/'+source_file)
 
                IF file_exists THEN BEGIN
                        IF not keyword_set(quiet) THEN  print, '        Extracting data from: '+source_file
                        source_data = getting_magneticdata_intermagnet([initial_year, initial_month, initial_day], STATION=station, QUIET=quiet)
                ENDIF ELSE BEGIN
                        IF not keyword_set(quiet) THEN PRINT, '        Data file not found!'
                ENDELSE

                data_number = N_ELEMENTS(source_data[*].year)
                file_string = STRARR(header+data_number)
                
                file_string[0:header-1] = header_striing[*]
                
                ;indexes_gap   = WHERE(source_data[*].X GE 99990.00)
                ;indexes_nogap = WHERE(source_data[*].X LT 99990.00)
                
                source_data_D = FLTARR(data_number)
                source_data_D[*] =(source_data[*].X LT 99990.00)*( asin(source_data[*].Y/sqrt(source_data[*].Y^2+source_data[*].X^2))*180./!PI*60. ) + $
                                  (source_data[*].X GE 99990.00)*999.00
                
                source_data_H = FLTARR(data_number)
                source_data_H[*] =(source_data[*].X LT 99990.00)*( sqrt(source_data[*].Y^2+source_data[*].X^2)) + $
                                  (source_data[*].X GE 99990.00)*99999.00
                                  
                source_data_F = FLTARR(data_number)
                source_data_F[*] =(source_data[*].F LT 99990.00)*source_data[*].F + $
                                  (source_data[*].F GE 99990.00 AND source_data[*].X LT 99990.00)*( sqrt(source_data_H[*]^2+source_data[*].Z^2)) + $
                                  (source_data[*].F GE 99990.00 AND source_data[*].X GE 99990.00)*99999.00
                
                FOR i=header, header+data_number-1 DO $
                        file_string[i] = string(source_data[i-header].year, source_data[i-header].month, source_data[i-header].day, $
                                                source_data[i-header].hour, source_data[i-header].minute, source_data[i-header].doy, $
                                                source_data_D[i-header], source_data_H[i-header], source_data[i-header].Z, source_data_F[i-header], $
                                       FORMAT='(I4,"-",I02,"-",I02, X, I02, ":", I02, ":00.000 ", I03, 7X, F6.2, 3(2X, F8.2))')


;##############################################################################
; creating data file
;##############################################################################
        ;output_datafile = station_code+'_'+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'.dat'
        output_datafile = gms[system.gms].code+string(tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)')+'rK.min'
        output_path     = system.datasource_dir+gms[system.gms].name+'/'
        
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
                        FOR i=0ll, header+data_number-1 DO PRINTF, lun, file_string[i]
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


PRO geomagixs_magneticdata_intermagnetfiletransform, initial, final, STATION=station, $
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
                ;print, i+1, '  ', string_date[i], '  ', processed_file_name[i]
        ENDFOR

        exist_data_file      = FILE_TEST(system.datasource_dir+gms[system.gms].name+'/'+data_file_name) AND not(keyword_set(force_all))

        IF N_ELEMENTS(where(exist_data_file EQ 0)) GT 1 THEN updating_files = N_ELEMENTS(where(exist_data_file EQ 0)) $
                ELSE IF where(exist_data_file EQ 0) GE 0 THEN updating_files = N_ELEMENTS(where(exist_data_file EQ 0)) $
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
        
                IF updating_files NE N_ELEMENTS(exist_data_file) AND not(keyword_set(quiet) OR keyword_set(force_all)) THEN BEGIN
                        PRINT, N_ELEMENTS(exist_data_file)-updating_files, FORMAT='("        There are still ",I," file(s) that can be updated.")'
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

        FOR i = 0ll, N_ELEMENTS(exist_data_file)-1 DO BEGIN
                IF exist_data_file[i] EQ 0 THEN BEGIN
                        tmp_year    = 0
                        tmp_month   = 0
                        tmp_day     = 0
                        READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                        fixing_intermagnetfile, [tmp_year, tmp_month, tmp_day], STATION=station, QUIET=quiet
                        ;print, tmp_year, tmp_month, tmp_day
                        ;tmp=getting_magneticdata_intermagnet([tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station)
                        ;print, tmp
                ENDIF
        ENDFOR

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Data-file(s) ready for computing!'
        ENDIF

RETURN


END




