CLASS zcl_sec_tmsroute_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        routekind           TYPE c LENGTH 15,
        configversion       TYPE n LENGTH 4,
        transportlayer      TYPE c LENGTH 4,
        sourcesystem        TYPE c LENGTH 10,
        targetsystem        TYPE c LENGTH 10,
        consolidationsystem TYPE c LENGTH 10,
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
    TYPES ty_version TYPE n LENGTH 4.

    DATA mo_auth TYPE REF TO zif_sec_auth.

    METHODS active_version
      RETURNING
        VALUE(rv_version) TYPE ty_version.
ENDCLASS.


CLASS zcl_sec_tmsroute_query IMPLEMENTATION.
  METHOD constructor.
    mo_auth = io_auth.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD active_version.
    SELECT MAX( version )
      FROM tcevers
      INTO @DATA(lv_version).
    IF lv_version IS INITIAL.
      SELECT MAX( version )
        FROM tcerele
        INTO @lv_version.
    ENDIF.
    rv_version = lv_version.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_transport_admin( ).
    IF io_request IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lv_version) = active_version( ).
    IF lv_version IS INITIAL.
      RETURN.
    ENDIF.

    " TCERELE: INTSYS is the source, CONSYS the consolidation target, ORICON the consolidation system.
    SELECT version, translayer, intsys, consys, oricon
      FROM tcerele
      WHERE version = @lv_version
      INTO TABLE @DATA(lt_consolidation).
    IF lt_consolidation IS INITIAL.
      SELECT MAX( version ) FROM tcerele INTO @lv_version.
      IF lv_version IS NOT INITIAL.
        SELECT version, translayer, intsys, consys, oricon
          FROM tcerele
          WHERE version = @lv_version
          INTO TABLE @lt_consolidation.
      ENDIF.
    ENDIF.

    LOOP AT lt_consolidation INTO DATA(ls_consolidation).
      APPEND VALUE ty_row(
        routekind           = 'Consolidation'
        configversion       = ls_consolidation-version
        transportlayer      = ls_consolidation-translayer
        sourcesystem        = ls_consolidation-intsys
        targetsystem        = ls_consolidation-consys
        consolidationsystem = ls_consolidation-oricon ) TO rt_rows.
    ENDLOOP.

    " TCEDELI: FROMSYSTEM is the source and TOSYSTEM the target. There is no transport layer.
    SELECT version, fromsystem, tosystem
      FROM tcedeli
      WHERE version = @lv_version
      INTO TABLE @DATA(lt_delivery).
    IF lt_delivery IS INITIAL.
      DATA lv_delivery TYPE ty_version.
      SELECT MAX( version ) FROM tcedeli INTO @lv_delivery.
      IF lv_delivery IS NOT INITIAL.
        SELECT version, fromsystem, tosystem
          FROM tcedeli
          WHERE version = @lv_delivery
          INTO TABLE @lt_delivery.
      ENDIF.
    ENDIF.

    LOOP AT lt_delivery INTO DATA(ls_delivery).
      APPEND VALUE ty_row(
        routekind     = 'Delivery'
        configversion = ls_delivery-version
        sourcesystem  = ls_delivery-fromsystem
        targetsystem  = ls_delivery-tosystem ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
