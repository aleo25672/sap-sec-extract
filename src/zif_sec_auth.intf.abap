INTERFACE zif_sec_auth
  PUBLIC.

  METHODS check_profile_display
    RAISING zcx_sec_settings.

  METHODS check_policy_display
    RAISING zcx_sec_settings.

  METHODS check_client_display
    RAISING zcx_sec_settings.

  METHODS check_system_change_display
    RAISING zcx_sec_settings.

  METHODS can_count_users
    RETURNING VALUE(rv_yes) TYPE abap_bool.
ENDINTERFACE.
