CLASS zcl_sec_tcode_usage_auth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_tcode_usage_auth.
ENDCLASS.


CLASS zcl_sec_tcode_usage_auth IMPLEMENTATION.
  METHOD zif_sec_tcode_usage_auth~check_workload_display.
    " S_TOOLS_EX_A is the value that keeps every user name visible.
    " Without it, ST03 replaces other users with a hash.
    AUTHORITY-CHECK OBJECT 'S_TOOLS_EX'
      ID 'AUTH' FIELD 'S_TOOLS_EX_A'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid = zcx_sec_access=>workload_not_authorized.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
