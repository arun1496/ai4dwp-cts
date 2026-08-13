# All Components and Requirements to Create AVD

This checklist covers what is required to deploy Azure Virtual Desktop successfully.

## 1) Azure platform requirements

- Active Azure subscription
- Supported Azure region for AVD metadata (host pool/workspace/app group)
- Sufficient quota for VM SKU in chosen region

## 2) Identity and access requirements

- Microsoft Entra tenant
- Deployment identity with resource creation permission
- Permission to create role assignments at needed scope
- End-user identities or groups to assign AVD access

Recommended deployment RBAC:
- Owner (simplest)
Or split roles:
- Desktop Virtualization Contributor (AVD objects)
- Virtual Machine Contributor (VM objects)
- Network Contributor (if creating VNet/subnet)
- User Access Administrator (for role assignments)

## 3) Network requirements

- VNet and subnet for session hosts
- DNS and outbound internet path from session hosts to required AVD endpoints
- NSG/Firewall rules that allow required AVD control-plane and broker endpoints

## 4) Core AVD components

- Host pool (Pooled or Personal)
- Application group (Desktop or RemoteApp)
- Workspace
- Session host VMs

For this project:
- Host pool: POOL-FIN-01 (Pooled)
- Load balancing: BreadthFirst
- Max session limit: 5
- App group: Desktop
- Workspace: FinBridge-Workspace

## 5) Session host VM requirements

- Supported Windows image (for example Windows 11 Enterprise multi-session AVD image)
- VM size appropriate for workload
- Security profile if required (Trusted Launch, Secure Boot, vTPM)
- AVD registration path (token + agent/DSC extension)
- Entra sign-in extension when using Entra joined access flow

## 6) Access requirements for users

To connect through AVD client:
- Desktop Virtualization User role at application group scope

To sign in directly to VM:
- Virtual Machine User Login role at VM scope

## 7) Operational requirements

- Monitoring/logging destination (optional but strongly recommended)
- Backup strategy for profiles and user data
- Patch/update strategy for session hosts
- Capacity and scaling strategy

## 8) Common failure points

- Invalid naming (resource group naming rules)
- Missing RBAC rights for role assignment
- Quoting/JSON issues in PowerShell command composition
- Missing connectivity to required AVD endpoints
- Host registration token retrieval/use errors
- Entra join or extension state issues causing host unavailable

