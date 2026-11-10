CLASS zcl_sec_tmsdom_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        domainname       TYPE c LENGTH 10,
        controllersystem TYPE c LENGTH 10,
        description      TYPE c LENGTH 120,
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


CLASS zcl_sec_tmsdom_query IMPLEMENTATION.
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

    SELECT domnam, domctl
      FROM tmscdom
      INTO TABLE @DATA(lt_domain).

    TYPES:
      BEGIN OF ty_text,
        domnam TYPE c LENGTH 10,
        langu  TYPE c LENGTH 1,
        domtxt TYPE c LENGTH 120,
      END OF ty_text.
    DATA lt_text TYPE STANDARD TABLE OF ty_text.
    IF lt_domain IS NOT INITIAL.
      SELECT domnam, langu, domtxt
        FROM tmscdomt
        FOR ALL ENTRIES IN @lt_domain
        WHERE domnam = @lt_domain-domnam
          AND ( langu = @sy-langu OR langu = 'E' )
        INTO TABLE @lt_text.
    ENDIF.

    LOOP AT lt_domain INTO DATA(ls_domain).
      DATA(lv_text) = ``.
      LOOP AT lt_text INTO DATA(ls_text) WHERE domnam = ls_domain-domnam AND langu = sy-langu.
        lv_text = ls_text-domtxt.
        EXIT.
      ENDLOOP.
      IF lv_text IS INITIAL.
        LOOP AT lt_text INTO ls_text WHERE domnam = ls_domain-domnam AND langu = 'E'.
          lv_text = ls_text-domtxt.
          EXIT.
        ENDLOOP.
      ENDIF.
      APPEND VALUE ty_row(
        domainname       = ls_domain-domnam
        controllersystem = ls_domain-domctl
        description      = lv_text ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
