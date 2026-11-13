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

    CLASS-METHODS file_event
      IMPORTING
        is_file        TYPE rsauetab2
        iv_system      TYPE csequence
      RETURNING
        VALUE(rs_row) TYPE ty_row.

  PRIVATE SECTION.
    TYPES:
      ty_stamp        TYPE c LENGTH 16,
      ty_stamp_range  TYPE RANGE OF ty_stamp,
      ty_client_range TYPE RANGE OF rsau_buf_data-slgmand,
      ty_user_range   TYPE RANGE OF rsau_buf_data-slguser,
      BEGIN OF ty_seen,
        messagearea    TYPE c LENGTH 2,
        messagesubid   TYPE c LENGTH 1,
        eventtimestamp TYPE c LENGTH 16,
        processid      TYPE c LENGTH 12,
        client         TYPE c LENGTH 3,
        systemid       TYPE c LENGTH 8,
        instancename   TYPE c LENGTH 40,
      END OF ty_seen,
      tt_seen TYPE HASHED TABLE OF ty_seen WITH UNIQUE KEY
        messagearea messagesubid eventtimestamp processid client systemid instancename.

    DATA mo_auth TYPE REF TO zif_sec_access_auth.

    CLASS-METHODS event_date
      IMPORTING
        iv_stamp       TYPE csequence
      RETURNING
        VALUE(rv_date) TYPE d.

    METHODS database_rows
      IMPORTING
        ir_time        TYPE ty_stamp_range
        ir_client      TYPE ty_client_range
        ir_user        TYPE ty_user_range
      RETURNING
        VALUE(rt_rows) TYPE tt_row.

    METHODS file_rows
      IMPORTING
        ir_time        TYPE ty_stamp_range
        ir_client      TYPE ty_client_range
        ir_user        TYPE ty_user_range
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_access.
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

    rt_rows = database_rows( ir_time = lr_time ir_client = lr_client ir_user = lr_user ).
    DATA lt_seen TYPE tt_seen.
    LOOP AT rt_rows INTO DATA(ls_known).
      INSERT VALUE ty_seen(
        messagearea    = ls_known-messagearea
        messagesubid   = ls_known-messagesubid
        eventtimestamp = ls_known-eventtimestamp
        processid      = ls_known-processid
        client         = ls_known-client
        systemid       = ls_known-systemid
        instancename   = ls_known-instancename ) INTO TABLE lt_seen.
    ENDLOOP.
    LOOP AT file_rows( ir_time = lr_time ir_client = lr_client ir_user = lr_user ) INTO DATA(ls_file_row).
      INSERT VALUE ty_seen(
        messagearea    = ls_file_row-messagearea
        messagesubid   = ls_file_row-messagesubid
        eventtimestamp = ls_file_row-eventtimestamp
        processid      = ls_file_row-processid
        client         = ls_file_row-client
        systemid       = ls_file_row-systemid
        instancename   = ls_file_row-instancename ) INTO TABLE lt_seen.
      IF sy-subrc = 0.
        APPEND ls_file_row TO rt_rows.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD database_rows.
    " An empty range matches nothing, so each optional filter has its own select.
    DATA lt_event TYPE STANDARD TABLE OF rsau_buf_data.
    IF ir_client IS INITIAL AND ir_user IS INITIAL.
      SELECT area, subid, slgdattim, slgproc, slgmand, sid, instance, counter,
             slgltrm2, slguser, slgtc, slgrepna, term_ipv6, sal_data
        FROM rsau_buf_data
        WHERE slgdattim IN @ir_time
        INTO CORRESPONDING FIELDS OF TABLE @lt_event.
    ELSEIF ir_user IS INITIAL.
      SELECT area, subid, slgdattim, slgproc, slgmand, sid, instance, counter,
             slgltrm2, slguser, slgtc, slgrepna, term_ipv6, sal_data
        FROM rsau_buf_data
        WHERE slgdattim IN @ir_time
          AND slgmand IN @ir_client
        INTO CORRESPONDING FIELDS OF TABLE @lt_event.
    ELSEIF ir_client IS INITIAL.
      SELECT area, subid, slgdattim, slgproc, slgmand, sid, instance, counter,
             slgltrm2, slguser, slgtc, slgrepna, term_ipv6, sal_data
        FROM rsau_buf_data
        WHERE slgdattim IN @ir_time
          AND slguser IN @ir_user
        INTO CORRESPONDING FIELDS OF TABLE @lt_event.
    ELSE.
      SELECT area, subid, slgdattim, slgproc, slgmand, sid, instance, counter,
             slgltrm2, slguser, slgtc, slgrepna, term_ipv6, sal_data
        FROM rsau_buf_data
        WHERE slgdattim IN @ir_time
          AND slgmand IN @ir_client
          AND slguser IN @ir_user
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

  METHOD file_event.
    DATA ls_entry TYPE rsauentr2.
    ls_entry = is_file-centdata.

    DATA lv_stamp TYPE c LENGTH 16.
    lv_stamp = ls_entry-slgdattim.
    IF lv_stamp IS INITIAL.
      lv_stamp = is_file-pos_creatt.
    ENDIF.
    IF lv_stamp IS INITIAL.
      lv_stamp = is_file-recevive_t.
    ENDIF.

    DATA lv_area TYPE c LENGTH 2.
    DATA lv_subid TYPE c LENGTH 1.
    lv_area = is_file-area.
    lv_subid = is_file-subid.
    IF lv_area IS INITIAL.
      DATA lv_type TYPE c LENGTH 4.
      lv_type = ls_entry-slgtype.
      IF strlen( lv_type ) >= 4.
        lv_area = substring( val = lv_type off = 1 len = 2 ).
        lv_subid = substring( val = lv_type off = 3 len = 1 ).
      ENDIF.
    ENDIF.

    DATA lv_proc TYPE c LENGTH 12.
    lv_proc = ls_entry-slgproc.
    DATA lv_instance TYPE c LENGTH 40.
    lv_instance = is_file-sender_id.

    rs_row = VALUE ty_row(
      messagearea     = lv_area
      messagesubid    = lv_subid
      eventtimestamp  = lv_stamp
      processid       = lv_proc
      client          = ls_entry-slgmand
      systemid        = iv_system
      instancename    = lv_instance
      messageid       = lv_area && lv_subid
      eventon         = event_date( lv_stamp )
      terminal        = ls_entry-slgltrm2
      username        = ls_entry-slguser
      transactioncode = ls_entry-slgtc
      programname     = ls_entry-slgrepna
      eventdata       = ls_entry-slgdata ).
  ENDMETHOD.

  METHOD file_rows.
    DATA lv_from TYPE ty_stamp.
    DATA lv_to TYPE ty_stamp.
    LOOP AT ir_time INTO DATA(ls_time).
      IF ls_time-low IS NOT INITIAL AND ( lv_from IS INITIAL OR ls_time-low < lv_from ).
        lv_from = ls_time-low.
      ENDIF.
      DATA lv_high TYPE ty_stamp.
      IF ls_time-high IS NOT INITIAL.
        lv_high = ls_time-high.
      ELSE.
        lv_high = ls_time-low.
      ENDIF.
      IF lv_high IS NOT INITIAL AND ( lv_to IS INITIAL OR lv_high > lv_to ).
        lv_to = lv_high.
      ENDIF.
    ENDLOOP.

    " RB_FILE in RSAU_READ_LOG. WHICHLOG A is the audit file on this server.
    DATA ls_sel TYPE rslgsel.
    DATA ls_audit TYPE rsausel.
    ls_sel-whichlog = 'A'.
    ls_sel-startdate = lv_from.
    ls_sel-stop_date = lv_to.
    IF strlen( lv_from ) >= 14.
      ls_sel-date = substring( val = CONV string( lv_from ) len = 8 ).
      ls_sel-time = substring( val = CONV string( lv_from ) off = 8 len = 6 ).
    ENDIF.
    IF strlen( lv_to ) >= 14.
      ls_sel-edate = substring( val = CONV string( lv_to ) len = 8 ).
      ls_sel-etime = substring( val = CONV string( lv_to ) off = 8 len = 6 ).
    ENDIF.
    CALL FUNCTION 'RSAU_SELINFO_INIT'
      CHANGING
        audit_selection = ls_audit.
    ls_audit-subclasid = 255.

    DATA lt_file TYPE STANDARD TABLE OF rsauetab2.
    TRY.
        CALL FUNCTION 'RSAU_READ_FILE'
          EXPORTING
            selection       = ls_sel
            selection_audit = ls_audit
          TABLES
            syslog_in_table = lt_file.
      CATCH cx_root INTO DATA(lx_read).
        RAISE EXCEPTION TYPE zcx_sec_access
          EXPORTING
            previous = lx_read.
    ENDTRY.

    LOOP AT lt_file INTO DATA(ls_file).
      DATA(ls_row) = file_event( is_file = ls_file iv_system = sy-sysid ).
      IF ls_row-eventtimestamp NOT IN ir_time.
        CONTINUE.
      ENDIF.
      IF ir_client IS NOT INITIAL.
        DATA lv_client TYPE rsau_buf_data-slgmand.
        lv_client = ls_row-client.
        IF lv_client NOT IN ir_client.
          CONTINUE.
        ENDIF.
      ENDIF.
      IF ir_user IS NOT INITIAL.
        DATA lv_user TYPE rsau_buf_data-slguser.
        lv_user = ls_row-username.
        IF lv_user NOT IN ir_user.
          CONTINUE.
        ENDIF.
      ENDIF.
      APPEND ls_row TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
