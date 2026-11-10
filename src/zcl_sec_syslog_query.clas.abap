CLASS zcl_sec_syslog_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        instancename    TYPE c LENGTH 20,
        filenumber      TYPE n LENGTH 6,
        fileposition    TYPE n LENGTH 10,
        eventon         TYPE d,
        eventat         TYPE t,
        messageid       TYPE c LENGTH 3,
        client          TYPE c LENGTH 3,
        username        TYPE c LENGTH 12,
        transactioncode TYPE c LENGTH 20,
        programname     TYPE c LENGTH 40,
        terminal        TYPE c LENGTH 8,
        messagedata     TYPE c LENGTH 64,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_access_auth OPTIONAL.

    METHODS read_rows
      IMPORTING
        io_request     TYPE REF TO if_rap_query_request OPTIONAL
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_access.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_access_auth.
ENDCLASS.


CLASS zcl_sec_syslog_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_system_log_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lt_date) = zcl_sec_query_util=>access_date_selection(
      it_range = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'EVENTON' )
      iv_name  = 'EVENTON' ).

    DATA lv_from TYPE d.
    DATA lv_to TYPE d.
    DATA lv_window TYPE abap_bool.
    LOOP AT lt_date INTO DATA(ls_date).
      IF to_upper( ls_date-sign ) = 'E'.
        CONTINUE.
      ENDIF.
      DATA lv_start TYPE d.
      DATA lv_end TYPE d.
      lv_start = ls_date-low.
      IF to_upper( ls_date-option ) = 'BT'.
        lv_end = ls_date-high.
      ELSE.
        lv_end = ls_date-low.
      ENDIF.
      IF lv_window = abap_false OR lv_start < lv_from.
        lv_from = lv_start.
      ENDIF.
      IF lv_window = abap_false OR lv_end > lv_to.
        lv_to = lv_end.
      ENDIF.
      lv_window = abap_true.
    ENDLOOP.
    IF lv_window = abap_false.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid      = zcx_sec_access=>filter_required
          filter_name = 'EVENTON'.
    ENDIF.

    " SM21 on this application server. The file does not always keep a full year.
    DATA ls_info TYPE rslgfinfo.
    DATA ls_sel TYPE rslgsel.
    DATA lt_log TYPE STANDARD TABLE OF rslgetab.
    ls_sel-whichlog = 'L'.
    ls_sel-date = lv_from.
    ls_sel-time = '000000'.
    ls_sel-edate = lv_to.
    ls_sel-etime = '235959'.
    ls_sel-startdate = lv_from && '00000000'.
    ls_sel-stop_date = lv_to && '23595999'.

    TRY.
        CALL FUNCTION 'RSLG_FILEINFO_INIT'
          EXPORTING
            whichlog   = 'L'
          IMPORTING
            info_after = ls_info.
        CALL FUNCTION 'RSLG_READ_FILE'
          EXPORTING
            file_info       = ls_info
            selection       = ls_sel
          TABLES
            syslog_in_table = lt_log.
      CATCH cx_root INTO DATA(lx_read).
        RAISE EXCEPTION TYPE zcx_sec_access
          EXPORTING
            previous = lx_read.
    ENDTRY.

    LOOP AT lt_log INTO DATA(ls_log).
      DATA ls_entry TYPE rslgentr.
      ls_entry = ls_log-centdata.
      DATA(lv_stamp) = COND string(
        WHEN ls_entry-slgdattim IS NOT INITIAL THEN ls_entry-slgdattim
        ELSE ls_log-pos_creatt ).
      DATA(lv_raw) = condense( lv_stamp ).
      DATA lv_date TYPE d.
      DATA lv_time TYPE t.
      CLEAR: lv_date, lv_time.
      IF strlen( lv_raw ) >= 14 AND substring( val = lv_raw len = 14 ) CO '0123456789'.
        lv_date = substring( val = lv_raw len = 8 ).
        lv_time = substring( val = lv_raw off = 8 len = 6 ).
      ENDIF.
      DATA(lv_instance) = COND string(
        WHEN ls_log-sender_id IS NOT INITIAL THEN ls_log-sender_id
        ELSE sy-host ).
      APPEND VALUE ty_row(
        instancename    = lv_instance
        filenumber      = ls_log-file_no
        fileposition    = ls_log-pos
        eventon         = lv_date
        eventat         = lv_time
        messageid       = ls_log-area && ls_log-subid
        client          = ls_entry-slgmand
        username        = ls_entry-slguser
        transactioncode = ls_entry-slgtc
        programname     = ls_entry-slgrepna
        terminal        = ls_entry-slgltrm
        messagedata     = ls_entry-slgdata ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
