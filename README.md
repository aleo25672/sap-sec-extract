# SAP security settings extract

Read-only OData V4 service for the profile parameters shown by report RSPFPAR, plus the four settings that sit beside that report and change an IT general control conclusion: security policies, client settings, system change options, and parameter history.

The service returns raw values and, where a value is derived, the derivation. The caller compares a policy with the application server and decides whether a production client is locked.

Activate this package on S/4HANA 1909 (ABAP platform 7.54) or later, on-premise or private cloud. It is not ABAP Cloud. `CL_SPFL_PROFILE_PARAMETER` is the class RSPFPAR uses, and it is not a released Cloud API.

The same repository contains a second service, `ZAPI_SEC_ACCESS`, for the account and assignment population. That service is documented under [Security access extract](#security-access-extract).

## Entity sets

Published service:

`/sap/opu/odata4/sap/zapi_sec_settings/srvd_a2x/sap/zapi_sec_settings/0001/`

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

The service binding is not in the repository. abapGit creates a binding through a workbench BAdI that has no implementation on S/4HANA 1909, and that import stops the pull. Create it in ABAP Development Tools: binding `ZAPI_SEC_SETTINGS`, type OData V4 - Web API, service `ZAPI_SEC_SETTINGS`, version `0001`, then publish it. The binding and the service definition share the name and are different object types.

A pull of the current repository does not import a binding, so that BAdI error does not occur. On a later pull, keep the binding when abapGit offers to remove objects that are not in the repository.

Run ABAP Unit on package `ZSEC_SETTINGS`. The tests cover security classification, policy value origin, domain-text fallbacks, filter and paging, lock-flag bits, password state, and an authorization failure that does not read profile parameters or access rows. They do not read the kernel or the database.

`examples/` holds one contract sample per entity set. The values are illustrative.

## Security access extract

Read-only OData V4 service for the accounts in the logon client and for the roles and profiles assigned to them. The caller decides which accounts are in scope for an access review. The service returns the stored assignment, including a role the user received through a composite role or through HR organizational management.

Published service:

`/sap/opu/odata4/sap/zapi_sec_access/srvd_a2x/sap/zapi_sec_access/0001/`

| Entity set | Source | What a row is |
| --- | --- | --- |
| `Users` | `USR02`, `USREFUS` | One user in the logon client |
| `RoleAssignments` | `AGR_USERS` | One role on one user, with validity dates |
| `ProfileAssignments` | `UST04`, and the reference user's profiles | One profile on one user |
| `Roles` | `AGR_DEFINE`, `AGR_TEXTS` line `00000` | The role header and its first description line |
| `RoleHierarchy` | `AGR_AGRS` | One composite role and one single role |

`Users` carries the user type, user group, validity, the raw `USR02-UFLAG`, the three lock bits, the password state, the password-hash version, the last logon, who created the user, the security policy, and the reference user. `SecurityPolicy` joins to `SecurityPolicies.PolicyName` on the settings service. `Client` is the logon client on every row and joins to `ClientSettings`.

The password hash is not in the extract. The person name and the email address are not in the extract. `I_User` is not a source: a normal read of that view returns no rows, and the account fields the review uses are on `USR02`.

`UserType` is `A` dialog, `B` system, `C` communications, `L` reference, or `S` service. `UserTypeText` is the domain text, with those English names when the domain text is missing.

`LockFlag` is the raw `USR02-UFLAG`. The three flags are the bits inside it: `32` globally locked by the administrator, `64` locally locked by the administrator, and `128` locked by failed logons. A stored value can combine those bits. A stray `+1` left by a maintenance lock does not change them, so `33` is still globally locked.

`PasswordState` is the stored integer. `0` can be changed and does not have to be. `1` is an initial password. `2` has expired. `3` no longer meets the current rules. `254` and `255` are the stored forms of `-2` and `-1`: the password cannot be changed, or it cannot be changed until the wait period ends. `PasswordHashVersion` is `USR02-CODVN`. `H` is the generic hash. `X` means the password is deactivated. Older codes stay on the row so the caller can see them. The hash value itself is not returned.

`ProfileSource` is `Assigned` for a row in `UST04` and `ReferenceUser` for a profile of the user named in `ReferenceUser`. The same profile can appear twice when the user has it directly and also inherits it. `RoleAssignments` already contains the single roles that came from a composite: `FromCompositeRole` is `AGR_USERS-COL_FLAG`, and `FromOrgManagement` is `AGR_USERS-ORG_FLAG`. `Exclusive` is `AGR_USERS-EXCLUDE`. `RoleHierarchy` is how the caller finds which composite contains a single role. Two composites can contain the same single role.

`Roles.Description` is `AGR_TEXTS` line `00000` in the logon language. When that line is missing, the English line is used. `ParentRole` is `AGR_DEFINE-PARENT_AGR`.

### Authorization

A failed check is an OData error. The response is not an empty list. Each check requires the authorization for value `*`, so a caller who can display only some user groups or some roles does not receive a partial population.

| Entity sets | Check |
| --- | --- |
| `Users` | `S_USER_GRP` activity 03 for user group `*` |
| `RoleAssignments` | `S_USER_GRP` activity 03 for user group `*`, and `S_USER_AGR` activity 03 for role `*` |
| `ProfileAssignments` | `S_USER_GRP` activity 03 for user group `*`, and `S_USER_PRO` activity 03 for profile `*` |
| `Roles`, `RoleHierarchy` | `S_USER_AGR` activity 03 for role `*` |

### Filters

The same range filters, `$select`, `$orderby`, `$top`, `$skip`, and `$count` as the settings service. A filter on an unknown property is an error (message 002 of `ZSEC_ACCESS`).

```http
GET .../Users?$filter=UserType eq 'A' and GloballyLocked eq 'X'
GET .../RoleAssignments?$filter=UserId eq 'JSMITH' and FromCompositeRole eq 'X'
GET .../ProfileAssignments?$filter=ProfileSource eq 'ReferenceUser'
GET .../Roles?$filter=ParentRole eq 'Z_FI_TEMPLATE'
GET .../RoleHierarchy?$filter=CompositeRole eq 'Z_FI_COMPOSITE'
```

A read is the logon client. There is no RFC to other clients or other application servers.

### Import

The access objects are in package `ZSEC_SETTINGS`, in the same abapGit repository as the settings extract. Create the service binding in ABAP Development Tools: binding `ZAPI_SEC_ACCESS`, type OData V4 - Web API, service `ZAPI_SEC_ACCESS`, version `0001`, then publish it. Keep the binding when abapGit offers to remove objects that are not in the repository.

## Repositories

- Cursor: [evolver/sap-sec-extract](https://cursor.com/codebase/evolver/sap-sec-extract)
- GitHub: [aleo25672/sap-sec-extract](https://github.com/aleo25672/sap-sec-extract)

The GitHub repository is public. The Cursor remote stays `origin`. GitHub is remote `github`.
