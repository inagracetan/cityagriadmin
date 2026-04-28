import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:typed_data';

Future<String?> saveFileSafely(
  List<int> bytes,
  String fileName,
  String extension,
) async {
  final uint8List = Uint8List.fromList(bytes);

  // Set the correct MIME type based on the extension
  String mimeType = 'application/octet-stream';
  final lowerExt = extension.toLowerCase().replaceAll('.', '');
  if (lowerExt == 'pdf') {
    mimeType = 'application/pdf';
  } else if (lowerExt == 'xlsx') {
    mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  } else if (lowerExt == 'csv') {
    mimeType = 'text/csv';
  }

  final blob = web.Blob(
    [uint8List.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );

  final url = web.URL.createObjectURL(blob);

  // Ensure fileName includes the extension
  final fullFileName = fileName.toLowerCase().endsWith('.$lowerExt')
      ? fileName
      : '$fileName.$lowerExt';

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fullFileName;

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
  return 'downloaded';
}
