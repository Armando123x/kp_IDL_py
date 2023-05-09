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
;       Instituto de Geofisica, UNAM
;       Tzinztuntzan 310, Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 23.iii.mmx
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
;




PRO geomagixs_check_system, QUIET=quiet
	On_error, 2
	COMPILE_OPT idl2, HIDDEN
	
        ;commons stantment        
        @geomagixs_commons
        
        ;seting up system variables
        geomagixs_setup_commons

;###############################################################################
        IF Flag_system NE 0 THEN RETURN
;###############################################################################

        IF system.geomagixs_dir EQ '' THEN BEGIN
                CD, CURRENT=tmp
                system.geomagixs_dir = tmp
        ENDIF

        system.geomagixs_dir += '/'

        ; checking reading permisson for config file
        IF system.setup_file EQ '' THEN system.setup_file = 'setup.config'

        ;IF NOT keyword_set(quiet) THEN PRINT, system.setup_file, FORMAT="('        * Checking setup file ', A, '.')"

        IF FILE_TEST(system.geomagixs_dir+system.setup_file, /READ) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: setup file ', A, ' not found.')", system.setup_file
                        PRINT, FORMAT="('                impossible to read system-congif data.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'Setup file '+system.setup_file+' not found or reading permission conflict. '
                RETURN
        ENDIF


        ;opening setup.config file
        file = FILE_SEARCH(system.geomagixs_dir+system.setup_file)

        string_lines = FILE_LINES(file[0])
        data_strings  = STRARR(string_lines)
        
        ;deading cmegd_setup.dat file
        OPENR, file_lun, file, /GET_LUN
                READF, file_lun, data_strings
        FREE_LUN, file_lun
        

        IF NOT keyword_set(quiet) THEN PRINT, system.setup_file, FORMAT="('        * Reading data from system file: ', A, '.')"

        ;extracting setup.config data
        j = 0
        FOR i = 0, string_lines-1 DO $
                IF STRPOS(data_strings[i], '#') NE 0 THEN BEGIN
                       data_strings[j] = data_strings[i]
                        j += 1
                        data_strings[i]=''
                ENDIF ELSE BEGIN
                        data_strings[i] = ''
                ENDELSE

IF j NE 3 THEN BEGIN ; 3 is the number of data aquired from setup file
                ; critical error, wrong setupfile format
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: compromised format of ', A, ' file.')", system.setupfile
                        PRINT, FORMAT="('                impossible to read data from setup file.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'Format of '+system.setupfile+' file compromised or corrupted. '
ENDIF ELSE BEGIN
;###############################################################################
        ; checking existence and reading permisson for input directory
        
        input_dir = data_strings[0]

        IF NOT keyword_set(quiet) THEN PRINT, input_dir, FORMAT="('        * Checking input directory-tree [', A, '].')"
        
        IF FILE_TEST(input_dir, /READ, /DIRECTORY) NE 1 THEN BEGIN
                        ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read input directory', A, '.')", input_dir
                        PRINT, FORMAT="('                it is mandatory reading permisson on input directory.')"
                ENDIF
                
                error.value[0] += 1
                error.log      += 'Input directory '+input_dir+' not found or reading permission conflict. '
                        ;RETURN
        ENDIF
        system.input_dir = input_dir+'/'
        
        
        ; checking existence and reading permisson for auxiliar directory
        system.auxiliar_dir = data_strings[1]

        ;IF NOT keyword_set(quiet) THEN PRINT, system.auxiliar_dir, FORMAT="('        * Setting ', A, ' as auxiliar directory.')"
        
        IF FILE_TEST(system.auxiliar_dir, /WRITE, /DIRECTORY) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to write on auxiliar directory', A, '.')", system.auxiliar_dir
                        PRINT, FORMAT="('                it is mandatory writing permisson on auxiliar.')"
                ENDIF
        
                error.value[0] += 1
                error.log      += 'Auxiliar directory '+system.auxiliar_dir+' not found or write permission conflict. '
                ;RETURN
        ENDIF
        system.auxiliar_dir += '/'
        
        
        
        ; checking existence and reading permisson for magnetic data source directory
        IF system.datasource_dir EQ '' THEN system.datasource_dir = system.input_dir+'data_source' $
                                       ELSE system.datasource_dir = system.input_dir+system.datasource_dir

        ;IF NOT keyword_set(quiet) THEN PRINT, system.datasource_dir, FORMAT="('        * Setting ', A, ' as magnetic-data source directory.')"
        
        IF FILE_TEST(system.datasource_dir, /READ, /DIRECTORY) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read data source directory', A, '.')", system.datasource_dir
                        PRINT, FORMAT="('                it is mandatory reading permisson on source directory.')"
                ENDIF
        
                error.value[0] += 1
                error.log      += 'Magnetic data source directory '+system.datasource_dir+' not found or read permission conflict. '
                ;RETURN
        ENDIF
        system.datasource_dir += '/'


        IF system.qdays_dir EQ '' THEN system.qdays_dir = system.datasource_dir+'qdays' $
                                  ELSE system.qdays_dir = system.datasource_dir+system.qdays_dir
        
        IF FILE_TEST(system.qdays_dir, /READ, /DIRECTORY) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read input data directory', A, '.')", system.qdays_dir+'qdays'
                        PRINT, FORMAT="('                it is mandatory reading permisson on source directory.')"
                ENDIF
        
                error.value[0] += 1
                error.log      += 'Input data directory '+system.qdays_dir+' not found or read permission conflict. '
                ;RETURN
        ENDIF
        system.qdays_dir += '/'

        ; checking writeing permisson for output directory
        system.output_dir = data_strings[2]

        IF NOT keyword_set(quiet) THEN PRINT, system.output_dir, FORMAT="('        * Checking output directory-tree [', A, '].')"
        
        IF FILE_TEST(system.output_dir, /WRITE, /DIRECTORY) NE 1 THEN BEGIN
                        ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to write in output directory', A, '.')", system.output_dir
                        PRINT, FORMAT="('                it is mandatory writing permisson on output directory.')"
                ENDIF
                
                        error.value[0] += 1
                        error.log      += 'Output directory '+system.output_dir+' not found or writing permission conflict. '
                        ;RETURN
        ENDIF
        system.output_dir += '/'


        ; checking writeing permisson for indexes directory
        IF system.indexes_dir EQ '' THEN system.indexes_dir = system.output_dir+'indexes' $
                                    ELSE system.indexes_dir = system.output_dir+system.indexes_dir

        ;IF NOT keyword_set(quiet) THEN PRINT, system.indexes_dir, FORMAT="('        * Setting ', A, ' as computed indexes directory.')"
        
        IF FILE_TEST(system.indexes_dir, /WRITE, /DIRECTORY) NE 1 THEN BEGIN
                        ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to write in computed indexes directory', A, '.')", system.indexes_dir
                        PRINT, FORMAT="('                it is mandatory writing permisson on indexes directory.')"
                ENDIF
                
                        error.value[0] += 1
                        error.log      += 'Computed indexes directory '+system.indexes_dir+' not found or writing permission conflict. '
                        ;RETURN
        ENDIF
        system.indexes_dir += '/'

        ; checking writeing permisson for indexes directory
        IF system.plots_dir EQ '' THEN system.plots_dir = system.output_dir+'plots' $
                                  ELSE system.plots_dir = system.output_dir+system.plots_dir

        ;IF NOT keyword_set(quiet) THEN PRINT, system.plots_dir, FORMAT="('        * Setting ', A, ' as plots directory.')"
        
        IF FILE_TEST(system.plots_dir, /WRITE, /DIRECTORY) NE 1 THEN BEGIN
                        ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to write in plots directory', A, '.')", system.plots_dir
                        PRINT, FORMAT="('                it is mandatory writing permisson on plots directory.')"
                ENDIF
                
                        error.value[0] += 1
                        error.log      += 'Plots directory '+system.plots_dir+' not found or writing permission conflict. '
                        ;RETURN
        ENDIF
        system.plots_dir += '/'


        ; checking writeing permisson for indexes directory
        IF system.processed_dir EQ '' THEN system.processed_dir = system.output_dir+'processed' $
                                  ELSE system.processed_dir = system.output_dir+system.processed_dir

        ;IF NOT keyword_set(quiet) THEN PRINT, system.processed_dir, FORMAT="('        * Setting ', A, ' as processed-files directory.')"
        
        IF FILE_TEST(system.processed_dir, /WRITE, /DIRECTORY) NE 1 THEN BEGIN
                        ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to write in processed files directory', A, '.')", system.processed_dir
                        PRINT, FORMAT="('                it is mandatory writing permisson on processed files directory.')"
                ENDIF
                
                        error.value[0] += 1
                        error.log      += 'Processed files directory '+system.processed_dir+' not found or writing permission conflict. '
                        ;RETURN
        ENDIF
        system.processed_dir += '/'


;###############################################################################
        
        
        ; checking reading permisson for input GMS data file
        ;system.gms_file = 'gms.config'
        IF system.gms EQ '' THEN system.gms_file = 'gms.config'
        
        ;IF NOT keyword_set(quiet) THEN PRINT, system.gms_file, FORMAT="('        * Checking GeoMagnetiStation data file ', A, '.')"
        
        IF FILE_TEST(system.geomagixs_dir+system.gms_file, /READ) NE 1 THEN BEGIN
                ; critical error, write permissons
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: unable to read GMS data file ', A, '.')", system.gms_file
                        PRINT, FORMAT="('                check reading permissons of existence of input data file.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'GMS file '+system.gms_file+' not found or reading permission conflict. '
                ;RETURN
        ENDIF
;###############################################################################

        ;opening gms.config file
        file = FILE_SEARCH(system.geomagixs_dir+system.gms_file)

        string_lines = FILE_LINES(file[0])
        data_strings  = STRARR(string_lines)
        
        ;deading cmegd_setup.dat file
        OPENR, file_lun, file, /GET_LUN
                READF, file_lun, data_strings
        FREE_LUN, file_lun
        

        IF NOT keyword_set(quiet) THEN PRINT, system.gms_file, FORMAT="('        * Reading data from system file: ', A, '.')"

        ;extracting setup.config data
        j = 0
        FOR i = 0, string_lines-1 DO $
                IF STRPOS(data_strings[i], '#') NE 0 THEN BEGIN
                       data_strings[j] = data_strings[i]
                        j += 1
                        data_strings[i]=''
                ENDIF ELSE BEGIN
                        data_strings[i] = ''
                ENDELSE

        IF j MOD 5 NE 0 THEN BEGIN ; 3 is the number of data aquired from setup file
                ; critical error, wrong setupfile format
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: compromised format of ', A, ' system file.')", system.gms_file
                        PRINT, FORMAT="('                impossible to read data from GMS file.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'Format of '+system.gms_file+' file compromised or corrupted. '
        ENDIF ELSE BEGIN

                gms_structure = { name        : '', $
                                  code        : '', $
                                  latitude    : 0., $
                                  longitude   : 0., $
                                  elevation   : 0., $
                                  calibration : FLTARR(28), $
                                  dates_index : INTARR(4,3), $
                                  dates_data  : INTARR(2,3), $
                                  base_line   : FLTARR(3), $  ; [D,H,Z]
                                  check_flag  : 0 $
                                }
                
                system.gms_total = j/5
                gms = REPLICATE(gms_structure, system.gms_total)
                
                
                FOR i = 0, system.gms_total-1 DO BEGIN
                        ;print, i
                        GMS[i].name      = data_strings[i*5]
                        GMS[i].code      = data_strings[i*5+1]
                        GMS[i].latitude  = Float(data_strings[i*5+2])
                        GMS[i].longitude = Float(data_strings[i*5+3])
                        GMS[i].elevation = Float(data_strings[i*5+4])
               ENDFOR
                
        ENDELSE
;###############################################################################
        IF (STRLEN(system.ftp_address)*STRLEN(system.ftp_user) LE 0) AND system.ftp_on GE 1 THEN BEGIN
                IF NOT keyword_set(quiet) THEN BEGIN
                        PRINT, FORMAT="('CRITICAL ERROR: Conflict with input data. Data of the FTP sercer is inconsistent or invalid.')"
                        PRINT, FORMAT="('                impossible to download data from FTP server file.')"
                ENDIF
                error.value[0] += 1
                error.log      += 'Missing user or/and address for FTP server; impossible to download data. '
        ENDIF


        ;IF (STRLEN(system.ssh_address)*STRLEN(system.ssh_user) LE 0) AND system.ssh_on GE 1 THEN BEGIN
        ;        IF NOT keyword_set(quiet) THEN BEGIN
        ;                PRINT, FORMAT="('CRITICAL ERROR: Conflict with input data. Data of the SSH sercer is inconsistent or invalid.')"
        ;                PRINT, FORMAT="('                impossible to download data from SSH server file.')"
        ;        ENDIF
        ;        error.value[0] += 1
        ;        error.log      += 'Missing user or/and address for SSH server; impossible to download data. '
        ;ENDIF
;###############################################################################



ENDELSE
;###############################################################################
Flag_system = 1

RETURN
END


