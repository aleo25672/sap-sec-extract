CLASS zcl_sec_access_auth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_access_auth.
ENDCLASS.


CLASS zcl_sec_access_auth IMPLEMENTATION.
  METHOD zif_sec_access_auth~check_user_display.
    " Group * keeps the population complete. A narrower group would hide accounts.
    AUTHORITY-CHECK OBJECT 'S_USER_GRP'
      ID 'CLASS' FIELD '*'
      ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid = zcx_sec_access=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_access_auth~check_role_display.
    " S_USER_AGR calls the role ACT_GROUP. AGR_NAME is the column on AGR_USERS.
    AUTHORITY-CHECK OBJECT 'S_USER_AGR'
      ID 'ACTVT'     FIELD '03'
      ID 'ACT_GROUP' FIELD '*'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid = zcx_sec_access=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_access_auth~check_profile_display.
    AUTHORITY-CHECK OBJECT 'S_USER_PRO'
      ID 'PROFILE' FIELD '*'
      ID 'ACTVT'   FIELD '03'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid = zcx_sec_access=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_access_auth~check_audit_display.
    " SM20 display. SM19 maintenance uses a different fixed value.
    AUTHORITY-CHECK OBJECT 'S_ADMI_FCD'
      ID 'S_ADMI_FCD' FIELD 'AUDD'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid = zcx_sec_access=>not_authorized.
    ENDIF.
  ENDMETHOD.

  METHOD zif_sec_access_auth~check_system_log_display.
    " SM21 display on this application server.
    AUTHORITY-CHECK OBJECT 'S_ADMI_FCD'
      ID 'S_ADMI_FCD' FIELD 'SM21'.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid = zcx_sec_access=>not_authorized.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
