CLASS zcl_sec_usr_chg_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        userid          TYPE c LENGTH 90,
        changenumber    TYPE c LENGTH 10,
        tablename       TYPE c LENGTH 30,
        tablekey        TYPE c LENGTH 70,
        fieldname       TYPE c LENGTH 30,
        itemchange      TYPE c LENGTH 1,
        client          TYPE c LENGTH 3,
        changedby       TYPE c LENGTH 12,
        changedate      TYPE dats,
        changetime      TYPE tims,
        transactioncode TYPE c LENGTH 20,
        headerchange    TYPE c LENGTH 1,
        valueold        TYPE c LENGTH 254,
        valuenew        TYPE c LENGTH 254,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_source TYPE REF TO zif_sec_access_source OPTIONAL
        io_auth   TYPE REF TO zif_sec_access_auth OPTIONAL.

    METHODS read_rows
      IMPORTING
        it_userid     TYPE zcl_sec_query_util=>tt_range OPTIONAL
        it_changedate TYPE zcl_sec_query_util=>tt_range OPTIONAL
        it_changedby  TYPE zcl_sec_query_util=>tt_range OPTIONAL
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_access.

  PRIVATE SECTION.
    DATA mo_source TYPE REF TO zif_sec_access_source.
    DATA mo_auth TYPE REF TO zif_sec_access_auth.

    METHODS selection_for
      IMPORTING
        it_range        TYPE zcl_sec_query_util=>tt_range
        iv_upper        TYPE abap_bool
        iv_date         TYPE abap_bool
      RETURNING
        VALUE(rt_range) TYPE zcl_sec_query_util=>tt_range
      RAISING
        zcx_sec_access.
ENDCLASS.


CLASS zcl_sec_usr_chg_query IMPLEMENTATION.
  METHOD constructor.
    mo_source = io_source.
    mo_auth = io_auth.
    IF mo_source IS NOT BOUND.
      mo_source = NEW zcl_sec_access_db( ).
    ENDIF.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD selection_for.
    LOOP AT it_range INTO DATA(ls_range).
      DATA(lv_low) = ls_range-low.
      DATA(lv_high) = ls_range-high.
      IF iv_date = abap_true.
        lv_low = zcl_sec_usr_chg_guard=>date_filter( lv_low ).
        lv_high = zcl_sec_usr_chg_guard=>date_filter( lv_high ).
      ELSEIF iv_upper = abap_true.
        lv_low = to_upper( lv_low ).
        lv_high = to_upper( lv_high ).
      ENDIF.
      APPEND VALUE #(
        sign   = ls_range-sign
        option = ls_range-option
        low    = lv_low
        high   = lv_high ) TO rt_range.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_user_display( ).
    DATA(lt_raw) = mo_source->read_user_changes(
      it_userid     = selection_for( it_range = it_userid iv_upper = abap_true iv_date = abap_false )
      it_changedate = selection_for( it_range = it_changedate iv_upper = abap_false iv_date = abap_true )
      it_changedby  = selection_for( it_range = it_changedby iv_upper = abap_true iv_date = abap_false ) ).
    LOOP AT lt_raw INTO DATA(ls_raw).
      APPEND VALUE ty_row(
        userid          = ls_raw-userid
        changenumber    = ls_raw-changenumber
        tablename       = ls_raw-tablename
        tablekey        = ls_raw-tablekey
        fieldname       = ls_raw-fieldname
        itemchange      = ls_raw-itemchange
        client          = sy-mandt
        changedby       = ls_raw-changedby
        changedate      = ls_raw-changedate
        changetime      = ls_raw-changetime
        transactioncode = ls_raw-transactioncode
        headerchange    = ls_raw-headerchange
        valueold        = zcl_sec_usr_chg_guard=>payload_value(
          iv_table = ls_raw-tablename
          iv_field = ls_raw-fieldname
          iv_value = ls_raw-valueold )
        valuenew        = zcl_sec_usr_chg_guard=>payload_value(
          iv_table = ls_raw-tablename
          iv_field = ls_raw-fieldname
          iv_value = ls_raw-valuenew ) ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_user_display( ).
    DATA(lt_rows) = read_rows(
      it_userid     = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'USERID' )
      it_changedate = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'CHANGEDATE' )
      it_changedby  = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'CHANGEDBY' ) ).

    TRY.
        zcl_sec_query_util=>filter_rows( EXPORTING io_request = io_request CHANGING ct_rows = lt_rows ).
      CATCH zcx_sec_settings INTO DATA(lx_settings).
        RAISE EXCEPTION TYPE zcx_sec_access
          EXPORTING
            textid      = zcx_sec_access=>filter_not_supported
            filter_name = lx_settings->filter_name.
    ENDTRY.

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
      LOOP AT lt_rows INTO DATA(ls_page) FROM lv_from TO lv_to.
        APPEND ls_page TO lt_page.
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
