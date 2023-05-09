;+
; NAME:
;       geomagixs_magneticindex_monthlyfile
;
;
; PURPOSE:
;
;       program to generats the montly file of the magnetic indexes for a given GMS
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Instituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro
;       Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 18.viii.mmxxii
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       geomagixs_magneticindex_monthlyfile, initial, final [, STATION=station, QUIET=quiet, FORCE_ALL=force_all, REAL_TIME=real_time]
;
;       Description:
;       It makes TXT files with the computed values of magnetic indexes of input
;       months for a given GMS.
;
; PARAMETERS:
;       initial    : initial date for the range of output files
;       final      : final date for the range of output files [final >= initial]
;
; KEYWORD PARAMETERS:
;
;       STATION    : named variable with the name or code of the given GMS
;       /QUIET     : set to supress the messages from the program
;       /REAL_TIME : set to use real-time K_mex data for ploting
;       /FORCE_ALL : set to force the program to overwrite pre-existing files,
;                    also avoids to waith for the user's assitance
;
; DEPENDENCIAS:
;       geomagixs system
;
; ARCHIVOS ANALIZADOS:
;       GMS_YYYYMMDD.index.[final/early]
;
; ARCHIVOS DE SALIDA:
;
; HISTORIA:
;-
;##############################################################################
;## AUXILARY FUNCTIONS AND PROGRAMS SECTION
;##
;## The fuctions and programs are:
;##     * reading_deltah_data (date [,STATION=station,REAL_TIME=real_time,QUIET=quiet])
;##     * makeing_kmex_plot, initial, final[, STATION = station, REAL_TIME = real_time, QUIET = quiet, PNG = png, JPEG = jpeg, DIR=dir, ERROR=error]
;##     * making_dhplot, initial, final, N_DAYS=n_days[, STATION=station, QUIET=quiet, REAL_TIME=real_time, PNG = png, JPEG = jpge, DIR = dir, ERROR=error]
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
                IF opened_files EQ 0 THEN MESSAGE, 'Error finding K-index data files or directories!'
                
        number_of_lines  = FILE_LINES(file)
        k_index_data = STRARR(number_of_lines)

        OPENR, lun, file, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[0]
                READF, lun, k_index_data, FORMAT='(A)'
        CLOSE, lun
        FREE_LUN, lun


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

        
        dat_str = { z : [0,0,0,0,0,0,0,0], y : 0}
        tmp_var = REPLICATE(dat_str,6)
        READS, k_index_data, tmp_var, FORMAT='(I3,X,I3,X,I3,X,I3,X,I3,X,I3,X,I3,X,I3,X,I3)';'(8(I3,X), I3)'
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
;##############################################################################
;##############################################################################
;##############################################################################
PRO making_montlyfile_k, initial, STATION = station, $
                                  REAL_TIME = real_time, $
                                  QUIET = quiet

        On_error, 2
        COMPILE_OPT idl2

;##############################################################################
; initialize directories
;##############################################################################
        ;kmex_setup
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
        file_number    = (JULDAY(initial_month+1, 0, initial_year) - JULDAY(initial_month, 0, initial_year))
        data_file_name = strarr(file_number)
        ;years          = intarr(file_number)
        ;months         = intarr(file_number)
        ;days           = intarr(file_number)
        string_date     = strarr(file_number)
        ;exist_file     = intarr(file_number)
        extention       = keyword_set(real_time) ? '.early' : '.final'
        extention       = STATION EQ 'planetary' ? '' : extention
       
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
                data_file_name[i] = gms[system.gms].code+'_'+string_date[i]+'.k_index'+extention
                ;kmex_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                ;print, i+1, '  ', data_file_name[i]
        ENDFOR

        exist_data_file   = FILE_TEST(system.indexes_dir+gms[system.gms].name+'/'+data_file_name)
        tmp               = where(exist_data_file EQ 1, capable_to_make)

        IF capable_to_make NE N_ELEMENTS(data_file_name) AND NOT keyword_set(quiet) THEN BEGIN 
                PRINT, FORMAT="('Input Warning: Invalid values, replacing conflictive values with data gaps.')"
                PRINT, FORMAT="('               missing GMS_YYYYMMDD.k_index',A,'.')", extention
                Error.value[3] += 1
                error.log      += 'Impossible to read index dH-file; file not found or reading permission conflict. '
        ENDIF
         
        ;dH_sigma_data    = FLTARR(file_number*24)
        ;dH_data          = FLTARR(file_number*25)
        k_mex_data    = INTARR(file_number*8)
        k_SUM_data    = INTARR(file_number)
        a_mex_data    = INTARR(file_number*8)
        a_median_data = INTARR(file_number)
        
        FOR i = 0, file_number-1 DO BEGIN
                IF exist_data_file[i] EQ 1 THEN BEGIN
                ;IF exist_data_file[i] THEN BEGIN
                        tmp_year    = 0
                        tmp_month   = 0
                        tmp_day     = 0
                        READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                        ;print, tmp_year, tmp_month, tmp_day
                        tmp_data    = reading_kmex_data([tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, REAL_TIME=real_time)
                        k_mex_data[i*8:(i+1)*8-1] = tmp_data.K_mex[*]
                        a_mex_data[i*8:(i+1)*8-1] = tmp_data.a_mex[*]
                        k_SUM_data[i]             = tmp_data.K_SUM
                        a_median_data[i]          = tmp_data.A_median
                        ;print, dH_sigma_data[i*24:(i+1)*24-1]
                        ;print, string_date[i], k_mex_data[i*8:(i+1)*8-1]
                        ;print, string_date[i], a_mex_data[i*8:(i+1)*8-1]
                        ;print, tmp_data.K_mex[*]
                ENDIF ELSE BEGIN
                        k_mex_data[i*8:(i+1)*8-1] = 999
                        a_mex_data[i*8:(i+1)*8-1] = 999
                        k_SUM_data[i]             = 999
                        a_median_data[i]          = 999
                ENDELSE
        ENDFOR


        cabecera_final        = 21LL
        
        file_data             =STRARR(file_number+cabecera_final)
;help, file_data
;definitive
;nowcast   
        data_type             = keyword_set(real_time) ? '(nowcast)   ' : '(definitive)'

        file_data[0]          =' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
        file_data[1]          =' Source of Data         Space Weather National Laboratory, UNAM                       |'
        str_tmp1 = ''
        for i = 0, 61 - STRLEN(gms[system.gms].name) DO str_tmp1+=' '
        file_data[2]          =' Station Name           '+ STRUPCASE(gms[system.gms].name)+str_tmp1+'|'
        file_data[3]          =' IAGA CODE              '+STRUPCASE(gms[system.gms].code)+'                                                           |'
        file_data[4]          =' Geodetic Latitude      '+STRING(gms[system.gms].latitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[5]          =' Geodetic Longitude     '+STRING(gms[system.gms].longitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[6]          =' Elevation              '+STRING(gms[system.gms].elevation,FORMAT='(F6.1)')+'                                                        |'
        file_data[7]          =' Reported               K and a indexes '+data_type+'                                  |'
        file_data[8]          =' Sensor Orientation     variation:DHZF                                                |'
        file_data[9]          =' Digital Sampling       1 seconds                                                     |'
        file_data[10]         =' Data Interval Type     Filtered 3-hours (00:00:00 - 02:59:59)                        |'
        file_data[11]         =' Data Type              Computed                                                      |'
        file_data[12]         =' # Element              16 3-hourly values, and daily-total (k) and daily-average (a) |'
        file_data[13]         =' # Unit                 nT                                                            |'
        file_data[14]         =' # Data Gap             999                                                           |'
        file_data[15]         =' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
        file_data[16]         =' # URL                  http://www.lance.unam.mx                                      |'
        file_data[17]         =' # Last Modified        Aug 17 2022                                                   |'
        file_data[18]         =' # File type            Monthly                                                       |'
        file_data[19]         =' # Reading Format       (I4,I2,I2,3X,I3,3X,9(X, I3),3X,9(X, I3))                      |'

        tmp_code              = STRUPCASE(gms[system.gms].code)
        file_data[20]         ='DATE       DOY   K:03  06  09  12  15  18  21  24 Tot   a:03  06  09  12  15  18  21  24 Avg |'
;DATE       DOY   K:03  06  09  12  15  18  21  24 Tot   a:03  06  09  12  15  18  21  24 Avg
;YYYYMMDD***123****003 010 023 013 007 023 030 017 127****002 004 009 005 003 009 015 006 006
;##############################################################################
; making plot
;##############################################################################
        extention       = keyword_set(real_time) ? '.early' : '.final'
        extention       = STATION EQ 'planetary' ? '' : extention

        file_name = gms[system.gms].code+'_'+string(initial_year,initial_month, FORMAT='(I4,I02,".k_index")')+extention
        ;file_dir  = kmex_plot_dir
        file_dir  = system.indexes_dir+gms[system.gms].name+'/'

        OPENW, lun, file_dir+file_name, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing data file!

                FOR i = 0, cabecera_final-1 DO PRINTF, lun, file_data[i]
                
                FOR i = 0, file_number-1 DO BEGIN
                        tmp_year    = 0
                        tmp_month   = 0
                        tmp_day     = 0
                        READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                        tmp_doy = JULDAY(tmp_month, tmp_day, tmp_year)-JULDAY(1, 0, tmp_year)
                        PRINTF, lun, tmp_year, tmp_month, tmp_day, tmp_doy, $
                                     k_mex_data[i*8:(i+1)*8-1], k_SUM_data[i], $
                                     a_mex_data[i*8:(i+1)*8-1], a_median_data[i], FORMAT='(I4,I02,I02,3X,I03,3X,9(X, I3),3X,9(X, I3))'
                        ;PRINT, tmp_year, tmp_month, tmp_day, tmp_doy, $
                        ;             k_mex_data[i*8:(i+1)*8-1], k_SUM_data[i], $
                        ;             a_mex_data[i*8:(i+1)*8-1], a_median_data[i], FORMAT='(I4,I02,I02,3X,I03,3X,9(X, I3),3X,9(X, I3))'
                        ;PRINT, tmp_year, tmp_month, tmp_day, tmp_doy, dH_data[i*25:(i+1)*25-1], FORMAT='(I4,I02,I02,3X,I03,3X,25(X, F8.1))'
                ENDFOR
        CLOSE, lun
        FREE_LUN, lun

        IF NOT keyword_set(quiet) THEN BEGIN
                print, '        Saving: '+file_name
                print, ''
        ENDIF

;print, file_number
;print, k_mex_data

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
FUNCTION reading_deltah_data, date, STATION=station, $
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

        
        file_name       = system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_'+string_date+'.delta_H'+extention

        file = FILE_SEARCH(file_name, COUNT=opened_files)
                IF opened_files EQ 0 THEN MESSAGE, 'Error finding dH-index data files or directories!'
                
        number_of_lines  = FILE_LINES(file)
        k_index_data = STRARR(number_of_lines)

        OPENR, lun, file, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[0]
                READF, lun, k_index_data, FORMAT='(A)'
        CLOSE, lun
        FREE_LUN, lun


        result = { $
                  delta_H      : FLTARR(25), $
                  sigma_H      : FLTARR(25) $
                 }

        
        dat_str = { z : FLTARR(25) }
        tmp_var = REPLICATE(dat_str,2)
        ;if string_date EQ '20210113' THEN BEGIN
        ;        print, 
        ;ENDIF
        READS, k_index_data, tmp_var, FORMAT='(X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8,X,F8)';'(8(I3,X), I3)'
        result.delta_H[*] = tmp_var[0].z[0:24]
        result.sigma_H[*] = tmp_var[1].z[0:24]
        RETURN, result
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
PRO making_montlyfile_dh, initial, STATION = station, $
                                  REAL_TIME = real_time, $
                                  QUIET = quiet

        On_error, 2
        COMPILE_OPT idl2

;##############################################################################
; initialize directories
;##############################################################################
        ;kmex_setup
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
        file_number    = (JULDAY(initial_month+1, 0, initial_year) - JULDAY(initial_month, 0, initial_year))
        data_file_name = strarr(file_number)
        ;years          = intarr(file_number)
        ;months         = intarr(file_number)
        ;days           = intarr(file_number)
        string_date     = strarr(file_number)
        ;exist_file     = intarr(file_number)
        extention       = keyword_set(real_time) ? '.early' : '.final'
        extention       = STATION EQ 'planetary' ? '' : extention
       
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
                data_file_name[i] = gms[system.gms].code+'_'+string_date[i]+'.delta_H'+extention
                ;kmex_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                ;print, i+1, '  ', data_file_name[i]
        ENDFOR

        exist_data_file   = FILE_TEST(system.indexes_dir+gms[system.gms].name+'/'+data_file_name)
        tmp               = where(exist_data_file EQ 1, capable_to_make)

        IF capable_to_make NE N_ELEMENTS(data_file_name) AND NOT keyword_set(quiet) THEN BEGIN 
                PRINT, FORMAT="('Input Warning: Invalid values, replacing conflictive values with data gaps.')"
                PRINT, FORMAT="('               missing GMS_YYYYMMDD.delta_H',A,'.')", extention
                Error.value[3] += 1
                error.log      += 'Impossible to read index dH-file; file not found or reading permission conflict. '
        ENDIF
         
        ;dH_sigma_data    = FLTARR(file_number*24)
        dH_data          = FLTARR(file_number*25)
        
        FOR i = 0, file_number-1 DO BEGIN
                IF exist_data_file[i] EQ 1 THEN BEGIN
                ;IF exist_data_file[i] THEN BEGIN
                        tmp_year    = 0
                        tmp_month   = 0
                        tmp_day     = 0
                        READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                        ;print, tmp_year, tmp_month, tmp_day
                        tmp_data    = reading_deltah_data([tmp_year, tmp_month, tmp_day], QUIET=quiet, STATION=station, REAL_TIME=real_time)
                        ;print, tmp_data.delta_H[0:24]
                        ;dH_sigma_data[i*24:(i+1)*24-1] = tmp_data.sigma_H[*]
                        dH_data[i*25:(i+1)*25-1]       = tmp_data.delta_H[*]
                        ;print, dH_sigma_data[i*24:(i+1)*24-1]
                        ;print, string_date[i], k_mex_data[i*8:(i+1)*8-1]
                        ;print, string_date[i], a_mex_data[i*8:(i+1)*8-1]
                        ;print, tmp_data.K_mex[*]
                ENDIF ELSE dH_data[i*25:(i+1)*25-1]       = 999999.
                ;ENDELSE
        ENDFOR

        cabecera_final        = 21LL
        
        file_data             =STRARR(file_number+cabecera_final)
;help, file_data
        data_type             = keyword_set(real_time) ? '(nowcast)   ' : '(definitive)'

        file_data[0]          =' FORMAT                 IAGA-2002x (Extended IAGA2002 Format)                         |'
        file_data[1]          =' Source of Data         Space Weather National Laboratory, UNAM                       |'
        str_tmp1 = ''
        for i = 0, 61 - STRLEN(gms[system.gms].name) DO str_tmp1+=' '
        file_data[2]          =' Station Name           '+ STRUPCASE(gms[system.gms].name)+str_tmp1+'|'
        file_data[3]          =' IAGA CODE              '+STRUPCASE(gms[system.gms].code)+'                                                           |'
        file_data[4]          =' Geodetic Latitude      '+STRING(gms[system.gms].latitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[5]          =' Geodetic Longitude     '+STRING(gms[system.gms].longitude,FORMAT='(F8.3)')+'                                                      |'
        file_data[6]          =' Elevation              '+STRING(gms[system.gms].elevation,FORMAT='(F6.1)')+'                                                        |'
        file_data[7]          =' Reported               Delta H '+data_type+'                                          |'
        file_data[8]          =' Sensor Orientation     variation:DHZF                                                |'
        file_data[9]          =' Digital Sampling       1 seconds                                                     |'
        file_data[10]         =' Data Interval Type     Filtered 1-hour (00:00:00 - 00:59:59)                         |'
        file_data[11]         =' Data Type              Computed                                                      |'
        file_data[12]         =' # Element              24 hourly-values per row                                      |'
        file_data[13]         =' # Unit                 nT                                                            |'
        file_data[14]         =' # Data Gap             999999.0                                                      |'
        file_data[15]         =' # Issued by            Instituto de Geofísica, UNAM, MEXICO                          |'
        file_data[16]         =' # URL                  http://www.lance.unam.mx                                      |'
        file_data[17]         =' # Last Modified        Aug 17 2022                                                   |'
        file_data[18]         =' # File type            Monthly                                                       |'
        file_data[19]         =' # Reading Format       (I4,I2,I2,3X,I3,3X,25(X, F8))                                 |'

        tmp_code              = STRUPCASE(gms[system.gms].code)
        file_data[20]         ='DATE       DOY          01       02       03       04       05       06       07       08       09       10       11       12       13       14       15       16       17       18       19       20       21       22       23       24      Avg |'

;##############################################################################
; making plot
;##############################################################################
        extention       = keyword_set(real_time) ? '.early' : '.final'
        extention       = STATION EQ 'planetary' ? '' : extention

        file_name = gms[system.gms].code+'_'+string(initial_year,initial_month, FORMAT='(I4,I02,".delta_H")')+extention
        ;file_dir  = kmex_plot_dir
        file_dir  = system.indexes_dir+gms[system.gms].name+'/'

        OPENW, lun, file_dir+file_name, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error while writing data file!

                FOR i = 0, cabecera_final-1 DO PRINTF, lun, file_data[i]
                
                FOR i = 0, file_number-1 DO BEGIN
                        tmp_year    = 0
                        tmp_month   = 0
                        tmp_day     = 0
                        READS, string_date[i], tmp_year, tmp_month, tmp_day, FORMAT='(I4,I02,I02)'
                        tmp_doy = JULDAY(tmp_month, tmp_day, tmp_year)-JULDAY(1, 0, tmp_year)
                        PRINTF, lun, tmp_year, tmp_month, tmp_day, tmp_doy, dH_data[i*25:(i+1)*25-1], FORMAT='(I4,I02,I02,3X,I03,3X,25(X, F8.1))'
                        ;PRINT, tmp_year, tmp_month, tmp_day, tmp_doy, dH_data[i*25:(i+1)*25-1], FORMAT='(I4,I02,I02,3X,I03,3X,25(X, F8.1))'
                ENDFOR
        CLOSE, lun
        FREE_LUN, lun

        IF NOT keyword_set(quiet) THEN BEGIN
                print, '        Saving: '+file_name
                print, ''
        ENDIF

;print, file_number
;print, k_mex_data

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




;SECUENCIA PRINCIPAL
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
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
PRO geomagixs_magneticindex_monthlyfile, initial, final, STATION=station, $
                                       QUIET=quiet, $
                                       FORCE_ALL=force_all, $
                                       REAL_TIME=real_time
        
        On_error, 2
        COMPILE_OPT idl2, HIDDEN
;##############################################################################
; initialize directories
;##############################################################################
        @geomagixs_commons
        geomagixs_setup_commons, /QUIET
        geomagixs_check_system, /QUIET
        geomagixs_setup_dates, STATION=station, /QUIET, /FORCE_ALL

;##############################################################################
; depuring inputs
;##############################################################################
        geomagixs_check_gms, STATION=station, /QUIET

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
        month_number    = (final_month-initial_month) + (final_year-initial_year)*12 + 1

        files_number       = (JULDAY(final_month+1, 0, final_year) - JULDAY(initial_month, 0, initial_year))
        ;days_ina_week   = 7
        ;print, month_number, files_number
        data_deltah_name   = strarr(files_number)
        data_kmex_name     = strarr(files_number)
        data_profiles_name = strarr(files_number)
        ;years           = intarr(file_number)
        ;months          = intarr(file_number)
        ;days            = intarr(file_number)
        string_date     = strarr(files_number)
        ;exist_file     = intarr(file_number)
        extention       = keyword_set(real_time) ? '.early' : '.final'
        extention       = STATION EQ 'planetary' ? '' : extention

        data_month_dh_name    = strarr(month_number)
        data_month_k_name     = strarr(month_number)
        data_month_prof_name  = strarr(month_number)

        FOR i=0ll, month_number-1 DO BEGIN
                tmp_year = initial_year + (i+initial_month-1) / 12
                tmp_month = ((i+initial_month) MOD 12)*((i+initial_month) MOD 12 NE 0) +  (12)*((i+initial_month) MOD 12 EQ 0)
                ;months[i] = tmp_month
                ;days[i]   = tmp_day
                string_date[i]    = string(tmp_year, tmp_month, FORMAT='(I4,I02)')
                ;data_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                data_month_dh_name[i]    = gms[system.gms].code+'_'+string_date[i]+'.delta_H'+extention
                data_month_k_name[i]     = gms[system.gms].code+'_'+string_date[i]+'.k_index'+extention
                data_month_prof_name[i]  = gms[system.gms].code+'_'+string_date[i]+'.profiles'+extention
                ;kmex_file_name[i] = station_code+'_'+string_date[i]+'.dat'
                ;print, i+1, '  ', string_date[i]
        ENDFOR

        ;exist_result_file = FILE_TEST(kmex_processed_dir+station_code+'_'+string_date+'.data'+extention) AND not(keyword_set(force_all))
        exist_monthly_file = FILE_TEST(system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_'+data_month_k_name[*]) AND (keyword_set(force_all) EQ 0 )
        capable_to_update  = N_ELEMENTS(exist_monthly_file)
        files_to_update = N_ELEMENTS(where(exist_monthly_file NE 1))

        ;print, capable_to_update, files_to_update
        
        IF not (keyword_set(quiet) OR keyword_set(force_all) ) THEN BEGIN
                IF TOTAL(files_to_update) GT 0 THEN BEGIN
                        print, ''
                        PRINT, files_to_update, FORMAT='("        A total of ",I," file(s) need to be updated.")' 
                ENDIF ELSE BEGIN
                        print, ''
                        PRINT, "        No file requires to be updated."
                        RETURN
                ENDELSE

                IF capable_to_update GT files_to_update THEN BEGIN
                        PRINT, capable_to_update-files_to_update, FORMAT='("        There are still ",I," file(s) that can be updated.")'
                        PRINT, '        Use the /FORCE_ALL keyword to force the updating of all file(s).'
                        PRINT, ''
                ENDIF
        ENDIF

        tmp_year    = 0
        tmp_month   = 0
        tmp_day     = 0

        FOR i=0ll, month_number-1 DO BEGIN
        ;print, i, exist_monthly_file[i]
                IF exist_monthly_file[i] EQ 0 THEN BEGIN
                        READS, string_date[i], tmp_year, tmp_month, FORMAT='(I4,I2)'
                        ;print, string_date[i], tmp_year, tmp_month
                        making_montlyfile_dh, [tmp_year, tmp_month,1], STATION=gms[system.gms].name, QUIET=quiet, REAL_TIME=real_time
                        making_montlyfile_k, [tmp_year, tmp_month,1], STATION=gms[system.gms].name, QUIET=quiet, REAL_TIME=real_time
                        ;making_k_monthfile, [tmp_year, tmp_mont], STATION=gms[system.gms].name, QUIET=quiet, REAL_TIME=real_time
                        ;making_dhplot, [tmp_year, tmp_month, 1], N_DAYS=3, STATION=station, QUIET=quiet, REAL_TIME=real_time
                        ;making_dhplot, [tmp_year, tmp_month, 1], N_DAYS=7, STATION=station, QUIET=quiet, REAL_TIME=real_time
                ENDIF
        ENDFOR

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        delta H-Plot files updated!'
        ENDIF

        RETURN


END
