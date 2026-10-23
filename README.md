# SAP security settings extract

Read-only OData V4 service for the profile parameters shown by report RSPFPAR, plus the four settings that sit beside that report and change an IT general control conclusion: security policies, client settings, system change options, and parameter history.

The service returns raw values and, where a value is derived, the derivation. The caller compares a policy with the application server and decides whether a production client is locked.

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

## IT general controls

RSPFPAR is the current profile of this application server. These four entity sets are the settings that report does not show. Read together, they are the evidence for two SOX IT general controls: access to programs and data, and change management.

| Entity sets | IT general control | What it adds to RSPFPAR |
| --- | --- | --- |
| `SecurityPolicies`, `SecurityPolicyAttributes` | Access to programs and data | Password and logon rules for users who have a security policy |
| `ClientSettings` | Change management | Whether this client allows customizing, repository changes, a client copy, or eCATT |
| `SystemChangeOptions` | Change management | Whether the system as a whole allows repository and cross-client changes |
| `ProfileParameterChanges` | Change management, and access to programs and data | Which security parameters changed, on which host, and on which date |

### Security policies

`SecurityPolicies` and `SecurityPolicyAttributes` are transaction SECPOL for the logon client. A policy is assigned to a user in SU01. For every attribute that policy covers, the user follows the policy instead of the `login/*` profile parameters.

`EffectiveValue` is the stored attribute when `ValueOrigin` is `Policy`. It is the kernel default when `ValueOrigin` is `KernelDefault`. An attribute the policy does not store applies that kernel default, including when this server has a stricter instance profile. SAP documents that as the designed behavior (KBA 3636563, KBA 3075533). Parameters with no SECPOL attribute, such as `login/no_automatic_user_sapstar`, stay on the instance profile for those users. Users with no policy stay on the instance profile.

The access-control test joins `SecurityPolicyAttributes.ProfileParameter` to `SecurityProfileParameters.ParameterName`. On the profile row, the value in force on this server is `InstanceProfileValue` when that field is filled, and `KernelDefaultValue` when it is empty. The caller compares that value with `EffectiveValue`. `AssignedUserCount` shows how many users in this client have the policy. User ids are not in the extract.

### Client settings

`ClientSettings` is transaction SCC4, one row per client in `T000`.

The row says whether the client allows client-specific customizing, cross-client customizing, repository changes, a client copy, and eCATT. `LastChangedBy` and `LastChangedOn` are the last time those switches were saved, which is the evidence that a production client was opened. They are not a history of every open and close.

A production client is usually role `P`, client-specific changes `2` (no changes allowed), cross-client changes `3` (no repository and no cross-client customizing), copy protection `X` or `L`, and eCATT not allowed. The service returns the codes and the texts.

Table logging of the client record is `TableChangeLogging` together with profile parameter `rec/client` on `SecurityProfileParameters`. The logging flag is the same on every client row. `rec/client` stays on the profile entity.

### System change options

`SystemChangeOptions` is transaction SE06. It is one setting for the whole system, shared by every client. SCC4 cannot close it.

The `Global` row is modifiable or not modifiable. While it is not modifiable, software components and namespaces cannot be changed. The service still returns those component and namespace rows as they are stored. The caller reads the global `ChangeOption` and applies that lock.

A production client can be closed in SCC4 while this global row is still modifiable. The change-management conclusion uses `ClientSettings` and `SystemChangeOptions` together.

### Profile parameter changes

`ProfileParameterChanges` is transaction TU02, table `PAHI`. A row is a parameter value on a host on a date. `SecurityRelevant` uses the same classification as RSPFPAR, so a change to `login/*` or another security prefix is marked on the history row. Join `ParameterName` to `SecurityProfileParameters` for the current value on this server.

This is the population of security-parameter changes in the audit period. The store keeps a day and a 64-character value. It does not keep the user or the time. The account that saved an RZ10 change is in the profile comment. A dynamic RZ11 change is system log message Q19. The newest day appears after the TU02 changelog update.

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

Pull the repository with abapGit into package `ZSEC_SETTINGS`, master language English, and activate the imported objects.

The service binding is not in the repository. abapGit creates it through a workbench BAdI that has no implementation on S/4HANA 1909, which stops the pull with "No implementation was selected for the current BAdI". Create the binding in ABAP Development Tools after the pull:

1. If a failed binding `ZAPI_SEC_SETTINGS_O4` already exists, delete it.
2. Create service binding `ZAPI_SEC_SETTINGS_O4`, binding type OData V4 - Web API, service `ZAPI_SEC_SETTINGS`, version `0001`.
3. Publish the binding locally.

On a later pull, keep `ZAPI_SEC_SETTINGS_O4` if abapGit offers to remove objects that are not in the repository.

Run ABAP Unit on package `ZSEC_SETTINGS`. The tests cover security classification, policy value origin, domain-text fallbacks, filter and paging, and an authorization failure that does not read profile parameters. They do not read the kernel or the database.

`examples/` holds one contract sample per entity set. The values are illustrative.

## Repositories

- Cursor: [evolver/sap-sec-extract](https://cursor.com/codebase/evolver/sap-sec-extract)
- GitHub: [aleo25672/sap-sec-extract](https://github.com/aleo25672/sap-sec-extract)

The GitHub repository is public. The Cursor remote stays `origin`. GitHub is remote `github`.
