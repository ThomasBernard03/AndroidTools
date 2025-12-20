import 'package:path/path.dart' as p;

extension StringExtensions on String {
  bool isRootPath() {
    final parentPath = p.dirname(this);
    return parentPath == this;
  }
}
