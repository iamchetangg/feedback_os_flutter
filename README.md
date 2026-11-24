# FeedbackOS Flutter SDK

A production-minded, offline-first Flutter SDK for **[FeedbackOS](https://feedbackos.dev)** — capturing user feedback, bug reports, presigned screenshot attachments, public feature voting boards, product roadmaps, and two-way support threads.

---

## Features

- 🛠 **Developer-Triggered Dialog Form**: Drop-in accessible dialog for capturing bugs and feature requests.
- ⚡ **Programmatic Submissions**: Headless API to submit structured feedback from custom UI.
- 🔒 **Direct Presigned Uploads**: Direct `PUT` uploads to Cloudflare R2 / S3 storage; binary blobs never traverse application servers.
- 📦 **Durable Offline-First Queue**: Persistent SQLite submission storage with exponential backoff, jitter, and automatic network resume.
- 👤 **Identity Association**: Link feedback and threads to authenticated user IDs or run anonymously with device UUIDv4 persistence.
- 🗳 **Community Board & Voting**: Paginated feature requests with optimistic upvoting and server confirmation rollback.
- 🗺 **Product Roadmap**: Structured tabbed view of planned, in-progress, and shipped features.
- 💬 **Feedback Threads & Messages**: Two-way discussions between users and your team with unread badge counters.
- 🔔 **Live Notifications**: Creator replies and status changes pushed over a WebSocket, with a live unread count and an optional in-app banner.

---

## Installation

Add `feedback_os_flutter` to your `pubspec.yaml`:

```yaml
dependencies:
  feedback_os_flutter: ^0.1.0
```

---

## Getting Started

### 1. Initialization

Initialize the SDK in your `main()` before calling `runApp()`. Provide your project's publishable API key:

```dart
import 'package:flutter/material.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FeedbackOS.instance.initialize(
    publishableKey: const String.fromEnvironment(
      'FEEDBACKOS_KEY',
      defaultValue: 'fos_pk_live_your_key_here',
    ),
    // baseUrl is optional and defaults to https://api.feedbackos.dev.
    // Point it at a local server for development, e.g.
    // http://localhost:8787 (or http://10.0.2.2:8787 from the Android emulator).
    options: FeedbackOSOptions(
      baseUrl: Uri.parse('https://api.feedbackos.dev'),
    ),
  );

  runApp(const MyApp());
}
```

> **Security Note:** Never hardcode secret keys in production binaries. Publishable keys (`fos_pk_...`) are public and project-scoped, but best practice is injecting them via `--dart-define` or environment configs.

---

## Usage Guide

### 2. Showing the Feedback Form

Display the built-in modal bottom sheet or dialog to collect user feedback:

```dart
final result = await FeedbackOS.instance.showFeedback(
  context: context,
  type: FeedbackType.bug, // or FeedbackType.feature
);

if (result != null && result.isSuccess) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Feedback received! Thank you.')),
  );
}
```

### 3. Programmatic Submission (Headless)

If you have your own bespoke UI, submit feedback directly:

```dart
final result = await FeedbackOS.instance.submitFeedback(
  type: FeedbackType.feature,
  title: 'Export transactions to CSV',
  description: 'Would love an option to export monthly reports to CSV format.',
  category: 'Reporting',
  screenshotUploadIds: ['upload_id_1'], // Optional uploaded screenshot IDs
);

switch (result.status) {
  case FeedbackSubmitStatus.sent:
    print('Delivered to server: ${result.clientSubmissionId}');
    break;
  case FeedbackSubmitStatus.queued:
    print('Offline: saved locally, will sync automatically');
    break;
  case FeedbackSubmitStatus.failure:
    print('Failed: ${result.errorMessage}');
    break;
}
```

### 4. User Identification & Logout

Link user reports to an authenticated account:

```dart
// When user logs in
await FeedbackOS.instance.identify(externalUserId: user.id);

// When user logs out
await FeedbackOS.instance.clearIdentity();
```

> **Queue Integrity**: Queued offline submissions record an identity snapshot at creation time and preserve user context during replay.

---

### 5. Screenshots & Attachments

Reserve an upload slot and directly send image bytes to the presigned storage URL:

```dart
final bytes = await File('path/to/screenshot.png').readAsBytes();

final uploadId = await FeedbackOS.instance.uploadScreenshot(
  filename: 'screenshot.png',
  bytes: bytes,
  contentType: 'image/png', // 'image/png' or 'image/jpeg'
);

// Pass uploadId into submitFeedback:
await FeedbackOS.instance.submitFeedback(
  type: FeedbackType.bug,
  title: 'Checkout button overflow',
  description: 'Text clips on iPhone SE screen size.',
  screenshotUploadIds: [uploadId],
);
```

---

### 6. Community Feature Board

Render the community feedback board with upvoting and pagination:

```dart
// 1. Create the BoardBloc using the SDK factory
final boardBloc = FeedbackOS.instance.createBoardBloc();

// 2. Provide the bloc to the view
BlocProvider<BoardBloc>.value(
  value: boardBloc..add(const BoardStarted()),
  child: BoardView(
    onBack: () => Navigator.pop(context),
  ),
);
```

### 7. Product Roadmap

Display planned, in-progress, and shipped milestones:

```dart
final boardBloc = FeedbackOS.instance.createBoardBloc();

BlocProvider<BoardBloc>.value(
  value: boardBloc..add(const RoadmapStarted()),
  child: RoadmapView(
    onBack: () => Navigator.pop(context),
  ),
);
```

### 8. User Feedback Threads & Discussions

Let users view their submitted items, see team responses, and reply:

```dart
final threadsBloc = FeedbackOS.instance.createThreadsBloc();

// List user feedback items
BlocProvider<ThreadsBloc>.value(
  value: threadsBloc..add(const MyItemsStarted()),
  child: MyFeedbackListView(
    onItemTap: (itemId) {
      // Navigate to ThreadDetailView
    },
  ),
);

// Detail discussion view
BlocProvider<ThreadsBloc>.value(
  value: threadsBloc..add(ThreadDetailStarted(itemId)),
  child: ThreadDetailView(itemId: itemId),
);
```

Check unread messages for a badge counter:

```dart
final int unreadCount = await FeedbackOS.instance.getUnreadCount();
print('Unread replies: $unreadCount');
```

For a badge that updates by itself, use the live `FeedbackOS.instance.unreadCount` listenable (see [Live Notifications](#9-live-notifications)).

### 9. Live Notifications

When realtime is enabled for your project, the SDK keeps a WebSocket open (`/v1/sdk/me/stream`) while the app is in the foreground, so users see creator replies and status changes without opening the feedback screens. It is on by default (`liveNotifications: true`) and only connects if the server SDK config reports `realtime.enabled`. Older servers that don't send the field never get connection attempts.

```dart
// Stream of live events (broadcast; survives reconnects and identify()).
final sub = FeedbackOS.instance.events.listen((event) {
  switch (event) {
    case ReplyReceived(:final itemId, :final authorName, :final preview):
      print('New reply on $itemId from ${authorName ?? 'the team'}: $preview');
    case StatusChanged(:final itemId, :final toStatus):
      print('$itemId is now $toStatus');
  }
});

// Badge driven by the live unread count.
ValueListenableBuilder<int>(
  valueListenable: FeedbackOS.instance.unreadCount,
  builder: (context, unread, _) => Badge(
    isLabelVisible: unread > 0,
    label: Text('$unread'),
    child: const Icon(Icons.forum_outlined),
  ),
);

// Optional: connection state.
FeedbackOS.instance.isLiveConnected; // ValueListenable<bool>
```

**In-app banner.** Set `showInAppNotificationBanner: true` to show a small banner at the top of the screen when an event arrives ("New reply" + preview, or "Status updated: shipped"). It dismisses itself after about 4 seconds, and tapping it opens the thread. Pass your app's `navigatorKey` (for example the one you give `MaterialApp` or `GoRouter`) so the SDK can find the overlay. Without one, it falls back to the app's root navigator. No banner is shown for a thread that is already open on screen.

```dart
final navigatorKey = GlobalKey<NavigatorState>();

await FeedbackOS.instance.initialize(
  publishableKey: 'fos_pk_...',
  options: FeedbackOSOptions(
    showInAppNotificationBanner: true,
    navigatorKey: navigatorKey,
  ),
);

MaterialApp(navigatorKey: navigatorKey, /* ... */);
```

**Behavior:**
- The socket connects when the app is resumed and closes when it is paused or hidden. It sends a `ping` every 45 seconds and reconnects with exponential backoff and jitter (1 second up to 5 minutes, or a 5-minute wait if the server reports realtime as unavailable).
- Missed events are not replayed. The unread count (number of threads with unread updates) is reconciled with the server on every (re)connect, shortly after each live event, and after a thread is read.
- An open thread refreshes as soon as an event for it arrives. The `threadPollingInterval` short polling only runs as a fallback while the socket is disconnected or disabled.
- The connection restarts on `identify()` and `clearIdentity()` and is torn down by `reset()`.
- To opt out, set `liveNotifications: false`.

---

## Offline Queue Resilience

The SDK uses a durable SQLite database (`sqflite`) for storing feedback items before network transmission:
1. **Immediate Write-Ahead Persistence**: Every submission is persisted to disk before initiating any network request.
2. **Exponential Backoff with Jitter**: If the server is unreachable or rate-limits with `Retry-After`, requests retry safely without hammering endpoints.
3. **Connectivity & Lifecycle Listeners**: Automatically flushes the queue when internet connectivity returns or when the app resumes from the background.
4. **Manual Queue Trigger**:
   ```dart
   final processedCount = await FeedbackOS.instance.flushQueue();
   ```

---

## Architectural Principles

This SDK is engineered strictly according to Clean Architecture and SOLID:
- **Feature-First Structure**: Features (`board`, `threads`, `uploads`, `feedback`) isolate `data/`, `domain/`, `presentation/`, and `state/`.
- **FP-Dart Error Handling**: Repository methods return `Either<Failure, Success>` with zero unhandled exceptions leaking to UI widgets.
- **CancelToken Support**: Network calls accept Dio `CancelToken`s for request cancellation on screen disposal.
- **Decoupled State**: BLoCs are instantiated via dependency injection and factory helpers, never inside the UI widget tree.
- **Centralized Design System**: Typography and tokens are centralized in `AppStyles`.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
