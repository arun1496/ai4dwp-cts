# Prevention Note

## Selected Process Control
**Intune Ring-0 Pilot with Monday Morning Logon Validation**

- **Control name:** Intune Ring-0 Pilot with Monday Morning Logon Validation
- **Owner:** Endpoint Engineering Change Owner (accountable), with Major Incident Manager as approver for release-to-broad deployment
- **Where it fits in the change process:** Mandatory release gate between Friday deployment completion and Monday broad assignment expansion; broad rollout cannot proceed until this gate passes
- **Trigger condition:** Any floor-targeted endpoint app or policy change scheduled for end-of-week release, especially where user logon path, profile load, shell startup, or desktop baseline may be affected
- **Evidence it checks:**
  1. Pilot cohort of representative users/devices on the target floor (for example: 10-20 devices across role types)
  2. Monday 06:30-08:00 measured sign-in KPIs versus baseline: time to credential acceptance, time to desktop ready, time to first app usable
  3. Shell health checks after logon: required desktop shortcuts present, expected desktop path available, no temporary profile indicators
  4. Change correlation proof: deployed app version, assignment state, install timestamp, reboot state, and rollback readiness status
  5. Pass/fail threshold evidence recorded in the change ticket with screenshots or exported metrics before production go/no-go
- **How it would have prevented or detected the issue earlier:**
  1. It would have exposed the login-delay and missing-shortcut regression in a small, controlled Ring-0 group before full Monday user impact.
  2. Failing KPIs or shell checks would have automatically held broad deployment and triggered rollback/containment before most Floor 6 users logged in.
  3. This turns Monday morning into a controlled validation window instead of a live enterprise discovery window, reducing blast radius and incident severity.
