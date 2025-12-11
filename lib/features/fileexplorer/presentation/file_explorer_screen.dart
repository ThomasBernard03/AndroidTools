import 'package:android_tools/features/fileexplorer/presentation/file_explorer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileExplorerScreen extends StatelessWidget {
  final bloc = FileExplorerBloc();

  FileExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: bloc, child: const Text("Hello"));
  }
}
