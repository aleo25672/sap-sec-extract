CLASS zcl_sec_objkey_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        programid  TYPE c LENGTH 4,
        objecttype TYPE c LENGTH 4,
        objectname TYPE c LENGTH 120,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_auth TYPE REF TO zif_sec_auth OPTIONAL.

    METHODS read_rows
      IMPORTING
        io_request     TYPE REF TO if_rap_query_request OPTIONAL
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_settings.

  PRIVATE SECTION.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_objkey_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_named_table( 'ADIRACCESS' ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    " ACCESSKEY stays in ADIRACCESS. The row is the registered object.
    SELECT pgmid, object, obj_name
      FROM adiraccess
      INTO TABLE @DATA(lt_object).

    LOOP AT lt_object INTO DATA(ls_object).
      APPEND VALUE ty_row(
        programid  = ls_object-pgmid
        objecttype = ls_object-object
        objectname = ls_object-obj_name ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
