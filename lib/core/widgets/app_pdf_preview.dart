import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// PDF preview used for every PDF the app produces: one page at a time with
/// page and zoom controls, keyboard navigation, and print/share actions.
class AppPdfPreview extends StatelessWidget {
  const AppPdfPreview({
    super.key,
    required this.buildPdf,
    required this.fileName,
    this.onOutput,
  });

  /// Produces the PDF bytes.
  final LayoutCallback buildPdf;

  /// Name for a shared or saved file, e.g. `Pilot_Logbook_2026.pdf`.
  final String fileName;

  /// Called after the PDF was printed or shared.
  final VoidCallback? onOutput;

  Future<void> _print(
    BuildContext context,
    LayoutCallback build,
    PdfPageFormat format,
  ) async {
    // Browsers name "Save as PDF" after the page title, and the printing
    // package ignores `name` on web, so show the file name while printing.
    if (kIsWeb) {
      await SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
          label: fileName.replaceAll(RegExp(r'\.pdf$'), ''),
        ),
      );
    }
    try {
      final printed = await Printing.layoutPdf(
        onLayout: build,
        name: fileName,
        format: format,
      );
      if (printed) onOutput?.call();
    } finally {
      if (kIsWeb) {
        await SystemChrome.setApplicationSwitcherDescription(
          const ApplicationSwitcherDescription(label: 'Spreadlog'),
        );
      }
    }
  }

  /// Web "share" just downloads the file, so it is offered as a download.
  Future<void> _download(
    BuildContext context,
    LayoutCallback build,
    PdfPageFormat format,
  ) async {
    final shared = await Printing.sharePdf(
      bytes: await build(format),
      filename: fileName,
    );
    if (shared) onOutput?.call();
  }

  @override
  Widget build(BuildContext context) {
    return PdfPreview.builder(
      build: buildPdf,
      pdfFileName: fileName,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      // Replaced by the action below so the web print gets the file name.
      allowPrinting: false,
      // On web sharing downloads the file; see the Download action below.
      allowSharing: !kIsWeb,
      onShared: (_) => onOutput?.call(),
      actions: [
        PdfPreviewAction(
          icon: const Tooltip(message: 'Print', child: Icon(Icons.print)),
          onPressed: _print,
        ),
        if (kIsWeb)
          PdfPreviewAction(
            icon: const Tooltip(
              message: 'Download',
              child: Icon(Icons.download),
            ),
            onPressed: _download,
          ),
      ],
      pagesBuilder: (context, pages) => _PagedPdfView(pages: pages),
    );
  }
}

class _PagedPdfView extends StatefulWidget {
  const _PagedPdfView({required this.pages});

  final List<PdfPreviewPageData> pages;

  @override
  State<_PagedPdfView> createState() => _PagedPdfViewState();
}

class _PagedPdfViewState extends State<_PagedPdfView> {
  final _pageController = PageController();
  final _transform = TransformationController();
  final _viewportKey = GlobalKey();
  int _index = 0;
  bool _zoomed = false;

  int get _pageCount => widget.pages.length;

  @override
  void dispose() {
    _pageController.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _pageCount || index == _index) return;
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      _transform.value = Matrix4.identity();
      _zoomed = false;
    });
  }

  void _zoom(double factor) {
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) return;
    final center = viewport.size.center(Offset.zero);
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(1.0, 6.0);
    if (target == 1) {
      _transform.value = Matrix4.identity();
    } else {
      final relative = target / current;
      final adjustment = Matrix4.identity()
        ..translateByDouble(center.dx, center.dy, 0, 1)
        ..scaleByDouble(relative, relative, 1, 1)
        ..translateByDouble(-center.dx, -center.dy, 0, 1);
      _transform.value = adjustment.multiplied(_transform.value);
    }
    setState(() => _zoomed = target > 1);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp) {
      _goTo(_index - 1);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown) {
      _goTo(_index + 1);
    } else if (key == LogicalKeyboardKey.home) {
      _goTo(0);
    } else if (key == LogicalKeyboardKey.end) {
      _goTo(_pageCount - 1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    // Wraps the controls too: clicking a zoom button moves focus there, and
    // the arrow keys must still turn pages instead of moving focus.
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              // Swiping would fight panning a zoomed page.
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemCount: _pageCount,
              itemBuilder: (context, i) {
                final page = widget.pages[i];
                final image = Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: AspectRatio(
                      aspectRatio: page.aspectRatio,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(blurRadius: 6, color: Colors.black38),
                          ],
                        ),
                        child: Image(image: page.image, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
                if (i != _index) return image;
                return InteractiveViewer(
                  key: _viewportKey,
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 6,
                  onInteractionEnd: (_) => setState(
                    () => _zoomed = _transform.value.getMaxScaleOnAxis() > 1.01,
                  ),
                  child: image,
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Material(
              child: SafeArea(
                top: false,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_pageCount > 1) ...[
                      IconButton(
                        tooltip: 'Previous page',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                      ),
                      Text('Page ${_index + 1} of $_pageCount'),
                      IconButton(
                        tooltip: 'Next page',
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _index == _pageCount - 1
                            ? null
                            : () => _goTo(_index + 1),
                      ),
                    ],
                    IconButton(
                      tooltip: 'Zoom out',
                      icon: const Icon(Icons.zoom_out),
                      onPressed: () => _zoom(1 / 1.5),
                    ),
                    IconButton(
                      tooltip: 'Fit page',
                      icon: const Icon(Icons.fit_screen),
                      onPressed: () => _zoom(0),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      icon: const Icon(Icons.zoom_in),
                      onPressed: () => _zoom(1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
