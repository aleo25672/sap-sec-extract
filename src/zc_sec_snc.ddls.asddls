@EndUserText.label: 'SNC name'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_SNC_QUERY'
define custom entity ZC_SEC_SNC
{
  key UserName          : abap.char(12);
      Client            : abap.char(3);
      SncName           : abap.char(255);
      GuiPasswordLogon  : abap.char(1);
      SecuritySystem    : abap.char(8);
      CreatedBy         : abap.char(12);
      CreatedOn         : abap.dats;
      CreatedAt         : abap.tims;
      ChangedBy         : abap.char(12);
      ChangedOn         : abap.dats;
      ChangedAt         : abap.tims;
}
