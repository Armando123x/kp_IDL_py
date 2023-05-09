;+
; NAME:
;       geomagixs
;
;
; PURPOSE:
;
;       main script for making a general update on the data of kmex-system
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Instituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro
;       Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 16.x.mmxvii
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       geomagixs
;
;       Description:
;       the script implements all the kmex-updaters, and other requiered sequences
;
;
; PARAMETERS:
;       Not requiered
;
; KEYWORD PARAMETERS:
;
;       Not requiered
;
; DEPENDENCIAS:
;       all the kmex file tree
;
; ARCHIVOS ANALIZADOS:
;       No one directly
;
; ARCHIVOS DE SALIDA:
;       No one directly
;
; HISTORIA:
;       01 nov 17       ver 1.0 in total function for real-time
;       24 aug 22       ver 2.0 multiple impruvements
;-



;https://stackoverflow.com/questions/11162341/running-idl-program-from-bash-with-variables
;https://www.l3harrisgeospatial.com/docs/command_line_options_for.html


;se requieren curl, ssh, sshpass, cron

; dar de alta a cron:
; sudo systemctl enable cron




PRO geomagixs


        On_error, 2
        COMPILE_OPT idl2, hidden

        CALDAT, SYSTIME( /JULIAN )+3./(24.*60.), M, D, Y, hr, mi
        PRINT, '###########################'
        PRINT, 'Update LOG-file'
        PRINT, 'Local time: ',Y,M,D,hr,mi, FORMAT='(A,I04,"/",I02,"/",I02,X,I02,":",I02)'
        CALDAT, SYSTIME( /JULIAN , /UTC)+3./(24.*60.), M, D, Y, hr, mi
        PRINT, 'UTC   time: ',Y,M,D,hr,mi, FORMAT='(A,I04,"/",I02,"/",I02,X,I02,":",I02)'
        PRINT, '###########################'

passed_args = COMMAND_LINE_ARGS( COUNT=args_number)
        IF args_number LT 2 OR args_number GT 3 THEN RETURN

;print, passed_args
working_dir = passed_args[0]
gms_stn     = passed_args[1]
real_time   = keyword_set(0)
;print, keyword_set(real_time)
IF args_number EQ 3 THEN $
        IF '-REAL_TIME' EQ STRUPCASE(passed_args[2]) THEN real_time = keyword_set(1) ELSE RETURN
;print, keyword_set(real_time)


;IF real_time THEN print, 'REAL_TIME' ELSE print, 'FINAL'

textoidl_directory  = STRMID(working_dir[0], 0, STRPOS (working_dir[0], '/geomagixs', /REVERSE_SEARCH))+'/textoidl'
!PATH = !PATH +':'+$
        EXPAND_PATH('+'+working_dir[0])+':'+$
        EXPAND_PATH('+'+textoidl_directory)
;print, !PATH
;quiet=1
;print, !QUIET

RESOLVE_ROUTINE, 'julday',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'caldat',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'moment',/COMPILE_FULL_FILE, /EITHER;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'stddev',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'poly_fit',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'mean',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'poly_fit',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'interpol',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'ts_smooth',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'ts_fcast',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'ts_coef',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'textoidl',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'textable',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'strtrans',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'strsplit',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'translate_sub_super',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'nexttok',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'loadct',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'filepath',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING
RESOLVE_ROUTINE, 'path_sep',/COMPILE_FULL_FILE, /EITHER, /NO_RECOMPILE;, /IS_FUNCTION, /NO_RECOMPILE, /QUIET, /SKIP_EXISTING

;##############################################################################
; starting system
;##############################################################################
        geomagixs_setup_commons;, /quiet
        ; [D,H,Z]
        ;offset = [0.19, 65.0, 6.20]

;return

;##############################################################################
; defining global variables
;##############################################################################
; NOTE: if kmex_startup_commons.pro is modified, it is mandatory to modify the
;       forthcoming "COMMON GEOMAGIXS_COMMONS" stantment
;##############################################################################
        COMMON GEOMAGIXS_COMMONS,   System, $
                                    Flag_commons, $
                                    Flag_setup, $ ; usada
                                    Flag_dates, $
                                    Flag_error, $
                                    Flag_system, $
                                    GMS, $
                                    Error, $
                                    Dates


;##############################################################################
; checking system
;##############################################################################
	geomagixs_check_system

        geomagixs_check_gms, STATION=gms_stn, /force_all
;return
;##############################################################################
; depuring inputs
;##############################################################################
	;GMS_set = ['pla', 'coe']

;FOR i=0, N_ELEMENTS(GMS_set)-1 DO BEGIN

	;geomagixs_check_gms, STATION=GMS_set[i], /force_all


	geomagixs_setup_dates, STATION=gms[system.gms].name, /force_all

	initial_date = JULDAY(system.today_date[1],system.today_date[2],system.today_date[0]) LT JULDAY(gms[system.gms].dates_data[1,1],gms[system.gms].dates_data[1,2],gms[system.gms].dates_data[1,0]) ? $
		       system.today_date[*] : gms[system.gms].dates_data[1,*]
	final_date   = system.today_date[*]

;##############################################################################
; updating magnetic source files
;##############################################################################
        geomagixs_quietdays_download, initial_date, final_date, /force_all
	geomagixs_magneticdata_download, initial_date, final_date, STATION=gms[system.gms].name, /force_all
	geomagixs_magneticdata_prepare, initial_date, final_date, STATION=gms[system.gms].name, /force_all;, OFFSET=offset
	geomagixs_magneticdata_process, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
        
;##############################################################################
; loading dates
;##############################################################################
	geomagixs_magneticindex_compute, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
        geomagixs_magneticindex_monthlyfile, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
	
	geomagixs_setup_dates, STATION=gms[system.gms].name, /force_all, /update_file


;##############################################################################
; REAL TIME section
;##############################################################################
        
        ;CALDAT, SYSTIME( /JULIAN , /UTC), M, D, Y, hr, mi
        ;tmp_minutes = 60.-float(mi)
        ;***********************************************
        ;IF tmp_minutes GT 0. THEN WAIT, tmp_minutes*60.
        ;***********************************************
	geomagixs_magneticindex_plotk, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
	
	geomagixs_magneticindex_plotdh, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
        
	geomagixs_magneticindex_plotb, initial_date, final_date, STATION=gms[system.gms].name, /force_all, REAL_TIME=real_time
;return        

        ;dst_latest_plot  = 'latest_'+gms[system.gms].code+'_dh.png'
        ;kmex_latest_plot = 'latest_'+gms[system.gms].code+'_kmex.png'

	;IF GMS_set[i] EQ 'coe' THEN BEGIN
        ;	dst_today_plot   = gms[system.gms].code+'_'+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'_07days.dH.early.png'
        ;	kmex_today_plot  = gms[system.gms].code+'_'+string(tmp_y,tmp_m,tmp_d, FORMAT='(I4,I02,I02)')+'_07days.k.early.png'
	;        
	;        dst_latest_plot  = 'latest_teo_dh.png'
        ;	kmex_latest_plot = 'latest_teo_kmex.png'
        ;ENDIF


        datatype = keyword_set(real_time) ? 'realtime/' : 'final/'
        datatype = gms[system.gms].code EQ 'pla' ? '' : datatype

        IF keyword_set(real_time) THEN BEGIN
                extention = gms[system.gms].code EQ 'pla' ? '' : '.early'
        
                CALDAT, SYSTIME( /JULIAN , /UTC), M, D, Y
                dst_montly_file   = gms[system.gms].code+'_'+string(Y,M, FORMAT='(I4,I02)')+'.delta_H'+extention
                kmex_monthly_file = gms[system.gms].code+'_'+string(Y,M, FORMAT='(I4,I02)')+'.k_index'+extention

                spawn, 'sshpass -p '+system.ftp_password+' scp '+system.indexes_dir+gms[system.gms].name+'/'+dst_montly_file+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/'+gms[system.gms].name+'/'+datatype+dst_montly_file, tmp_results, tmp_errors
                IF STRLEN(tmp_errors) GT 0 THEN BEGIN
                        PRINT, dst_montly_file, FORMAT="('Warning Error: Errors detected during upload of ',A,' file.')"
                        PRINT, FORMAT="('               it is mandatory manually check and solve the issue(s).')"
                ENDIF ELSE BEGIN
                        PRINT, ''
                        PRINT, dst_montly_file, FORMAT="('        ',A,' file upload success!')"
                ENDELSE

                
                spawn, 'sshpass -p '+system.ftp_password+' scp '+system.indexes_dir+gms[system.gms].name+'/'+kmex_monthly_file+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/'+gms[system.gms].name+'/'+datatype+kmex_monthly_file, tmp_results, tmp_errors
                IF STRLEN(tmp_errors) GT 0 THEN BEGIN
                        PRINT, kmex_monthly_file, FORMAT="('Warning Error: Errors detected during upload of ',A,' file.')"
                        PRINT, FORMAT="('               it is mandatory manually check and solve the issue(s).')"
                ENDIF ELSE BEGIN
                        PRINT, ''
                        PRINT, kmex_monthly_file, FORMAT="('        ',A,' file upload success!')"
                ENDELSE


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
                IF STRLEN(tmp_errors) GT 0 THEN BEGIN
                        PRINT, dst_latest_plot, FORMAT="('Warning Error: Errors detected during upload of ',A,' file.')"
                        PRINT, FORMAT="('               it is mandatory manually check and solve the issue(s).')"
                ENDIF ELSE BEGIN
                        PRINT, ''
                        PRINT, dst_latest_plot, FORMAT="('        ',A,' file upload success!')"
                ENDELSE

                spawn, 'sshpass -p '+system.ftp_password+' scp '+system.plots_dir+gms[system.gms].name+'/'+'7days/'+kmex_today_plot+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/' +gms[system.gms].name+'/'+kmex_latest_plot, tmp_results, tmp_errors
                IF STRLEN(tmp_errors) GT 0 THEN BEGIN
                        PRINT, kmex_latest_plot, FORMAT="('Warning Error: Errors detected during upload of ',A,' file.')"
                        PRINT, FORMAT="('               it is mandatory manually check and solve the issue(s).')"
                ENDIF ELSE BEGIN
                        PRINT, ''
                        PRINT, kmex_latest_plot, FORMAT="('        ',A,' file upload success!')"
                ENDELSE
                
                IF gms[system.gms].code NE 'pla' THEN BEGIN
                        spawn, 'sshpass -p '+system.ftp_password+' scp '+system.plots_dir+gms[system.gms].name+'/'+'7days/'+profiles_today_plot+' '+system.ftp_user+'@'+system.ftp_ip+':'+'/publicdata/'+gms[system.gms].name+'/'+profile_latest_plot, tmp_results, tmp_errors
                        IF STRLEN(tmp_errors) GT 0 THEN BEGIN
                                PRINT, profile_latest_plot, FORMAT="('Warning Error: Errors detected during upload of ',A,' file.')"
                                PRINT, FORMAT="('               it is mandatory manually check and solve the issue(s).')"
                        ENDIF ELSE BEGIN
                                PRINT, ''
                                PRINT, profile_latest_plot, FORMAT="('        ',A,' file upload success!')"
                        ENDELSE
                ENDIF
        ENDIF
;print, dst_latest_plot, kmex_latest_plot
        ;CALDAT, SYSTIME( /JULIAN , /UTC), M, D, Y, hr, mi

        ;#######################################################################
        ; ARREGLAR ESTA SECCION PARA QUE SEA INDEPENDIENTE DE LA ESTACION DE TRABAJO
        
                ;#######################################################################
                ; SECCION PARA COMPUTADORA LOCAL
        ;spawn, 'cp '+kmex_plot_dir+'7days/'+kmex_GMS_name[kmex_GMS]+'/'+dst_today_plot+' /home/piter/Dropbox/kmex_realtime/'+dst_latest_plot, tmp_results, tmp_errors

        ;        tmp_results = ''
        ;        tmp_errors  = ''

                ;#######################################################################
                ; SECCION PARA COMPUTADORA EXTERNA O SERVIDOR
        ;#######################################################################
        ;spawn, 'sshpass -p '+system.ssh_password+' scp '+system.plots_dir+gms[system.gms].name+'/'+'7days/'+dst_today_plot+' '+'pcorona@www.rice.unam.mx:/vol0/kpmex/real_time/'+dst_latest_plot, tmp_results, tmp_errors


;print, 'sshpass -p '+system.ftp_password+' scp '+system.plots_dir+gms[system.gms].name+'/'+'7days/'+dst_today_plot+' '+system.ftp_user+'@'+'132.248.208.46'+':'+'/publicdata/'+gms[system.gms].name+'/'+datatype+'/'+dst_latest_plot;, tmp_results, tmp_errors
	;IF GMS_set[i] EQ 'pla' THEN BEGIN
	;        print, tmp_results
	;        print, tmp_errors
        ;ENDIF

        ;***********************************************
        ;IF (hr MOD 3 EQ 0) THEN BEGIN
        ;***********************************************
        ;        spawn, 'cp '+kmex_plot_dir+'7days/'+kmex_GMS_name[kmex_GMS]+'/'+kmex_today_plot+' /home/piter/Dropbox/kmex_realtime/'+kmex_latest_plot, tmp_results, tmp_errors
                ;#######################################################################
                ;spawn, 'sshpass -p '+system.ssh_password+' scp '+system.plots_dir+gms[system.gms].name+'/'+'7days/'+kmex_today_plot+' '+'pcorona@www.rice.unam.mx:/vol0/kpmex/real_time/'+kmex_latest_plot, tmp_results, tmp_errors
        ;***********************************************
        ;ENDIF
        ;***********************************************
        ;#######################################################################
        ;print, tmp_results, tmp_errors
;ENDFOR
;print, tmp_Y, tmp_M, tmp_D, tmp_H, tmp_H mod 3

;system_error = GETENV('KMEX_ERROR')
;system_storm = GETENV('KMEX_STORM')

;print, system_error, ', ',system_storm
;print, kmex_date_today

;ENDFOR
        PRINT, '###########################'
        PRINT, '###########################'

RETURN

END







