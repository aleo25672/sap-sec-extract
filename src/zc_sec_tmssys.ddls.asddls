@EndUserText.label: 'Transport system'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_TMSSYS_QUERY'
define custom entity ZC_SEC_TMSSYS
{
  key DomainName     : abap.char(10);
  key SystemName     : abap.char(10);
      SystemType     : abap.char(1);
      SystemTypeText : abap.char(40);
      TransportGroup : abap.char(10);
      Description    : abap.char(120);
}
