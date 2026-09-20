import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cloudinary_download.dart';

/// Намоиши пурраи аксҳо — калон кардан (pinch-to-zoom), гузариш бо
/// ангушт, ва боргирии як ё ҳамаи аксҳо (тавассути браузер).
class PhotoGalleryScreen extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const PhotoGalleryScreen({super.key, required this.photoUrls, this.initialIndex = 0});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  Future<void> _downloadCurrent() async {
    final url = cloudinaryDownloadUrl(widget.photoUrls[_currentIndex]);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _downloadAll() async {
    for (final url in widget.photoUrls) {
      await launchUrl(Uri.parse(cloudinaryDownloadUrl(url)), mode: LaunchMode.externalApplication);
      // Каме таваққуф, то браузер тавонад ҳар боргириро алоҳида идора кунад.
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photoUrls.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Боргирии ин акс',
            onPressed: _downloadCurrent,
          ),
          if (widget.photoUrls.length > 1)
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              tooltip: 'Боргирии ҳамаи аксҳо',
              onPressed: _downloadAll,
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoUrls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.network(
                widget.photoUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
