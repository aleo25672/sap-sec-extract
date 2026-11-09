CLASS zcl_sec_system_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        systemid            TYPE c LENGTH 8,
        applicationserver   TYPE c LENGTH 32,
        databasesystem      TYPE c LENGTH 10,
        databasehost        TYPE c LENGTH 32,
        databaserelease     TYPE string,
        operatingsystem     TYPE c LENGTH 10,
        machinetype         TYPE c LENGTH 5,
        ipaddress           TYPE c LENGTH 45,
        saprelease          TYPE c LENGTH 4,
        unicodesystem       TYPE c LENGTH 1,
        installationnumber  TYPE c LENGTH 10,
      END OF ty_row,
      tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    METHODS constructor
      IMPORTING
        io_source TYPE REF TO zif_sec_system_source OPTIONAL
        io_auth   TYPE REF TO zif_sec_auth OPTIONAL.

    METHODS read_rows
      RETURNING
        VALUE(rt_rows) TYPE tt_row
      RAISING
        zcx_sec_settings.

  PRIVATE SECTION.
    DATA mo_source TYPE REF TO zif_sec_system_source.
    DATA mo_auth TYPE REF TO zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_system_query IMPLEMENTATION.
  METHOD constructor.
    mo_source = io_source.
    mo_auth = io_auth.
    IF mo_source IS NOT BOUND.
      mo_source = NEW zcl_sec_system_source( ).
    ENDIF.
    IF mo_auth IS NOT BOUND.
      mo_auth = NEW zcl_sec_auth( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_rows.
    mo_auth->check_system_display( ).
    DATA(ls_status) = mo_source->read_status( ).
    APPEND VALUE ty_row(
      systemid           = ls_status-system_id
      applicationserver  = ls_status-application_server
      databasesystem     = ls_status-database_system
      databasehost       = ls_status-database_host
      databaserelease    = ls_status-database_release
      operatingsystem    = ls_status-operating_system
      machinetype        = ls_status-machine_type
      ipaddress          = ls_status-ip_address
      saprelease         = ls_status-sap_release
      unicodesystem      = ls_status-unicode_system
      installationnumber = ls_status-installation_number ) TO rt_rows.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
