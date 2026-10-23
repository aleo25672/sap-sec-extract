CLASS zcl_sec_pflchg_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        hostname          TYPE c LENGTH 32,
        parametername     TYPE c LENGTH 64,
        changedate        TYPE d,
        parametertype     TYPE c LENGTH 1,
        systemid          TYPE c LENGTH 8,
        parameterstate    TYPE c LENGTH 1,
        parameterstatetext TYPE c LENGTH 60,
        parametertypetext TYPE c LENGTH 60,
        parametervalue    TYPE c LENGTH 64,
        securityrelevant  TYPE c LENGTH 1,
        securityarea      TYPE c LENGTH 20,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_pflchg_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_profile_display( ).

    DATA lr_name TYPE RANGE OF pahi-parname.
    DATA lr_date TYPE RANGE OF pahi-pardate.
    DATA lr_host TYPE RANGE OF pahi-hostname.
    DATA lr_type TYPE RANGE OF pahi-partype.

    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'PARAMETERNAME' ) INTO DATA(ls_name).
      APPEND VALUE #(
        sign = ls_name-sign
        option = ls_name-option
        low = to_upper( ls_name-low )
        high = to_upper( ls_name-high ) ) TO lr_name.
    ENDLOOP.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'CHANGEDATE' ) INTO DATA(ls_date).
      APPEND VALUE #( sign = ls_date-sign option = ls_date-option low = ls_date-low high = ls_date-high ) TO lr_date.
    ENDLOOP.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'HOSTNAME' ) INTO DATA(ls_host).
      APPEND VALUE #(
        sign = ls_host-sign
        option = ls_host-option
        low = to_upper( ls_host-low )
        high = to_upper( ls_host-high ) ) TO lr_host.
    ENDLOOP.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'PARAMETERTYPE' ) INTO DATA(ls_type).
      APPEND VALUE #(
        sign = ls_type-sign
        option = ls_type-option
        low = to_upper( ls_type-low )
        high = to_upper( ls_type-high ) ) TO lr_type.
    ENDLOOP.

    " An empty range adds no restriction. Character filters are matched in upper case.
    SELECT hostname, systemid, pardate, parname, partype, parstate, parvalue
      FROM pahi
      WHERE upper( parname ) IN @lr_name
        AND pardate IN @lr_date
        AND upper( hostname ) IN @lr_host
        AND upper( partype ) IN @lr_type
      INTO TABLE @DATA(lt_history).

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_history INTO DATA(ls_history).
      DATA(ls_class) = zcl_sec_pfl_param_classify=>classify( ls_history-parname ).
      APPEND VALUE ty_row(
        hostname           = ls_history-hostname
        parametername      = ls_history-parname
        changedate         = ls_history-pardate
        parametertype      = ls_history-partype
        systemid           = ls_history-systemid
        parameterstate     = ls_history-parstate
        parameterstatetext = zcl_sec_domain_text=>domain_text( iv_domain = 'PARSTATE' iv_code = ls_history-parstate )
        parametertypetext  = zcl_sec_domain_text=>domain_text( iv_domain = 'PARTYPE' iv_code = ls_history-partype )
        parametervalue     = ls_history-parvalue
        securityrelevant   = COND #( WHEN ls_class-relevant = abap_true THEN 'X' ELSE ' ' )
        securityarea       = ls_class-area ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>filter_rows( EXPORTING io_request = io_request CHANGING ct_rows = lt_rows ).

    DATA(lt_sort) = zcl_sec_query_util=>sort_from_request( io_request ).
    zcl_sec_query_util=>sort_by( EXPORTING it_sort = lt_sort CHANGING ct_data = lt_rows ).

    DATA lv_skip TYPE i.
    DATA lv_top TYPE i.
    DATA lv_from TYPE i.
    DATA lv_to TYPE i.
    zcl_sec_query_util=>paging_from_request( EXPORTING io_request = io_request IMPORTING ev_skip = lv_skip ev_top = lv_top ).
    zcl_sec_query_util=>page(
      EXPORTING iv_lines = lines( lt_rows ) iv_skip = lv_skip iv_top = lv_top
      IMPORTING ev_from = lv_from ev_to = lv_to ).

    DATA lt_page TYPE tt_row.
    IF lv_to >= lv_from.
      LOOP AT lt_rows INTO DATA(ls_row) FROM lv_from TO lv_to.
        APPEND ls_row TO lt_page.
      ENDLOOP.
    ENDIF.

    IF io_request->is_data_requested( ) = abap_true.
      io_response->set_data( lt_page ).
    ENDIF.
    IF io_request->is_total_numb_of_rec_requested( ) = abap_true.
      io_response->set_total_number_of_records( lines( lt_rows ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
