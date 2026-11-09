CLASS zcl_sec_company_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        companycode       TYPE c LENGTH 4,
        companyname       TYPE c LENGTH 25,
        country           TYPE c LENGTH 3,
        currency          TYPE c LENGTH 5,
        chartofaccounts   TYPE c LENGTH 4,
        fiscalyearvariant TYPE c LENGTH 2,
        productive        TYPE c LENGTH 1,
        language          TYPE c LENGTH 1,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_company_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_named_table( 'T001' ).

    SELECT bukrs, butxt, land1, waers, ktopl, periv, xprod, spras
      FROM t001
      INTO TABLE @DATA(lt_company).

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_company INTO DATA(ls_company).
      APPEND VALUE ty_row(
        companycode       = ls_company-bukrs
        companyname       = ls_company-butxt
        country           = ls_company-land1
        currency          = ls_company-waers
        chartofaccounts   = ls_company-ktopl
        fiscalyearvariant = ls_company-periv
        productive        = ls_company-xprod
        language          = ls_company-spras ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
