CLASS zcl_sec_prgn_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        customizingid    TYPE c LENGTH 20,
        customizingvalue TYPE c LENGTH 10,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_prgn_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_named_table( 'PRGN_CUST' ).

    SELECT id, path
      FROM prgn_cust
      INTO TABLE @DATA(lt_switch).

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_switch INTO DATA(ls_switch).
      APPEND VALUE ty_row(
        customizingid    = ls_switch-id
        customizingvalue = ls_switch-path ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
