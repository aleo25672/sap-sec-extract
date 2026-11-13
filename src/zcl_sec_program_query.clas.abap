CLASS zcl_sec_program_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        programname        TYPE c LENGTH 40,
        programtype        TYPE c LENGTH 1,
        programtypetext    TYPE c LENGTH 60,
        createdby          TYPE c LENGTH 12,
        createdon          TYPE d,
        changedby          TYPE c LENGTH 12,
        changedon          TYPE d,
        version            TYPE c LENGTH 10,
        authorizationgroup TYPE c LENGTH 8,
        unicodecheck       TYPE c LENGTH 1,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_program_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_named_table( 'TRDIR' ).
    zcl_sec_query_util=>require_filter( io_request = io_request iv_name = 'PROGRAMNAME' ).

    DATA lr_name TYPE RANGE OF trdir-name.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'PROGRAMNAME' ) INTO DATA(ls_name).
      APPEND VALUE #(
        sign   = ls_name-sign
        option = ls_name-option
        low    = to_upper( ls_name-low )
        high   = to_upper( ls_name-high ) ) TO lr_name.
    ENDLOOP.

    SELECT name, subc, cnam, cdat, unam, udat, vern, secu, uccheck
      FROM trdir
      WHERE upper( name ) IN @lr_name
      INTO TABLE @DATA(lt_program).

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_program INTO DATA(ls_program).
      APPEND VALUE ty_row(
        programname        = ls_program-name
        programtype        = ls_program-subc
        programtypetext    = zcl_sec_domain_text=>domain_text(
                               iv_domain = 'SUBC'
                               iv_code = ls_program-subc
                               it_fallback = zcl_sec_domain_text=>program_type_fallbacks( ) )
        createdby          = ls_program-cnam
        createdon          = ls_program-cdat
        changedby          = ls_program-unam
        changedon          = ls_program-udat
        version            = ls_program-vern
        authorizationgroup = ls_program-secu
        unicodecheck       = ls_program-uccheck ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
