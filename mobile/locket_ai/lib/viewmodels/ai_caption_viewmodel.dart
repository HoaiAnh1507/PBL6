import 'package:flutter/foundation.dart';

/// Job status for AI caption generation
enum CaptionJobStatus {
  processing, // AI is working
  completed,  // AI finished successfully
  failed,     // AI failed
}

/// Represents a pending AI caption generation job
class PendingCaptionJob {
  final String postId;
  final String mediaPath;
  final bool isVideo;
  final String mood;
  final DateTime createdAt;
  CaptionJobStatus status;
  String? errorMessage;

  PendingCaptionJob({
    required this.postId,
    required this.mediaPath,
    required this.isVideo,
    required this.mood,
    required this.createdAt,
    this.status = CaptionJobStatus.processing,
    this.errorMessage,
  });
}

/// ViewModel to manage AI caption generation state across the app
/// Allows background AI processing while user navigates freely
class AICaptionViewModel extends ChangeNotifier {
  PendingCaptionJob? _currentJob;
  bool _shouldNavigateToCapture = false;

  PendingCaptionJob? get currentJob => _currentJob;
  bool get hasActiveJob => _currentJob != null;
  bool get shouldNavigateToCapture => _shouldNavigateToCapture;

  /// Start tracking a new AI caption job
  void startJob({
    required String postId,
    required String mediaPath,
    required bool isVideo,
    required String mood,
  }) {
    _currentJob = PendingCaptionJob(
      postId: postId,
      mediaPath: mediaPath,
      isVideo: isVideo,
      mood: mood,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Clear the current job when completed or cancelled
  void clearJob() {
    _currentJob = null;
    _shouldNavigateToCapture = false;
    notifyListeners();
  }

  /// Mark current job as completed successfully
  void markJobCompleted() {
    if (_currentJob != null) {
      _currentJob!.status = CaptionJobStatus.completed;
      notifyListeners();
    }
  }

  /// Mark current job as failed
  void markJobFailed({String? errorMessage}) {
    if (_currentJob != null) {
      _currentJob!.status = CaptionJobStatus.failed;
      _currentJob!.errorMessage = errorMessage;
      notifyListeners();
    }
  }

  /// Request navigation to capture preview page
  void requestNavigateToCapture() {
    _shouldNavigateToCapture = true;
    notifyListeners();
  }

  /// Acknowledge navigation request
  void acknowledgeNavigation() {
    _shouldNavigateToCapture = false;
    notifyListeners();
  }

  /// Check if a specific post is currently being processed
  bool isProcessing(String postId) {
    return _currentJob?.postId == postId;
  }
}
