CLASS zcl_sec_e071_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        request       TYPE c LENGTH 20,
        position      TYPE n LENGTH 6,
        programid     TYPE c LENGTH 4,
        objecttype    TYPE c LENGTH 4,
        objectname    TYPE c LENGTH 120,
        objectfunction TYPE c LENGTH 1,
        objectlanguage TYPE c LENGTH 1,
        owner         TYPE c LENGTH 12,
        changedon     TYPE d,
        targetsystem  TYPE c LENGTH 10,
        requeststatus TYPE c LENGTH 1,
        description   TYPE c LENGTH 60,
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


CLASS zcl_sec_e071_query IMPLEMENTATION.
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

    SELECT o~trkorr, o~as4pos, o~pgmid, o~object, o~obj_name, o~objfunc, o~lang,
           h~as4user, h~as4date, h~tarsystem, h~trstatus
      FROM e071 AS o
      INNER JOIN e070 AS h
        ON h~trkorr = o~trkorr
      WHERE h~as4date IN @lr_date
      INTO TABLE @DATA(lt_object).

    TYPES:
      BEGIN OF ty_text,
        trkorr  TYPE c LENGTH 20,
        langu   TYPE c LENGTH 1,
        as4text TYPE c LENGTH 60,
      END OF ty_text.
    DATA lt_text TYPE STANDARD TABLE OF ty_text.
    DATA lt_request TYPE STANDARD TABLE OF c LENGTH 20.
    LOOP AT lt_object INTO DATA(ls_key).
      APPEND ls_key-trkorr TO lt_request.
    ENDLOOP.
    SORT lt_request.
    DELETE ADJACENT DUPLICATES FROM lt_request.
    IF lt_request IS NOT INITIAL.
      SELECT trkorr, langu, as4text
        FROM e07t
        FOR ALL ENTRIES IN @lt_request
        WHERE trkorr = @lt_request-table_line
          AND ( langu = @sy-langu OR langu = 'E' )
        INTO TABLE @lt_text.
    ENDIF.

    LOOP AT lt_object INTO DATA(ls_object).
      DATA(lv_text) = ``.
      LOOP AT lt_text INTO DATA(ls_text) WHERE trkorr = ls_object-trkorr AND langu = sy-langu.
        lv_text = ls_text-as4text.
        EXIT.
      ENDLOOP.
      IF lv_text IS INITIAL.
        LOOP AT lt_text INTO ls_text WHERE trkorr = ls_object-trkorr AND langu = 'E'.
          lv_text = ls_text-as4text.
          EXIT.
        ENDLOOP.
      ENDIF.
      APPEND VALUE ty_row(
        request        = ls_object-trkorr
        position       = ls_object-as4pos
        programid      = ls_object-pgmid
        objecttype     = ls_object-object
        objectname     = ls_object-obj_name
        objectfunction = ls_object-objfunc
        objectlanguage = ls_object-lang
        owner          = ls_object-as4user
        changedon      = ls_object-as4date
        targetsystem   = ls_object-tarsystem
        requeststatus  = ls_object-trstatus
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
