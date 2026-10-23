CLASS ltcl_dynamic_flag DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS true_for_x FOR TESTING.
    METHODS true_for_one FOR TESTING.
    METHODS false_for_zero FOR TESTING.
    METHODS false_for_blank FOR TESTING.
ENDCLASS.

CLASS ltcl_dynamic_flag IMPLEMENTATION.
  METHOD true_for_x.
    cl_abap_unit_assert=>assert_true( zcl_sec_pfl_param_source=>dynamic_flag( 'X' ) ).
    cl_abap_unit_assert=>assert_true( zcl_sec_pfl_param_source=>dynamic_flag( 'x' ) ).
  ENDMETHOD.

  METHOD true_for_one.
    cl_abap_unit_assert=>assert_true( zcl_sec_pfl_param_source=>dynamic_flag( '1' ) ).
  ENDMETHOD.

  METHOD false_for_zero.
    cl_abap_unit_assert=>assert_false( zcl_sec_pfl_param_source=>dynamic_flag( '0' ) ).
  ENDMETHOD.

  METHOD false_for_blank.
    cl_abap_unit_assert=>assert_false( zcl_sec_pfl_param_source=>dynamic_flag( '' ) ).
    cl_abap_unit_assert=>assert_false( zcl_sec_pfl_param_source=>dynamic_flag( ' ' ) ).
  ENDMETHOD.
ENDCLASS.
