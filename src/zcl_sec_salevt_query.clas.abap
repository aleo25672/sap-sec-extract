CLASS zcl_sec_salevt_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        messagearea     TYPE c LENGTH 2,
        messagesubid    TYPE c LENGTH 1,
        eventtimestamp  TYPE c LENGTH 16,
        processid       TYPE c LENGTH 12,
        client          TYPE c LENGTH 3,
        systemid        TYPE c LENGTH 8,
        instancename    TYPE c LENGTH 40,
        counter         TYPE int2,
        messageid       TYPE c LENGTH 3,
        eventon         TYPE d,
        terminal        TYPE c LENGTH 20,
        username        TYPE c LENGTH 12,
        transactioncode TYPE c LENGTH 20,
        programname     TYPE c LENGTH 40,
        terminaladdress TYPE c LENGTH 45,
        eventdata       TYPE string,
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
    TYPES ty_stamp TYPE c LENGTH 16.

    DATA mo_auth TYPE REF TO zif_sec_access_auth.

    METHODS event_date
      IMPORTING
        iv_stamp     TYPE csequence
      RETURNING
        VALUE(rv_date) TYPE d.
ENDCLASS.


CLASS zcl_sec_salevt_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD event_date.
    DATA(lv_raw) = shift_left( val = condense( iv_stamp ) sub = ` ` ).
    IF strlen( lv_raw ) >= 8.
      DATA(lv_day) = substring( val = lv_raw len = 8 ).
      IF lv_day CO '0123456789'.
        rv_date = lv_day.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_audit_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lt_sql) = zcl_sec_query_util=>access_timestamp_selection(
      it_range = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'EVENTON' )
      iv_name  = 'EVENTON' ).
    " SLGDATTIM is 16 characters. The shared date helper builds a 14-character bound.
    DATA lr_time TYPE RANGE OF ty_stamp.
    LOOP AT lt_sql INTO DATA(ls_sql).
      DATA(lv_low) = condense( CONV string( ls_sql-low ) ).
      DATA(lv_high) = condense( CONV string( ls_sql-high ) ).
      IF strlen( lv_low ) = 14.
        lv_low = lv_low && '00'.
      ENDIF.
      IF strlen( lv_high ) = 14.
        lv_high = lv_high && '99'.
      ENDIF.
      APPEND VALUE #(
        sign   = ls_sql-sign
        option = ls_sql-option
        low    = lv_low
        high   = lv_high ) TO lr_time.
    ENDLOOP.

    DATA lr_client TYPE RANGE OF rsau_buf_data-slgmand.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'CLIENT' ) INTO DATA(ls_client).
      APPEND VALUE #(
        sign   = ls_client-sign
        option = to_upper( ls_client-option )
        low    = ls_client-low
        high   = ls_client-high ) TO lr_client.
    ENDLOOP.
    DATA lr_user TYPE RANGE OF rsau_buf_data-slguser.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'USERNAME' ) INTO DATA(ls_user).
      APPEND VALUE #(
        sign   = ls_user-sign
        option = to_upper( ls_user-option )
        low    = to_upper( ls_user-low )
        high   = to_upper( ls_user-high ) ) TO lr_user.
    ENDLOOP.

    " An empty range matches nothing, so each optional filter has its own select.
    DATA lt_event TYPE STANDARD TABLE OF rsau_buf_data.
    IF lr_client IS INITIAL AND lr_user IS INITIAL.
      SELECT area, subid, slgdattim, slgproc, slgmand, sid, instance, counter,
             slgltrm2, slguser, slgtc, slgrepna, term_ipv6, sal_data
        FROM rsau_buf_data
        WHERE slgdattim IN @lr_time
        INTO CORRESPONDING FIELDS OF TABLE @lt_event.
    ELSEIF lr_user IS INITIAL.
      SELECT area, subid, slgdattim, slgproc, slgmand, sid, instance, counter,
             slgltrm2, slguser, slgtc, slgrepna, term_ipv6, sal_data
        FROM rsau_buf_data
        WHERE slgdattim IN @lr_time
          AND slgmand IN @lr_client
        INTO CORRESPONDING FIELDS OF TABLE @lt_event.
    ELSEIF lr_client IS INITIAL.
      SELECT area, subid, slgdattim, slgproc, slgmand, sid, instance, counter,
             slgltrm2, slguser, slgtc, slgrepna, term_ipv6, sal_data
        FROM rsau_buf_data
        WHERE slgdattim IN @lr_time
          AND slguser IN @lr_user
        INTO CORRESPONDING FIELDS OF TABLE @lt_event.
    ELSE.
      SELECT area, subid, slgdattim, slgproc, slgmand, sid, instance, counter,
             slgltrm2, slguser, slgtc, slgrepna, term_ipv6, sal_data
        FROM rsau_buf_data
        WHERE slgdattim IN @lr_time
          AND slgmand IN @lr_client
          AND slguser IN @lr_user
        INTO CORRESPONDING FIELDS OF TABLE @lt_event.
    ENDIF.

    LOOP AT lt_event INTO DATA(ls_event).
      APPEND VALUE ty_row(
        messagearea     = ls_event-area
        messagesubid    = ls_event-subid
        eventtimestamp  = ls_event-slgdattim
        processid       = ls_event-slgproc
        client          = ls_event-slgmand
        systemid        = ls_event-sid
        instancename    = ls_event-instance
        counter         = ls_event-counter
        messageid       = ls_event-area && ls_event-subid
        eventon         = event_date( ls_event-slgdattim )
        terminal        = ls_event-slgltrm2
        username        = ls_event-slguser
        transactioncode = ls_event-slgtc
        programname     = ls_event-slgrepna
        terminaladdress = ls_event-term_ipv6
        eventdata       = ls_event-sal_data ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
