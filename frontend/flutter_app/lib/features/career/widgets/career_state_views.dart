import 'package:flutter/material.dart';

// Shared loading, empty and error views for the Career module.
//
// Every career screen shows the same three states in the same way, so a
// student learns the pattern once: a spinner with a label while loading, a
// clear explanation plus a retry button when something fails, and a friendly
// message when there is simply nothing to show. Keeping them in one file stops
// the screens from drifting apart visually.

/// Shows a short confirmation or problem message.
///
/// Every screen in the Career module reports outcomes through this one
/// function, so feedback looks and behaves the same everywhere: floating above
/// the content, green when something succeeded and dark neutral when it did
/// not. Any message already on screen is dismissed first, so a quick second
/// action does not queue up behind a stale one.
void showCareerMessage(
  BuildContext context,
  String message, {
  bool success = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? const Color(0xFF15803D)
            : const Color(0xFF1F2937),
      ),
    );
}

/// Centred spinner with a short label, so the wait is explained rather than
/// leaving the student looking at a bare circle.
class CareerLoadingView extends StatelessWidget {
  const CareerLoadingView({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 18),
        Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

/// Error state with the server's own message and a retry action.
///
/// Wrapped in a scrollable so it still works inside a [RefreshIndicator]:
/// the student can pull down to retry as well as tap the button.
class CareerErrorView extends StatelessWidget {
  const CareerErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _CentredScrollable(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFFFEE2E2),
          foregroundColor: Color(0xFFDC2626),
          child: Icon(Icons.error_outline_rounded, size: 32),
        ),
        const SizedBox(height: 18),
        Text(
          'Something went wrong',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Constrained so the stadium button does not stretch edge to edge.
        SizedBox(
          width: 200,
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ),
      ],
    ),
  );
}

/// Empty state: nothing failed, there is just nothing to show yet.
class CareerEmptyView extends StatelessWidget {
  const CareerEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.actionLabel = 'Refresh',
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => _CentredScrollable(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: const Color(0xFFDBEAFE),
          foregroundColor: const Color(0xFF3B82F6),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Centres its child while staying scrollable, so these views can sit inside a
/// [RefreshIndicator] and still respond to a pull-down gesture.
class _CentredScrollable extends StatelessWidget {
  const _CentredScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: child,
          ),
        ),
      ),
    ),
  );
}
