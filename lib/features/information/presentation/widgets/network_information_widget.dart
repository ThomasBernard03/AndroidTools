import 'package:flutter/material.dart';

class NetworkInformationWidget extends StatelessWidget {
  final String? wifiSsid;
  final String? ipAddress;

  const NetworkInformationWidget({
    super.key,
    this.wifiSsid,
    this.ipAddress,
  });

  @override
  Widget build(BuildContext context) {
    final hasWifi = wifiSsid != null && wifiSsid!.isNotEmpty;

    return SizedBox(
      width: 200,
      height: 200,
      child: Card(
        color: Color(0xFF1A1D1C),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    hasWifi ? Icons.wifi : Icons.wifi_off,
                    size: 64,
                    color: hasWifi
                        ? Colors.white.withAlpha(100)
                        : Colors.white.withAlpha(50),
                  ),
                ),
              ),
              Text(
                wifiSsid ?? "Not connected",
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              if (ipAddress != null && ipAddress!.isNotEmpty)
                Text(
                  ipAddress!,
                  style: TextStyle(color: Color(0xFF6C696E), fontSize: 14),
                ),
              Text(
                "Network",
                style: TextStyle(color: Color(0xFF6C696E), fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
