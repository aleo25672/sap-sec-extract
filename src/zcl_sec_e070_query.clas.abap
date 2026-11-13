CLASS zcl_sec_e070_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        request             TYPE c LENGTH 20,
        requestfunction     TYPE c LENGTH 1,
        requestfunctiontext TYPE c LENGTH 60,
        requeststatus       TYPE c LENGTH 1,
        requeststatustext   TYPE c LENGTH 40,
        targetsystem        TYPE c LENGTH 10,
        category            TYPE c LENGTH 4,
        categorytext        TYPE c LENGTH 20,
        owner               TYPE c LENGTH 12,
        changedon           TYPE d,
        changedat           TYPE t,
        parentrequest       TYPE c LENGTH 20,
        description         TYPE c LENGTH 60,
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


CLASS zcl_sec_e070_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_transport_display( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lt_sql) = zcl_sec_query_util=>date_selection(
      it_range = zcl_sec_query_util=>ranges_for( io_request = io_request iv_name = 'CHANGEDON' )
      iv_name  = 'CHANGEDON' ).

    DATA lr_date TYPE RANGE OF d.
    LOOP AT lt_sql INTO DATA(ls_sql).
      APPEND VALUE #(
        sign   = ls_sql-sign
        option = ls_sql-option
        low    = ls_sql-low
        high   = ls_sql-high ) TO lr_date.
    ENDLOOP.

    SELECT trkorr, trfunction, trstatus, tarsystem, korrdev, as4user, as4date, as4time, strkorr
      FROM e070
      WHERE as4date IN @lr_date
      INTO TABLE @DATA(lt_request).

    TYPES:
      BEGIN OF ty_text,
        trkorr  TYPE c LENGTH 20,
        langu   TYPE c LENGTH 1,
        as4text TYPE c LENGTH 60,
      END OF ty_text.
    DATA lt_text TYPE STANDARD TABLE OF ty_text.
    IF lt_request IS NOT INITIAL.
      SELECT trkorr, langu, as4text
        FROM e07t
        FOR ALL ENTRIES IN @lt_request
        WHERE trkorr = @lt_request-trkorr
          AND ( langu = @sy-langu OR langu = 'E' )
        INTO TABLE @lt_text.
    ENDIF.

    LOOP AT lt_request INTO DATA(ls_request).
      DATA(lv_text) = ``.
      LOOP AT lt_text INTO DATA(ls_text) WHERE trkorr = ls_request-trkorr AND langu = sy-langu.
        lv_text = ls_text-as4text.
        EXIT.
      ENDLOOP.
      IF lv_text IS INITIAL.
        LOOP AT lt_text INTO ls_text WHERE trkorr = ls_request-trkorr AND langu = 'E'.
          lv_text = ls_text-as4text.
          EXIT.
        ENDLOOP.
      ENDIF.
      APPEND VALUE ty_row(
        request             = ls_request-trkorr
        requestfunction     = ls_request-trfunction
        requestfunctiontext = zcl_sec_domain_text=>request_function_text( ls_request-trfunction )
        requeststatus       = ls_request-trstatus
        requeststatustext   = zcl_sec_domain_text=>request_status_text( ls_request-trstatus )
        targetsystem        = ls_request-tarsystem
        category            = ls_request-korrdev
        categorytext        = zcl_sec_domain_text=>request_category_text( ls_request-korrdev )
        owner               = ls_request-as4user
        changedon           = ls_request-as4date
        changedat           = ls_request-as4time
        parentrequest       = ls_request-strkorr
        description         = lv_text ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
