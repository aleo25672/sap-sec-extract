CLASS zcl_sec_tablog_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        tablename      TYPE c LENGTH 30,
        logdatachanges TYPE c LENGTH 1,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_tablog_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    mo_auth->check_named_table( 'DD09L' ).

    DATA lr_name TYPE RANGE OF dd09l-tabname.
    LOOP AT zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'TABLENAME' ) INTO DATA(ls_name).
      APPEND VALUE #(
        sign   = ls_name-sign
        option = ls_name-option
        low    = to_upper( ls_name-low )
        high   = to_upper( ls_name-high ) ) TO lr_name.
    ENDLOOP.

    TYPES:
      BEGIN OF ty_table,
        tabname   TYPE c LENGTH 30,
        protokoll TYPE c LENGTH 1,
      END OF ty_table.
    DATA lt_table TYPE STANDARD TABLE OF ty_table.
    IF lr_name IS INITIAL.
      SELECT tabname, protokoll
        FROM dd09l
        WHERE as4local = 'A'
        INTO TABLE @lt_table.
    ELSE.
      SELECT tabname, protokoll
        FROM dd09l
        WHERE as4local = 'A'
          AND upper( tabname ) IN @lr_name
        INTO TABLE @lt_table.
    ENDIF.

    DATA lt_rows TYPE tt_row.
    LOOP AT lt_table INTO DATA(ls_table).
      APPEND VALUE ty_row(
        tablename      = ls_table-tabname
        logdatachanges = ls_table-protokoll ) TO lt_rows.
    ENDLOOP.

    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
