import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfPreviewWidget extends StatefulWidget {
  final String pdfPath;
  final String fileName;

  const PdfPreviewWidget({
    super.key,
    required this.pdfPath,
    required this.fileName,
  });

  @override
  State<PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<PdfPreviewWidget> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      setState(() {
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(widget.pdfPath),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('password') || errorStr.contains('encrypted')) {
      return 'This PDF is password-protected';
    } else if (errorStr.contains('corrupt') || errorStr.contains('invalid')) {
      return 'This PDF file appears to be corrupted';
    } else if (errorStr.contains('format')) {
      return 'Unsupported PDF format';
    }

    return 'Failed to load PDF: ${error.toString()}';
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Cannot display PDF',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_pdfController == null) {
      return const Center(
        child: Text('PDF controller not initialized'),
      );
    }

    return Container(
      color: Colors.black12,
      child: PdfViewPinch(
        controller: _pdfController!,
        scrollDirection: Axis.vertical,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black12,
        ),
        onDocumentError: (error) {
          setState(() {
            _errorMessage = _getErrorMessage(error);
          });
        },
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
          pageLoaderBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorBuilder: (context, error) => Center(
            child: Text(
              'Error loading page',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
