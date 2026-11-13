CLASS zcl_sec_kernel_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

    TYPES:
      BEGIN OF ty_row,
        systemid           TYPE c LENGTH 8,
        applicationserver  TYPE c LENGTH 32,
        kernelrelease      TYPE string,
        kernelpatchlevel   TYPE string,
        compiledon         TYPE string,
        compiledat         TYPE string,
        databaselibrary    TYPE string,
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


CLASS zcl_sec_kernel_query IMPLEMENTATION.
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
    DATA(ls_kernel) = mo_source->read_kernel( ).
    APPEND VALUE ty_row(
      systemid          = ls_kernel-system_id
      applicationserver = ls_kernel-application_server
      kernelrelease     = ls_kernel-kernel_release
      kernelpatchlevel  = ls_kernel-kernel_patch_level
      compiledon        = ls_kernel-compiled_on
      compiledat        = ls_kernel-compiled_at
      databaselibrary   = ls_kernel-database_library ) TO rt_rows.
  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA(lt_rows) = read_rows( ).
    zcl_sec_query_util=>apply(
      EXPORTING io_request = io_request io_response = io_response
      CHANGING ct_rows = lt_rows ).
  ENDMETHOD.
ENDCLASS.
