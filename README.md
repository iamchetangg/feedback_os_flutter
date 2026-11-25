<h1 align="center">FeedbackOS for Flutter</h1>

<p align="center">
  Collect bug reports and feature requests, show a community board and roadmap,<br/>
  and reply to your users, all inside your Flutter app.
</p>

<p align="center">
  <a href="https://pub.dev/packages/feedback_os_flutter"><img src="https://img.shields.io/pub/v/feedback_os_flutter.svg" alt="pub version"/></a>
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue" alt="platforms"/>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT license"/></a>
</p>

---

## Features

| | |
|---|---|
| 📝 **Feedback form** | Drop-in bottom sheet for bug reports and feature requests, with screenshots. |
| ⚡ **Headless API** | Submit feedback from your own UI. |
| 📦 **Offline-first** | Submissions are saved on the device and sent automatically when the network is back. |
| 👤 **User identity** | Link feedback to your signed-in users, or keep it anonymous. |
| 🗳 **Community board** | Let users browse and upvote feature requests. |
| 🗺 **Roadmap** | Show what's planned, in progress, and shipped. |
| 💬 **Threads** | Two-way conversations between users and your team, with unread badges. |
| 🔔 **Live notifications** | Replies and status changes arrive in real time, with an optional in-app banner. |

## Contents

1. [Installation](#installation)
2. [Initialize](#initialize)
3. [Feedback form](#feedback-form)
4. [Headless submission](#headless-submission)
5. [Identify users](#identify-users)
6. [Board, roadmap & threads](#board-roadmap--threads)
7. [Live notifications](#live-notifications)
8. [Theming](#theming)
9. [Options](#options)
10. [Error handling](#error-handling)

---

## Installation

```yaml
dependencies:
  feedback_os_flutter: ^0.1.2
```

## Initialize

Call `initialize` once in `main()`, before `runApp()`, with your project's publishable key from the FeedbackOS dashboard.

```dart
import 'package:flutter/material.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FeedbackOS.instance.initialize(
    publishableKey: const String.fromEnvironment('FEEDBACKOS_KEY'),
  );

  runApp(const MyApp());
}
```

> [!TIP]
> Publishable keys (`fos_pk_...`) are safe to ship in your app. Passing yours with `--dart-define` keeps it out of source control.

## Feedback form

```dart
final result = await FeedbackOS.instance.showFeedback(
  context: context,
  initialType: FeedbackType.bug, // or FeedbackType.feature
);

if (result != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Thanks for your feedback!')),
  );
}
```

Users can attach up to 3 screenshots, which are compressed automatically before upload.

## Headless submission

Build your own UI and submit directly:

```dart
final screenshot = await FeedbackOS.pickScreenshot(); // optional

final result = await FeedbackOS.instance.submitFeedback(
  type: FeedbackType.feature,
  title: 'Export transactions to CSV',
  description: 'An option to export monthly reports would be great.',
  category: 'Reporting',
  attachments: [if (screenshot != null) screenshot],
);

switch (result.status) {
  case FeedbackSubmitStatus.sent:
    print('Delivered: ${result.itemId}');
  case FeedbackSubmitStatus.queued:
    print('Offline: saved and will be sent automatically');
}
```

Every submission is saved on the device before it is sent, so nothing is lost when the user is offline. Queued items are retried with backoff, and also sent when the app resumes or the network comes back.

## Identify users

```dart
// After sign-in
await FeedbackOS.instance.identify(externalUserId: user.id);

// After sign-out
await FeedbackOS.instance.clearIdentity();
```

Feedback queued while offline keeps the identity it was created with.

## Board, roadmap & threads

Each of these opens a built-in screen with one call. All of them use the same screen, which has **Board**, **Roadmap** and **My requests** tabs and a **+ New request** button.

```dart
FeedbackOS.instance.openBoard(context: context);
FeedbackOS.instance.openRoadmap(context: context);
FeedbackOS.instance.openFeedbackDashboard(context: context); // "My requests"
FeedbackOS.instance.openThreadDetail(context: context, itemId: itemId);
```

To show a badge, read the unread count once:

```dart
final int unread = await FeedbackOS.instance.getUnreadCount();
```

For a badge that updates by itself, use the `unreadCount` listenable described in [Live notifications](#live-notifications).

## Live notifications

When realtime is enabled for your project, the SDK keeps a live connection open while the app is in the foreground. Users see replies and status changes without reopening the feedback screens. It's on by default.

```dart
// Live events
FeedbackOS.instance.events.listen((event) {
  switch (event) {
    case ReplyReceived(:final itemId, :final authorName, :final preview):
      print('${authorName ?? 'The team'} replied on $itemId: $preview');
    case StatusChanged(:final itemId, :final toStatus):
      print('$itemId is now $toStatus');
  }
});

// A badge that updates by itself
ValueListenableBuilder<int>(
  valueListenable: FeedbackOS.instance.unreadCount,
  builder: (context, unread, _) => Badge(
    isLabelVisible: unread > 0,
    label: Text('$unread'),
    child: const Icon(Icons.forum_outlined),
  ),
);
```

To show whether the live connection is up, listen to `FeedbackOS.instance.isLiveConnected` (a `ValueListenable<bool>`).

### In-app banner

You can turn on a small banner that appears when an event arrives. Tapping it opens the thread.

```dart
final navigatorKey = GlobalKey<NavigatorState>();

await FeedbackOS.instance.initialize(
  publishableKey: 'fos_pk_...',
  options: FeedbackOSOptions(
    showInAppNotificationBanner: true,
    navigatorKey: navigatorKey,
  ),
);

MaterialApp(navigatorKey: navigatorKey /* ... */);
```

If you don't pass a `navigatorKey`, the SDK uses the app's root navigator. No banner is shown for a thread that is already open.

### Good to know

- The connection opens while the app is in the foreground, closes in the background, and reconnects automatically.
- Events missed while disconnected aren't replayed, but `unreadCount` is resynced with the server every time the connection is restored.
- An open thread refreshes as soon as a new event arrives. `threadPollingInterval` polling is only a fallback while the live connection is down.
- `identify()` and `clearIdentity()` restart the connection for the new user.
- To turn it off, set `liveNotifications: false`.

## Theming

The SDK screens use a light theme by default. You can use the built-in dark theme, build one from your app's `ThemeData`, or set your own colors:

```dart
FeedbackOSOptions(theme: FeedbackOSTheme.dark());
FeedbackOSOptions(theme: FeedbackOSTheme.fromTheme(Theme.of(context)));
FeedbackOSOptions(theme: const FeedbackOSTheme(primaryColor: Colors.teal));

// Change it at runtime
FeedbackOS.instance.switchTheme(isDark: true);
```

## Options

All fields of `FeedbackOSOptions` are optional.

| Option | Default | Description |
|---|---|---|
| `theme` | `FeedbackOSTheme()` | Colors used by the SDK screens. |
| `liveNotifications` | `true` | Receive replies and status changes in real time. |
| `showInAppNotificationBanner` | `false` | Show a banner when a live event arrives. |
| `navigatorKey` | `null` | Your app's navigator key, used by the banner. |
| `threadPollingInterval` | `4s` | How often an open thread refreshes while live updates are unavailable. |
| `maxOfflineQueueSize` | `500` | Maximum number of submissions kept offline. |
| `queueItemTtl` | `7 days` | How long an offline submission is kept before it expires. |
| `connectTimeout` | `15s` | Network connect timeout. |
| `receiveTimeout` | `15s` | Network receive timeout. |
| `debugLogging` | `false` | Print SDK logs. Keys, payloads and images are never logged. |

## Error handling

When a call fails, the SDK throws a subclass of `FeedbackOsException`:

```dart
try {
  await FeedbackOS.instance.identify(externalUserId: user.id);
} on FeedbackOsNetworkException {
  // Offline or timed out
} on FeedbackOsRateLimitException {
  // Too many requests, try again later
} on FeedbackOsException catch (e) {
  print(e.message);
}
```

`submitFeedback` doesn't throw on network errors. The submission is queued and the call returns `FeedbackSubmitStatus.queued`.

---

## License

MIT. See [LICENSE](LICENSE).
