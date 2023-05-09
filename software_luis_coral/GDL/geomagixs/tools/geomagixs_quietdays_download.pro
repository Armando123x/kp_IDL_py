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
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;SECUENCIA PRINCIPAL


PRO geomagixs_quietdays_download, initial, final, STATION=station, $
                                             QUIET=quiet, $
                                             FORCE_ALL=force_all

        On_error, 2
        ;Compile_OPT No es necesario 
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
        ;IF kmex_GMS GT 99 THEN BEGIN
        ;                        MESSAGE, 'Read manuals for help.'
        ;                        RETURN
        ;ENDIF

        geomagixs_setup_dates, STATION=station, QUIET=quiet

        update_flag = 0
        ;IF keyword_set(force_all) BEGIN
GOTO, jump
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
                                        error.value[0] += 2
                                        error.log      += 'Ambiguous range of dates, it is required only two input dates to define a time period. '
                                        RETURN
                                  END
        ENDCASE

                
jump:
        ;ENDIF
        

;##############################################################################
; initializing dates and hours
;##############################################################################
        initial_date = initial
        final_date   = final


;##############################################################################
; reading data files
;##############################################################################
        files_number = ((final_date[0] MOD 1000)-(initial_date[0] MOD 1000))/10+1

        IF not keyword_set(quiet) THEN BEGIN
                print, ''
                PRINT, files_number, FORMAT='("        A total of ",I," data-file(s) are going to be rewriten.")'
                PRINT, '        WARNING: Previous data will be PERMANENTLY lost if proceed!'
        ENDIF

        proceed = 'Y'
        REPEAT BEGIN
                IF not (keyword_set(quiet) OR keyword_set(force_all)) THEN READ, proceed, PROMPT='        Continue (Y/N)?: '
                proceed=STRUPCASE(proceed)
                IF proceed EQ 'N' OR proceed EQ 'NO' THEN RETURN
        ENDREP UNTIL proceed EQ 'Y' OR proceed EQ 'YES'


        files_source_name_k      = STRARR(files_number)
        directories_source_name  = STRARR(files_number)
        directories_destiny_name = STRARR(files_number)
        terminal_results_k       = STRARR(files_number)+''
        terminal_errors_k        = STRARR(files_number)+''

;###############################################################################
;###############################################################################
;###############################################################################
        for i=0, files_number-1 DO BEGIN
                tmp_millenium = (initial_date[0]/1000)*1000
                tmp_century   = (((initial_date[0] MOD 1000) / 100))*100
                tmp_decade    = (((initial_date[0] MOD 1000) MOD 100)/10+i)*10
                tmp_year      = tmp_millenium+tmp_century+tmp_decade
                
                today_julian = JULDAY(system.today_date[1],system.today_date[2],system.today_date[0])
                tmp_julian_0 = JULDAY(1, 1, tmp_year)
                tmp_julian_1 = JULDAY(12, 31, tmp_year+9)
                

                IF today_julian GE tmp_julian_0 AND today_julian LE tmp_julian_1 THEN $
                        files_source_name_k[i]      = 'qd'+string(tmp_year, tmp_decade/10, FORMAT='(I4,I01)')+'x.txt' $
                ELSE files_source_name_k[i]      = 'qd'+string(tmp_year, tmp_decade+9, FORMAT='(I4,I02)')+'.txt'
;                print, files_source_name_k[i]

                directories_source_name[i]  = 'ftp://ftp.gfz-potsdam.de/pub/home/obs/kp-ap/quietdst/'

                ;files_destiny_name[i]       = gms[system.gms].code+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'rmin.min'
                directories_destiny_name[i] = system.qdays_dir

                
                tmp_results = ''
                tmp_errors  = ''
                
                IF not keyword_set(quiet) THEN BEGIN
                        PRINT, ''
                        PRINT, tmp_year, FORMAT='("        Copying ", I04, "-decade data file.")'
                ENDIF

                
                spawn, 'wget '+directories_source_name[i]+files_source_name_k[i]+' -O '+directories_destiny_name[i]+files_source_name_k[i], tmp_results, tmp_errors

                ;SPAWN, 'curl '+directories_source_name[i]+files_source_name_k[i]+' -o '+directories_destiny_name[i]+files_source_name_k[i], tmp_results, tmp_errors


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

        ENDFOR

        failed_kfiles = STRPOS(strupcase(terminal_errors_k), 'NO EXIST')
        failed_kfiles = WHERE(failed_kfiles GE 0)


        IF TOTAL(failed_kfiles) GE 0 THEN failed_knumber = N_ELEMENTS(failed_kfiles) $
                ELSE failed_knumber = 0
                


        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, files_number-failed_knumber, FORMAT='("        A total of ", I," [qdYYY0yy.txt] files were saved.")'
                IF failed_knumber GT 0 THEN PRINT, failed_knumber, FORMAT='("                Missing ", I," qdYYY0yy.txt files!")'
        ENDIF




;###############################################################################
; QD data file SECTION
;###############################################################################
                        
        index_dates     = [0,0,0,0,0,0]
        
        ;FILE_TEST(system.auxiliar_dir+'qdays.dates', /READ)
        
        ;file_qd    = FILE_SEARCH(system.auxiliar_dir+'qdays.dates', COUNT=exist_qdfile)
        
        qdays_files              = FILE_SEARCH(system.qdays_dir+'qd??????.txt')
        qdays_files_number       = N_ELEMENTS(qdays_files)
        qdays_files_lines        = FILE_LINES(qdays_files)
        qdays_files_stringlenght = STRLEN(qdays_files)

        IF FIX(PRODUCT(FILE_TEST(qdays_files, /READ))) NE 1 THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read Q-days data file(s) ', A, '.')", 'qd??????.txt'
                        PRINT, FORMAT="('                check reading permissons or existence of input data file.')"
                ENDIF
                error.value[2] += 1
                error.log      += 'Q-days input file(s) '+'qd??????.txt'+' not found or reading permission conflict. Manually download quiet days files to fix it. '
                RETURN
        ENDIF
        
        READS, STRMID(qdays_files[0], qdays_files_stringlenght[0]-10, 3), qdays_initial_year, FORMAT='(I3)'
        READS, STRMID(qdays_files[qdays_files_number-1], qdays_files_stringlenght[qdays_files_number-1]-10, 3), qdays_final_year, FORMAT='(I3)'
        qdays_initial_year *=10
        qdays_final_year *=10
                
                ;print, FILE_LINES(qdays_files)/12
;print, qdays_files[0]
;print, qdays_files[qdays_files_number-1]


                
        IF qdays_files_number GT 1 THEN $
                IF TOTAL(FILE_LINES(qdays_files[0:qdays_files_number-2])/12) NE (qdays_files_number-1)*11 THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Critical Error: Conflict with input data. Qdays data missing or unable to be read.')"
                                PRINT, FORMAT="('                check reading permissons or the existence of Qdays data file.')"
                        ENDIF
                        error.value[2] += 1
                        error.log      += 'Q-days dates file '+'qdays.dates'+' not found or reading permission conflict. Manually download quiet days files to fix it. '
                ENDIF
        
                ;print, ((qdays_files_lines[qdays_files_number-1]-3) / 14), ((qdays_files_lines[qdays_files_number-1]-3) MOD 14)
        
        qdays_initial_year = FIX(qdays_initial_year)
        qdays_final_year   = FIX(qdays_final_year)+((qdays_files_lines[qdays_files_number-1]-4) / 14)
;print, qdays_initial_year, qdays_final_year
        
        tmp_months = ((qdays_files_lines[qdays_files_number-1]-4) MOD 14)
;print, tmp_months
        
        IF tmp_months LT 8 THEN qdays_final_month  = FIX(tmp_months) $
                           ELSE qdays_final_month  = FIX(tmp_months-1)
;print, qdays_final_month
        
        CALDAT, JULDAY (qdays_final_month+1, 0, qdays_final_year), tmp_month, qdays_final_day, temporal_year
        ;print, qdays_final_year, qdays_final_month, qdays_final_day

        index_dates[0:2] = [qdays_initial_year,1,1]
        ;CALDAT, JULDAY(final_date[1]+1,0,final_date[0]),tmp_m,tmp_d,tmp_y
        index_dates[3:5] = [qdays_final_year,qdays_final_month,qdays_final_day]
        
        file = system.auxiliar_dir+'qdays.dates'
        string_data = STRARR(2)
        string_data[0] = '# File with available data for quiet days [YYYYMMDD]-[YYYYMMDD]:'
        string_data[1] = STRING(index_dates, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')

                
        OPENW, lun, file, /GET_LUN, ERROR=err
                IF err NE 0 THEN MESSAGE, 'Error opening '+file
                FOR i = 0, N_ELEMENTS(string_data)-1 DO PRINTF, lun, string_data[i]
        CLOSE, lun
        FREE_LUN, lun
                
        IF NOT keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Updated '+'qdays.dates'+' file.'
                PRINT, STRING(index_dates,FORMAT='("                Date range: [",I4,I02,I02,"-",I4,I02,I02,"]")')
        ENDIF



        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        Q-days data files updated!'
        ENDIF

        return


END




