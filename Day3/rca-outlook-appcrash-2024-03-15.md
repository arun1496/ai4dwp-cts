# RCA: Outlook Application Crash Incident (2024-03-15)

## Incident Summary
- Application: OUTLOOK.EXE (Microsoft Outlook)
- Time window reviewed: 09:14:22 to 09:18:05
- Log source: Windows Application log
- Primary symptoms: Outlook crashes repeatedly within minutes of launch.

## Event Timeline (Reconstructed in Plain English)
1. At 09:13:44, Outlook was launched (from the Event 1000 process start time).
2. At 09:14:22, Outlook crashed (Event ID 1000, Source: Application Error).
3. At 09:17:45, Outlook crashed again with the same fault signature (Event ID 1000).
4. At 09:18:01, Windows Error Reporting recorded an APPCRASH bucket for the failure (Event ID 1001).
5. At 09:18:05, .NET Runtime logged an unhandled exception and process termination (Event ID 1026), specifically System.AccessViolationException.

## What the Events Mean
- Event 1000 confirms process crash details from Windows application fault handling.
- Event 1001 confirms crash telemetry was generated and grouped as APPCRASH.
- Event 1026 confirms the process ended due to an unhandled .NET exception.

## Most Likely Cause
Most likely cause: Outlook encountered invalid memory access (access violation) during runtime, likely from an unstable code path in Outlook or an interacting component (commonly an add-in), resulting in repeated process termination.

## Evidence Supporting This Cause
1. Repeated identical crash signature:
- Faulting application: OUTLOOK.EXE (same version 16.0.17126.20132)
- Faulting module: KERNELBASE.dll (same version 10.0.22621.3155)
- Exception code: 0xc0000005
- Fault offset: 0x000000000003a4b2

2. Crash recurs shortly after launch:
- First run starts at 09:13:44 and crashes at 09:14:22 (about 38 seconds later), indicating failure during startup/initialization workflows.
- Second crash occurs minutes later with same signature, indicating reproducibility rather than a one-off transient.

3. .NET exception aligns with memory corruption/access fault behavior:
- Event 1026 reports unhandled System.AccessViolationException.
- AccessViolationException is consistent with invalid memory access and aligns with 0xc0000005 from Event 1000.

4. Windows Error Reporting confirms APPCRASH classification:
- Event 1001 shows APPCRASH with a persistent fault bucket, supporting a recurring known crash pattern.

## RCA Statement
Outlook repeatedly crashed because it hit an access violation (0xc0000005), with a stable and repeatable fault signature in KERNELBASE.dll and an accompanying unhandled System.AccessViolationException. The repeating pattern strongly indicates a deterministic defect path (application/add-in interaction during initialization), not random user behavior.

## Confidence and Limitations
- Confidence: Medium-High.
- Limitation: No crash dump, add-in list, or Office diagnostic logs were provided, so root trigger attribution (core Outlook code vs specific add-in) cannot be proven conclusively from these events alone.

## Suggested Next Validation Steps
1. Launch Outlook in safe mode and compare stability.
2. Disable COM add-ins in stages to identify triggering component.
3. Collect and inspect WER crash dump for call stack correlation.
4. Verify Office update channel/patch history around build 16.0.17126.20132.
5. Test with a clean Outlook profile to exclude profile corruption.
