CLASS zcx_sec_access DEFINITION
  PUBLIC
  INHERITING FROM cx_rap_query_provider
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " IF_T100_MESSAGE and IF_T100_DYN_MSG come from CX_RAP_QUERY_PROVIDER.
    DATA filter_name TYPE string READ-ONLY.

    CONSTANTS:
      BEGIN OF not_authorized,
        msgid TYPE symsgid VALUE 'ZSEC_ACCESS',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF not_authorized,
      BEGIN OF filter_not_supported,
        msgid TYPE symsgid VALUE 'ZSEC_ACCESS',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'FILTER_NAME',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF filter_not_supported.

    METHODS constructor
      IMPORTING
        textid      LIKE if_t100_message=>t100key OPTIONAL
        previous    LIKE previous OPTIONAL
        filter_name TYPE string OPTIONAL.
ENDCLASS.


CLASS zcx_sec_access IMPLEMENTATION.
  METHOD constructor.
    super->constructor( previous = previous ).
    me->filter_name = filter_name.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
