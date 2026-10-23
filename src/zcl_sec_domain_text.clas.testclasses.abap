CLASS ltcl_domain_text DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS global_and_namespace FOR TESTING.
    METHODS client_role_fallback FOR TESTING.
    METHODS unknown_code_stays FOR TESTING.
ENDCLASS.

CLASS ltcl_domain_text IMPLEMENTATION.
  METHOD global_and_namespace.
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>global_change_text( ' ' ) exp = 'Modifiable' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>global_change_text( 'N' ) exp = 'Not modifiable' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>namespace_change_text( 'X' ) exp = 'Modifiable' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>namespace_change_text( '' ) exp = 'Not modifiable' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>namespace_change_text( ' ' ) exp = 'Not modifiable' ).
  ENDMETHOD.

  METHOD client_role_fallback.
    DATA(lv_text) = zcl_sec_domain_text=>from_list(
      iv_code = 'p'
      it_values = zcl_sec_domain_text=>client_role_fallbacks( ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_text exp = 'Production' ).
  ENDMETHOD.

  METHOD unknown_code_stays.
    DATA(lv_text) = zcl_sec_domain_text=>from_list(
      iv_code = 'Z'
      it_values = zcl_sec_domain_text=>component_fallbacks( ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_text exp = 'Z' ).
  ENDMETHOD.
ENDCLASS.
