CLASS ltcl_domain_text DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS global_and_namespace FOR TESTING.
    METHODS client_role_fallback FOR TESTING.
    METHODS unknown_code_stays FOR TESTING.
    METHODS component_program_and_batch FOR TESTING.
    METHODS transport_and_request_texts FOR TESTING.
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

  METHOD component_program_and_batch.
    DATA(lv_component) = zcl_sec_domain_text=>from_list(
      iv_code = 'S'
      it_values = zcl_sec_domain_text=>component_type_fallbacks( ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_component exp = 'NetWeaver basis component' ).
    DATA(lv_program) = zcl_sec_domain_text=>from_list(
      iv_code = '1'
      it_values = zcl_sec_domain_text=>program_type_fallbacks( ) ).
    cl_abap_unit_assert=>assert_equals( act = lv_program exp = 'Executable program' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>batch_session_text( ' ' ) exp = 'To be processed' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>batch_session_text( 'E' ) exp = 'Incorrect' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>batch_session_text( 'F' ) exp = 'Finished' ).
  ENDMETHOD.

  METHOD transport_and_request_texts.
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>transport_system_text( 'V' ) exp = 'Virtual system' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>request_function_text( 'K' ) exp = 'Workbench request' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>request_status_text( 'R' ) exp = 'Released' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>request_category_text( 'CUST' ) exp = 'Customizing' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>tp_return_text( '0008' ) exp = 'Error' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>tp_return_text( '0000' ) exp = 'Success' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_domain_text=>tp_return_text( '' ) exp = '' ).
  ENDMETHOD.
ENDCLASS.
