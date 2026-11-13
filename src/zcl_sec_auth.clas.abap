CLASS zcl_sec_auth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_auth.
ENDCLASS.


CLASS zcl_sec_auth IMPLEMENTATION.
  METHOD zif_sec_auth~check_profile_display.
    AUTHORITY-CHECK OBJECT 'S_ADMI_FCD'
      ID 'S_ADMI_FCD' FIELD 'PADM'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~check_policy_display.
    AUTHORITY-CHECK OBJECT 'S_SECPOL'
      ID 'ACTVT'      FIELD '03'
      ID 'POLICYNAME' DUMMY.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~check_client_display.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
      ID 'TABLE' FIELD 'T000'
      ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~check_system_change_display.
    " Same display function report RSWBO004 uses for the SE06 system change screen.
    AUTHORITY-CHECK OBJECT 'S_CTS_ADMI'
      ID 'CTS_ADMFCT' FIELD 'TABL'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~check_system_display.
    " SM51 and the system status screens use this display activity.
    AUTHORITY-CHECK OBJECT 'S_RZL_ADM'
      ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~check_named_table.
    " AUTHORITY-CHECK rejects a string. The table name is 30 characters.
    DATA lv_table TYPE c LENGTH 30.
    lv_table = to_upper( iv_table ).
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
      ID 'TABLE' FIELD lv_table
      ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~check_batch_input_display.
    " SM35 analyze. Group * is the overview of every session.
    AUTHORITY-CHECK OBJECT 'S_BDC_MONI'
      ID 'BDCGROUPID' FIELD '*'
      ID 'BDCAKTI'    FIELD 'ANAL'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~check_transport_admin.
    " STMS domain, systems, routes, and the tp parameter profile.
    AUTHORITY-CHECK OBJECT 'S_CTS_ADMI'
      ID 'CTS_ADMFCT' FIELD 'TADM'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~check_transport_display.
    " SE09 and SE10 display of every request type.
    AUTHORITY-CHECK OBJECT 'S_TRANSPRT'
      ID 'TTYPE' FIELD '*'
      ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_settings
        EXPORTING
          textid = zcx_sec_settings=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_auth~can_count_users.
    AUTHORITY-CHECK OBJECT 'S_USER_GRP'
      ID 'CLASS' FIELD '*'
      ID 'ACTVT' FIELD '03'.
    rv_yes = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.
ENDCLASS.
