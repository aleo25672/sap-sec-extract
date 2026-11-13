CLASS zcl_sec_proginc_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        programname TYPE c LENGTH 40,
        includename TYPE c LENGTH 40,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_proginc_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_named_table( 'D010INC' ).
    zcl_sec_query_util=>require_filter( io_request = io_request iv_name = 'PROGRAMNAME' ).

    DATA lr_name TYPE RANGE OF d010inc-master.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'PROGRAMNAME' ) INTO DATA(ls_name).
      APPEND VALUE #(
        sign   = ls_name-sign
        option = ls_name-option
        low    = to_upper( ls_name-low )
        high   = to_upper( ls_name-high ) ) TO lr_name.
    ENDLOOP.

    SELECT master, include
      FROM d010inc
      WHERE upper( master ) IN @lr_name
      INTO TABLE @DATA(lt_include).

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_include INTO DATA(ls_include).
      APPEND VALUE ty_row(
        programname = ls_include-master
        includename = ls_include-include ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
