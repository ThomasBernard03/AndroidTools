import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/arta.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/shell.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/plaintext.dart';

class TextPreviewWidget extends StatefulWidget {
  final String content;
  final String fileName;

  const TextPreviewWidget({
    super.key,
    required this.content,
    required this.fileName,
  });

  @override
  State<TextPreviewWidget> createState() => _TextPreviewWidgetState();
}

class _TextPreviewWidgetState extends State<TextPreviewWidget> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.content,
      language: _getLanguageFromFileName(widget.fileName),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Détermine le langage de coloration syntaxique selon l'extension du fichier
  dynamic _getLanguageFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      // Dart
      case 'dart':
        return dart;

      // Java & Kotlin
      case 'java':
        return java;
      case 'kt':
      case 'kts':
        return kotlin;

      // XML & HTML
      case 'xml':
      case 'html':
      case 'htm':
        return xml;

      // JSON & YAML
      case 'json':
        return json;
      case 'yaml':
      case 'yml':
        return yaml;

      // Python
      case 'py':
      case 'pyw':
        return python;

      // JavaScript & TypeScript
      case 'js':
      case 'jsx':
      case 'mjs':
        return javascript;
      case 'ts':
      case 'tsx':
        return typescript;

      // C/C++
      case 'c':
      case 'h':
      case 'cpp':
      case 'cc':
      case 'cxx':
      case 'hpp':
        return cpp;

      // CSS
      case 'css':
      case 'scss':
      case 'sass':
        return css;

      // Shell scripts
      case 'sh':
      case 'bash':
      case 'zsh':
        return shell;

      // SQL
      case 'sql':
        return sql;

      // Gradle (utilise le format Groovy/Kotlin)
      case 'gradle':
        return fileName.endsWith('.gradle.kts') ? kotlin : java;

      // Fichiers de configuration Android
      case 'properties':
      case 'pro':
        return plaintext;

      // Markdown, text, etc.
      case 'md':
      case 'txt':
      case 'log':
      default:
        return plaintext;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: CodeTheme(
        data: CodeThemeData(styles: artaTheme),
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontSize: 12),
          wrap: true,
          readOnly: true,
        ),
      ),
    );
  }
}
