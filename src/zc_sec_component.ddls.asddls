@EndUserText.label: 'Software component'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_COMPONENT_QUERY'
define custom entity ZC_SEC_COMPONENT
{
  key Component            : abap.char(30);
      Release              : abap.char(10);
      SupportPackageLevel  : abap.char(10);
      ComponentType        : abap.char(1);
      ComponentTypeText    : abap.char(60);
}
