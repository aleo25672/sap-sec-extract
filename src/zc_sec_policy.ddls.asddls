@EndUserText.label: 'Security policy'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_POLICY_QUERY'
define custom entity ZC_SEC_POLICY
{
  key PolicyName        : abap.char(40);
      Client            : abap.clnt;
      Description       : abap.char(60);
      CreatedBy         : abap.char(12);
      CreatedOn         : abap.dec(15,0);
      ChangedBy         : abap.char(12);
      ChangedOn         : abap.dec(15,0);
      AssignedUserCount : abap.int4;
      UsersCounted      : abap.char(1);
}
