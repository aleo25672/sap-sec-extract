CLASS zcl_sec_access_db DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_access_source.
ENDCLASS.


CLASS zcl_sec_access_db IMPLEMENTATION.
  METHOD zif_sec_access_source~read_users.
    SELECT userid, usertype, usergroup, validfrom, validto, lockflag,
           passwordstate, passwordhashversion, lastlogondate, lastlogontime,
           createdby, createdon, securitypolicy, referenceuser
      FROM zi_sec_user
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_role_assignments.
    SELECT userid, rolename, validfrom, validto, exclusive, changedon,
           fromcompositerole, fromorgmanagement
      FROM zi_sec_role_assign
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_profile_assignments.
    SELECT userid, profilename, profilesource, referenceuser
      FROM zi_sec_prof_assign
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_roles.
    SELECT rolename, parentrole, createdby, createdon, changedby, changedon, description
      FROM zi_sec_role
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.

  METHOD zif_sec_access_source~read_role_hierarchy.
    SELECT compositerole, singlerole
      FROM zi_sec_role_hier
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.
  ENDMETHOD.
ENDCLASS.
