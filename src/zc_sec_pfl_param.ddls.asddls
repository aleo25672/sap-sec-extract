@EndUserText.label: 'Security profile parameter'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SEC_PFL_PARAM_QUERY'
define custom entity ZC_SEC_PFL_PARAM
{
  key ApplicationServer     : abap.char(64);
  key ParameterName         : abap.string(0);
      KernelDefaultValueRaw : abap.string(0);
      KernelDefaultValue    : abap.string(0);
      InstanceProfileValue  : abap.string(0);
      Description           : abap.string(0);
      ParameterType         : abap.int4;
      Unit                  : abap.string(0);
      RestrictionValues     : abap.string(0);
      DynamicallyChangeable : abap.char(1);
      ParameterStatus       : abap.int4;
      StatusText            : abap.string(0);
      SecurityRelevant      : abap.char(1);
      SecurityArea          : abap.char(20);
      SystemId              : abap.char(8);
}
