@EndUserText.label: 'Profile parameter change'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_PFLCHG_QUERY'
define custom entity ZC_SEC_PFL_CHG
{
  key HostName           : abap.char(32);
  key ParameterName      : abap.char(64);
  key ChangeDate         : abap.dats;
  key ParameterType      : abap.char(1);
  key SystemId           : abap.char(8);
      ParameterState     : abap.char(1);
      ParameterStateText : abap.char(60);
      ParameterTypeText  : abap.char(60);
      ParameterValue     : abap.char(64);
      SecurityRelevant   : abap.char(1);
      SecurityArea       : abap.char(20);
}
