;+
; NAME:
;       geomagixs_setup_dates.pro
;
;
; PURPOSE:
;
;       management of dates data
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Instituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Patzcuaro
;       Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 9.ii.mmxxi
;
; CATEGORY:
;
;       Numerical Data Analize
;
; CALLING SEQUENCE:
;
;       management of dates data, [/UPDATE_FILE, STATION=station, /QUIET=quiet, LAST_UPDATE=last_update, ERROR=error]
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






PRO geomagixs_setup_dates, UPDATE_file=update_file, STATION=station, $
                           QUIET=quiet, FORCE_ALL = force_all
        On_error, 2
        COMPILE_OPT idl2, HIDDEN
        
        geomagixs_setup_commons, QUIET=quiet
        @geomagixs_commons
        geomagixs_check_system, QUIET=quiet
        
;###############################################################################
        IF N_ELEMENTS(flag_dates) GT 0 AND (NOT keyword_set(update_file) AND NOT keyword_set(force_all)) THEN RETURN
;###############################################################################

        geomagixs_check_gms, STATION=station, QUIET=quiet
        
        ;error=0
        ;-----------------------------------------------------------------------
        ;exist_data_file   = FILE_TEST(geomagixs_aux_dir+geomagixs_GMS_code[geomagixs_GMS]+'.dates')
        IF FILE_TEST(system.auxiliar_dir+gms[system.gms].name+'.dates', /READ) NE 1 AND NOT keyword_set(update_file) THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read GMS data file ', A, '.')", gms[system.gms].name+'.dates'
                        PRINT, FORMAT="('                check reading permissons of existence of input data file.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'GMS file '+gms[system.gms].name+'.dates'+' not found or reading permission conflict.  Use /update_file to fix it. '
                ;RETURN
        ENDIF ELSE BEGIN
                file    = FILE_SEARCH(system.auxiliar_dir+gms[system.gms].name+'.dates', COUNT=exist_file)
                ;IF exist_file EQ 0 THEN MESSAGE, 'Critical Error! Missing '+ geomagixs_GMS_code[geomagixs_GMS]+'.dates'
        ENDELSE
                
                

        index_dates     = [0,0,0,0,0,0]
        index_dates_0   = [0,0,0,0,0,0]
        magnetic_dates  = [0,0,0,0,0,0]
        magnetic_dates1 = [0,0,0,0,0,0]
        magnetic_dates2 = [0,0,0,0,0,0]

        ;IF NOT keyword_set(quiet) THEN PRINT, ''


        IF exist_file AND NOT keyword_set(update_file) THEN BEGIN
                number_of_lines  = FILE_LINES(file[0])
                date_data        = STRARR(number_of_lines)

                OPENR, lun, file[0], /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[0]
                        READF, lun, date_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun
                
                j = 0
                FOR i = 0, number_of_lines-1 DO $
                IF STRPOS(date_data[i], '#') NE 0 THEN BEGIN
                       date_data[j] = date_data[i]
                        j += 1
                        date_data[i]=''
                ENDIF ELSE BEGIN
                        date_data[i] = ''
                ENDELSE

                READS, date_data[0], index_dates, FORMAT='(I4,I02,I02,X,I4,I02,I02)'
                READS, date_data[1], index_dates_0, FORMAT='(I4,I02,I02,X,I4,I02,I02)'
                READS, date_data[2], magnetic_dates, FORMAT='(I4,I02,I02,X,I4,I02,I02)'
                
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, '        * Data loaded from '+gms[system.gms].name+'.dates file.'
                ENDIF
        ENDIF ELSE BEGIN
                IF NOT keyword_set(update_file) THEN BEGIN
                        IF NOT keyword_set(quiet) THEN BEGIN
                                PRINT, FORMAT="('Input Warning: Unable to read GMS dates file ', A, '.')", gms[system.gms].name+'.dates'
                                PRINT, FORMAT="('               GEOMAGIXS system is trying to generate the system file.')"
                        ENDIF
                        error.value[3] += 1
                        error.log      += 'Input data file '+gms[system.gms].name+'.dates'+' not found or reading permission conflict. '

                ENDIF
                
                
;###############################################################################
;###############################################################################
;###############################################################################
                IF gms[system.gms].name NE 'planetary' THEN BEGIN
                ;print, gms[system.gms].name
                        file = FILE_SEARCH(system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_????????.k_index.early', COUNT=total_files)
                        ;print, file[0]+file[total_files-1]
                        ;print, FILE_SEARCH(system.indexes_dir+gms[system.gms].name, /expand_tilde, /TEST_DIRECTORY)+'/'+gms[system.gms].code+'_'
                        expected_number = 0
                        str_lenght1 = STRLEN(FILE_SEARCH(system.indexes_dir+gms[system.gms].name, /expand_tilde, /TEST_DIRECTORY))+ $
                                      STRLEN('/'+gms[system.gms].code+'_')
                        str_lenght2 = STRLEN('.k_index.early')+$
                                      STRLEN(FILE_SEARCH(system.indexes_dir+gms[system.gms].name, /expand_tilde, /TEST_DIRECTORY))+ $
                                      STRLEN('/'+gms[system.gms].code+'_')
                        tmp_str1 = str_lenght1 LT 10 ? STRING(str_lenght1, FORMAT='(I1,"X")') : STRING(str_lenght1, FORMAT='(I2,"X")')
                        tmp_str1 = str_lenght1 GE 100 ? STRING(str_lenght1, FORMAT='(I3,"X")') : tmp_str1
                        tmp_str2 = str_lenght2 LT 10 ? STRING(str_lenght2, FORMAT='(I1,"X")') : STRING(str_lenght2, FORMAT='(I2,"X")')
                        tmp_str2 = str_lenght2 GE 100 ? STRING(str_lenght2, FORMAT='(I3,"X")') : tmp_str2


                        IF total_files GT 0 THEN BEGIN
                        
                        ;print, '('+tmp_str1+',I4,I02,I02,'+tmp_str2+',I4,I02,I02,:)'
                                READS, file[0]+file[total_files-1], index_dates, FORMAT='('+tmp_str1+',I4,I2,I2,'+tmp_str2+',I4,I2,I2,:)'
                                ;index_dates=tmp
                                expected_number = JULDAY(index_dates[4],index_dates[5],index_dates[3])-JULDAY(index_dates[1],index_dates[2],index_dates[0])+1
                        ENDIF
;/home/piter/DATA/output/indexes/coeneo/coe_
;/home/piter/DATA/output/indexes/coeneo/coe_20210101.k_index.early/home/piter/DATA/output/indexes/coeneo/coe_20210408.k_index.early
                        IF total_files LE 0 OR expected_number GT total_files THEN BEGIN
                                IF NOT keyword_set(quiet) THEN BEGIN
                                        PRINT, FORMAT="('Inconsistency Warning: Incomplete early index data files for selected GMS [', A)", gms[system.gms].name+'].'
                                        PRINT, FORMAT="('                       It is requaried to manualy UPDATE the index files.')"
                                ENDIF
                                error.value[4] += 1
                                error.log      += 'Incomplete early index data files for selected GMS ['+gms[system.gms].name+']. Manual update required. '
                        ENDIF
                
                
                
                        file0 = FILE_SEARCH(system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_????????.k_index.final', COUNT=total_files)
                        ;print, file[0]+file[total_files-1]
                        ;print, FILE_SEARCH(system.indexes_dir+gms[system.gms].name, /expand_tilde, /TEST_DIRECTORY)+'/'+gms[system.gms].code+'_'
                        expected_number = 0
                        str_lenght1 = STRLEN(FILE_SEARCH(system.indexes_dir+gms[system.gms].name, /expand_tilde, /TEST_DIRECTORY))+ $
                                      STRLEN('/'+gms[system.gms].code+'_')
                        str_lenght2 = STRLEN('.k_index.final')+$
                                      STRLEN(FILE_SEARCH(system.indexes_dir+gms[system.gms].name, /expand_tilde, /TEST_DIRECTORY))+ $
                                      STRLEN('/'+gms[system.gms].code+'_')
                        tmp_str1 = str_lenght1 LT 10 ? STRING(str_lenght1, FORMAT='(I1,"X")') : STRING(str_lenght1, FORMAT='(I2,"X")')
                        tmp_str1 = str_lenght1 GE 100 ? STRING(str_lenght1, FORMAT='(I3,"X")') : tmp_str1
                        tmp_str2 = str_lenght2 LT 10 ? STRING(str_lenght2, FORMAT='(I1,"X")') : STRING(str_lenght2, FORMAT='(I2,"X")')
                        tmp_str2 = str_lenght2 GE 100 ? STRING(str_lenght2, FORMAT='(I3,"X")') : tmp_str2


                        IF total_files GT 0 THEN BEGIN
                                READS, file0[0]+file0[total_files-1], index_dates_0, FORMAT='('+tmp_str1+',I4,I2,I2,'+tmp_str2+',I4,I2,I2,:)'
                                expected_number = JULDAY(index_dates_0[4],index_dates_0[5],index_dates_0[3])-JULDAY(index_dates_0[1],index_dates_0[2],index_dates_0[0])+1
                        ENDIF
                
                        IF total_files LE 0 OR expected_number GT total_files THEN BEGIN
                                IF NOT keyword_set(quiet) THEN BEGIN
                                        PRINT, FORMAT="('Inconsistency Warning: Incomplete final index data files for selected GMS [', A)", gms[system.gms].name+'].'
                                        PRINT, FORMAT="('                       It is requaried to manualy UPDATE the index files.')"
                                ENDIF
                                error.value[4] += 1
                                error.log      += 'Incomplete final index data files for selected GMS ['+gms[system.gms].name+']. Manual update required. '
                        ENDIF




                        file1 = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/'+gms[system.gms].code+'????????rmin.min', COUNT=total_files1)
                        
                        expected_number1 = 0
                        str_lenght1 = STRLEN(FILE_SEARCH(system.datasource_dir+gms[system.gms].name, /EXPAND_TILDE, /TEST_DIRECTORY))+ $
                                      STRLEN('/'+gms[system.gms].code)
                        str_lenght2 = STRLEN('rmin.min')+$
                                      STRLEN(FILE_SEARCH(system.datasource_dir+gms[system.gms].name, /EXPAND_TILDE, /TEST_DIRECTORY))+ $
                                      STRLEN('/'+gms[system.gms].code)
                        tmp_str1 = str_lenght1 LT 10 ? STRING(str_lenght1, FORMAT='(I1,"X")') : STRING(str_lenght1, FORMAT='(I2,"X")')
                        tmp_str1 = str_lenght1 GE 100 ? STRING(str_lenght1, FORMAT='(I3,"X")') : tmp_str1
                        tmp_str2 = str_lenght2 LT 10 ? STRING(str_lenght2, FORMAT='(I1,"X")') : STRING(str_lenght2, FORMAT='(I2,"X")')
                        tmp_str2 = str_lenght2 GE 100 ? STRING(str_lenght2, FORMAT='(I3,"X")') : tmp_str2

                        IF total_files1 GT 0 THEN BEGIN
                                READS, file1[0]+file1[total_files1-1], magnetic_dates1, FORMAT='('+tmp_str1+',I4,I2,I2,'+tmp_str2+',I4,I2,I2,:)'
                                expected_number1 = JULDAY(magnetic_dates1[4],magnetic_dates1[5],magnetic_dates1[3])-JULDAY(magnetic_dates1[1],magnetic_dates1[2],magnetic_dates1[0])+1
                        ENDIF
                
                
                        file2 = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/'+gms[system.gms].code+'????????rK.min', COUNT=total_files2)

                        expected_number2 = 0
                        str_lenght1 = STRLEN(FILE_SEARCH(system.datasource_dir+gms[system.gms].name, /expand_tilde, /TEST_DIRECTORY))+ $
                                      STRLEN('/'+gms[system.gms].code)
                        str_lenght2 = STRLEN('rK.min')+$
                                      STRLEN(FILE_SEARCH(system.datasource_dir+gms[system.gms].name, /expand_tilde, /TEST_DIRECTORY))+ $
                                      STRLEN('/'+gms[system.gms].code)
                        tmp_str1 = str_lenght1 LT 10 ? STRING(str_lenght1, FORMAT='(I1,"X")') : STRING(str_lenght1, FORMAT='(I2,"X")')
                        tmp_str1 = str_lenght1 GE 100 ? STRING(str_lenght1, FORMAT='(I3,"X")') : tmp_str1
                        tmp_str2 = str_lenght2 LT 10 ? STRING(str_lenght2, FORMAT='(I1,"X")') : STRING(str_lenght2, FORMAT='(I2,"X")')
                        tmp_str2 = str_lenght2 GE 100 ? STRING(str_lenght2, FORMAT='(I3,"X")') : tmp_str2


;/home/piter/DATA/input/data_source/coeneo/coe20201210rK.min/home/piter/DATA/input/data_source/coeneo/coe20210408rK.min

                        IF total_files2 GT 0 THEN BEGIN
                                READS, file2[0]+file2[total_files2-1], magnetic_dates2, FORMAT='('+tmp_str1+',I4,I2,I2,'+tmp_str2+',I4,I2,I2,:)'
                                expected_number2 = JULDAY(magnetic_dates2[4],magnetic_dates2[5],magnetic_dates2[3])-JULDAY(magnetic_dates2[1],magnetic_dates2[2],magnetic_dates2[0])+1
                        ENDIF
                
                        IF (expected_number1 GT total_files1) OR total_files2 LE 0 OR (expected_number2 GT total_files2) THEN BEGIN
                                IF NOT keyword_set(quiet) THEN BEGIN
                                        PRINT, FORMAT="('Inconsistency Warning: Incomplete magnetic data files for selected GMS [', A)", gms[system.gms].name+'].'
                                        PRINT, FORMAT="('			GEOMAGIXS system will take as gaps the missing data files.')"
                                ENDIF
                                error.value[4] += 1
                                error.log      += 'Incomplete magnetic data files for selected GMS ['+gms[system.gms].name+']. Missing data will be assumed as gaps. '
                        ENDIF
                ENDIF ELSE BEGIN
                        ;print, system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code
                        file = FILE_SEARCH(system.indexes_dir+gms[system.gms].name+'/'+gms[system.gms].code+'_????????.k_index', COUNT=total_files)
                        ;print, file[0]+file[total_files-1]
                        expected_number = 0
                        IF total_files GT 0 THEN BEGIN
                                tmp_pos  = STRPOS(file[0], gms[system.gms].code+'_', /REVERSE_SEARCH) + STRLEN(gms[system.gms].code+'_')
                                tmp_str1 = STRING(tmp_pos, FORMAT='(I0,"X")')
                                tmp_pos  = STRPOS(file[total_files-1], gms[system.gms].code+'_', /REVERSE_SEARCH) + STRLEN(gms[system.gms].code+'_')+STRLEN('.k_index')
                                tmp_str2 = STRING(tmp_pos, FORMAT='(I0,"X")')
                                format_str = '('+tmp_str1+',I4,I2,I2,'+tmp_str2+',I4,I2,I2,:)'
                                READS, file[0]+file[total_files-1], index_dates, FORMAT=format_str
                                expected_number = JULDAY(index_dates[4],index_dates[5],index_dates[3])-JULDAY(index_dates[1],index_dates[2],index_dates[0])+1
                        ENDIF
                        
                        index_dates_0 = index_dates
;/home/piter/DATA/output/indexes/planetary/pla_20210101.k_index/home/piter/DATA/output/indexes/planetary/pla_20210318.k_index
                        IF total_files LE 0 OR expected_number GT total_files THEN BEGIN
                                IF NOT keyword_set(quiet) THEN BEGIN
                                        PRINT, FORMAT="('Inconsistency Warning: Incomplete index data files for selected GMS [', A)", gms[system.gms].name
                                        PRINT, FORMAT="('                       It is requaried to manualy UPDATE the index files.')"
                                ENDIF
                                error.value[4] += 1
                                error.log      += 'Incomplete index data files for selected GMS ['+gms[system.gms].name+']. Manual update required. '
                        ENDIF


; ##############################################################################
                        file1 = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/kp????.wdc', COUNT=total_files1)
                        expected_number1 = 0
;/home/piter/DATA/input/data_source/planetary/kp1401.wdc/home/piter/DATA/input/data_source/planetary/kp2103.wdc
                        ;print, total_files1
                        IF total_files1 GT 0 THEN BEGIN
                                tmp_mag_dates = [0,0,0,0]
                                tmp_pos  = STRPOS(file1[0], 'kp', /REVERSE_SEARCH) + STRLEN('kp')
                                tmp_str1 = STRING(tmp_pos, FORMAT='(I0,"X")')
                                tmp_pos  = STRPOS(file1[total_files1-1], 'kp', /REVERSE_SEARCH) + STRLEN('kp')+STRLEN('.wdc')
                                tmp_str2 = STRING(tmp_pos, FORMAT='(I0,"X")')
                                format_str = '('+tmp_str1+',I2,I2,'+tmp_str2+',I2,I2,:)'
                                READS, file1[0]+file1[total_files1-1], tmp_mag_dates, FORMAT=format_str

                                expected_number1 = (tmp_mag_dates[2]-tmp_mag_dates[0])*12+tmp_mag_dates[3]-tmp_mag_dates[1]+1
                                
                                magnetic_dates1[4] = tmp_mag_dates[3]
                                magnetic_dates1[3] = tmp_mag_dates[2]+2000
                                magnetic_dates1[1] = tmp_mag_dates[1]
                                magnetic_dates1[0] = tmp_mag_dates[0]+2000
                                
                                magnetic_dates1[2] = JULDAY(magnetic_dates1[1]+1,0,magnetic_dates1[0])-JULDAY(magnetic_dates1[1],0,magnetic_dates1[0])
                                magnetic_dates1[5] = JULDAY(magnetic_dates1[4]+1,0,magnetic_dates1[3])-JULDAY(magnetic_dates1[4],0,magnetic_dates1[3])
                        ENDIF
; ##############################################################################
                
                
; ##############################################################################
                        file2 = FILE_SEARCH(system.datasource_dir+gms[system.gms].name+'/dst????.dat', COUNT=total_files2)
                        expected_number2 = 0
                        
                        ;print, file2
                        ;print, total_files2
                        
                        ;stop
                
                        IF total_files2 GT 0 THEN BEGIN
                                tmp_mag_dates = [0,0,0,0]
                                tmp_mag_dates = [0,0,0,0]
                                tmp_pos  = STRPOS(file2[0], 'dst', /REVERSE_SEARCH) + STRLEN('dst')
                                tmp_str1 = STRING(tmp_pos, FORMAT='(I0,"X")')
                                tmp_pos  = STRPOS(file2[total_files2-1], 'dst', /REVERSE_SEARCH) + STRLEN('dst')+STRLEN('.dat')
                                tmp_str2 = STRING(tmp_pos, FORMAT='(I0,"X")')
                                format_str = '('+tmp_str1+',I2,I2,'+tmp_str2+',I2,I2,:)'
                                READS, file2[0]+file2[total_files2-1], tmp_mag_dates, FORMAT=format_str

                                expected_number2 = (tmp_mag_dates[2]-tmp_mag_dates[0])*12+tmp_mag_dates[3]-tmp_mag_dates[1]+1
                                
                                magnetic_dates2[4] = tmp_mag_dates[3]
                                magnetic_dates2[3] = tmp_mag_dates[2]+2000
                                magnetic_dates2[1] = tmp_mag_dates[1]
                                magnetic_dates2[0] = tmp_mag_dates[0]+2000
                                
                                magnetic_dates2[2] = JULDAY(magnetic_dates2[1]+1,0,magnetic_dates2[0])-JULDAY(magnetic_dates2[1],0,magnetic_dates2[0])
                        ENDIF
                        
                        ;stop
                        IF (expected_number1 GT total_files1) OR total_files2 LE 0 OR (expected_number2 GT total_files2) THEN BEGIN
                                IF NOT keyword_set(quiet) THEN BEGIN
                                        PRINT, FORMAT="('Inconsistency Warning: Incomplete magnetic data files for selected GMS [', A)", gms[system.gms].name+'].'
                                        PRINT, FORMAT="('                       GEOMAGIXS system will take as gaps the missing data files.')"
                                ENDIF
                                error.value[4] += 1
                                error.log      += 'Incomplete magnetic data files for selected GMS ['+gms[system.gms].name+']. Missing data will be assumed as gaps. '
                        ENDIF


;/home/piter/DATA/input/data_source/planetary/dst1401.dat/home/piter/DATA/input/data_source/planetary/dst2103.dat
;/home/piter/DATA/input/data_source/planetary/kp1401.wdc/home/piter/DATA/input/data_source/planetary/kp2103.wdc
                
                ENDELSE
                
                
                
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################

                                    
                                    
                IF PRODUCT(magnetic_dates1) GT 0 THEN BEGIN
                        magnetic_dates[3:5] = (JULDAY(magnetic_dates2[4], magnetic_dates2[5], magnetic_dates2[3]) GE JULDAY(magnetic_dates1[4], magnetic_dates1[5], magnetic_dates1[3])) ? magnetic_dates2[3:5] : magnetic_dates1[3:5]
                        magnetic_dates[0:2] = (JULDAY(magnetic_dates2[1], magnetic_dates2[2], magnetic_dates2[0]) LT JULDAY(magnetic_dates1[1], magnetic_dates1[2], magnetic_dates1[0])) ? magnetic_dates2[0:2] : magnetic_dates1[0:2]
                ENDIF ELSE BEGIN
                        magnetic_dates[3:5] = magnetic_dates2[3:5]
                        magnetic_dates[0:2] = magnetic_dates2[0:2]
                ENDELSE

                
                file = system.auxiliar_dir+gms[system.gms].name+'.dates'
                string_data = STRARR(5)
                string_data[0] = '# File with available date range for the GMS: 1st and 2nd rows are related with the early and final k-index files, respectively; and the 3rd row with the magnetic data files.'
                string_data[1] = '# the format is initial-final date [YYYYMMDD]'
                string_data[2] = STRING(index_dates, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')
                string_data[3] = STRING(index_dates_0, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')
                string_data[4] = STRING(magnetic_dates, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')

                OPENW, lun, file, /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name
                        FOR i = 0, N_ELEMENTS(string_data)-1 DO PRINTF, lun, string_data[i]
                CLOSE, lun
                FREE_LUN, lun
                
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, '        * Updated '+gms[system.gms].name+'.dates file.'
                ENDIF

        ENDELSE



        IF NOT keyword_set(quiet) THEN BEGIN
                PRINT, '        Index [early] files date-range: '+STRING(index_dates, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')
                PRINT, '        Index [final] files date-range: '+STRING(index_dates_0, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')
                PRINT, '        Magnetic data date-range:       '+STRING(magnetic_dates, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')
                PRINT, ''
        ENDIF
      
        gms[system.gms].dates_index[0,*] = index_dates[0:2]
        gms[system.gms].dates_index[1,*] = index_dates[3:5]
        gms[system.gms].dates_index[2,*] = index_dates_0[0:2]
        gms[system.gms].dates_index[3,*] = index_dates_0[3:5]
        gms[system.gms].dates_data[0,*]  = magnetic_dates[0:2]
        gms[system.gms].dates_data[1,*]  = magnetic_dates[3:5]
        



;###############################################################################
; QUIET DAYS SECTION
;###############################################################################
IF NOT keyword_set(update_file) THEN BEGIN                 
        IF NOT FILE_TEST(system.auxiliar_dir+'qdays.dates', /READ) THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                ; critical error, write permissons
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read Q-days dates file ', A, '.')", 'qdays.dates'
                        PRINT, FORMAT="('                check reading permissons or existence of input data file.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'Q-days dates file '+'qdays.dates'+' not found or reading permission conflict. Use download quietdays tool to fix it. '
                RETURN
        ENDIF ELSE BEGIN
                file_qd    = FILE_SEARCH(system.auxiliar_dir+'qdays.dates', COUNT=exist_qdfile)
                ;IF exist_qdfile EQ 0 THEN MESSAGE, 'Critical Error! Missing '+ 'qdays.data'
        ENDELSE


        IF exist_qdfile THEN BEGIN
                number_of_lines  = FILE_LINES(file_qd[0])
                date_data        = STRARR(number_of_lines)

                OPENR, lun, file_qd[0], /GET_LUN, ERROR=err
                        IF err NE 0 THEN MESSAGE, 'Error opening '+file_name[0]
                        READF, lun, date_data, FORMAT='(A)'
                CLOSE, lun
                FREE_LUN, lun

                j = 0
                FOR i = 0, number_of_lines-1 DO $
                IF STRPOS(date_data[i], '#') NE 0 THEN BEGIN
                       date_data[j] = date_data[i]
                        j += 1
                        date_data[i]=''
                ENDIF ELSE BEGIN
                        date_data[i] = ''
                ENDELSE

                READS, date_data[0], index_dates, FORMAT='(I4,I02,I02,X,I4,I02,I02)'

                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, '        * Data loaded from '+'qdays.dates'+' file.'
                ENDIF
        ENDIF
        
        ;###################################
        ;###################################
        ; FALTA LA SECCION DE UPDATES

        IF NOT keyword_set(quiet) THEN BEGIN
                PRINT, '        Quiet Days date-range:    '+STRING(index_dates, FORMAT='(I4,I02,I02,"-",I4,I02,I02)')
                PRINT, ''
        ENDIF
        
        system.qdays_dates[0,*]          = index_dates[0:2]
        system.qdays_dates[1,*]          = index_dates[3:5]
ENDIF
        



        Flag_dates = 1


        RETURN

END



