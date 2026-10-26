@EndUserText.label: 'Security access profile assignment'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_PROF_ASSIGN_QUERY'
define custom entity ZC_SEC_PROF_ASSIGN
{
  key UserId         : abap.char(12);
  key ProfileName    : abap.char(12);
  key ProfileSource  : abap.char(13);
      Client         : abap.char(3);
      ReferenceUser  : abap.char(12);
}
