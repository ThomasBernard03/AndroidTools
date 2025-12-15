import 'package:android_tools/features/fileexplorer/core/int_extensions.dart';
import 'package:android_tools/features/fileexplorer/presentation/file_explorer_bloc.dart';
import 'package:android_tools/features/fileexplorer/presentation/file_type_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileExplorerScreen extends StatelessWidget {
  final bloc = FileExplorerBloc();

  FileExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc..add(OnAppearing()),
      child: Scaffold(
        body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
          builder: (context, state) {
            return ListView.builder(
              itemCount: state.files.length,
              itemBuilder: (context, index) {
                final file = state.files[index];
                return ListTile(
                  leading: Icon(file.type.icon()),
                  title: Text(file.name),
                  subtitle: Text(file.date.toString()),
                  onTap: () {},
                );
              },
            );
          },
        ),
      ),
    );
  }
}
