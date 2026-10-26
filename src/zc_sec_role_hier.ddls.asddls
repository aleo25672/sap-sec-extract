@EndUserText.label: 'Security access role hierarchy'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_ROLE_HIER_QUERY'
define custom entity ZC_SEC_ROLE_HIER
{
  key CompositeRole : abap.char(30);
  key SingleRole    : abap.char(30);
      Client        : abap.clnt;
}
