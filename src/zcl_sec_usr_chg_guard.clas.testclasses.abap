CLASS ltcl_guard DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS password_hash_is_blank FOR TESTING.
    METHODS address_and_mail_are_blank FOR TESTING.
    METHODS lock_and_hash_version_stay FOR TESTING.
    METHODS date_filter_canonical FOR TESTING.
    METHODS date_filter_rejects_text FOR TESTING.
ENDCLASS.


CLASS ltcl_guard IMPLEMENTATION.
  METHOD password_hash_is_blank.
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'BCODE' iv_value = 'HASH' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'passcode' iv_value = 'HASH' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USH02' iv_field = 'PWDSALTEDHASH' iv_value = 'HASH' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'OCOD3' iv_value = 'HASH' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'PASSWORD' iv_value = 'HASH' ) ).
  ENDMETHOD.

  METHOD address_and_mail_are_blank.
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'adrp' iv_field = 'NAME_FIRST' iv_value = 'Ada' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'ADRP' iv_field = 'PERSNUMBER' iv_value = '0001' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'ADR6' iv_field = 'SMTP_ADDR' iv_value = 'a@b.c' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR03' iv_field = 'NAME1' iv_value = 'Ada' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'ADR2' iv_field = 'TEL_NUMBER' iv_value = '1' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'SMTP_ADDR' iv_value = 'a@b.c' ) ).
    cl_abap_unit_assert=>assert_initial(
      zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'INTAD' iv_value = 'a@b.c' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR21' iv_field = 'PERSNUMBER' iv_value = '0001' )
      exp = '0001' ).
  ENDMETHOD.

  METHOD lock_and_hash_version_stay.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'UFLAG' iv_value = '64' )
      exp = '64' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'CLASS' iv_value = 'SUPER' )
      exp = 'SUPER' ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_sec_usr_chg_guard=>payload_value( iv_table = 'USR02' iv_field = 'CODVN' iv_value = 'H' )
      exp = 'H' ).
    cl_abap_unit_assert=>assert_false( zcl_sec_usr_chg_guard=>is_sensitive( iv_table = '' iv_field = '' ) ).
  ENDMETHOD.

  METHOD date_filter_canonical.
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_usr_chg_guard=>date_filter( '2026-10-27' ) exp = '20261027' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_usr_chg_guard=>date_filter( '20261027' ) exp = '20261027' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_sec_usr_chg_guard=>date_filter( '2026-10-27T00:00:00Z' ) exp = '20261027' ).
    cl_abap_unit_assert=>assert_initial( zcl_sec_usr_chg_guard=>date_filter( '' ) ).
  ENDMETHOD.

  METHOD date_filter_rejects_text.
    TRY.
        zcl_sec_usr_chg_guard=>date_filter( 'yesterday' ).
        cl_abap_unit_assert=>fail( 'A change date that is not a date must raise' ).
      CATCH zcx_sec_access INTO DATA(lx_access).
        cl_abap_unit_assert=>assert_equals( act = lx_access->filter_name exp = 'ChangeDate' ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
