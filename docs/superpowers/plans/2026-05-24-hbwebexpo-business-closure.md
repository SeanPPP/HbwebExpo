# HbwebExpo Business Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the five known frontend gaps in priority order: staff detail schedule/records, attendance punch verification, warehouse product-location quantity flow, warehouse Chinese copy polish, and employee-profile image upload.

**Architecture:** Keep each gap in its own module boundary and avoid broad page rewrites. Phase 1 workers own independent business flows with disjoint write sets; Phase 2 runs after Phase 1 integration so locale and shared upload changes do not collide.

**Tech Stack:** Expo Router, React Native Paper, TypeScript, TanStack Query, Zustand, existing `apiClient`, existing i18next locale files.

---

## Execution Order

1. **Phase 1, parallel:** Task 1 staff detail schedule/records, Task 2 attendance punch verification, Task 3 warehouse location quantity flow.
2. **Phase 1 integration:** review agent patches, run typecheck, reconcile API contracts with backend availability.
3. **Phase 2, sequential or parallel if files remain disjoint:** Task 4 warehouse Chinese copy polish, Task 5 employee profile image upload.
4. **Final verification:** run targeted tests, `npm exec -- tsc --noEmit`, and a manual route smoke checklist.

## Current Dependency Boundary

- Installed and usable now: `expo-camera`, `expo-file-system`.
- Not installed now: `expo-location`, `expo-image-picker`, `expo-network`, `expo-media-library`.
- Therefore Task 2 must not assume GPS/network packages are available unless a separate dependency change is approved.
- Therefore Task 5 should first use camera capture and signed upload; gallery picker can be a later dependency-backed enhancement.

## Implementation Status

- Task 1 completed by gpt-5.4 Worker A: staff detail now has in-page personal, schedule, and records sections. Frontend endpoints are prepared for `/react/v1/attendance/employees/{userGuid}/week` and `/react/v1/attendance/employees/{userGuid}/records`; missing backend support is shown as a localized error state.
- Task 2 completed by gpt-5.4 Worker B: punch verification state is displayed and submitted in the punch payload without adding new dependencies. True GPS/native network capture still requires approved `expo-location` / `expo-network` dependency work.
- Task 3 completed by gpt-5.4 Worker C: warehouse product-location binding now includes an initial quantity input, validation, and request payload support. Backend must persist `initialQuantity` for the quantity to become authoritative.
- Task 4 completed locally after Worker C: warehouse Chinese status labels and remaining `Bin` copy were localized.
- Task 5 completed by gpt-5.4 Worker D: employee profile images now use camera capture and signed upload UI. Frontend expects `POST /api/EmployeeProfiles/me/image-upload-signature`; missing backend support is shown as a localized error state.

## Task 1: Staff Detail Schedule And Records

**Owner:** Worker A.

**Problem:** `app/staff/[userGuid].tsx` shows `个人信息 / 排班 / 记录`, but the schedule and record tabs only navigate to the generic attendance page. The user expects employee-specific detail inside the staff workflow.

**Files:**
- Modify: `HbwebExpoApp/app/staff/[userGuid].tsx`
- Create: `HbwebExpoApp/src/modules/users/staff-attendance-api.ts`
- Create: `HbwebExpoApp/src/modules/users/staff-attendance-types.ts`
- Modify: `HbwebExpoApp/src/modules/users/index.ts`
- Modify: `HbwebExpoApp/src/modules/users/types.ts` only if existing profile data lacks fields needed by the staff detail screen.
- Modify: `HbwebExpoApp/src/locales/zh/screens/userManagement.json`
- Modify: `HbwebExpoApp/src/locales/en/screens/userManagement.json`

**Implementation contract:**
- Keep `个人信息` as the default tab.
- Make `排班` render the selected employee's weekly schedule in the same staff detail page.
- Make `记录` render the selected employee's recent attendance punches/leave/approval records in the same staff detail page.
- If backend endpoints are missing, add frontend API functions with clearly named endpoint paths that match the existing attendance controller naming style, and make the UI show a real error/empty state instead of silently redirecting.
- Do not move staff profile editing into this task.

**Steps:**
- [ ] Inspect `app/staff/[userGuid].tsx` and replace the current `openSchedule` redirect pattern with local tab state: `personal`, `schedule`, `records`.
- [ ] Add typed API functions in `src/modules/users/staff-attendance-api.ts` for employee schedule and record queries. Prefer existing endpoints if present in the backend contract; otherwise use explicit paths such as `/attendance/employees/{userGuid}/week` and `/attendance/employees/{userGuid}/records`.
- [ ] Add or reuse normalization helpers so schedule data is converted into existing `AttendanceSchedule` records and records are displayed with existing status translation keys.
- [ ] Add loading, empty, retry, and error states for both new tabs.
- [ ] Add zh/en locale keys under `userManagement.detail.schedule` and `userManagement.detail.records`.
- [ ] Run `npm exec -- tsc --noEmit`.

**Acceptance:**
- Opening a staff card keeps the user on `/staff/[userGuid]`.
- Tapping `排班` does not leave the detail screen.
- Tapping `记录` does not leave the detail screen.
- Missing backend data produces a visible localized empty/error state.

## Task 2: Attendance Punch Verification

**Owner:** Worker B.

**Problem:** `TodayPunchCard` displays store/timezone placeholders as location/network verification. The UI itself says the verification is not connected.

**Files:**
- Modify: `HbwebExpoApp/app/(tabs)/attendance.tsx`
- Modify: `HbwebExpoApp/src/components/attendance/TodayPunchCard.tsx`
- Modify: `HbwebExpoApp/src/modules/attendance/api.ts`
- Modify: `HbwebExpoApp/src/modules/attendance/types.ts`
- Create if useful: `HbwebExpoApp/src/modules/attendance/use-punch-verification.ts`
- Modify: `HbwebExpoApp/app.json` only if new native permission text is required.
- Modify: `HbwebExpoApp/src/locales/zh/screens/attendance.json`
- Modify: `HbwebExpoApp/src/locales/en/screens/attendance.json`

**Implementation contract:**
- Collect and display actual frontend verification state before punch submission where Expo supports it.
- At minimum, support location permission state, latitude/longitude availability, and a clear network state from reachable frontend data.
- Send verification payload with `punchAttendance`.
- Do not block punching permanently when permission is denied; surface a warning and send a payload that lets backend decide.
- Remove the "not connected yet" user-facing copy once a real verification state is displayed.

**Steps:**
- [ ] Check whether `expo-location` is installed. If it is not installed, do not add a dependency in the worker without coordinator approval; implement the hook behind an adapter and report the dependency requirement.
- [ ] Extend `AttendancePunch` request typing to include `locationLatitude`, `locationLongitude`, `locationAccuracy`, `locationPermissionStatus`, and `networkVerificationStatus`.
- [ ] Add a hook that resolves verification state on attendance screen focus and before punch.
- [ ] Update `TodayPunchCard` props to receive verification state and render status chips: available, permission denied, unavailable, unknown.
- [ ] Update `punchAttendance` call sites to include verification payload.
- [ ] Add zh/en locale keys for permission denied, unavailable, captured, and sent-for-review states.
- [ ] Run `npm exec -- tsc --noEmit`.

**Acceptance:**
- The attendance page no longer claims location/network are placeholders.
- The punch button can submit a payload including verification fields.
- Denied permissions show a localized warning rather than a broken screen.

## Task 3: Warehouse Location Quantity Flow

**Owner:** Worker C.

**Problem:** The warehouse location bind modal explicitly says initial quantity is unsupported. That leaves product-location binding incomplete for warehouse operations.

**Files:**
- Modify: `HbwebExpoApp/app/(tabs)/warehouse.tsx`
- Modify: `HbwebExpoApp/src/modules/warehouse/api.ts`
- Modify: `HbwebExpoApp/src/modules/warehouse/types.ts`
- Modify: `HbwebExpoApp/src/locales/zh/screens/warehouse.json`
- Modify: `HbwebExpoApp/src/locales/en/screens/warehouse.json`

**Implementation contract:**
- Replace the unsupported message with an initial quantity input.
- Send quantity with product-location bind action if backend supports it.
- If backend does not yet support quantity, keep the field in UI state but fail gracefully with a localized message that explains backend support is required.
- Preserve existing product lookup, scan-to-bind, unbind, create location, edit location, and print flows.

**Steps:**
- [ ] Add `initialQuantity` state to the bind modal, defaulting to `"0"` or an existing product count if the backend returns one.
- [ ] Validate the quantity as a non-negative number before bind.
- [ ] Extend `bindProductToLocation` request payload to include `initialQuantity`.
- [ ] Update the bind modal copy to describe quantity input rather than unsupported mobile behavior.
- [ ] Add zh/en locale keys for invalid quantity and backend quantity unsupported.
- [ ] Run `npm exec -- tsc --noEmit`.

**Acceptance:**
- The bind modal has a quantity input.
- Confirm bind validates the quantity.
- Existing scan/search/select-to-bind behavior remains intact.

## Task 4: Warehouse Chinese Copy Polish

**Owner:** Phase 2 worker after Task 3 merges.

**Problem:** Chinese warehouse locale still includes English status text such as `Bound`, `Empty`, and `Low Stock`.

**Files:**
- Modify: `HbwebExpoApp/src/locales/zh/screens/warehouse.json`
- Inspect only: `HbwebExpoApp/app/(tabs)/warehouse.tsx`

**Steps:**
- [ ] Replace `location.statusBound` with `已绑定`.
- [ ] Replace `location.statusEmpty` with `空货位`.
- [ ] Replace `location.statusLowStock` with `低库存`.
- [ ] Search warehouse UI for additional visible English in zh locale using `rg -n "Bound|Empty|Low Stock|Bin" HbwebExpoApp/src/locales/zh/screens/warehouse.json HbwebExpoApp/app/(tabs)/warehouse.tsx`.
- [ ] Run `npm exec -- tsc --noEmit`.

**Acceptance:**
- Warehouse zh locale has no accidental English status labels.
- No business code is changed in this task unless required to consume existing locale keys.

## Task 5: Employee Profile Image Upload

**Owner:** Phase 2 worker.

**Problem:** Employee profile asks users to paste avatar and identity photo URLs. This is not a complete mobile UX.

**Files:**
- Modify: `HbwebExpoApp/app/(tabs)/employee-profile.tsx`
- Modify: `HbwebExpoApp/src/modules/employee-profile/api.ts`
- Modify: `HbwebExpoApp/src/modules/employee-profile/types.ts`
- Create if useful: `HbwebExpoApp/src/modules/employee-profile/image-upload.ts`
- Modify: `HbwebExpoApp/app.json` only if camera/media permission text is required.
- Modify: `HbwebExpoApp/src/locales/zh/screens/employeeProfile.json`
- Modify: `HbwebExpoApp/src/locales/en/screens/employeeProfile.json`

**Implementation contract:**
- Replace raw URL maintenance with image actions: take photo and upload.
- Reuse the existing signed-upload pattern from warehouse if backend exposes compatible upload signatures.
- Keep the final saved profile payload as URLs.
- Do not expose protocol/port configuration or raw upload implementation details in user-facing text.

**Steps:**
- [ ] Inspect warehouse image upload flow in `warehouse.tsx` and `src/modules/warehouse/api.ts`.
- [ ] Add employee-profile upload API wrapper for avatar and identity photo.
- [ ] Update the profile page to show image action buttons and previews for avatar and identity photo.
- [ ] Use `expo-camera` for the first implementation because `expo-image-picker` is not installed in the current app.
- [ ] Keep URL fields hidden or read-only debug-only; normal users should not type URLs.
- [ ] Add zh/en locale keys for take photo, upload, upload failed, upload success, remove image, and permission required.
- [ ] Run `npm exec -- tsc --noEmit`.

**Acceptance:**
- Users can upload avatar and identity photo from the mobile UI.
- Saved employee profile still stores URLs in the existing API payload.
- Existing text inputs for banking, superannuation, personal details, and identity ID continue to work.

## Integration And Verification

- [ ] Review all worker summaries and changed file lists.
- [ ] Check for conflicts in shared files:
  - `HbwebExpoApp/src/locales/zh/screens/warehouse.json`
  - `HbwebExpoApp/src/locales/en/screens/warehouse.json`
- [ ] Run `npm exec -- tsc --noEmit` from `HbwebExpoApp`.
- [ ] Run targeted local tests if touched:
  - `node` or project test runner for `src/modules/navigation/default-route.test.ts`
  - `src/components/navigation/tab-grouping.test.ts`
  - existing attendance/user validation tests if module signatures change.
- [ ] Manual smoke checklist:
  - Staff list -> staff detail -> personal tab.
  - Staff detail -> schedule tab.
  - Staff detail -> records tab.
  - Attendance page -> verification display.
  - Attendance punch with allowed permission.
  - Attendance punch with denied/unavailable permission.
  - Warehouse -> location -> bind product with quantity.
  - Warehouse zh status labels.
  - Employee profile -> upload avatar.
  - Employee profile -> upload identity photo.

## Commit Plan

Use Chinese commit messages per repo instruction.

- Phase 1 Task 1 commit: `feat: 完善店员详情排班和记录`
- Phase 1 Task 2 commit: `feat: 接入考勤打卡校验信息`
- Phase 1 Task 3 commit: `feat: 完善货位绑定数量流程`
- Phase 2 Task 4 commit: `fix: 完善仓库页面中文文案`
- Phase 2 Task 5 commit: `feat: 支持个人资料图片上传`
