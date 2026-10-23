CLASS zcl_sec_policy_derive DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS:
      c_policy TYPE string VALUE 'Policy',
      c_kernel TYPE string VALUE 'KernelDefault'.

    CLASS-METHODS origin
      IMPORTING
        iv_persisted     TYPE abap_bool
      RETURNING
        VALUE(rv_origin) TYPE string.

    CLASS-METHODS effective
      IMPORTING
        iv_persisted       TYPE abap_bool
        iv_stored          TYPE i
        iv_default         TYPE i
      RETURNING
        VALUE(rv_effective) TYPE i.
ENDCLASS.


CLASS zcl_sec_policy_derive IMPLEMENTATION.
  METHOD origin.
    IF iv_persisted = abap_true.
      rv_origin = c_policy.
    ELSE.
      rv_origin = c_kernel.
    ENDIF.
  ENDMETHOD.

  METHOD effective.
    IF iv_persisted = abap_true.
      rv_effective = iv_stored.
    ELSE.
      rv_effective = iv_default.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
