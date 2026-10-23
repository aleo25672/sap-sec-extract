# SAP security settings extract

Read-only OData V4 service for the profile parameters shown by report RSPFPAR, plus the security policies, client settings, and system change options that sit beside them.

The service returns raw values and, where a value is derived, the derivation. It does not compare a policy with the application server, and it does not decide whether a production client is locked. That comparison belongs in the caller.

Activate this package on S/4HANA 1909 (ABAP platform 7.54) or later, on-premise or private cloud. It is not ABAP Cloud. `CL_SPFL_PROFILE_PARAMETER` is the class RSPFPAR uses, and it is not a released Cloud API.

## Entity sets

Published service:

`/sap/opu/odata4/sap/zapi_sec_settings_o4/srvd/sap/zapi_sec_settings/0001/`

| Entity set | Source | What a row is |
| --- | --- | --- |
| `SecurityProfileParameters` | RSPFPAR, current application server | Kernel default and the user-defined value, side by side |
| `SecurityPolicies` | SECPOL, logon client | Policy header and assigned-user count |
| `SecurityPolicyAttributes` | SECPOL attributes | Effective value and whether it was stored on the policy or taken from the kernel default |
| `ClientSettings` | SCC4 / `T000` | One row per client |
| `SystemChangeOptions` | SE06 | Global row, software components, and namespaces |
| `ProfileParameterChanges` | TU02 / `PAHI` | Parameter history for a host and a date |

`SecurityProfileParameters` keeps three value fields:

- `KernelDefaultValueRaw` is the RSPFPAR column "System Default Value (Unsubstituted Form)".
- `KernelDefaultValue` is the substituted kernel default.
- `InstanceProfileValue` is the RSPFPAR column "User-Defined Value". It is filled from `DEFAULT.PFL`, the instance profile, or a dynamic RZ11 change. It is empty when this server is still on the kernel default.

The service does not choose which of those is in force.

`SecurityPolicyAttributes.ValueOrigin` is `Policy` when `SEC_POLICY_RT` stores the attribute, and `KernelDefault` when it does not. `EffectiveValue` is the stored value or `SEC_POLICY_ATTR-DEFAULT_VALUE`. `ProfileParameter` is the join key to `SecurityProfileParameters.ParameterName`. An attribute the policy does not store applies the kernel default to assigned users, not the instance profile value. SAP documents that as the designed behavior (KBA 3636563, KBA 3075533). Users with no policy still use the instance profile. Parameters with no SECPOL attribute, such as `login/no_automatic_user_sapstar`, also stay on the instance profile.

`DISABLE_PASSWORD_LOGON` also supersedes `login/password_logon_usergroup`. The payload carries the single profile parameter name stored on `SEC_POLICY_ATTR`.

A landscape pull is one call per application server. Policy and client data are for the logon client (`sap-client`) or, for `T000`, every client. There is no RFC to other instances.

## Authorization

| Entity sets | Check |
| --- | --- |
| `SecurityProfileParameters`, `ProfileParameterChanges` | `S_ADMI_FCD` / `PADM` |
| `SecurityPolicies`, `SecurityPolicyAttributes` | `S_SECPOL` activity 03 |
| `ClientSettings` | `S_TABU_NAM` for `T000`, activity 03 |
| `SystemChangeOptions` | `S_CTS_ADMI` function `TABL`. Report `RSWBO004` uses that function for the SE06 display. Confirm it on the target system. |

A failed check is an OData error. The response is not an empty list.

`AssignedUserCount` is filled only when `S_USER_GRP` activity 03 is granted for user group `*`. Otherwise `UsersCounted` is blank and the count is empty. User ids are not returned.

## Filters

Range filters, `$select`, `$orderby`, `$top`, `$skip`, and `$count`. Every property of an entity accepts a range filter. A filter on an unknown property is an error (message 004). Character comparisons are case-insensitive, and a blank flag matches an empty value. `gt`, `ge`, `lt`, `le`, and `bt` compare integers numerically when both sides are integers, so 10 is greater than 2.

```http
GET .../SecurityProfileParameters?$filter=SecurityRelevant eq 'X'&$count=true
GET .../SecurityProfileParameters?$filter=startswith(ParameterName,'login/')
GET .../SecurityPolicyAttributes?$filter=ValueOrigin eq 'KernelDefault'
GET .../ClientSettings?$filter=ClientRole eq 'P'
GET .../SystemChangeOptions?$filter=SettingScope eq 'Global'
GET .../ProfileParameterChanges?$filter=ChangeDate ge 2026-01-01 and ParameterName eq 'login/min_password_lng'
```

`ProfileParameterChanges` pushes the host, parameter name, date, and parameter type filters into the `PAHI` select. Character filters are applied with `upper`, so the name match is case-insensitive. An empty range does not restrict the select. Pass a date or name filter. The table also holds database and operating-system parameters. The entity key is host, parameter name, date, parameter type, and system id, which is the `PAHI` key. `PAHI-SYSTEMID` is CHAR 2; the property is 8 characters so the value is not clipped. `ParameterValue` is 64 characters. The row has a date and no time, and it has no user. The newest day appears only after the TU02 changelog update.

`ParameterStatus` and `StatusText` repeat the raw `SPFL_PARAMETER_LIST-STATE`. The numeric legend is release-specific, so the service does not translate it.

## Import

Pull the repository with abapGit into package `ZSEC_SETTINGS`, master language English.

If the service binding object does not deserialize, create it in ABAP Development Tools:

1. Activate the message class, exception, interfaces, classes, and custom entities.
2. Create service definition `ZAPI_SEC_SETTINGS` from `src/zapi_sec_settings.srvd.srvdsrv`.
3. Create service binding `ZAPI_SEC_SETTINGS_O4`, binding type OData V4 - Web API, service `ZAPI_SEC_SETTINGS`, version `0001`.
4. Publish the binding locally.

Run ABAP Unit on package `ZSEC_SETTINGS`. The tests cover security classification, policy value origin, domain-text fallbacks, filter and paging, and an authorization failure that does not read profile parameters. They do not read the kernel or the database.

`examples/` holds one contract sample per entity set. The values are illustrative.

## Repositories

- Cursor: [evolver/sap-sec-extract](https://cursor.com/codebase/evolver/sap-sec-extract)
- GitHub: [aleo25672/sap-sec-extract](https://github.com/aleo25672/sap-sec-extract)

The GitHub repository is public. The Cursor remote stays `origin`. GitHub is remote `github`.
