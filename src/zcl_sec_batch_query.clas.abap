CLASS zcl_sec_batch_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        client           TYPE c LENGTH 3,
        queueid          TYPE c LENGTH 20,
        sessionname      TYPE c LENGTH 12,
        creator          TYPE c LENGTH 12,
        createdon        TYPE d,
        createdat        TYPE t,
        queuestate       TYPE c LENGTH 1,
        queuestatetext   TYPE c LENGTH 40,
        transactioncount TYPE i,
        errorcount       TYPE i,
        deletedcount     TYPE i,
        startedon        TYPE d,
        startedat        TYPE t,
        username         TYPE c LENGTH 12,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_batch_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_batch_input_display( ).

    DATA lr_session TYPE RANGE OF apqi-groupid.
    DATA lr_state TYPE RANGE OF apqi-qstate.
    DATA lr_date TYPE RANGE OF apqi-credate.

    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'SESSIONNAME' ) INTO DATA(ls_session).
      APPEND VALUE #(
        sign   = ls_session-sign
        option = ls_session-option
        low    = to_upper( ls_session-low )
        high   = to_upper( ls_session-high ) ) TO lr_session.
    ENDLOOP.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'QUEUESTATE' ) INTO DATA(ls_state).
      APPEND VALUE #(
        sign   = ls_state-sign
        option = ls_state-option
        low    = to_upper( ls_state-low )
        high   = to_upper( ls_state-high ) ) TO lr_state.
    ENDLOOP.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'CREATEDON' ) INTO DATA(ls_date).
      APPEND VALUE #(
        sign   = ls_date-sign
        option = ls_date-option
        low    = ls_date-low
        high   = ls_date-high ) TO lr_date.
    ENDLOOP.

    " PASSWD is the queue password and stays out of the row.
    " A missing filter matches every value. An initial range would match nothing.
    IF lr_session IS INITIAL.
      lr_session = VALUE #( ( sign = 'I' option = 'CP' low = '*' ) ).
    ENDIF.
    IF lr_state IS INITIAL.
      lr_state = VALUE #( ( sign = 'I' option = 'CP' low = '*' ) ).
    ENDIF.
    IF lr_date IS INITIAL.
      lr_date = VALUE #( ( sign = 'I' option = 'BT' low = '00000000' high = '99991231' ) ).
    ENDIF.

    SELECT mandant, qid, groupid, creator, credate, cretime, qstate,
           transcnt, transcnte, transcntd, startdate, starttime, userid
      FROM apqi
      WHERE upper( groupid ) IN @lr_session
        AND upper( qstate ) IN @lr_state
        AND credate IN @lr_date
      INTO TABLE @DATA(lt_session).

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_session INTO DATA(ls_session_row).
      APPEND VALUE ty_row(
        client           = ls_session_row-mandant
        queueid          = ls_session_row-qid
        sessionname      = ls_session_row-groupid
        creator          = ls_session_row-creator
        createdon        = ls_session_row-credate
        createdat        = ls_session_row-cretime
        queuestate       = ls_session_row-qstate
        queuestatetext   = zcl_sec_domain_text=>batch_session_text( ls_session_row-qstate )
        transactioncount = ls_session_row-transcnt
        errorcount       = ls_session_row-transcnte
        deletedcount     = ls_session_row-transcntd
        startedon        = ls_session_row-startdate
        startedat        = ls_session_row-starttime
        username         = ls_session_row-userid ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
