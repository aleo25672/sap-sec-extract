CLASS ltcl_source DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_source.
    DATA role_org_called TYPE abap_bool.
ENDCLASS.


CLASS ltcl_source IMPLEMENTATION.
  METHOD zif_sec_access_source~read_users.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_assignments.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_profile_assignments.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_roles.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_hierarchy.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_profiles.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_authorizations.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_role_org_levels.
    role_org_called = abap_true.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_profiles.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_profile_authorizations.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_authorization_values.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_critical_authorizations.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_critical_variants.
    RETURN.
  ENDMETHOD.
  METHOD zif_sec_access_source~read_user_changes.
    RETURN.
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_deny DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sec_access_auth.
ENDCLASS.


CLASS ltcl_deny IMPLEMENTATION.
  METHOD zif_sec_access_auth~check_user_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_role_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
  METHOD zif_sec_access_auth~check_profile_display.
    RAISE EXCEPTION TYPE zcx_sec_access
      EXPORTING
        textid = zcx_sec_access=>not_authorized.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_query_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS denied_auth_does_not_read FOR TESTING.
ENDCLASS.


CLASS ltcl_query_auth IMPLEMENTATION.
  METHOD denied_auth_does_not_read.
    DATA(lo_source) = NEW ltcl_source( ).
    DATA(lo_query) = NEW zcl_sec_role_org_query(
      io_source = lo_source
      io_auth   = NEW ltcl_deny( ) ).

    TRY.
        lo_query->read_rows( ).
        cl_abap_unit_assert=>fail( 'Authorization failure must raise' ).
      CATCH zcx_sec_access.
        cl_abap_unit_assert=>assert_false( lo_source->role_org_called ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
