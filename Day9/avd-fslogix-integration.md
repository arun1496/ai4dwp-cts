# FSLogix Integration with Azure Virtual Desktop

This guide explains purpose, requirements, and integration steps in simple language.

## 1) Purpose of FSLogix in AVD

FSLogix solves user profile consistency in non-persistent or pooled desktops.

Without FSLogix:
- Users can lose app settings between sessions.
- Outlook/OneDrive/Teams behavior can be inconsistent.

With FSLogix:
- User profile is stored in a profile container (VHD/VHDX) on network storage.
- User gets the same profile experience across session hosts.
- Sign-in and app behavior are more predictable.

## 2) Requirements for FSLogix integration

### Licensing and platform
- Eligible Microsoft licenses for AVD and FSLogix use
- Session hosts joined to supported identity model (Entra/AD depending design)

### Storage
- SMB file share location for profile containers, usually:
  - Azure Files (Premium recommended for production)
  - Azure NetApp Files (large or performance-heavy environments)
- Enough IOPS/throughput and capacity for user count

### Network and security
- Session hosts must reach the SMB endpoint
- Port 445 path allowed
- DNS resolves storage endpoint correctly

### Access model
- Users need permissions to create/use their profile container
- Recommended NTFS + share permissions aligned to least privilege

### Session host prerequisites
- FSLogix agent installed on each session host
- Registry or policy settings configured for profile container path and behavior

## 3) Integration architecture (high level)

1. Create storage account and file share for profiles.
2. Configure identity-aware access to file share.
3. Set share and NTFS permissions.
4. Install FSLogix agent on each session host.
5. Configure FSLogix profile settings (VHDLocations and core policy).
6. Reboot or refresh policy on hosts.
7. Validate profile container is created at first user sign-in.

## 4) Typical FSLogix settings to configure

Common settings:
- Enabled = 1
- VHDLocations = \\fileserver\profileshare
- DeleteLocalProfileWhenVHDShouldApply = 1
- FlipFlopProfileDirectoryName = 1
- IsDynamic = 1

Optional depending standards:
- VolumeType = VHDX
- SizeInMBs for profile limits
- Redirections.xml for excluding noisy/cache folders

## 5) Recommended implementation flow for this AVD project

1. Build and validate AVD host pool first (already done in this project).
2. Stand up Azure Files Premium share in same or peered region.
3. Configure identity-based SMB access and permissions.
4. Install FSLogix on sh-fin-01.
5. Apply FSLogix registry/policy settings.
6. Test with one pilot user (P04).
7. Validate:
- Profile container is created
- Reconnect lands with same profile state
- Outlook/OneDrive behavior is stable

## 6) Validation checklist

- User can sign in to AVD desktop.
- FSLogix profile container file appears for user.
- No temporary profile events.
- Re-login preserves desktop/app data.
- Logoff/sign-in times are acceptable.

## 7) Common FSLogix issues and remediation

Issue: Temporary profile loaded.  
Likely cause: Share/NTFS permission mismatch or container lock problem.  
Remediation: Validate permissions and ensure single active lock.

Issue: Container not created.  
Likely cause: Wrong VHDLocations path or SMB access blocked.  
Remediation: Test path access from session host and check port 445/network route.

Issue: Slow sign-in.  
Likely cause: Storage performance bottleneck or oversized profile.  
Remediation: Move to higher-performance storage tier and tune exclusions.

Issue: Office cache/profile growth.  
Likely cause: No profile optimization policy.  
Remediation: Use exclusions/redirections and right-size profile strategy.

## 8) Security best practices

- Use least privilege for share and NTFS ACLs.
- Restrict storage network access (private endpoints where possible).
- Enable monitoring for profile failures and unusual profile growth.
- Keep FSLogix agent updated and aligned with Microsoft support baseline.

