CLASS zcl_sec_tpalog_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        importtimestamp TYPE n LENGTH 14,
        request         TYPE c LENGTH 20,
        targetsystem    TYPE c LENGTH 10,
        sourceclient    TYPE c LENGTH 3,
        step            TYPE c LENGTH 1,
        importon        TYPE d,
        allclients      TYPE c LENGTH 1,
        project         TYPE c LENGTH 20,
        username        TYPE c LENGTH 12,
        returncode      TYPE c LENGTH 4,
        returncodetext  TYPE c LENGTH 20,
        hostname        TYPE c LENGTH 32,
        administrator   TYPE c LENGTH 12,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

    METHODS read_rows
      IMPORTING
        io_request     TYPE REF TO if_rap_query_request OPTIONAL
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_settings.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_tpalog_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_transport_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lt_sql) = zcl_sec_query_util=>timestamp_selection(
      it_range = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'IMPORTON' )
      iv_name  = 'IMPORTON' ).

    TYPES ty_stamp TYPE n LENGTH 14.
    DATA lr_time TYPE RANGE OF ty_stamp.
    LOOP AT lt_sql INTO DATA(ls_sql).
      APPEND VALUE #(
        sign   = ls_sql-sign
        option = ls_sql-option
        low    = ls_sql-low
        high   = ls_sql-high ) TO lr_time.
    ENDLOOP.

    " TPALOG is the buffer STMS shows as import history. TPALOGHDR is the file header and is not a row.
    SELECT trtime, trkorr, tarsystem, trcli, trstep, allcli, project, truser, retcode, host, admin
      FROM tpalog
      WHERE trtime IN @lr_time
      INTO TABLE @DATA(lt_import).

    LOOP AT lt_import INTO DATA(ls_import).
      DATA(lv_day) = CONV string( ls_import-trtime ).
      DATA lv_date TYPE d.
      CLEAR lv_date.
      IF strlen( lv_day ) >= 8.
        lv_date = lv_day(8).
      ENDIF.
      APPEND VALUE ty_row(
        importtimestamp = ls_import-trtime
        request         = ls_import-trkorr
        targetsystem    = ls_import-tarsystem
        sourceclient    = ls_import-trcli
        step            = ls_import-trstep
        importon        = lv_date
        allclients      = ls_import-allcli
        project         = ls_import-project
        username        = ls_import-truser
        returncode      = ls_import-retcode
        returncodetext  = zcl_sec_domain_text=>tp_return_text( ls_import-retcode )
        hostname        = ls_import-host
        administrator   = ls_import-admin ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
