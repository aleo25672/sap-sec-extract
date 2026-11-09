CLASS zcl_sec_system_source DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_system_source.
ENDCLASS.


CLASS zcl_sec_system_source IMPLEMENTATION.
  METHOD zif_sec_system_source~read_status.
    DATA ls_rfcsi TYPE rfcsi.
    CALL FUNCTION 'RFC_SYSTEM_INFO'
      IMPORTING
        rfcsi_export = ls_rfcsi
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0 OR ls_rfcsi-rfcsysid IS INITIAL.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>system_read_failed.
    ENDIF.

    DATA lv_install TYPE string.
    CALL FUNCTION 'SLIC_GET_LICENCE_NUMBER'
      IMPORTING
        license_number = lv_install
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0.
      CLEAR lv_install.
    ENDIF.

    DATA lv_unused TYPE thlines-thline.
    DATA lt_db_vendor TYPE STANDARD TABLE OF thlines.
    DATA lt_unused TYPE STANDARD TABLE OF thlines.
    CALL FUNCTION 'TH_SAPREL'
      IMPORTING
        kern_rel        = lv_unused
        kern_dblib      = lv_unused
        kern_comp_on    = lv_unused
        kern_comp_time  = lv_unused
        kern_patchlevel = lv_unused
      TABLES
        supp_db_sap     = lt_unused
        supp_db_vendor  = lt_db_vendor
        supp_op_sys     = lt_unused
        patchcomment    = lt_unused
      EXCEPTIONS
        OTHERS = 1.

    DATA lv_dbrel TYPE string.
    IF sy-subrc = 0.
      READ TABLE lt_db_vendor INTO DATA(ls_db) INDEX 1.
      IF sy-subrc = 0.
        lv_dbrel = ls_db-thline.
      ENDIF.
    ENDIF.

    DATA lv_ip TYPE c LENGTH 45.
    lv_ip = ls_rfcsi-rfcipv6addr.
    IF lv_ip IS INITIAL.
      lv_ip = ls_rfcsi-rfcipaddr.
    ENDIF.

    rs_status-system_id = ls_rfcsi-rfcsysid.
    rs_status-application_server = sy-host.
    rs_status-database_system = ls_rfcsi-rfcdbsys.
    rs_status-database_host = ls_rfcsi-rfcdbhost.
    rs_status-database_release = condense( lv_dbrel ).
    rs_status-operating_system = ls_rfcsi-rfcopsys.
    rs_status-machine_type = ls_rfcsi-rfcmach.
    rs_status-ip_address = lv_ip.
    rs_status-sap_release = ls_rfcsi-rfcsaprl.
    rs_status-unicode_system = COND #( WHEN cl_abap_char_utilities=>charsize > 1 THEN 'X' ELSE ' ' ).
    rs_status-installation_number = condense( lv_install ).
  ENDMETHOD.

  METHOD zif_sec_system_source~read_kernel.
    DATA lv_rel TYPE thlines-thline.
    DATA lv_patch TYPE thlines-thline.
    DATA lv_compiled_on TYPE thlines-thline.
    DATA lv_compiled_at TYPE thlines-thline.
    DATA lv_dblib TYPE thlines-thline.
    DATA lt_unused TYPE STANDARD TABLE OF thlines.

    CALL FUNCTION 'TH_SAPREL'
      IMPORTING
        kern_rel        = lv_rel
        kern_dblib      = lv_dblib
        kern_comp_on    = lv_compiled_on
        kern_comp_time  = lv_compiled_at
        kern_patchlevel = lv_patch
      TABLES
        supp_db_sap     = lt_unused
        supp_db_vendor  = lt_unused
        supp_op_sys     = lt_unused
        patchcomment    = lt_unused
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0 OR lv_rel IS INITIAL.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>system_read_failed.
    ENDIF.

    rs_kernel-system_id = sy-sysid.
    rs_kernel-application_server = sy-host.
    rs_kernel-kernel_release = condense( |{ lv_rel }| ).
    rs_kernel-kernel_patch_level = condense( |{ lv_patch }| ).
    rs_kernel-compiled_on = condense( |{ lv_compiled_on }| ).
    rs_kernel-compiled_at = condense( |{ lv_compiled_at }| ).
    rs_kernel-database_library = condense( |{ lv_dblib }| ).
  ENDMETHOD.
ENDCLASS.
