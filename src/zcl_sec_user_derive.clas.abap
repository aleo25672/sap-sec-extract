CLASS zcl_sec_user_derive DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_lock,
        globally_locked     TYPE c LENGTH 1,
        locally_locked      TYPE c LENGTH 1,
        failed_logon_locked TYPE c LENGTH 1,
      END OF ty_lock.

    " USR02-UFLAG bits. A stored +1 is a maintenance lock and leaves these bits unchanged.
    CONSTANTS:
      c_lock_global TYPE i VALUE 32,
      c_lock_local  TYPE i VALUE 64,
      c_lock_failed TYPE i VALUE 128.

    CLASS-METHODS locks
      IMPORTING
        iv_lock_flag   TYPE i
      RETURNING
        VALUE(rs_lock) TYPE ty_lock.

    CLASS-METHODS user_type_text
      IMPORTING
        iv_user_type   TYPE clike
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS user_type_fallbacks
      RETURNING
        VALUE(rt_values) TYPE zcl_sec_domain_text=>tt_value.

    CLASS-METHODS password_state_text
      IMPORTING
        iv_state       TYPE i
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS hash_version_text
      IMPORTING
        iv_version     TYPE clike
      RETURNING
        VALUE(rv_text) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS flag
      IMPORTING
        iv_yes         TYPE abap_bool
      RETURNING
        VALUE(rv_flag) TYPE abap_bool.
ENDCLASS.


CLASS zcl_sec_user_derive IMPLEMENTATION.
  METHOD flag.
    rv_flag = COND #( WHEN iv_yes = abap_true THEN 'X' ELSE ' ' ).
  ENDMETHOD.

  METHOD locks.
    " Each mask is one bit of the stored flag. Integer BIT-AND is rejected on this release.
    rs_lock-globally_locked = flag( xsdbool( ( ( iv_lock_flag DIV c_lock_global ) MOD 2 ) = 1 ) ).
    rs_lock-locally_locked = flag( xsdbool( ( ( iv_lock_flag DIV c_lock_local ) MOD 2 ) = 1 ) ).
    rs_lock-failed_logon_locked = flag( xsdbool( ( ( iv_lock_flag DIV c_lock_failed ) MOD 2 ) = 1 ) ).
  ENDMETHOD.

  METHOD user_type_fallbacks.
    rt_values = VALUE #(
      ( code = 'A' text = 'Dialog' )
      ( code = 'B' text = 'System' )
      ( code = 'C' text = 'Communications Data' )
      ( code = 'L' text = 'Reference' )
      ( code = 'S' text = 'Service' ) ).
  ENDMETHOD.

  METHOD user_type_text.
    rv_text = zcl_sec_domain_text=>domain_text(
      iv_domain   = 'XUUSTYP'
      iv_code     = iv_user_type
      it_fallback = user_type_fallbacks( ) ).
  ENDMETHOD.

  METHOD password_state_text.
    " Stored as INT1. The signed values -2 and -1 are 254 and 255.
    CASE iv_state.
      WHEN 0.
        rv_text = 'Password can be changed, change is not required'.
      WHEN 1.
        rv_text = 'Initial password, change is required'.
      WHEN 2.
        rv_text = 'Password has expired, change is required'.
      WHEN 3.
        rv_text = 'Password must be changed because it no longer meets the rules'.
      WHEN 254.
        rv_text = 'Password cannot be changed'.
      WHEN 255.
        rv_text = 'Password cannot be changed until the wait period ends'.
      WHEN OTHERS.
        rv_text = |{ iv_state }|.
    ENDCASE.
  ENDMETHOD.

  METHOD hash_version_text.
    CASE to_upper( condense( iv_version ) ).
      WHEN 'A'.
        rv_text = 'Obsolete code version A'.
      WHEN 'B'.
        rv_text = 'MD5, uppercase ASCII'.
      WHEN 'D'.
        rv_text = 'MD5, uppercase UTF-8'.
      WHEN 'E'.
        rv_text = 'Corrected code version D'.
      WHEN 'H'.
        rv_text = 'Generic hash'.
      WHEN 'X'.
        rv_text = 'Password deactivated'.
      WHEN OTHERS.
        rv_text = condense( iv_version ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
