INTERFACE zif_sec_access_auth
  PUBLIC.

  METHODS check_user_display
    RAISING zcx_sec_access.

  METHODS check_role_display
    RAISING zcx_sec_access.

  METHODS check_profile_display
    RAISING zcx_sec_access.
ENDINTERFACE.
