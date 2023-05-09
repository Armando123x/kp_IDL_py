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
; CATEGORY:https://www.l3harrisgeospatial.com/docs/r_correlate.html
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
; FUNCION AUXILIAR
FUNCTION getting_data, file_name

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

;##############################################################################
; reading data files
;##############################################################################

        file = FILE_SEARCH(file_name, COUNT=opened_files)        
                IF opened_files LT 1 THEN MESSAGE, file_name+' not found.'

        number_of_lines = FILE_LINES(file)
        file_data   = STRARR(number_of_lines)
        
        OPENR, lun, file, /GET_LUN, ERROR=err
                READF, lun, file_data, FORMAT='(A)'
        CLOSE, lun
        FREE_LUN, lun
        
        
;print, STRLEN(file_data[0]),number_of_lines
        IF STRLEN(file_data[0]) LE 56 THEN BEGIN
                DataStruct  =  { year : 0, month : 0, day : 0, $
                                 hour : 0, minute : 0, $
                                 D : 0., H : 0., Z : 0., I : 0., F : 0. }
                
                
                format_for_reading = '(I4,X,I2,X,I2,X,I2,X,I2,X,F7,X,F7,X,F7,X,F7,X,F7)'
                
                PRINT, 'reading magnetic data from: '+file_name
        ENDIF ELSE BEGIN
                DataStruct  =  { year : 0, month : 0, day : 0, $
                                 hour : 0, minute : 0, $
                                 D : 0., H : 0., Z : 0., Tc : 0., Ts : 0. }
                
                format_for_reading = '(I4,X,I2,X,I2,X,I2,X,I2,2x,F9,X,F9,X,F9,X,F8,X,F8)'
                
                PRINT, 'reading voltage data from: '+file_name
        ENDELSE
        data = REPLICATE(DataStruct, number_of_lines)


        READS, file_data, data, FORMAT=format_for_reading

        dummy = SIZE(TEMPORARY(file_data))
                         

        Return, data
END


;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
;##############################################################################
; FUNCION AUXILIAR




;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################
;###############################################################################

















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


PRO geomagixs_make_viewstation, initial, final, STATION=station, $
                                                QUIET=quiet, $
                                                FORCE_ALL=force_all, $
                                                H=h, D=d, Z=z

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

        number_of_days = JULDAY(final_month,final_day,final_year)-JULDAY(initial_month,initial_day-1,initial_year)
        
        time_array     = findgen(number_of_days*24*60)/(number_of_days*24*60-1)*(number_of_days*24*60)


;##############################################################################
; reading data files
;##############################################################################
        calibration_dir = '~/DATA/calibration'
        PRINT, 'WARNING:'
        PRINT, '        This program compares the values of AUXILIAR gms with those'
        PRINT, '        values of the selected station ['+STRUPCASE(gms[system.gms].name)+'].'
        PRINT, ''
        PRINT, ''
        PRINT, '   Serching for the files:'
        PRINT, '      '+gms[system.gms].code+'_'+STRING(initial_year, initial_month, initial_day, final_year, final_month, final_day, $
                                      FORMAT='(I4,I02,I02,"-",I4,I02,I02)')+'.calibration.[m/v]'
        PRINT, '   at the directory: '+calibration_dir

        file_name = gms[system.gms].code+'_'+STRING(initial_year, initial_month, initial_day, final_year, final_month, final_day, $
                                      FORMAT='(I4,I02,I02,"-",I4,I02,I02)')+'.calibration.*'
        files_station = FILE_SEARCH(calibration_dir+'/'+file_name, COUNT=opened_files)
        IF opened_files NE 2 THEN MESSAGE, '* FATAL ERROR: Missing calibration files: '+file_name

        PRINT, ''
        PRINT, '   Reading Data files.'


        station_magnetic_data = getting_data(files_station[0])
        station_voltage_data  = getting_data(files_station[1])
        

        ;print, magnetic_indexes

        PRINT, ''
        PRINT, ''
        PRINT, '   Base-line reference values: <H> [nT]    <D> [°]    <Z> [nT]'
        H_base = 27393.3
        D_base = 5.434
        Z_base = 29444.6
        PRINT, H_base, D_base, Z_base, FORMAT='(32X,F7.1,6X,F5.3,5X,F7.1)'


        magnetic_indexes       = WHERE(station_magnetic_data[*].H LT 99990.0 AND $
                                       station_magnetic_data[*].D LT 90.0 AND $
                                       station_magnetic_data[*].Z LT 99990.0 AND $
                                       ABS(station_voltage_data[*].H) LT 1500.0 AND $
                                       ABS(station_voltage_data[*].D) LT 1500.0 AND $
                                       ABS(station_voltage_data[*].Z) LT 1500.0)

DEVICE, DECOMPOSED = 0
        WINDOW, 2, XSIZE=1200, YSIZE=800, TITLE='General Data'
        !P.MULTI = [0, 3, 3]
LOADCT, 39
        
        Y_max = MAX([station_magnetic_data[magnetic_indexes].H-H_base])
        Y_min = MIN([station_magnetic_data[magnetic_indexes].H-H_base])
        
        PLOT, time_array[magnetic_indexes]/(24*60)+1, station_magnetic_data[magnetic_indexes].H-H_base, $
              color=0, background=255 , Title='H [nT] - Station(blue)', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60)+1, station_magnetic_data[magnetic_indexes].H-H_base, color=245
        OPLOT, time_array[magnetic_indexes]/(24*60)+1, station_magnetic_data[magnetic_indexes].H-H_base, color=50, NSUM=60.*24.,thick=2

        Y_max = MAX([station_magnetic_data[magnetic_indexes].Z-Z_base])
        Y_min = MIN([station_magnetic_data[magnetic_indexes].Z-Z_base])
        
        PLOT, time_array[magnetic_indexes]/(24*60)+1, station_magnetic_data[magnetic_indexes].Z-Z_base, $
              color=0, background=1 , Title='Z [nT] - Station(blue)', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60)+1, station_magnetic_data[magnetic_indexes].Z-Z_base, color=245
        OPLOT, time_array[magnetic_indexes]/(24*60)+1, station_magnetic_data[magnetic_indexes].Z-Z_base, color=50, NSUM=60.*24.,thick=2

        Y_max = MAX([station_magnetic_data[magnetic_indexes].D-D_base])
        Y_min = MIN([station_magnetic_data[magnetic_indexes].D-D_base])
        
        PLOT, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].D-D_base, $
              color=0, background=1 , Title='D [nT] - Station(blue)', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].D-D_base, color=245
        OPLOT, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].D-D_base, color=50, NSUM=60.*24.,thick=2




        Y_max = MAX([station_voltage_data[magnetic_indexes].H])
        Y_min = MIN([station_voltage_data[magnetic_indexes].H])
        
        PLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].H, $
              color=0, background=255 , Title='H [mV] - Station(blue)', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].H, color=245
        OPLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].H, color=50, NSUM=60.*24.,thick=2

        Y_max = MAX([station_voltage_data[magnetic_indexes].Z])
        Y_min = MIN([station_voltage_data[magnetic_indexes].Z])
        
        PLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].Z, $
              color=0, background=255 , Title='Z [mV] - Auxiliar(red) & Station(blue)', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].Z, color=245
        OPLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].Z, color=50, NSUM=60.*24.,thick=2

        Y_max = MAX([station_voltage_data[magnetic_indexes].D])
        Y_min = MIN([station_voltage_data[magnetic_indexes].D])
        
        PLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].D, $
              color=0, background=255 , Title='D [mV] - Station(blue)', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].D, color=245
        OPLOT, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].D, color=50, NSUM=60.*24.,thick=2




        Y_max = MAX(station_magnetic_data[magnetic_indexes].F)
        Y_min = MIN(station_magnetic_data[magnetic_indexes].F)
        
        PLOT, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].F, $
              color=0, background=1 , Title='F [nT] - Station', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].F, color=245
        OPLOT, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].F, color=50, NSUM=60.*24.,thick=2

        Y_max = 0.15*(MAX([station_voltage_data[magnetic_indexes].Ts])-250.)+25.
        Y_min = 0.15*(MIN([station_voltage_data[magnetic_indexes].Ts])-250.)+25.
        
        PLOT, time_array[magnetic_indexes]/(24*60), 0.15*(station_voltage_data[magnetic_indexes].Ts-250.)+25., $
              color=0, background=1 , Title='Tsensor [C Deg] - Auxiliar(red) & Station(blue)', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60), 0.15*(station_voltage_data[magnetic_indexes].Ts-250.)+25., color=245
        OPLOT, time_array[magnetic_indexes]/(24*60), 0.15*(station_voltage_data[magnetic_indexes].Ts-250.)+25., color=50, NSUM=60.*24.,thick=2

        Y_max = 0.15*(MAX([station_voltage_data[magnetic_indexes].Tc])-250.)+25.
        Y_min = 0.15*(MIN([station_voltage_data[magnetic_indexes].Tc])-250.)+25.
        
        PLOT, time_array[magnetic_indexes]/(24*60), 0.15*(station_voltage_data[magnetic_indexes].Tc-250.)+25, $
              color=0, background=1 , Title='Tcontrol [C Deg] - Station vs Auxiliar', /NODATA, CHARSIZE=2., YRANGE=[Y_min, Y_max]
        OPLOT, time_array[magnetic_indexes]/(24*60), 0.15*(station_voltage_data[magnetic_indexes].Tc-250.)+25, color=245
        OPLOT, time_array[magnetic_indexes]/(24*60), 0.15*(station_voltage_data[magnetic_indexes].Tc-250.)+25, color=50, NSUM=60.*24.,thick=2

LOADCT, 0





IF keyword_set(H) THEN BEGIN
PRINT, '========================================================================'
PRINT, ' H - component analysis'
PRINT, '------------------------------------------------------------------------'
PRINT, ''

        valid_indexes       = (station_magnetic_data[*].H LE 99999.0) AND (auxiliar_magnetic_data[*].H LE 99999.0) AND $
                              (station_voltage_data[*].Ts GE 180.0) AND (auxiliar_voltage_data[*].Ts GE 180.0)

        
        magnetic_indexes       = WHERE(station_magnetic_data[*].H LT 99999.0 AND auxiliar_magnetic_data[*].H LT 99999.0 )
        magnetic_indexes0      = WHERE(valid_indexes EQ 1)
        PRINT, ''
        PRINT, ''
        PRINT, '   Correlations:  H [nT]       H [mV]'

        corr1 = CORRELATE(station_magnetic_data[magnetic_indexes].H-H_base, auxiliar_magnetic_data[magnetic_indexes].H-H_base)
        corr2 = CORRELATE(station_voltage_data[magnetic_indexes].H, auxiliar_voltage_data[magnetic_indexes].H)
        PRINT, corr1, corr2, FORMAT='(18X,F6.4,7X,F6.4, "  *** non-gap data ")'
        ;print, magnetic_indexes
        corr1 = CORRELATE(station_magnetic_data[magnetic_indexes0].H-H_base, auxiliar_magnetic_data[magnetic_indexes0].H-H_base)
        corr2 = CORRELATE(station_voltage_data[magnetic_indexes0].H, auxiliar_voltage_data[magnetic_indexes0].H)
        PRINT, corr1, corr2, FORMAT='(18X,F6.4,7X,F6.4, "  *** non-gap & temp data ")'
        ;print, TOTAL(ABS(station_magnetic_data[magnetic_indexes].H-auxiliar_magnetic_data[magnetic_indexes].H))/TOTAL(station_magnetic_data[magnetic_indexes].H)
        ;print, CORRELATE(station_magnetic_data[magnetic_indexes].H-H_base, (auxiliar_magnetic_data[magnetic_indexes].H-H_base)/corr1), $
        ;       CORRELATE((station_magnetic_data[*].H-H_base)*valid_indexes, (auxiliar_magnetic_data[*].H-H_base)*valid_indexes/corr2)
        PRINT, ''
        PRINT, ''
        station_magnetic_mean  = MEDIAN(station_magnetic_data[magnetic_indexes].H-H_base)
        station_voltage_mean   = MEDIAN(station_voltage_data[magnetic_indexes].H)
        auxiliar_magnetic_mean = MEDIAN(auxiliar_magnetic_data[magnetic_indexes].H-H_base)
        auxiliar_voltage_mean  = MEDIAN(auxiliar_voltage_data[magnetic_indexes].H)

        PRINT, '   Medians +/- STDDEV:  H [nT]       H [mV]'
        PRINT, 'STATION:', MEDIAN(station_magnetic_data[magnetic_indexes].H-H_base), $
                           STDDEV(station_magnetic_data[magnetic_indexes].H-H_base), $
                           MEDIAN(station_voltage_data[magnetic_indexes].H), $
                           STDDEV(station_voltage_data[magnetic_indexes].H), $
                           FORMAT='(A, 5X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'
        print, 'Auxiliar:', MEDIAN(auxiliar_magnetic_data[magnetic_indexes].H-H_base), $
                           STDDEV(auxiliar_magnetic_data[magnetic_indexes].H-H_base), $
                           MEDIAN(auxiliar_voltage_data[magnetic_indexes].H), $
                           STDDEV(auxiliar_voltage_data[magnetic_indexes].H), $
                           FORMAT='(A, 4X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'
PRINT, '------------------------------------------------------------------------'
        print, 'Differences:', MEDIAN(station_magnetic_data[magnetic_indexes].H-auxiliar_magnetic_data[magnetic_indexes].H), $
                               STDDEV(station_magnetic_data[magnetic_indexes].H-auxiliar_magnetic_data[magnetic_indexes].H), $
                               MEDIAN(station_voltage_data[magnetic_indexes].H-auxiliar_voltage_data[magnetic_indexes].H), $
                               STDDEV(station_voltage_data[magnetic_indexes].H-auxiliar_voltage_data[magnetic_indexes].H), $
                               FORMAT='(A, X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'

        c_magnetic = MEDIAN(station_magnetic_data[magnetic_indexes].H-auxiliar_magnetic_data[magnetic_indexes].H)
        c_voltage  = MEDIAN(station_voltage_data[magnetic_indexes].H-auxiliar_voltage_data[magnetic_indexes].H)


PRINT, '========================================================================'
PRINT, '------------------------------------------------------------------------'

        print, ''
        magneticfit = LINFIT(station_magnetic_data[magnetic_indexes].H-H_base, $
                           station_voltage_data[magnetic_indexes].H, $
                           MEASURE_ERRORS=measure_errors)
        print, 'Magntic fit:', magneticfit, '   constants in mV and nT:', magneticfit[1]*c_magnetic, c_voltage/magneticfit[1]

PRINT, '------------------------------------------------------------------------'

        auxiliarfit = LINFIT(auxiliar_magnetic_data[magnetic_indexes].H-H_base, $
                             auxiliar_voltage_data[magnetic_indexes].H, $
                             MEASURE_ERRORS=measure_errors)
        print, 'Auxiliar fit:', auxiliarfit

        print, ''
PRINT, '------------------------------------------------------------------------'
        
        result = LINFIT(auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic, $
                        station_magnetic_data[magnetic_indexes].H-H_base, $;-c_voltage, $
                        MEASURE_ERRORS=measure_errors, sigma=uncertainties)
                        
        print, '1st line fit:     ', result
        print, '    uncertainties:', uncertainties
        print, '      correlation:', correlate(auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic,station_magnetic_data[magnetic_indexes].H-H_base)
        
        result1 = LINFIT((auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1], $
                          station_magnetic_data[magnetic_indexes].H-H_base, $
                          MEASURE_ERRORS=measure_errors, sigma=uncertainties)
        print, '2nd line fit:     ', result1
        print, '    uncertainties:', uncertainties
        print, '      correlation:', correlate((auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic)*result[1],station_magnetic_data[magnetic_indexes].H-H_base)




        tmp_auxiliar_magnetic_data = (auxiliar_voltage_data[magnetic_indexes].H+result[0]/result[1])*result[1]/magneticfit[1]-magneticfit[0]
        tmp_auxiliar_voltage_data  = (auxiliar_voltage_data[magnetic_indexes].H)*result[1]
        tmp_station_voltage_data = station_voltage_data[magnetic_indexes].H-result[0]
        
        ;plot, station_magnetic_data[magnetic_indexes].H-c_magnetic-H_base, linestyle=1
        ;plot, (station_voltage_data[magnetic_indexes].H-c_voltage)
        ;oplot, auxiliar_voltage_data[magnetic_indexes].H
DEVICE, DECOMPOSED = 0
        WINDOW, 0, XSIZE=600, YSIZE=600, TITLE='H - Callibration window'
        !P.MULTI = [0, 2, 2]
        
        tmp_arr = station_voltage_data[magnetic_indexes].Ts-auxiliar_voltage_data[magnetic_indexes].Ts

;plot, (tmp_arr[*]), linestyle=0, NSUM=50*24;, YRange=[-600,100.]

;plot, station_voltage_data[magnetic_indexes].Ts, linestyle=1
;oplot, auxiliar_voltage_data[magnetic_indexes].Ts, linestyle=0
LOADCT, 39

        Y_max = MAX([auxiliar_magnetic_data[magnetic_indexes].H-H_base,station_magnetic_data[magnetic_indexes].H-H_base])
        Y_min = MIN([auxiliar_magnetic_data[magnetic_indexes].H-H_base,station_magnetic_data[magnetic_indexes].H-H_base])
        plot, time_array[magnetic_indexes]/(24*60),auxiliar_magnetic_data[magnetic_indexes].H-H_base, linestyle=0, title='nT', $
              YRange=[Y_min,Y_max], /NoData, Color=0, background=255, CHARSIZE=1.0
        oplot, time_array[magnetic_indexes]/(24*60), auxiliar_magnetic_data[magnetic_indexes].H-H_base, color = 254
        oplot, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].H-H_base, color = 50;, title='Station mV'


        Y_max = MAX([auxiliar_voltage_data[magnetic_indexes].H,station_voltage_data[magnetic_indexes].H])
        Y_min = MIN([auxiliar_voltage_data[magnetic_indexes].H,station_voltage_data[magnetic_indexes].H])
        plot, time_array[magnetic_indexes]/(24*60),auxiliar_voltage_data[magnetic_indexes].H, linestyle=0, title='mV', $
              YRange=[Y_min,Y_max], /NODATA, Color=0, background=255, CHARSIZE=1.0
        oplot, time_array[magnetic_indexes]/(24*60),auxiliar_voltage_data[magnetic_indexes].H, color = 254

        oplot, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].H, color = 50;, title='Station mV'


        Y_max = MAX((auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1]-(station_magnetic_data[magnetic_indexes].H-H_base))
        Y_min = MIN((auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1]-(station_magnetic_data[magnetic_indexes].H-H_base))
        plot, time_array[magnetic_indexes]/(24*60), (auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1]-(station_magnetic_data[magnetic_indexes].H-H_base), linestyle=0, title='Auxiliar vs Station Difference [nT]', $
              YRange=[Y_min,Y_max], /NODATA, Color=0, background=255, CHARSIZE=1.0
        oplot, time_array[magnetic_indexes]/(24*60), (auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1]-(station_magnetic_data[magnetic_indexes].H-H_base), color = 254
        
        Y_max = MAX((station_magnetic_data[magnetic_indexes].H-H_base))
        Y_min = MIN((station_magnetic_data[magnetic_indexes].H-H_base))
        X_max = MAX((auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1])
        X_min = MIN((auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1])
        Y_max = MAX([Y_max,X_max])
        Y_min = MIN([Y_min,X_min])
        X_max = Y_max
        X_min = X_min
        plot, (auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1], (station_magnetic_data[magnetic_indexes].H-H_base), title='Station vs Auxiliar [nT]', YRange=[Y_min,Y_max], XRange=[X_min,X_max], /NODATA, Color=0, background=255, CHARSIZE=1.0
        oplot,  (auxiliar_magnetic_data[magnetic_indexes].H-H_base+c_magnetic+result[0]/result[1])*result[1], (station_magnetic_data[magnetic_indexes].H-H_base), color = 254
;oplot, time_array[magnetic_indexes]/(24*60),(station_magnetic_data[magnetic_indexes].H-H_base), linestyle=2

LOADCT, 0

print, Mean((auxiliar_magnetic_data[magnetic_indexes].H-H_base)/(station_magnetic_data[magnetic_indexes].H-H_base)), STDDEV((auxiliar_magnetic_data[magnetic_indexes].H-H_base)/(station_magnetic_data[magnetic_indexes].H-H_base))

        PRINT, '------------------------------------------------------------------------'
        PRINT, '========================================================================'
        PRINT, '------ H component------------------------------------------------------'
        PRINT, ' New proportional constant [nT/mV] & new offset [mV]'
        PRINT, auxiliarfit[1]*result[1], (c_magnetic+result[0]/result[1])*auxiliarfit[1]*result[1],  c_voltage
        PRINT, '------------------------------------------------------------------------'
        PRINT, '========================================================================'
        PRINT, ''

DEVICE, DECOMPOSED = 0
        WINDOW, 1, XSIZE=600, YSIZE=600, TITLE='H - Revision window'
        !P.MULTI = [0, 2, 2]
LOADCT, 39
        PLOT, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].H-H_base, color=0, background=255, title='Station [nT] vs Auxiliar [mV]', Ytitle='nT'
        ;Oplot, time_array[magnetic_indexes]/(24*60), (auxiliar_voltage_data[magnetic_indexes].H+(c_magnetic+result[0]/result[1])*auxiliarfit[1]*result[1])/auxiliarfit[1]*result[1], color=250
        Oplot, time_array[magnetic_indexes]/(24*60), (auxiliar_voltage_data[magnetic_indexes].H+(c_magnetic+result[0]/result[1])*auxiliarfit[1]*result[1])/(auxiliarfit[1]*result[1]), color=250


        PLOT, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].H-H_base - $
                                                    (auxiliar_voltage_data[magnetic_indexes].H+(c_magnetic)*auxiliarfit[1]*result[1])/(auxiliarfit[1]*result[1]), $;], $
                                                    color=0, background=255, title='Final Difference', Ytitle='nT'


LOADCT, 0
ENDIF

;plot, auxiliar_magnetic_data[magnetic_indexes].H-H_base, linestyle=0

;plot, station_magnetic_data[magnetic_indexes].H-H_base, linestyle=0

;print, N_ELEMENTS(magnetic_indexes), N_ELEMENTS(station_magnetic_data[*].H), N_ELEMENTS(station_voltage_data[*].H)
;for i=0, N_ELEMENTS(magnetic_indexes)-1 DO print, station_voltage_data[i].H, station_magnetic_data[i].H
;print, MAX((station_magnetic_data[*].H-H_base)*valid_indexes), MAX((station_voltage_data[*].H)*valid_indexes)
;print, MIN((station_magnetic_data[*].H-H_base)*valid_indexes), MIN((station_voltage_data[*].H)*valid_indexes)
IF keyword_set(D) THEN BEGIN
        PRINT, ''
        PRINT, ''
        magnetic_indexes       = WHERE(station_magnetic_data[*].D LT 90.0 AND auxiliar_magnetic_data[*].D LT 90.0 AND $
                              (station_voltage_data[*].D LE 0.0) AND (auxiliar_voltage_data[*].D LE 0.0))
        valid_indexes       = (station_magnetic_data[*].D LE 90.0) AND (auxiliar_magnetic_data[*].D LE 90.0) AND $
                              (station_voltage_data[*].D LE 0.0) AND (auxiliar_voltage_data[*].D LE 180.0)
        magnetic_indexes0      = WHERE(valid_indexes EQ 1)

        PRINT, '   Correlations:  D [nT]       D [mV]'

        corr1 = CORRELATE(station_magnetic_data[magnetic_indexes].D, auxiliar_magnetic_data[magnetic_indexes].D)
        corr2 = CORRELATE(station_voltage_data[magnetic_indexes].D, auxiliar_voltage_data[magnetic_indexes].D)
        PRINT, corr1, corr2, FORMAT='(18X,F6.2,7X,F6.2, "  *** non-gap data ")'
        ;print, magnetic_indexes
        corr1 = CORRELATE(station_magnetic_data[magnetic_indexes0].D, auxiliar_magnetic_data[magnetic_indexes0].D)
        corr2 = CORRELATE(station_voltage_data[magnetic_indexes0].D, auxiliar_voltage_data[magnetic_indexes0].D)
        PRINT, corr1, corr2, FORMAT='(18X,F6.2,7X,F6.2, "  *** non-gap & temp data ")'
        ;print, TOTAL(ABS(station_magnetic_data[magnetic_indexes].H-auxiliar_magnetic_data[magnetic_indexes].H))/TOTAL(station_magnetic_data[magnetic_indexes].H)
        ;print, CORRELATE(station_magnetic_data[magnetic_indexes].H-H_base, (auxiliar_magnetic_data[magnetic_indexes].H-H_base)/corr1), $
        ;       CORRELATE((station_magnetic_data[*].H-H_base)*valid_indexes, (auxiliar_magnetic_data[*].H-H_base)*valid_indexes/corr2)
        PRINT, ''
        PRINT, ''
        station_magnetic_mean  = MEDIAN(station_magnetic_data[magnetic_indexes].D-D_base)
        station_voltage_mean   = MEDIAN(station_voltage_data[magnetic_indexes].D)
        auxiliar_magnetic_mean = MEDIAN(auxiliar_magnetic_data[magnetic_indexes].D-D_base)
        auxiliar_voltage_mean  = MEDIAN(auxiliar_voltage_data[magnetic_indexes].D)

        PRINT, '   Medians +/- STDDEV:  H [nT]       H [mV]'
        PRINT, 'STATION:', MEDIAN(station_magnetic_data[magnetic_indexes].D-D_base), $
                           STDDEV(station_magnetic_data[magnetic_indexes].D-D_base), $
                           MEDIAN(station_voltage_data[magnetic_indexes].D), $
                           STDDEV(station_voltage_data[magnetic_indexes].D), $
                           FORMAT='(A, 5X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'
        print, 'Auxiliar:', MEDIAN(auxiliar_magnetic_data[magnetic_indexes].D-D_base), $
                           STDDEV(auxiliar_magnetic_data[magnetic_indexes].D-D_base), $
                           MEDIAN(auxiliar_voltage_data[magnetic_indexes].D), $
                           STDDEV(auxiliar_voltage_data[magnetic_indexes].D), $
                           FORMAT='(A, 4X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'
        PRINT, '------------------------------------------------------------------------'
        print, 'Differences:', MEDIAN(station_magnetic_data[magnetic_indexes].D-auxiliar_magnetic_data[magnetic_indexes].D), $
                               STDDEV(station_magnetic_data[magnetic_indexes].D-auxiliar_magnetic_data[magnetic_indexes].D), $
                               MEDIAN(station_voltage_data[magnetic_indexes].D-auxiliar_voltage_data[magnetic_indexes].D), $
                               STDDEV(station_voltage_data[magnetic_indexes].D-auxiliar_voltage_data[magnetic_indexes].D), $
                               FORMAT='(A, X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'

        c_magnetic = MEDIAN(station_magnetic_data[magnetic_indexes].D-auxiliar_magnetic_data[magnetic_indexes].D)
        c_voltage  = MEDIAN(station_voltage_data[magnetic_indexes].D-auxiliar_voltage_data[magnetic_indexes].D)


        PRINT, '========================================================================'
        PRINT, '------------------------------------------------------------------------'


        print, ''
        magneticfit = LINFIT(station_magnetic_data[magnetic_indexes].D-D_base, $
                           station_voltage_data[magnetic_indexes].D, $
                           MEASURE_ERRORS=measure_errors)
        print, 'Magntic fit:', magneticfit, '   constants in mV and nT:', magneticfit[1]*c_magnetic, c_voltage/magneticfit[1]

        PRINT, '------------------------------------------------------------------------'

        auxiliarfit = LINFIT(auxiliar_magnetic_data[magnetic_indexes].D-D_base, $
                             auxiliar_voltage_data[magnetic_indexes].D, $
                             MEASURE_ERRORS=measure_errors)
        print, 'Auxiliar fit:', auxiliarfit

        print, ''
        PRINT, '------------------------------------------------------------------------'
        
        result = LINFIT(auxiliar_magnetic_data[magnetic_indexes].D-D_base+c_magnetic, $
                        station_magnetic_data[magnetic_indexes].D-D_base, $;-c_voltage, $
                        MEASURE_ERRORS=measure_errors, sigma=uncertainties)
                        
        print, '1st line fit:     ', result
        print, '    uncertainties:', uncertainties
        print, '      correlation:', correlate(auxiliar_magnetic_data[magnetic_indexes].D-D_base+c_magnetic,station_magnetic_data[magnetic_indexes].D-D_base)
        
        result1 = LINFIT((auxiliar_magnetic_data[magnetic_indexes].D-D_base+c_magnetic+result[0]/result[1])*result[1], $
                         station_magnetic_data[magnetic_indexes].D-D_base, $
                        MEASURE_ERRORS=measure_errors, sigma=uncertainties)
        print, '2nd line fit:     ', result1
        print, '    uncertainties:', uncertainties
        print, '      correlation:', correlate((auxiliar_magnetic_data[magnetic_indexes].D-D_base+c_magnetic)*result[1],station_magnetic_data[magnetic_indexes].D-D_base)




        tmp_auxiliar_magnetic_data = (auxiliar_voltage_data[magnetic_indexes].D+result[0]/result[1])*result[1]/magneticfit[1]-magneticfit[0]
        tmp_auxiliar_voltage_data  = (auxiliar_voltage_data[magnetic_indexes].D)*result[1]
        tmp_station_voltage_data = station_voltage_data[magnetic_indexes].D-result[0]


        WINDOW, 0, XSIZE=1200, YSIZE=1200, TITLE='Callibration window'
        !P.MULTI = [0, 2, 2]
        
        tmp_arr = station_voltage_data[magnetic_indexes].Ts-auxiliar_voltage_data[magnetic_indexes].Ts

;plot, (tmp_arr[*]), linestyle=0, NSUM=50*24;, YRange=[-600,100.]

;plot, station_voltage_data[magnetic_indexes].Ts, linestyle=1
;oplot, auxiliar_voltage_data[magnetic_indexes].Ts, linestyle=0
        plot, time_array[magnetic_indexes]/(24*60),auxiliar_magnetic_data[magnetic_indexes].D-D_base, linestyle=0, title='nT';, YRange=[-50.,250.]

        oplot, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].D-D_base, linestyle=2;, title='Station mV'


        plot, time_array[magnetic_indexes]/(24*60),auxiliar_voltage_data[magnetic_indexes].D, linestyle=0, title='mV';, YRange=[-50.,250.]

        oplot, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].D, linestyle=2;, title='Station mV'



        plot, time_array[magnetic_indexes]/(24*60), (auxiliar_magnetic_data[magnetic_indexes].D-D_base+c_magnetic+result[0]/result[1])*result[1]-(station_magnetic_data[magnetic_indexes].D-D_base), linestyle=0, title='Station vs Auxiliar Difference'

        plot, (auxiliar_magnetic_data[magnetic_indexes].D-D_base+c_magnetic+result[0]/result[1])*result[1], (station_magnetic_data[magnetic_indexes].D-D_base), title='Station vs Auxiliar [nT]';, YRange=[50.,120.], XRange=[50.,120.]
        PRINT, '------------------------------------------------------------------------'
        PRINT, '========================================================================'
        PRINT, '------ D component------------------------------------------------------'
        PRINT, ' New proportional constant [nT/mV] & new offset [mV]'
        PRINT, auxiliarfit[1]*result[1], (c_magnetic+result[0]/result[1])/result[1]

;return
        PRINT, '------------------------------------------------------------------------'
        PRINT, '========================================================================'
        PRINT, ''
ENDIF


IF keyword_set(Z) THEN BEGIN
        PRINT, ''
        PRINT, ''
        magnetic_indexes       = WHERE(station_magnetic_data[*].Z LT 99999.0 AND auxiliar_magnetic_data[*].Z LT 99999.0 )
        valid_indexes       = (station_magnetic_data[*].Z LE 99999.0) AND (auxiliar_magnetic_data[*].Z LE 99999.0) AND $
                              (station_voltage_data[*].Ts GE 180.0) AND (auxiliar_voltage_data[*].Ts GE 180.0)
        magnetic_indexes0      = WHERE(valid_indexes EQ 1)

        PRINT, '   Correlations:  Z [nT]       Z [mV]'

        corr1 = CORRELATE(station_magnetic_data[magnetic_indexes].Z-Z_base, auxiliar_magnetic_data[magnetic_indexes].Z-Z_base)
        corr2 = CORRELATE(station_voltage_data[magnetic_indexes].Z, auxiliar_voltage_data[magnetic_indexes].Z)
        PRINT, corr1, corr2, FORMAT='(18X,F6.4,7X,F6.4, "  *** non-gap data ")'
        ;print, magnetic_indexes
        corr1 = CORRELATE(station_magnetic_data[magnetic_indexes0].Z-Z_base, auxiliar_magnetic_data[magnetic_indexes0].Z-Z_base)
        corr2 = CORRELATE(station_voltage_data[magnetic_indexes0].Z, auxiliar_voltage_data[magnetic_indexes0].Z)
        PRINT, corr1, corr2, FORMAT='(18X,F6.4,7X,F6.4, "  *** non-gap & temp data ")'
        ;print, TOTAL(ABS(station_magnetic_data[magnetic_indexes].H-auxiliar_magnetic_data[magnetic_indexes].H))/TOTAL(station_magnetic_data[magnetic_indexes].H)
        ;print, CORRELATE(station_magnetic_data[magnetic_indexes].H-H_base, (auxiliar_magnetic_data[magnetic_indexes].H-H_base)/corr1), $
        ;       CORRELATE((station_magnetic_data[*].H-H_base)*valid_indexes, (auxiliar_magnetic_data[*].H-H_base)*valid_indexes/corr2)
        PRINT, ''
        PRINT, ''
        station_magnetic_mean  = MEDIAN(station_magnetic_data[magnetic_indexes].Z-Z_base)
        station_voltage_mean   = MEDIAN(station_voltage_data[magnetic_indexes].Z)
        auxiliar_magnetic_mean = MEDIAN(auxiliar_magnetic_data[magnetic_indexes].Z-Z_base)
        auxiliar_voltage_mean  = MEDIAN(auxiliar_voltage_data[magnetic_indexes].Z)

        PRINT, '   Medians +/- STDDEV:  Z [nT]       Z [mV]'
        PRINT, 'STATION:', MEDIAN(station_magnetic_data[magnetic_indexes].Z-Z_base), $
                           STDDEV(station_magnetic_data[magnetic_indexes].Z-Z_base), $
                           MEDIAN(station_voltage_data[magnetic_indexes].Z), $
                           STDDEV(station_voltage_data[magnetic_indexes].Z), $
                           FORMAT='(A, 5X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'
        print, 'Auxiliar:', MEDIAN(auxiliar_magnetic_data[magnetic_indexes].Z-Z_base), $
                           STDDEV(auxiliar_magnetic_data[magnetic_indexes].Z-Z_base), $
                           MEDIAN(auxiliar_voltage_data[magnetic_indexes].Z), $
                           STDDEV(auxiliar_voltage_data[magnetic_indexes].Z), $
                           FORMAT='(A, 4X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'
        PRINT, '------------------------------------------------------------------------'
        print, 'Differences:', MEDIAN(station_magnetic_data[magnetic_indexes].Z-auxiliar_magnetic_data[magnetic_indexes].Z), $
                               STDDEV(station_magnetic_data[magnetic_indexes].Z-auxiliar_magnetic_data[magnetic_indexes].Z), $
                               MEDIAN(station_voltage_data[magnetic_indexes].Z-auxiliar_voltage_data[magnetic_indexes].Z), $
                               STDDEV(station_voltage_data[magnetic_indexes].Z-auxiliar_voltage_data[magnetic_indexes].Z), $
                               FORMAT='(A, X, F7.2,"+/-",F7.3, 7X, F7.2, "+/-", F7.3)'

        c_magnetic = MEDIAN(station_magnetic_data[magnetic_indexes].Z-auxiliar_magnetic_data[magnetic_indexes].Z)
        c_voltage  = MEDIAN(station_voltage_data[magnetic_indexes].Z-auxiliar_voltage_data[magnetic_indexes].Z)

        PRINT, '========================================================================'
        PRINT, '------------------------------------------------------------------------'


        print, ''
        magneticfit = LINFIT(station_magnetic_data[magnetic_indexes].Z-Z_base, $
                           station_voltage_data[magnetic_indexes].Z, $
                           MEASURE_ERRORS=measure_errors)
        print, 'Magntic fit:', magneticfit, '   constants in mV and nT:', magneticfit[1]*c_magnetic, c_voltage/magneticfit[1]

        PRINT, '------------------------------------------------------------------------'

        auxiliarfit = LINFIT(auxiliar_magnetic_data[magnetic_indexes].Z-Z_base, $
                             auxiliar_voltage_data[magnetic_indexes].Z, $
                             MEASURE_ERRORS=measure_errors)
        print, 'Auxiliar fit:', auxiliarfit

        print, ''
        PRINT, '------------------------------------------------------------------------'
        
        result = LINFIT(auxiliar_magnetic_data[magnetic_indexes].Z-Z_base+c_magnetic, $
                        station_magnetic_data[magnetic_indexes].Z-Z_base, $;-c_voltage, $
                        MEASURE_ERRORS=measure_errors, sigma=uncertainties)
                        
        print, '1st line fit:     ', result
        print, '    uncertainties:', uncertainties
        print, '      correlation:', correlate(auxiliar_magnetic_data[magnetic_indexes].Z-Z_base+c_magnetic,station_magnetic_data[magnetic_indexes].Z-Z_base)
        
        result1 = LINFIT((auxiliar_magnetic_data[magnetic_indexes].Z-Z_base+c_magnetic+result[0]/result[1])*result[1], $
                         station_magnetic_data[magnetic_indexes].Z-Z_base, $
                        MEASURE_ERRORS=measure_errors, sigma=uncertainties)
        print, '2nd line fit:     ', result1
        print, '    uncertainties:', uncertainties
        print, '      correlation:', correlate((auxiliar_magnetic_data[magnetic_indexes].Z-Z_base+c_magnetic)*result[1],station_magnetic_data[magnetic_indexes].Z-Z_base)




        tmp_auxiliar_magnetic_data = (auxiliar_voltage_data[magnetic_indexes].Z+result[0]/result[1])*result[1]/magneticfit[1]-magneticfit[0]
        tmp_auxiliar_voltage_data  = (auxiliar_voltage_data[magnetic_indexes].Z)*result[1]
        tmp_station_voltage_data = station_voltage_data[magnetic_indexes].Z-result[0]


        WINDOW, 0, XSIZE=1200, YSIZE=1200, TITLE='Callibration window'
        !P.MULTI = [0, 2, 2]
        
        tmp_arr = station_voltage_data[magnetic_indexes].Ts-auxiliar_voltage_data[magnetic_indexes].Ts

;plot, (tmp_arr[*]), linestyle=0, NSUM=50*24;, YRange=[-600,100.]

;plot, station_voltage_data[magnetic_indexes].Ts, linestyle=1
;oplot, auxiliar_voltage_data[magnetic_indexes].Ts, linestyle=0
        plot, time_array[magnetic_indexes]/(24*60),auxiliar_magnetic_data[magnetic_indexes].Z-Z_base, linestyle=0, title='nT', YRange=[-50.,250.]

        oplot, time_array[magnetic_indexes]/(24*60), station_magnetic_data[magnetic_indexes].Z-Z_base, linestyle=2;, title='Station mV'


        plot, time_array[magnetic_indexes]/(24*60),auxiliar_voltage_data[magnetic_indexes].Z, linestyle=0, title='mV', YRange=[-50.,250.]

        oplot, time_array[magnetic_indexes]/(24*60), station_voltage_data[magnetic_indexes].Z, linestyle=2;, title='Station mV'



        plot, time_array[magnetic_indexes]/(24*60), (auxiliar_magnetic_data[magnetic_indexes].Z-Z_base+c_magnetic+result[0]/result[1])*result[1]-(station_magnetic_data[magnetic_indexes].Z-Z_base), linestyle=0, title='Station vs Auxiliar Difference'

        plot, (auxiliar_magnetic_data[magnetic_indexes].Z-Z_base+c_magnetic+result[0]/result[1])*result[1], (station_magnetic_data[magnetic_indexes].Z-Z_base), title='Station vs Auxiliar [nT]', YRange=[50.,120.], XRange=[50.,120.]
        PRINT, '------------------------------------------------------------------------'
        PRINT, '========================================================================'
        PRINT, '------ Z component------------------------------------------------------'
        PRINT, ' New proportional constant [nT/mV] & new offset [mV]'
        PRINT, auxiliarfit[1]*result[1], (c_magnetic+result[0]/result[1])*auxiliarfit[1]*result[1]
        PRINT, '------------------------------------------------------------------------'
        PRINT, '========================================================================'
        PRINT, ''
ENDIF


RETURN


END




