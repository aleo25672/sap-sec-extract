CLASS ltcl_derive DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS stored_value_is_policy FOR TESTING.
    METHODS missing_value_is_kernel FOR TESTING.
    METHODS stored_zero_stays_policy FOR TESTING.
ENDCLASS.

CLASS ltcl_derive IMPLEMENTATION.
  METHOD stored_value_is_policy.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_policy_derive=>origin( abap_true )
      exp = zcl_sec_policy_derive=>c_policy ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_policy_derive=>effective( iv_persisted = abap_true iv_stored = 8 iv_default = 6 )
      exp = 8 ).
  ENDMETHOD.

  METHOD missing_value_is_kernel.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_policy_derive=>origin( abap_false )
      exp = zcl_sec_policy_derive=>c_kernel ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_policy_derive=>effective( iv_persisted = abap_false iv_stored = 8 iv_default = 6 )
      exp = 6 ).
  ENDMETHOD.

  METHOD stored_zero_stays_policy.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_policy_derive=>origin( abap_true )
      exp = zcl_sec_policy_derive=>c_policy ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_policy_derive=>effective( iv_persisted = abap_true iv_stored = 0 iv_default = 0 )
      exp = 0 ).
  ENDMETHOD.
ENDCLASS.
