@EndUserText.label: 'System change option'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_SYSCHG_QUERY'
define custom entity ZC_SEC_SYS_CHANGE
{
  key SettingScope     : abap.char(20);
  key ObjectName       : abap.char(30);
      ChangeOption     : abap.char(1);
      ChangeOptionText : abap.char(60);
}
