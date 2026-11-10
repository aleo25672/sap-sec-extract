CLASS zcl_sec_tmssys_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        domainname     TYPE c LENGTH 10,
        systemname     TYPE c LENGTH 10,
        systemtype     TYPE c LENGTH 1,
        systemtypetext TYPE c LENGTH 40,
        transportgroup TYPE c LENGTH 10,
        description    TYPE c LENGTH 120,
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


CLASS zcl_sec_tmssys_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_transport_admin( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    SELECT domnam, sysnam, systyp, transgrp
      FROM tmscsys
      INTO TABLE @DATA(lt_system).

    TYPES:
      BEGIN OF ty_text,
        domnam TYPE c LENGTH 10,
        sysnam TYPE c LENGTH 10,
        langu  TYPE c LENGTH 1,
        systxt TYPE c LENGTH 120,
      END OF ty_text.
    DATA lt_text TYPE STANDARD TABLE OF ty_text.
    IF lt_system IS NOT INITIAL.
      SELECT domnam, sysnam, langu, systxt
        FROM tmscsyst
        FOR ALL ENTRIES IN @lt_system
        WHERE domnam = @lt_system-domnam
          AND sysnam = @lt_system-sysnam
          AND ( langu = @sy-langu OR langu = 'E' )
        INTO TABLE @lt_text.
    ENDIF.

    LOOP AT lt_system INTO DATA(ls_system).
      DATA(lv_text) = ``.
      LOOP AT lt_text INTO DATA(ls_text)
        WHERE domnam = ls_system-domnam AND sysnam = ls_system-sysnam AND langu = sy-langu.
        lv_text = ls_text-systxt.
        EXIT.
      ENDLOOP.
      IF lv_text IS INITIAL.
        LOOP AT lt_text INTO ls_text
          WHERE domnam = ls_system-domnam AND sysnam = ls_system-sysnam AND langu = 'E'.
          lv_text = ls_text-systxt.
          EXIT.
        ENDLOOP.
      ENDIF.
      APPEND VALUE ty_row(
        domainname     = ls_system-domnam
        systemname     = ls_system-sysnam
        systemtype     = ls_system-systyp
        systemtypetext = zcl_sec_domain_text=>transport_system_text( ls_system-systyp )
        transportgroup = ls_system-transgrp
        description    = lv_text ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
