import 'package:android_tools/features/fileexplorer/core/string_extensions.dart';
import 'package:android_tools/features/fileexplorer/domain/entities/file_type.dart';
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
        appBar: AppBar(
          centerTitle: false,
          title: BlocBuilder<FileExplorerBloc, FileExplorerState>(
            builder: (context, state) {
              return Text(state.path);
            },
          ),
          leading: BlocBuilder<FileExplorerBloc, FileExplorerState>(
            builder: (context, state) {
              return IconButton(
                onPressed: state.path.isRootPath()
                    ? null
                    : () {
                        context.read<FileExplorerBloc>().add(OnGoBack());
                      },
                icon: Icon(Icons.chevron_left_rounded),
              );
            },
          ),
        ),
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
                  onTap: () {
                    if (file.type == FileType.directory) {
                      context.read<FileExplorerBloc>().add(
                        OnGoToFolder(folder: file),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
