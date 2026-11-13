INTERFACE zif_sec_system_source
  PUBLIC.

  TYPES:
    BEGIN OF ty_status,
      system_id             TYPE c LENGTH 8,
      application_server    TYPE c LENGTH 32,
      database_system       TYPE c LENGTH 10,
      database_host         TYPE c LENGTH 32,
      database_release      TYPE string,
      operating_system      TYPE c LENGTH 10,
      machine_type          TYPE c LENGTH 5,
      ip_address            TYPE c LENGTH 45,
      sap_release           TYPE c LENGTH 4,
      unicode_system        TYPE c LENGTH 1,
      installation_number   TYPE c LENGTH 10,
    END OF ty_status,
    BEGIN OF ty_kernel,
      system_id          TYPE c LENGTH 8,
      application_server TYPE c LENGTH 32,
      kernel_release     TYPE string,
      kernel_patch_level TYPE string,
      compiled_on        TYPE string,
      compiled_at        TYPE string,
      database_library   TYPE string,
    END OF ty_kernel.

  METHODS read_status
    RETURNING
      VALUE(rs_status) TYPE ty_status
    RAISING
      zcx_sec_settings.

  METHODS read_kernel
    RETURNING
      VALUE(rs_kernel) TYPE ty_kernel
    RAISING
      zcx_sec_settings.
ENDINTERFACE.
