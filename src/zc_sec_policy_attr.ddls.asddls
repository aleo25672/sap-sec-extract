@EndUserText.label: 'Security policy attribute'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_POLICY_ATTR_QUERY'
define custom entity ZC_SEC_POLICY_ATTR
{
  key PolicyName       : abap.char(40);
  key AttributeName    : abap.char(40);
      ValueOrigin      : abap.char(13);
      EffectiveValue   : abap.int4;
      DefaultValue     : abap.int4;
      ProfileParameter : abap.char(60);
      Description      : abap.char(60);
      Client           : abap.clnt;
}
