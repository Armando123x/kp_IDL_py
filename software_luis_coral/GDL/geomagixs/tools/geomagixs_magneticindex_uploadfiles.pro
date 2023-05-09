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
PRO geomagixs_magneticindex_uploadfiles, initial, final, STATION=station, $
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
        tmp                = where(exist_monthly_file EQ 1, capable_to_upload)
        ;capable_to_update  = N_ELEMENTS(exist_monthly_file)
        ;files_to_update = N_ELEMENTS(where(exist_monthly_file NE 1))
        tmp                = where(exist_monthly_file NE 1, files_to_update)

        ;print, capable_to_update, files_to_update
        
        IF not (keyword_set(quiet) OR keyword_set(force_all) ) THEN BEGIN
                IF capable_to_upload GT 0 THEN BEGIN
                        print, ''
                        PRINT, capable_to_update, FORMAT='("        A total of ",I," file(s) can be uploaded to the FTP server.")' 
                ENDIF ELSE BEGIN
                        print, ''
                        PRINT, "        No file(s) can be uploaded."
                        RETURN
                ENDELSE

                IF files_to_update GT 0 THEN BEGIN
                        PRINT, files_to_update, FORMAT='("        There are still ",I," missed file(s) that can be updated.")'
                        PRINT, '        Use MONTHLYFILE tool manually to updating all file(s).'
                        PRINT, ''
                ENDIF
        ENDIF

        tmp_year    = 0
        tmp_month   = 0
        tmp_day     = 0

        FOR i=0ll, month_number-1 DO BEGIN
        ;print, i, exist_monthly_file[i]
                IF exist_monthly_file[i] THEN BEGIN
        datatype = keyword_set(real_time) ? 'realtime/' : 'final/'
        datatype = gms[system.gms].code EQ 'pla' ? '' : datatype

IF keyword_set(real_time) THEN BEGIN
        extention = gms[system.gms].code EQ 'pla' ? '' : '.early'
        
        CALDAT, SYSTIME( /JULIAN , /UTC), M, D, Y
        dst_montly_file   = gms[system.gms].code+'_'+string(Y,M, FORMAT='(I4,I02)')+'.delta_H'+extention
        kmex_monthly_file = gms[system.gms].code+'_'+string(Y,M, FORMAT='(I4,I02)')+'.k_index'+extention

        spawn, 'sshpass -p '+system.ftp_password+' scp '+system.indexes_dir+gms[system.gms].name+'/'+dst_montly_file+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/'+gms[system.gms].name+'/'+datatype+dst_montly_file, tmp_results, tmp_errors
        spawn, 'sshpass -p '+system.ftp_password+' scp '+system.indexes_dir+gms[system.gms].name+'/'+kmex_monthly_file+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/'+gms[system.gms].name+'/'+datatype+kmex_monthly_file, tmp_results, tmp_errors


        CALDAT, JULDAY(final_date[1],final_date[2],final_date[0])-6, tmp_m, tmp_d, tmp_y
	IF gms[system.gms].code EQ 'pla' THEN BEGIN
        	dst_today_plot   = gms[system.gms].code+'_'+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'_07days.dH.png'
        	kmex_today_plot  = gms[system.gms].code+'_'+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'_07days.k.png'
	        
	        dst_latest_plot  = 'latest_dst.png'
        	kmex_latest_plot = 'latest_kp.png'
        ENDIF ELSE BEGIN
        	dst_today_plot       = gms[system.gms].code+'_'+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'_07days.dH.early.png'
        	kmex_today_plot      = gms[system.gms].code+'_'+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'_07days.k.early.png'
        	profiles_today_plot  = gms[system.gms].code+'_'+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'_07days.B.early.png'
	        
	        dst_latest_plot      = 'latest_'+gms[system.gms].code+'_dh.png'
        	kmex_latest_plot     = 'latest_'+gms[system.gms].code+'_k.png'
        	profile_latest_plot  = 'latest_'+gms[system.gms].code+'_B.png'
        ENDELSE

        spawn, 'sshpass -p '+system.ftp_password+' scp '+system.plots_dir+gms[system.gms].name+'/'+'7days/'+dst_today_plot+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/'+gms[system.gms].name+'/'+dst_latest_plot, tmp_results, tmp_errors
        
        spawn, 'sshpass -p '+system.ftp_password+' scp '+system.plots_dir+gms[system.gms].name+'/'+'7days/'+dst_today_plot+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/' +gms[system.gms].name+'/'+kmex_latest_plot, tmp_results, tmp_errors
        IF gms[system.gms].code NE 'pla' THEN $
                spawn, 'sshpass -p '+system.ftp_password+' scp '+system.plots_dir+gms[system.gms].name+'/'+'7days/'+dst_today_plot+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/'+gms[system.gms].name+'/'+profile_latest_plot, tmp_results, tmp_errors
ENDIF
                ENDIF
        ENDFOR

        IF not keyword_set(quiet) THEN BEGIN
                PRINT, ''
                PRINT, '        delta H-Plot files updated!'
        ENDIF

        RETURN


END
