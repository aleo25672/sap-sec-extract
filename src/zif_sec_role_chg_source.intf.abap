INTERFACE zif_sec_role_chg_source
  PUBLIC.

  TYPES:
    BEGIN OF ty_role_change,
      rolename        TYPE cdhdr-objectid,
      changenumber    TYPE cdhdr-changenr,
      changedby       TYPE cdhdr-username,
      changedate      TYPE cdhdr-udate,
      changetime      TYPE cdhdr-utime,
      transactioncode TYPE cdhdr-tcode,
      headerchange    TYPE cdhdr-change_ind,
      tablename       TYPE cdpos-tabname,
      tablekey        TYPE cdpos-tabkey,
      fieldname       TYPE cdpos-fname,
      itemchange      TYPE cdpos-chngind,
      valueold        TYPE cdpos-value_old,
      valuenew        TYPE cdpos-value_new,
    END OF ty_role_change,
    tt_role_change TYPE STANDARD TABLE OF ty_role_change WITH EMPTY KEY.

  METHODS read_role_changes
    IMPORTING
      it_rolename   TYPE zcl_sec_query_util=>tt_range
      it_changedate TYPE zcl_sec_query_util=>tt_range
      it_changedby  TYPE zcl_sec_query_util=>tt_range
    RETURNING
      VALUE(rt_rows) TYPE tt_role_change
    RAISING
      zcx_sec_access.
ENDINTERFACE.
