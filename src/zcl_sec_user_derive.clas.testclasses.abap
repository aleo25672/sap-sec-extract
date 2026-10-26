CLASS ltcl_derive DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS unlocked FOR TESTING.
    METHODS each_lock_bit FOR TESTING.
    METHODS combined_and_maintenance_bit FOR TESTING.
    METHODS user_type_fallback FOR TESTING.
    METHODS password_state FOR TESTING.
    METHODS hash_version FOR TESTING.
ENDCLASS.


CLASS ltcl_derive IMPLEMENTATION.
  METHOD unlocked.
    DATA(ls_lock) = zcl_sec_user_derive=>locks( 0 ).
    cl_abap_unit_assert=>assert_equals( act = ls_lock-globally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_lock-locally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_lock-failed_logon_locked exp = ' ' ).

    ls_lock = zcl_sec_user_derive=>locks( 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_lock-globally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_lock-locally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_lock-failed_logon_locked exp = ' ' ).
  ENDMETHOD.

  METHOD each_lock_bit.
    DATA(ls_global) = zcl_sec_user_derive=>locks( 32 ).
    cl_abap_unit_assert=>assert_equals( act = ls_global-globally_locked exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_global-locally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_global-failed_logon_locked exp = ' ' ).

    DATA(ls_local) = zcl_sec_user_derive=>locks( 64 ).
    cl_abap_unit_assert=>assert_equals( act = ls_local-globally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_local-locally_locked exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_local-failed_logon_locked exp = ' ' ).

    DATA(ls_failed) = zcl_sec_user_derive=>locks( 128 ).
    cl_abap_unit_assert=>assert_equals( act = ls_failed-globally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_failed-locally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_failed-failed_logon_locked exp = 'X' ).
  ENDMETHOD.

  METHOD combined_and_maintenance_bit.
    DATA(ls_maint) = zcl_sec_user_derive=>locks( 33 ).
    cl_abap_unit_assert=>assert_equals( act = ls_maint-globally_locked exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_maint-locally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_maint-failed_logon_locked exp = ' ' ).

    DATA(ls_both_admin) = zcl_sec_user_derive=>locks( 96 ).
    cl_abap_unit_assert=>assert_equals( act = ls_both_admin-globally_locked exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_both_admin-locally_locked exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_both_admin-failed_logon_locked exp = ' ' ).

    DATA(ls_local_failed) = zcl_sec_user_derive=>locks( 192 ).
    cl_abap_unit_assert=>assert_equals( act = ls_local_failed-globally_locked exp = ' ' ).
    cl_abap_unit_assert=>assert_equals( act = ls_local_failed-locally_locked exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_local_failed-failed_logon_locked exp = 'X' ).

    DATA(ls_all) = zcl_sec_user_derive=>locks( 224 ).
    cl_abap_unit_assert=>assert_equals( act = ls_all-globally_locked exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_all-locally_locked exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_all-failed_logon_locked exp = 'X' ).
  ENDMETHOD.

  METHOD user_type_fallback.
    DATA(lv_text) = zcl_sec_domain_text=>from_list(
      iv_code   = 'a'
      it_values = zcl_sec_user_derive=>user_type_fallbacks( ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_text exp = 'Dialog' ).
    lv_text = zcl_sec_domain_text=>from_list(
      iv_code   = 'Z'
      it_values = zcl_sec_user_derive=>user_type_fallbacks( ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_text exp = 'Z' ).
  ENDMETHOD.

  METHOD password_state.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_user_derive=>password_state_text( 0 )
      exp = 'Password can be changed, change is not required' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_user_derive=>password_state_text( 1 )
      exp = 'Initial password, change is required' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_user_derive=>password_state_text( 254 )
      exp = 'Password cannot be changed' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_user_derive=>password_state_text( 255 )
      exp = 'Password cannot be changed until the wait period ends' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_user_derive=>password_state_text( 9 )
      exp = '9' ).
  ENDMETHOD.

  METHOD hash_version.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_user_derive=>hash_version_text( 'h' )
      exp = 'Generic hash' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_user_derive=>hash_version_text( 'X' )
      exp = 'Password deactivated' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_user_derive=>hash_version_text( 'Q' )
      exp = 'Q' ).
  ENDMETHOD.
ENDCLASS.
