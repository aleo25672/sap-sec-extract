CLASS zcl_sec_role_chg_db DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sec_role_chg_source.
ENDCLASS.


CLASS zcl_sec_role_chg_db IMPLEMENTATION.
  METHOD zif_sec_role_chg_source~read_role_changes.
    DATA lr_role TYPE RANGE OF cdhdr-objectid.
    DATA lr_date TYPE RANGE OF cdhdr-udate.
    DATA lr_by TYPE RANGE OF cdhdr-username.
    DATA ls_date_range LIKE LINE OF lr_date.

    LOOP AT it_rolename INTO DATA(ls_role).
      APPEND VALUE #(
        sign   = CONV #( to_upper( ls_role-sign ) )
        option = CONV #( to_upper( ls_role-option ) )
        low    = CONV #( to_upper( ls_role-low ) )
        high   = CONV #( to_upper( ls_role-high ) ) ) TO lr_role.
    ENDLOOP.
    LOOP AT it_changedby INTO DATA(ls_by).
      APPEND VALUE #(
        sign   = CONV #( to_upper( ls_by-sign ) )
        option = CONV #( to_upper( ls_by-option ) )
        low    = CONV #( to_upper( ls_by-low ) )
        high   = CONV #( to_upper( ls_by-high ) ) ) TO lr_by.
    ENDLOOP.
    LOOP AT it_changedate INTO DATA(ls_date).
      CLEAR ls_date_range.
      ls_date_range-sign = CONV #( to_upper( ls_date-sign ) ).
      ls_date_range-option = CONV #( to_upper( ls_date-option ) ).
      TRY.
          IF ls_date-low IS NOT INITIAL.
            ls_date_range-low = ls_date-low.
          ENDIF.
          IF ls_date-high IS NOT INITIAL.
            ls_date_range-high = ls_date-high.
          ENDIF.
        CATCH cx_sy_conversion_error INTO DATA(lx_date).
          RAISE EXCEPTION TYPE zcx_sec_access
            EXPORTING
              textid      = zcx_sec_access=>filter_not_supported
              previous    = lx_date
              filter_name = 'ChangeDate'.
      ENDTRY.
      APPEND ls_date_range TO lr_date.
    ENDLOOP.

    " An empty range adds no restriction. The view blanks password and address values.
    SELECT rolename, changenumber, changedby, changedate, changetime, transactioncode,
           headerchange, tablename, tablekey, fieldname, itemchange, valueold, valuenew
      FROM zi_sec_role_chg
      WHERE rolename IN @lr_role
        AND changedate IN @lr_date
        AND changedby IN @lr_by
      INTO CORRESPONDING FIELDS OF TABLE @rt_rows.

    LOOP AT rt_rows ASSIGNING FIELD-SYMBOL(<ls_row>).
      <ls_row>-valueold = CONV #( zcl_sec_usr_chg_guard=>payload_value(
        iv_table = <ls_row>-tablename
        iv_field = <ls_row>-fieldname
        iv_value = <ls_row>-valueold ) ).
      <ls_row>-valuenew = CONV #( zcl_sec_usr_chg_guard=>payload_value(
        iv_table = <ls_row>-tablename
        iv_field = <ls_row>-fieldname
        iv_value = <ls_row>-valuenew ) ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
