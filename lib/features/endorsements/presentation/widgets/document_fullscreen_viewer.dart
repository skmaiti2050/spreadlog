import 'package:flutter/material.dart';

import '../../domain/endorsement_document.dart';
import 'image_loader/endorsement_image_loader.dart';

class DocumentFullscreenViewer extends StatefulWidget {
  final EndorsementDocument document;
  final int initialPage;

  const DocumentFullscreenViewer({
    super.key,
    required this.document,
    this.initialPage = 0,
  });

  @override
  State<DocumentFullscreenViewer> createState() =>
      _DocumentFullscreenViewerState();
}

class _DocumentFullscreenViewerState extends State<DocumentFullscreenViewer> {
  final _transform = TransformationController();
  final _viewportKey = GlobalKey();
  late int _pageIndex;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialPage;
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _changePage(int index) {
    setState(() {
      _pageIndex = index;
      _transform.value = Matrix4.identity();
    });
  }

  void _zoom(double factor, [Offset? anchor]) {
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) return;
    final center = anchor ?? viewport.size.center(Offset.zero);
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(1.0, 8.0);
    if (target == 1) {
      _transform.value = Matrix4.identity();
      return;
    }
    final relative = target / current;
    final adjustment = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(relative, relative, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    _transform.value = adjustment.multiplied(_transform.value);
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(document.category.label),
        leading: IconButton(
          tooltip: 'Close full view',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(_pageIndex),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, imageConstraints) {
                    return GestureDetector(
                      onDoubleTapDown: (details) =>
                          _doubleTapPosition = details.localPosition,
                      onDoubleTap: () {
                        if (_transform.value.getMaxScaleOnAxis() > 1) {
                          _transform.value = Matrix4.identity();
                        } else {
                          _zoom(2.5, _doubleTapPosition);
                        }
                      },
                      child: InteractiveViewer(
                        key: _viewportKey,
                        transformationController: _transform,
                        minScale: 1,
                        maxScale: 8,
                        child: SizedBox(
                          width: imageConstraints.maxWidth,
                          height: imageConstraints.maxHeight,
                          child: defaultImageLoader.buildImage(
                            document.pages[_pageIndex].originalPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Material(
                child: SafeArea(
                  top: false,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (document.pageCount > 1) ...[
                        IconButton(
                          tooltip: 'Previous document page',
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _pageIndex == 0
                              ? null
                              : () => _changePage(_pageIndex - 1),
                        ),
                        Text('Page ${_pageIndex + 1} of ${document.pageCount}'),
                        IconButton(
                          tooltip: 'Next document page',
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _pageIndex == document.pageCount - 1
                              ? null
                              : () => _changePage(_pageIndex + 1),
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
                        onPressed: () => _transform.value = Matrix4.identity(),
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
            ],
          );
        },
      ),
    );
  }
}
