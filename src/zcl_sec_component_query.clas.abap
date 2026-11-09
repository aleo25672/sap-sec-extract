CLASS zcl_sec_component_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        component           TYPE c LENGTH 30,
        release             TYPE c LENGTH 10,
        supportpackagelevel TYPE c LENGTH 10,
        componenttype       TYPE c LENGTH 1,
        componenttypetext   TYPE c LENGTH 60,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_component_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_named_table( 'CVERS' ).

    SELECT component, release, extrelease, comp_type
      FROM cvers
      INTO TABLE @DATA(lt_component).

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_component INTO DATA(ls_component).
      APPEND VALUE ty_row(
        component           = ls_component-component
        release             = ls_component-release
        supportpackagelevel = ls_component-extrelease
        componenttype       = ls_component-comp_type
        componenttypetext   = zcl_sec_domain_text=>domain_text(
                                iv_domain = 'RELC_TYPE'
                                iv_code = ls_component-comp_type
                                it_fallback = zcl_sec_domain_text=>component_type_fallbacks( ) ) ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
