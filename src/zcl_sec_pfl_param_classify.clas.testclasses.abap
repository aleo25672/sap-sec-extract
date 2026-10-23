CLASS ltcl_classify DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS login_prefix FOR TESTING.
    METHODS uppercase_name FOR TESTING.
    METHODS explicit_session FOR TESTING.
    METHODS explicit_client FOR TESTING.
    METHODS secure_store_prefix FOR TESTING.
    METHODS other_parameter FOR TESTING.
ENDCLASS.

CLASS ltcl_classify IMPLEMENTATION.
  METHOD login_prefix.
    DATA(ls) = zcl_sec_pfl_param_classify=>classify( 'login/min_password_lng' ).
    cl_abap_unit_assert=>assert_true( ls-relevant ).
    cl_abap_unit_assert=>assert_equals( act = ls-area exp = 'Login' ).
  ENDMETHOD.

  METHOD uppercase_name.
    DATA(ls) = zcl_sec_pfl_param_classify=>classify( 'LOGIN/FAILS_TO_USER_LOCK' ).
    cl_abap_unit_assert=>assert_true( ls-relevant ).
    cl_abap_unit_assert=>assert_equals( act = ls-area exp = 'Login' ).
  ENDMETHOD.

  METHOD explicit_session.
    DATA(ls) = zcl_sec_pfl_param_classify=>classify( 'rdisp/gui_auto_logout' ).
    cl_abap_unit_assert=>assert_true( ls-relevant ).
    cl_abap_unit_assert=>assert_equals( act = ls-area exp = 'Session' ).
  ENDMETHOD.

  METHOD explicit_client.
    DATA(ls) = zcl_sec_pfl_param_classify=>classify( 'rec/client' ).
    cl_abap_unit_assert=>assert_true( ls-relevant ).
    cl_abap_unit_assert=>assert_equals( act = ls-area exp = 'Client' ).
  ENDMETHOD.

  METHOD secure_store_prefix.
    DATA(ls) = zcl_sec_pfl_param_classify=>classify( 'system/secure_communication' ).
    cl_abap_unit_assert=>assert_true( ls-relevant ).
    cl_abap_unit_assert=>assert_equals( act = ls-area exp = 'SecureStore' ).
  ENDMETHOD.

  METHOD other_parameter.
    DATA(ls) = zcl_sec_pfl_param_classify=>classify( 'rdisp/wp_no_dia' ).
    cl_abap_unit_assert=>assert_false( ls-relevant ).
    cl_abap_unit_assert=>assert_initial( ls-area ).
  ENDMETHOD.
ENDCLASS.
