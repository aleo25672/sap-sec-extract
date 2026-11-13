CLASS zcl_sec_ust10c_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        profilename TYPE c LENGTH 12,
        version     TYPE c LENGTH 1,
        subprofile  TYPE c LENGTH 12,
        client      TYPE c LENGTH 3,
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


CLASS zcl_sec_ust10c_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_access_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_profile_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    SELECT profn, aktps, subprof
      FROM ust10c
      INTO TABLE @DATA(lt_profile).

    LOOP AT lt_profile INTO DATA(ls_profile).
      APPEND VALUE ty_row(
        profilename = ls_profile-profn
        version     = ls_profile-aktps
        subprofile  = ls_profile-subprof
        client      = sy-mandt ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply_access(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
