import 'package:flutter/material.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FeedbackOS SDK with staging options
  await FeedbackOS.instance.initialize(
    publishableKey: const String.fromEnvironment(
      'FEEDBACKOS_KEY',
      defaultValue: 'fos_pk_test_sample_12345',
    ),
    options: FeedbackOSOptions.staging(debugLogging: true),
  );

  runApp(const FeedbackOsExampleApp());
}

class FeedbackOsExampleApp extends StatelessWidget {
  const FeedbackOsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FeedbackOS SDK Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _queuedCount = 0;
  int _failedCount = 0;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    final queued = await FeedbackOS.instance.getQueuedCount();
    final failed = await FeedbackOS.instance.getFailedCount();
    setState(() {
      _queuedCount = queued;
      _failedCount = failed;
    });
  }

  Future<void> _openFeedback(FeedbackType type) async {
    final result = await FeedbackOS.instance.showFeedback(
      context: context,
      initialType: type,
    );

    if (result != null) {
      setState(() {
        _statusMessage = result.isSent
            ? 'Delivered to server (ID: ${result.itemId ?? "acknowledged"})'
            : 'Queued locally for offline delivery';
      });
      await _refreshCounts();
    }
  }

  Future<void> _flushQueue() async {
    final count = await FeedbackOS.instance.flushQueue();
    setState(() {
      _statusMessage = 'Flushed queue: $count item(s) sent';
    });
    await _refreshCounts();
  }

  Future<void> _toggleIdentity() async {
    final active = FeedbackOS.instance.activeExternalUserId;
    if (active == null) {
      await FeedbackOS.instance.identify(externalUserId: 'customer_demo_42');
      setState(() {
        _statusMessage = 'Identified as customer_demo_42';
      });
    } else {
      await FeedbackOS.instance.clearIdentity();
      setState(() {
        _statusMessage = 'Cleared user identity';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUser = FeedbackOS.instance.activeExternalUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FeedbackOS Example'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 0,
              color: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Identity: ${activeUser ?? "Anonymous"}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pending in Offline Queue: $_queuedCount',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    Text(
                      'Permanently Failed: $_failedCount',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form triggers
            const Text(
              'Interactive Feedback Form',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.bug_report),
              label: const Text('Report a Bug'),
              onPressed: () => _openFeedback(FeedbackType.bug),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.lightbulb),
              label: const Text('Request a Feature'),
              onPressed: () => _openFeedback(FeedbackType.feature),
            ),
            const SizedBox(height: 24),

            // Identity & Offline Actions
            const Text(
              'Identity & Queue Control',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: Icon(activeUser == null ? Icons.login : Icons.logout),
              label: Text(
                activeUser == null
                    ? 'Identify as customer_demo_42'
                    : 'Clear Identity (Logout)',
              ),
              onPressed: _toggleIdentity,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Flush Offline Queue Now'),
              onPressed: _flushQueue,
            ),
          ],
        ),
      ),
    );
  }
}
