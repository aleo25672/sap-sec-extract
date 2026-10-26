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
    AUTHORITY-CHECK OBJECT 'S_USER_AGR'
      ID 'ACTVT'    FIELD '03'
      ID 'AGR_NAME' FIELD '*'.
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
ENDCLASS.
