@EndUserText.label: 'tp parameter'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_TPPAR_QUERY'
define custom entity ZC_SEC_TPPAR
{
  key DomainName      : abap.char(10);
  key ConfigVersion   : abap.numc(4);
  key SystemName      : abap.char(10);
  key OperatingSystem : abap.char(10);
  key DatabaseSystem  : abap.char(3);
  key ParameterName   : abap.char(60);
      ParameterValue  : abap.char(200);
}
