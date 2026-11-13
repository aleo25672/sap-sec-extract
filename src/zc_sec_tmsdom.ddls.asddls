@EndUserText.label: 'Transport domain'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_TMSDOM_QUERY'
define custom entity ZC_SEC_TMSDOM
{
  key DomainName       : abap.char(10);
      ControllerSystem : abap.char(10);
      Description      : abap.char(120);
}
