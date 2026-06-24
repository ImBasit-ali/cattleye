import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/ui/app_loader.dart';
import '../../models/camera_model.dart';
import '../../models/cattle_analysis_result.dart';
import '../../models/video_analysis_result.dart';
import '../../models/video_process_outcome.dart';
import '../../providers/camera_provider.dart';
import '../../providers/cattle_provider.dart';
import '../../domain/exceptions/analysis_exceptions.dart';
import '../../widgets/home_shell_scope.dart';
import '../../widgets/backend_status_indicator.dart';

/// Camera Monitoring Screen — Windows desktop only.
/// Shows live IP camera feeds with AI analysis overlays.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: HomeShellScope.leading(context),
        title: Text(context.l10n.cameras),
        actions: [
          const BackendStatusAppBarAction(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reconnect all cameras',
            onPressed: () {
              final provider = context.read<CameraProvider>();
              for (final cam in provider.cameras) {
                provider.reconnectCamera(cam.id);
              }
            },
          ),
        ],
      ),
      body: Consumer<CameraProvider>(
        builder: (context, provider, _) {
          if (provider.cameras.isEmpty) {
            return _buildEmptyState();
          }
          return _buildCameraGrid(provider);
        },
      ),
      floatingActionButton: _buildFabs(),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'No cameras added yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the buttons at the bottom right to add an IP camera\n'
              'or upload a recorded video for AI analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Camera grid ───────────────────────────────────────────────────────────

  Widget _buildCameraGrid(CameraProvider provider) {
    final crossAxisCount = _gridCrossAxisCount(context);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 16 / 10,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.cameras.length,
      itemBuilder: (context, index) {
        return _CameraTile(
          camera: provider.cameras[index],
          onAnalyze: () =>
              context.read<CameraProvider>().analyzeCurrentFrame(
                    provider.cameras[index].id,
                  ),
          onReconnect: () =>
              context.read<CameraProvider>().reconnectCamera(
                    provider.cameras[index].id,
                  ),
          onRemove: () => _confirmRemoveCamera(provider.cameras[index]),
          onViewDetails: () =>
              _showAnalysisDetails(provider.cameras[index]),
        );
      },
    );
  }

  int _gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1600) return 4;
    if (width >= 1200) return 3;
    if (width >= 800) return 2;
    return 1;
  }

  // ── FABs ──────────────────────────────────────────────────────────────────

  Widget _buildFabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'fab_video',
          onPressed: _showVideoUploadDialog,
          backgroundColor: AppTheme.warningOrange,
          tooltip: 'Upload Video',
          child: const Icon(Icons.video_file_outlined),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'fab_camera',
          onPressed: _showAddCameraDialog,
          backgroundColor: AppTheme.lightTeal,
          tooltip: 'Add Camera',
          child: const Icon(Icons.add_a_photo_outlined),
        ),
      ],
    );
  }

  // ── Add Camera Dialog ─────────────────────────────────────────────────────

  Future<void> _showAddCameraDialog() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final snapshotCtrl = TextEditingController();
    String cameraType = 'RGB';
    String zone = 'Feeding Area';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_a_photo_outlined, color: AppTheme.lightTeal),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Add IP Camera',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DarkTextField(
                    controller: nameCtrl,
                    label: 'Camera Name',
                    hint: 'e.g. Barn Cam 01',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _DarkTextField(
                    controller: urlCtrl,
                    label: 'Stream / Snapshot URL',
                    hint:
                        'http://192.168.1.100/video.mjpg  or  /snap.jpg',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || !uri.hasScheme) {
                        return 'Enter a valid http:// URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _DarkTextField(
                    controller: snapshotCtrl,
                    label: 'Snapshot URL (optional)',
                    hint:
                        'http://192.168.1.100/snap.jpg (for AI frame capture)',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _DarkDropdown(
                          label: 'Camera Type',
                          value: cameraType,
                          items: CameraModel.cameraTypes,
                          onChanged: (v) =>
                              setDlgState(() => cameraType = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DarkDropdown(
                          label: 'Zone',
                          value: zone,
                          items: CameraModel.functionalZones,
                          onChanged: (v) => setDlgState(() => zone = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _InfoTip(
                      'Supports MJPEG streams and periodic JPEG snapshots.\n'
                      'RTSP cameras: enter snapshot URL for AI analysis.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTeal,
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await context.read<CameraProvider>().addCamera(
                      name: nameCtrl.text.trim(),
                      streamUrl: urlCtrl.text.trim(),
                      snapshotUrl: snapshotCtrl.text.trim().isEmpty
                          ? null
                          : snapshotCtrl.text.trim(),
                      cameraType: cameraType,
                      functionalZone: zone,
                    );
              },
              child: const Text('Add Camera'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Video Upload Dialog ───────────────────────────────────────────────────

  Future<void> _showVideoUploadDialog() async {
    String? pendingFilePath;
    String? pendingFileName;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _VideoUploadDialog(
        onProcess: (filePath, fileName) {
          pendingFilePath = filePath;
          pendingFileName = fileName;
          Navigator.of(ctx).pop();
        },
      ),
    );

    if (pendingFilePath != null && mounted) {
      final result = await _processVideoWithProgress(
        pendingFilePath!,
        pendingFileName ?? 'video',
      );
      if (!mounted) return;

      if (result != null && result.alreadyProcessed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(VideoAlreadyProcessedException.message),
            backgroundColor: AppTheme.warningOrange,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (result != null && result.analysis.animals.isNotEmpty) {
        final count = result.analysis.animals.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 1
                  ? 'Success — 1 cattle detected and data collected.'
                  : 'Success — $count cattle detected and data collected.',
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 4),
          ),
        );
        final cattle = context.read<CattleProvider>();
        if (result.savedDetectionRows.isNotEmpty) {
          // Immediate UI update; realtime dedupes if events arrive later.
          cattle.ingestDetections(result.savedDetectionRows);
        } else {
          await cattle.loadDetections();
        }
        await cattle.loadAnimals();
        if (mounted) {
          // Jump to Dashboard tab so the saved detections are visible.
          HomeShellScope.maybeOf(context)?.setTab(0);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Video analysis failed. Check your connection and try again.',
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<VideoProcessOutcome?> _processVideoWithProgress(
    String filePath,
    String fileName,
  ) async {
    final notifier = ValueNotifier<String>('Starting analysis…');

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ValueListenableBuilder<String>(
          valueListenable: notifier,
          builder: (context, status, child) => AlertDialog(
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: AppLoader.inline(size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Processing Video',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Text(
              status,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    VideoProcessOutcome? outcome;
    try {
      outcome = await context.read<CameraProvider>().processVideoFile(
            filePath: filePath,
            videoFileName: fileName,
            onProgress: (s) => notifier.value = s,
          );
    } on VideoAlreadyProcessedException {
      if (mounted) {
        Navigator.of(context).pop();
      }
      notifier.dispose();
      return VideoProcessOutcome(
        analysis: VideoAnalysisResult(
          cattleCount: 0,
          buffaloCount: 0,
          animals: const [],
          videoFileName: fileName,
        ),
        savedDetections: 0,
        alreadyProcessed: true,
      );
    } on NoCattleInVideoException {
      if (mounted) {
        Navigator.of(context).pop();
      }
      notifier.dispose();
      return null;
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      notifier.dispose();
      return null;
    }

    if (mounted) Navigator.of(context).pop();
    notifier.dispose();
    return outcome;
  }

  // (Video results summary dialog removed — after Analyze Video we navigate to
  // Dashboard where the saved detections are shown.)

  // ── Analysis details drawer ───────────────────────────────────────────────

  void _showAnalysisDetails(CameraModel camera) {
    showDialog(
      context: context,
      builder: (ctx) => _AnalysisDetailsDialog(camera: camera),
    );
  }

  // ── Remove camera confirm ─────────────────────────────────────────────────

  Future<void> _confirmRemoveCamera(CameraModel camera) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text('Remove Camera?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "${camera.name}" from monitoring?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<CameraProvider>().removeCamera(camera.id);
    }
  }
}

// ── Camera Tile ───────────────────────────────────────────────────────────────

class _CameraTile extends StatelessWidget {
  final CameraModel camera;
  final VoidCallback onAnalyze;
  final VoidCallback onReconnect;
  final VoidCallback onRemove;
  final VoidCallback onViewDetails;

  const _CameraTile({
    required this.camera,
    required this.onAnalyze,
    required this.onReconnect,
    required this.onRemove,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          _buildHeader(context),
          // Frame / feed area
          Expanded(child: _buildFeedArea()),
          // Footer with AI status
          _buildFooter(),
        ],
      ),
    );
  }

  Color get _borderColor {
    switch (camera.connectionState) {
      case CameraConnectionState.connected:
        return AppTheme.successGreen.withValues(alpha: 0.6);
      case CameraConnectionState.connecting:
        return AppTheme.warningOrange.withValues(alpha: 0.6);
      case CameraConnectionState.error:
        return AppTheme.errorRed.withValues(alpha: 0.6);
      case CameraConnectionState.disconnected:
        return Colors.white12;
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF111B27),
        borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          _ConnectionDot(state: camera.connectionState),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              camera.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            camera.cameraType,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(width: 6),
          _TileMenuButton(
            camera: camera,
            onAnalyze: onAnalyze,
            onReconnect: onReconnect,
            onRemove: onRemove,
            onViewDetails: onViewDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedArea() {
    if (camera.currentFrame != null && camera.currentFrame!.isNotEmpty) {
      return GestureDetector(
        onTap: onViewDetails,
        child: ClipRRect(
          child: Image.memory(
            camera.currentFrame!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      );
    }

    return _buildNoFeedPlaceholder();
  }

  Widget _buildNoFeedPlaceholder() {
    return GestureDetector(
      onTap: onReconnect,
      child: Container(
        color: const Color(0xFF0C1520),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                camera.connectionState == CameraConnectionState.connecting
                    ? Icons.hourglass_empty_outlined
                    : camera.connectionState == CameraConnectionState.error
                        ? Icons.videocam_off_outlined
                        : Icons.videocam_outlined,
                color: Colors.white24,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                camera.connectionState == CameraConnectionState.connecting
                    ? 'Connecting…'
                    : camera.connectionState == CameraConnectionState.error
                        ? camera.errorMessage ?? 'Connection error'
                        : 'Tap to connect',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              if (camera.connectionState == CameraConnectionState.connecting)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTeal.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final analysis = camera.lastAnalysis;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111B27),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
      ),
      child: Row(
        children: [
          if (analysis != null) ...[
            _HealthBadge(status: analysis.overall.status),
            const SizedBox(width: 8),
            if (analysis.lameness.detected)
              const _MiniTag(
                  label: 'LAME', color: AppTheme.errorRed),
            const SizedBox(width: 4),
            Text(
              'BCS ${analysis.bcs.score}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            const Spacer(),
            if (analysis.earTag.tagNumber != null)
              Text(
                '# ${analysis.earTag.tagNumber}',
                style: const TextStyle(
                    color: AppTheme.lightTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
          ] else ...[
            const Icon(Icons.hourglass_top,
                size: 12, color: Colors.white24),
            const SizedBox(width: 4),
            const Text(
              'Awaiting analysis',
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
          const Spacer(),
          if (camera.frameCount > 0)
            Text(
              '${camera.frameCount} frames',
              style: const TextStyle(color: Colors.white24, fontSize: 9),
            ),
        ],
      ),
    );
  }
}

// ── Video Upload Dialog ───────────────────────────────────────────────────────

class _VideoUploadDialog extends StatefulWidget {
  final void Function(String filePath, String fileName) onProcess;

  const _VideoUploadDialog({required this.onProcess});

  @override
  State<_VideoUploadDialog> createState() => _VideoUploadDialogState();
}

class _VideoUploadDialogState extends State<_VideoUploadDialog> {
  String? _filePath;
  String? _fileName;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.video_file_outlined, color: AppTheme.warningOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Analyze Video',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a recorded barn video. The app will analyze the full '
              'video, count cattle, assign IDs, and detect milking status, '
              'BCS, and lameness.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _filePath != null
                        ? AppTheme.successGreen
                        : AppTheme.mediumGray,
                  ),
                ),
                child: _filePath == null
                    ? Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              color: Colors.grey[400], size: 36),
                          const SizedBox(height: 8),
                          Text('Tap to select video file',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13)),
                          Text('MP4, AVI, MOV, MKV',
                              style: TextStyle(
                                  color: AppTheme.textHint, fontSize: 11)),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(Icons.video_file,
                              color: AppTheme.successGreen, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _fileName ?? '',
                              style: TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: Colors.grey[600], size: 18),
                            onPressed: () =>
                                setState(() => _filePath = null),
                          ),
                        ],
                      ),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Text(_errorMsg!,
                  style: const TextStyle(
                      color: AppTheme.errorRed, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _filePath != null ? _startProcessing : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Analyze Video'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _filePath = result.files.first.path;
        _fileName = result.files.first.name;
        _errorMsg = null;
      });
    }
  }

  Future<void> _startProcessing() async {
    if (_filePath == null) return;

    final file = File(_filePath!);
    if (!file.existsSync()) {
      setState(() => _errorMsg = 'File not found: $_filePath');
      return;
    }

    widget.onProcess(_filePath!, _fileName ?? 'video');
  }
}

// ── Analysis Details Dialog ───────────────────────────────────────────────────

class _AnalysisDetailsDialog extends StatelessWidget {
  final CameraModel camera;

  const _AnalysisDetailsDialog({required this.camera});

  @override
  Widget build(BuildContext context) {
    final a = camera.lastAnalysis;

    return Dialog(
      backgroundColor: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF111B27),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  if (camera.currentFrame != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(camera.currentFrame!,
                          width: 80,
                          height: 50,
                          fit: BoxFit.cover,
                          gaplessPlayback: true),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(camera.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text(
                            '${camera.functionalZone} · ${camera.cameraType}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            if (a == null)
              const Expanded(
                child: Center(
                  child: Text('No analysis data yet.\nTrigger analysis first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38)),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _AnalysisResultCards(result: a),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisResultCards extends StatelessWidget {
  final CattleAnalysisResult result;

  const _AnalysisResultCards({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Overall health banner
        _OverallHealthCard(health: result.overall),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _EarTagCard(earTag: result.earTag)),
            const SizedBox(width: 12),
            Expanded(child: _MuzzleCard(muzzle: result.muzzle)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _BcsCard(bcs: result.bcs)),
            const SizedBox(width: 12),
            Expanded(child: _LamenessCard(lameness: result.lameness)),
          ],
        ),
        const SizedBox(height: 12),
        _FeedingCard(feeding: result.feeding),
      ],
    );
  }
}

class _OverallHealthCard extends StatelessWidget {
  final OverallHealth health;
  const _OverallHealthCard({required this.health});

  Color get _statusColor {
    switch (health.status) {
      case 'Critical':
        return AppTheme.errorRed;
      case 'Requires Attention':
        return AppTheme.warningOrange;
      case 'Needs Monitoring':
        return AppTheme.infoBlue;
      default:
        return AppTheme.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon, color: _statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(health.status,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                if (health.priorityAlert != null)
                  Text('⚠ ${health.priorityAlert}',
                      style: TextStyle(
                          color: _statusColor.withValues(alpha: 0.8),
                          fontSize: 12)),
                Text(health.summary,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon {
    switch (health.status) {
      case 'Critical':
        return Icons.emergency;
      case 'Requires Attention':
        return Icons.warning_amber;
      case 'Needs Monitoring':
        return Icons.visibility;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class _EarTagCard extends StatelessWidget {
  final EarTagResult earTag;
  const _EarTagCard({required this.earTag});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      icon: Icons.sell_outlined,
      title: 'Ear Tag',
      children: [
        _Row('Detected', earTag.detected ? 'Yes' : 'No',
            earTag.detected ? AppTheme.successGreen : Colors.white38),
        if (earTag.tagNumber != null)
          _Row('Tag #', earTag.tagNumber!, AppTheme.lightTeal),
        if (earTag.tagColor != null) _Row('Color', earTag.tagColor!),
        _Row('Position', earTag.tagPosition),
        _Row('OCR Confidence', '${earTag.ocrConfidence}%'),
        if (earTag.notes.isNotEmpty) _Note(earTag.notes),
      ],
    );
  }
}

class _MuzzleCard extends StatelessWidget {
  final MuzzleResult muzzle;
  const _MuzzleCard({required this.muzzle});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      icon: Icons.face_outlined,
      title: 'Muzzle ID',
      children: [
        _Row('Detected', muzzle.detected ? 'Yes' : 'No',
            muzzle.detected ? AppTheme.successGreen : Colors.white38),
        if (muzzle.breedEstimate.isNotEmpty)
          _Row('Breed', muzzle.breedEstimate),
        _Row('Distinctiveness', muzzle.distinctiveness),
        if (muzzle.notes.isNotEmpty) _Note(muzzle.notes),
      ],
    );
  }
}

class _BcsCard extends StatelessWidget {
  final BcsResult bcs;
  const _BcsCard({required this.bcs});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      icon: Icons.monitor_weight_outlined,
      title: 'Body Condition (BCS)',
      children: [
        _Row('Score', '${bcs.score}', _bcsColor(bcs.score)),
        _Row('Category', bcs.category),
        _Row('Visible Ribs', bcs.visibleRibs ? 'Yes' : 'No'),
        _Row('Confidence', '${bcs.confidence}%'),
        if (bcs.recommendation.isNotEmpty) _Note(bcs.recommendation),
      ],
    );
  }

  Color _bcsColor(double score) {
    if (score < 2.0 || score > 4.0) return AppTheme.errorRed;
    if (score < 2.5 || score > 3.5) return AppTheme.warningOrange;
    return AppTheme.successGreen;
  }
}

class _LamenessCard extends StatelessWidget {
  final LamenessResult lameness;
  const _LamenessCard({required this.lameness});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      icon: Icons.directions_walk_outlined,
      title: 'Lameness',
      children: [
        _Row(
          'Detected',
          lameness.detected ? 'YES' : 'No',
          lameness.detected ? AppTheme.errorRed : AppTheme.successGreen,
        ),
        _Row('Locomotion Score', '${lameness.locomotionScore}/5'),
        _Row('Posture', lameness.posture),
        if (lameness.detected) ...[
          _Row('Affected Limb', lameness.affectedLimb),
          _Row(
            'Urgency',
            lameness.urgency.toUpperCase(),
            _urgencyColor(lameness.urgency),
          ),
        ],
        _Row('Confidence', '${lameness.confidence}%'),
      ],
    );
  }

  Color _urgencyColor(String u) {
    switch (u) {
      case 'urgent':
        return AppTheme.errorRed;
      case 'veterinary attention':
        return AppTheme.warningOrange;
      case 'monitor':
        return AppTheme.infoBlue;
      default:
        return AppTheme.successGreen;
    }
  }
}

class _FeedingCard extends StatelessWidget {
  final FeedingResult feeding;
  const _FeedingCard({required this.feeding});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      icon: Icons.restaurant_outlined,
      title: 'Feeding Behavior',
      horizontal: true,
      children: [
        _Row('Behavior', feeding.currentBehavior),
        _Row('Head Position', feeding.headPosition),
        _Row('Zone', feeding.locationZone),
        _Row(
          'Engagement',
          '${feeding.feedingEngagement}%',
          _engagementColor(feeding.feedingEngagement),
        ),
        if (feeding.notes.isNotEmpty) _Note(feeding.notes),
      ],
    );
  }

  Color _engagementColor(int v) {
    if (v >= 70) return AppTheme.successGreen;
    if (v >= 40) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _AnalysisCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool horizontal;

  const _AnalysisCard({
    required this.icon,
    required this.title,
    required this.children,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.lightTeal, size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          if (horizontal)
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: children,
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Row(this.label, this.value, [this.valueColor]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? Colors.white70,
                    fontSize: 11,
                    fontWeight: valueColor != null
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontStyle: FontStyle.italic)),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  final String status;
  const _HealthBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'Critical':
        return AppTheme.errorRed;
      case 'Requires Attention':
        return AppTheme.warningOrange;
      case 'Needs Monitoring':
        return AppTheme.infoBlue;
      default:
        return AppTheme.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: _color, fontSize: 8, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 8, fontWeight: FontWeight.w700)),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  final CameraConnectionState state;
  const _ConnectionDot({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (state) {
      case CameraConnectionState.connected:
        color = AppTheme.successGreen;
      case CameraConnectionState.connecting:
        color = AppTheme.warningOrange;
      case CameraConnectionState.error:
        color = AppTheme.errorRed;
      case CameraConnectionState.disconnected:
        color = Colors.white24;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TileMenuButton extends StatelessWidget {
  final CameraModel camera;
  final VoidCallback onAnalyze;
  final VoidCallback onReconnect;
  final VoidCallback onRemove;
  final VoidCallback onViewDetails;

  const _TileMenuButton({
    required this.camera,
    required this.onAnalyze,
    required this.onReconnect,
    required this.onRemove,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      iconSize: 16,
      icon: const Icon(Icons.more_vert, color: Colors.white38, size: 16),
      color: const Color(0xFF1A2332),
      onSelected: (value) {
        switch (value) {
          case 'analyze':
            onAnalyze();
          case 'reconnect':
            onReconnect();
          case 'details':
            onViewDetails();
          case 'remove':
            onRemove();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'analyze',
          child: _MenuRow(
              icon: Icons.analytics_outlined,
              label: 'Analyze Now',
              color: AppTheme.lightTeal),
        ),
        const PopupMenuItem(
          value: 'details',
          child: _MenuRow(
              icon: Icons.info_outline, label: 'View Details'),
        ),
        const PopupMenuItem(
          value: 'reconnect',
          child: _MenuRow(
              icon: Icons.refresh, label: 'Reconnect'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'remove',
          child: _MenuRow(
              icon: Icons.delete_outline,
              label: 'Remove',
              color: AppTheme.errorRed),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow(
      {required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white70;
    return Row(
      children: [
        Icon(icon, color: c, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: c, fontSize: 13)),
      ],
    );
  }
}

// ── Form helper widgets ───────────────────────────────────────────────────────

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;

  const _DarkTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0F1923),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppTheme.lightTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.errorRed),
        ),
      ),
    );
  }
}

class _DarkDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DarkDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF1A2332),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0F1923),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
      items: items
          .map((v) => DropdownMenuItem(
                value: v,
                child: Text(v,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _InfoTip extends StatelessWidget {
  final String text;
  const _InfoTip(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
