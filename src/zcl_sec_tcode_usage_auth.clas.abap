CLASS zcl_sec_tcode_usage_auth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_tcode_usage_auth.
ENDCLASS.


CLASS zcl_sec_tcode_usage_auth IMPLEMENTATION.
  METHOD zif_sec_tcode_usage_auth~check_workload_display.
    " Message 004. The text id is local so this class activates against the current exception.
    DATA ls_text TYPE if_t100_message=>t100key.
    " S_TOOLS_EX_A is the value that keeps every user name visible.
    " Without it, ST03 replaces other users with a hash.
    AUTHORITY-CHECK OBJECT 'S_TOOLS_EX'
      ID 'AUTH' FIELD 'S_TOOLS_EX_A'.
    IF sy-subrc <> 0.
      ls_text-msgid = |ZSEC_ACCESS|.
      ls_text-msgno = |004|.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid = ls_text.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
