CLASS zcl_sec_ush04_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        username     TYPE c LENGTH 12,
        changedon    TYPE d,
        changedat    TYPE t,
        changedby    TYPE c LENGTH 12,
        client       TYPE c LENGTH 3,
        profilecount TYPE int2,
        profilelist  TYPE string,
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


CLASS zcl_sec_ush04_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_user_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lt_sql) = zcl_sec_query_util=>access_date_selection(
      it_range = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'CHANGEDON' )
      iv_name  = 'CHANGEDON' ).

    DATA lr_date TYPE RANGE OF d.
    LOOP AT lt_sql INTO DATA(ls_sql).
      APPEND VALUE #(
        sign   = ls_sql-sign
        option = ls_sql-option
        low    = ls_sql-low
        high   = ls_sql-high ) TO lr_date.
    ENDLOOP.

    " NRPRO is the length of the LCHR profile list and has to be selected immediately before it.
    TYPES:
      BEGIN OF ty_ush,
        bname TYPE c LENGTH 12,
        modda TYPE d,
        modti TYPE t,
        modbe TYPE c LENGTH 12,
        nrpro TYPE int2,
        profs TYPE c LENGTH 3750,
      END OF ty_ush.
    DATA lt_ush TYPE STANDARD TABLE OF ty_ush.

    SELECT bname, modda, modti, modbe, nrpro, profs
      FROM ush04
      WHERE modda IN @lr_date
      INTO TABLE @lt_ush.

    LOOP AT lt_ush INTO DATA(ls_ush).
      APPEND VALUE ty_row(
        username     = ls_ush-bname
        changedon    = ls_ush-modda
        changedat    = ls_ush-modti
        changedby    = ls_ush-modbe
        client       = sy-mandt
        profilecount = ls_ush-nrpro
        profilelist  = ls_ush-profs ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
