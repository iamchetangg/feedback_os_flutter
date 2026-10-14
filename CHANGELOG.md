# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
