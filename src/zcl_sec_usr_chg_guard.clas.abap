CLASS zcl_sec_usr_chg_guard DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS is_sensitive
      IMPORTING
        iv_table           TYPE string
        iv_field           TYPE string
      RETURNING
        VALUE(rv_sensitive) TYPE abap_bool.

    CLASS-METHODS payload_value
      IMPORTING
        iv_table         TYPE string
        iv_field         TYPE string
        iv_value         TYPE string
      RETURNING
        VALUE(rv_value)  TYPE string.

    " YYYYMMDD. An empty bound stays empty. Dashes and a trailing time are removed.
    CLASS-METHODS date_filter
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_date)  TYPE string
      RAISING
        zcx_sec_access.

    CLASS-METHODS class_constructor.

  PRIVATE SECTION.
    TYPES ty_name TYPE c LENGTH 30.
    CLASS-DATA gt_tables TYPE HASHED TABLE OF ty_name WITH UNIQUE KEY table_line.
    CLASS-DATA gt_fields TYPE HASHED TABLE OF ty_name WITH UNIQUE KEY table_line.
ENDCLASS.


CLASS zcl_sec_usr_chg_guard IMPLEMENTATION.
  METHOD class_constructor.
    " Address and person tables on change document object IDENTITY.
    " The same names are cleared in ZI_SEC_USR_CHG.
    gt_tables = VALUE #(
      ( 'ADRP' ) ( 'ADRC' ) ( 'ADR2' ) ( 'ADR3' ) ( 'ADR6' ) ( 'ADCP' ) ( 'ADRT' ) ( 'USR03' ) ).
    gt_fields = VALUE #(
      ( 'BCODE' ) ( 'PASSCODE' ) ( 'PWDSALTEDHASH' ) ( 'PASSWORD' )
      ( 'OCOD1' ) ( 'OCOD2' ) ( 'OCOD3' ) ( 'OCOD4' ) ( 'OCOD5' )
      ( 'NAME_FIRST' ) ( 'NAME_LAST' ) ( 'NAME_TEXT' ) ( 'NAME_LAST2' ) ( 'NICKNAME' )
      ( 'MC_NAMEFIR' ) ( 'MC_NAMELAS' )
      ( 'NAME1' ) ( 'NAME2' ) ( 'NAME3' ) ( 'NAME4' )
      ( 'SMTP_ADDR' ) ( 'SMTP_SRCH' ) ( 'INTAD' ) ( 'FIRSTNAME' ) ( 'LASTNAME' )
      ( 'TEL_NUMBER' ) ( 'TELNR' ) ( 'TELNR_LONG' ) ( 'TEL_EXTENS' ) ( 'MOB_NUMBER' ) ).
  ENDMETHOD.

  METHOD is_sensitive.
    DATA(lv_table) = to_upper( condense( iv_table ) ).
    DATA(lv_field) = to_upper( condense( iv_field ) ).
    IF line_exists( gt_tables[ table_line = lv_table ] ).
      rv_sensitive = abap_true.
      RETURN.
    ENDIF.
    rv_sensitive = xsdbool( line_exists( gt_fields[ table_line = lv_field ] ) ).
  ENDMETHOD.

  METHOD payload_value.
    IF is_sensitive( iv_table = iv_table iv_field = iv_field ) = abap_true.
      RETURN.
    ENDIF.
    rv_value = iv_value.
  ENDMETHOD.

  METHOD date_filter.
    DATA(lv_raw) = condense( iv_value ).
    IF lv_raw IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_t) = find( val = lv_raw sub = 'T' ).
    IF lv_t > 0.
      lv_raw = substring( val = lv_raw len = lv_t ).
    ENDIF.
    lv_raw = replace( val = lv_raw sub = '-' with = '' occ = 0 ).
    lv_raw = replace( val = lv_raw sub = '/' with = '' occ = 0 ).
    CONDENSE lv_raw NO-GAPS.
    IF strlen( lv_raw ) <> 8 OR lv_raw CN '0123456789'.
      RAISE EXCEPTION TYPE zcx_sec_access
        EXPORTING
          textid      = zcx_sec_access=>filter_not_supported
          filter_name = 'ChangeDate'.
    ENDIF.
    rv_date = lv_raw.
  ENDMETHOD.
ENDCLASS.
