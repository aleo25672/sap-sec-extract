CLASS zcl_sec_tppar_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        domainname      TYPE c LENGTH 10,
        configversion   TYPE n LENGTH 4,
        systemname      TYPE c LENGTH 10,
        operatingsystem TYPE c LENGTH 10,
        databasesystem  TYPE c LENGTH 3,
        parametername   TYPE c LENGTH 60,
        parametervalue  TYPE c LENGTH 200,
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


CLASS zcl_sec_tppar_query IMPLEMENTATION.
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

    DATA lv_version TYPE n LENGTH 4.
    SELECT MAX( version )
      FROM tmspconf
      INTO @lv_version.
    IF lv_version IS INITIAL.
      RETURN.
    ENDIF.

    SELECT domnam, version, sysname, opsys, dbsys, name AS paramname, value AS paramvalue
      FROM tmspconf
      WHERE version = @lv_version
      INTO TABLE @DATA(lt_parameter).

    LOOP AT lt_parameter INTO DATA(ls_parameter).
      APPEND VALUE ty_row(
        domainname      = ls_parameter-domnam
        configversion   = ls_parameter-version
        systemname      = ls_parameter-sysname
        operatingsystem = ls_parameter-opsys
        databasesystem  = ls_parameter-dbsys
        parametername   = ls_parameter-paramname
        parametervalue  = ls_parameter-paramvalue ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( io_request ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
