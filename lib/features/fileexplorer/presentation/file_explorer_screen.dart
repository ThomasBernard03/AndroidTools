import 'package:android_tools/features/fileexplorer/core/int_extensions.dart';
import 'package:android_tools/features/fileexplorer/presentation/file_explorer_bloc.dart';
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
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        style: TextStyle(fontSize: 12),
                        "name:${file.name} links:${file.links} date:${file.date} owner:${file.owner} permissions:${file.permissions}",
                      ),
                    ),
                    Text("${file.size?.toReadableBytes().toString()}"),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
