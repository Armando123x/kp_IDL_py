;+
; NAME:
;       geomagixs_setup.pro
;
;
; PURPOSE:
;
;       Declares and defines the COMMON variables for geomagixs system
;
;       this script is GDL compatible.
;
; AUTHOR:
;
;       Pedro Corona Romero
;       Space Weather National Laboratory (LANCE)
;       Instituto de Geofisica, Unidad Michoacan
;       UNAM, Campus Morelia
;       Antigua Carretera a Pátzcuaro
;       Morelia, Michoacan, Mexico
;       piter.cr@gmail.com
;       Mexico, 2021
;
; CATEGORY:
;
;       Numerical Data Analysis
;
; CALLING SEQUENCE:
;
;       geomagixs_setup_commons [, /QUIET]
;
;       Description:
;       this file declares de common variables.
;
;
; PARAMETERS:
;       Not Apply
;
; KEYWORD PARAMET
;       /QUIET          :       turn off messages
;
; DEPENDENCIES:
;       Not Apply
;
; ANALIZED FILES:
;       Not Apply
;
; OUTPUT FILES:
;
; HISTORY:
;-

PRO geomagixs_setup_commons, QUIET=quiet
        On_error, 2
        COMPILE_OPT idl2, HIDDEN

        ;commons stantment        
        @geomagixs_commons
        
;###############################################################################
        IF N_ELEMENTS(Flag_setup) NE 0 THEN RETURN
;###############################################################################
        
        IF not keyword_set(quiet) THEN PRINT, '        * Preparing common variables.'
        ;-----------------------------------------------------------------------
        ; system flags
        Flag_commons     = 1
        Flag_dates       = 0
        Flag_error       = 0
        Flag_system      = 0
        ;-----------------------------------------------------------------------
        ; errors

        error_message = ['Critical Error: Missing or corrupted system file(s) or directory(ies). Review your installation or check out directory tree and location of data files.', $
                         'Critical Error: Impossible to save (read) output (input) file(s). Missing directories or permissions conflict.',$
                         'Critical Error: Conflict with input data. Data inconsistent or invalid.', $
                         'Input Warning: Invalid values or values out of the range, proceeding with predefined values and replacing conflictive values with data gaps.', $
                         'Inconsistency Warning: the requested conditions may compromise the computed results.' ]
        
        
        
        Error = { message        : STRARR(N_ELEMENTS(error_message)) , $
                  value          : INTARR(N_ELEMENTS(error_message)) , $
                  critical       : 0, $
                  log            : '' $
                }
        
        Error.message=error_message
        
        ;-----------------------------------------------------------------------
        ; system general data
        system = { output_dir        : '',  $ ; output data directory, if blank the $HOME directory is used.
                   input_dir         : '',  $ ; input data directory, if blank the $HOME directory is used.
                   datasource_dir    : 'data_source',  $ ; input data directory, if blank the $HOME directory is used.
                   auxiliar_dir      : '',  $ ; input data directory, if blank the $HOME directory is used.
                   indexes_dir       : 'indexes',  $ ; input data directory, if blank the $HOME directory is used.
                   qdays_dir         : 'qdays',  $ ; input data directory, if blank the $HOME directory is used.
                   plots_dir         : 'plots',  $ ; input data directory, if blank the $HOME directory is used.
                   processed_dir     : 'processed',  $ ; input data directory, if blank the $HOME directory is used.
                   geomagixs_dir     : '/home/luis/GDL/geomagixs',  $ ; input data directory, if blank the $HOME directory is used.
                   gms_file          : 'gms.config',  $ ; input data file
                   gms               : 2, $ ; 0: planetary, 1: mexico, 2: coeneo, 3: teoloyucan
                   gms_total         : 0, $
                   setup_file        : '',  $ ; setup data file
                   log               : '',  $
                   qdays_dates       : INTARR(2,3), $
                   today_date        : [0,0,0], $
                   contact1_mail     : '', $
                   contact2_mail     : '', $
                   ssh_on            : 0, $  ; ssh Activated [1] Not Activated [0]
                   ;ssh_address       : 'www.rice.unam.mx:/vol0/kpmex/', $
                   ;ssh_user          : 'pcorona', $
                   ;ssh_password      : 'G30m4gn3t0!', $
                   ftp_on            : 1, $  ; ftp Activated [1] Not Activated [0]
                   ftp_ip            : '132.248.208.46', $
                   ftp_address       : 'sftp://132.248.208.46/data/' , $
                   ftp_user          : 'regmex', $
                   ftp_password      : 'r3gm3x-m0r3l14', $
                   version           : '1.2', $  ; version of this software
                   date              : '2022/08/22' $
                 }
        
        spawn, 'echo $GEOMAGIXS_DIR', result
        IF STRLEN(result) NE 0 THEN system.geomagixs_dir=result
        ;-----------------------------------------------------------------------
        CALDAT, SYSTIME( /JULIAN, /UTC ), M, D, Y
        system.today_date = [y,m,d]

        Flag_setup = 1

RETURN

END
