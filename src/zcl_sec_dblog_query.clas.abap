CLASS zcl_sec_dblog_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        logdate         TYPE d,
        logtime         TYPE t,
        logid           TYPE c LENGTH 18,
        tablename       TYPE c LENGTH 30,
        recordkey       TYPE c LENGTH 250,
        hostname        TYPE c LENGTH 20,
        username        TYPE c LENGTH 12,
        transactioncode TYPE c LENGTH 20,
        programname     TYPE c LENGTH 40,
        operation       TYPE c LENGTH 1,
        operationtext   TYPE c LENGTH 10,
        versionnumber   TYPE c LENGTH 2,
        language        TYPE c LENGTH 1,
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

    METHODS operation_text
      IMPORTING
        iv_operation   TYPE csequence
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.


CLASS zcl_sec_dblog_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD operation_text.
    CASE to_upper( iv_operation ).
      WHEN 'I'.
        rv_text = 'Insert'.
      WHEN 'U'.
        rv_text = 'Update'.
      WHEN 'D'.
        rv_text = 'Delete'.
      WHEN OTHERS.
        rv_text = iv_operation.
    ENDCASE.
  ENDMETHOD.

  METHOD read_rows.
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    " RSTBHIST reads DBTABLOG for one table. The caller names that table.
    zcl_sec_query_util=>require_filter( io_request = io_request iv_name = 'TABLENAME' ).
    DATA lr_table TYPE RANGE OF c LENGTH 30.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'TABLENAME' ) INTO DATA(ls_name).
      IF ls_name-low IS NOT INITIAL.
        mo_auth->check_named_table( to_upper( ls_name-low ) ).
      ENDIF.
      IF ls_name-high IS NOT INITIAL.
        mo_auth->check_named_table( to_upper( ls_name-high ) ).
      ENDIF.
      APPEND VALUE #(
        sign   = ls_name-sign
        option = to_upper( ls_name-option )
        low    = to_upper( ls_name-low )
        high   = to_upper( ls_name-high ) ) TO lr_table.
    ENDLOOP.

    DATA(lt_sql) = zcl_sec_query_util=>date_selection(
      it_range = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'LOGDATE' )
      iv_name  = 'LOGDATE' ).
    DATA lr_date TYPE RANGE OF d.
    LOOP AT lt_sql INTO DATA(ls_sql).
      APPEND VALUE #(
        sign   = ls_sql-sign
        option = ls_sql-option
        low    = ls_sql-low
        high   = ls_sql-high ) TO lr_date.
    ENDLOOP.

    " LOGDATA is the binary image of the changed row. Archived logs are not in this table.
    SELECT logdate, logtime, logid, tabname, logkey, hostname, username,
           tcode, progname, optype, versno, language
      FROM dbtablog
      WHERE logdate IN @lr_date
        AND tabname IN @lr_table
      INTO TABLE @DATA(lt_log).

    LOOP AT lt_log INTO DATA(ls_log).
      APPEND VALUE ty_row(
        logdate         = ls_log-logdate
        logtime         = ls_log-logtime
        logid           = ls_log-logid
        tablename       = ls_log-tabname
        recordkey       = ls_log-logkey
        hostname        = ls_log-hostname
        username        = ls_log-username
        transactioncode = ls_log-tcode
        programname     = ls_log-progname
        operation       = ls_log-optype
        operationtext   = operation_text( ls_log-optype )
        versionnumber   = ls_log-versno
        language        = ls_log-language ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
