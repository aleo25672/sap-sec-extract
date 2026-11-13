CLASS zcl_sec_se16n_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        documentid      TYPE p LENGTH 11 DECIMALS 7,
        client          TYPE c LENGTH 3,
        tablename       TYPE c LENGTH 30,
        username        TYPE c LENGTH 12,
        changedon       TYPE d,
        changedat       TYPE t,
        clientdependent TYPE c LENGTH 1,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_se16n_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_named_table( 'SE16N_CD_KEY' ).

    DATA(lt_table) = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'TABLENAME' ).
    DATA(lt_date) = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'CHANGEDON' ).
    IF lt_table IS INITIAL AND lt_date IS INITIAL.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid      = zcx_sec_settings=>filter_required
          filter_name = 'TABLENAME or CHANGEDON'.
    ENDIF.

    DATA lr_table TYPE RANGE OF se16n_cd_key-tab.
    LOOP AT lt_table INTO DATA(ls_table_range).
      APPEND VALUE #(
        sign   = ls_table_range-sign
        option = ls_table_range-option
        low    = to_upper( ls_table_range-low )
        high   = to_upper( ls_table_range-high ) ) TO lr_table.
    ENDLOOP.

    DATA lr_date TYPE RANGE OF se16n_cd_key-sdate.
    LOOP AT lt_date INTO DATA(ls_date).
      APPEND VALUE #(
        sign   = ls_date-sign
        option = ls_date-option
        low    = ls_date-low
        high   = ls_date-high ) TO lr_date.
    ENDLOOP.

    DATA lt_change TYPE STANDARD TABLE OF se16n_cd_key.
    IF lr_table IS NOT INITIAL AND lr_date IS NOT INITIAL.
      SELECT id, mandt, tab, uname, sdate, stime, clntdep
        FROM se16n_cd_key
        WHERE upper( tab ) IN @lr_table
          AND sdate IN @lr_date
        INTO CORRESPONDING FIELDS OF TABLE @lt_change.
    ELSEIF lr_table IS NOT INITIAL.
      SELECT id, mandt, tab, uname, sdate, stime, clntdep
        FROM se16n_cd_key
        WHERE upper( tab ) IN @lr_table
        INTO CORRESPONDING FIELDS OF TABLE @lt_change.
    ELSE.
      SELECT id, mandt, tab, uname, sdate, stime, clntdep
        FROM se16n_cd_key
        WHERE sdate IN @lr_date
        INTO CORRESPONDING FIELDS OF TABLE @lt_change.
    ENDIF.

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_change INTO DATA(ls_change).
      APPEND VALUE ty_row(
        documentid      = ls_change-id
        client          = ls_change-mandt
        tablename       = ls_change-tab
        username        = ls_change-uname
        changedon       = ls_change-sdate
        changedat       = ls_change-stime
        clientdependent = ls_change-clntdep ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
