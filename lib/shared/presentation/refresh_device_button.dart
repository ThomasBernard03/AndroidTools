import 'package:flutter/material.dart';

class RefreshDeviceButton extends StatelessWidget {
  final void Function()? onPressed;

  const RefreshDeviceButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(onPressed: onPressed, child: Text("Refresh devices")),
        Text("Can't find any android devices"),
      ],
    );
  }
}
