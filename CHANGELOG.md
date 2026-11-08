# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-11-08

### Added
- **Unified Feedback Container (`FeedbackContainerView`)**:
  - Consolidated community board, roadmap, and user threads into a unified 3-tab segmented interface (`Board` | `Roadmap` | `My requests`).
  - Added persistent '+ New request' floating action button to submit feedback from any tab.
  - Updated facade methods `openBoard()`, `openRoadmap()`, and `openFeedbackDashboard()` to route directly into the container at the appropriate tab, eliminating repetitive route stacking.
- **Modern Design & Theming**:
  - Centralized typography and styling in `AppStyles` (`lib/core/theme/styles.dart`).
  - Added cohesive status color system across dots, badges, and steppers (`Open: #8A8F98`, `Planned: #4DA7FC`, `In progress: #F1CA4B`, `Shipped: #26A644`, `Closed: #62666D`).
  - Refined default dark mode styling and theme tokens for cards, surfaces, and accents.
- **Screenshot Attachments & Smart Compression**:
  - Added screenshot attachment support in feedback form with thumbnail previews and removal (up to 3 images).
  - Implemented client-side compression that strictly guarantees file size under 256 KB while preserving native image resolution.
  - Integrated presigned upload pipeline to obtain upload reference IDs prior to submitting feedback.
- **Real-Time Thread Polling & Discussion Timeline**:
  - Modernized `ThreadDetailView` with chat bubble timeline and 4-step progress stepper (`Open` -> `Planned` -> `In progress` -> `Shipped`).
  - Added lifecycle-aware short polling for active thread discussions (default 4 seconds, configurable via `threadPollingInterval`), pausing when backgrounded and resuming when foregrounded.
  - Added pull-to-refresh (`RefreshIndicator`) on `MyFeedbackListView`.
  - Added optimistic local unread badge clearing when opening feedback threads.

### Changed
- **Modal Feedback Form**:
  - `showFeedback` now opens as a modern modal bottom sheet (`FeedbackFormSheet`) with feedback type selection (`Report bug` / `Idea or request`) and a dedicated confirmation screen ("Thanks, we got it").
  - Added `PopScope` and tap-to-dismiss behavior for smooth keyboard dismissal.
- **Ownership Verification on Taps**:
  - Restricted thread detail screen navigation in Board and Roadmap views strictly to items owned by the current user (`item.isMine`).
- **Configuration & Facade Cleanup**:
  - Simplified `FeedbackOSOptions` with `const` constructor, removing redundant environment URL boilerplate.
  - Streamlined `FeedbackOS.instance` surface, keeping public APIs focused on headless functions and direct UI invocations.

### Fixed
- Fixed bug where "New reply" badge persisted on `MyFeedbackListView` after viewing the thread.
- Fixed repetitive route stacking loops between `RoadmapView` and `BoardView`.
- Fixed null exception on status color getters when resolving colors from stale theme instances.

## [0.1.0] - 2026-10-14

### Added
- **Core SDK Infrastructure**:
  - `FeedbackOS.instance` facade with thread-safe lifecycle and configuration caching.
  - Secure persistent device UUIDv4 generation via `flutter_secure_storage` with in-memory test fallbacks.
  - Device and app metadata collection (`device_info_plus`, `package_info_plus`).
  - Standardized error envelope handling (`invalid_request`, `unauthorized`, `rate_limited`, `upload_not_found`, etc.).
- **Feedback & Identity**:
  - Developer-triggered dialog form (`showFeedback`) supporting bug reports and feature requests.
  - Programmatic submission API (`submitFeedback`) returning typed statuses (`sent`, `queued`, `failed`).
  - Identity management (`identify`, `clearIdentity`) with queue snapshot serialization.
- **Durable Offline Queue**:
  - SQLite persistent queue (`sqflite`) persisting submissions before network delivery.
  - Exponential backoff with jitter and `Retry-After` header respect.
  - Mutex-protected serialized sync triggers on app lifecycle resume and connectivity restoration.
- **Screenshots & Attachments**:
  - Presigned direct-to-storage upload pipeline (`POST /v1/sdk/uploads` reservation -> direct `PUT` to R2).
  - Strict client-side validation against MIME types and config size limits.
  - Expired upload renewal during offline queue replay.
- **Community Board & Product Roadmap**:
  - Typed endpoints for `GET /v1/sdk/board`, `POST /v1/sdk/items/{id}/vote`, and `DELETE /v1/sdk/items/{id}/vote`.
  - `BoardView` and `RoadmapView` presentation widgets with BLoC state management (`BoardBloc`).
  - `GET /v1/sdk/roadmap` categorized by Planned, In Progress, and Shipped.
- **Feedback Threads & Discussions**:
  - Typed endpoints for `GET /v1/sdk/me/unread`, `GET /v1/sdk/me/items`, `GET /v1/sdk/me/items/{id}`, `POST /v1/sdk/me/items/{id}/replies`, and `POST /v1/sdk/me/items/{id}/read`.
  - `MyFeedbackListView` and `ThreadDetailView` presentation widgets with `ThreadsBloc`.
- **Example App**:
  - Comprehensive Flutter example application built with `go_router` and BLoC demonstrating full feature set.
