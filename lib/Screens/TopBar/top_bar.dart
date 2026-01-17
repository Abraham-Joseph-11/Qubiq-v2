import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../Providers/block_provider.dart';
import '../../Services/bluetooth_manager.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BlockProvider>();
    final bluetooth = context.watch<BluetoothManager>();

    // ✅ Detect screen width to adjust sizes dynamically
    double screenWidth = MediaQuery.of(context).size.width;
    bool isSmallMobile = screenWidth < 400;

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Back Button
          IconButton(
            constraints: const BoxConstraints(), // Removes default padding
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),

          // 2. Heading: "Little Emmi"
          // ✅ Reduced font size on small screens to prevent overflow
          Text(
            'Little Emmi',
            style: TextStyle(
                color: const Color(0xFF007AFF),
                fontSize: isSmallMobile ? 16 : 20,
                fontWeight: FontWeight.bold
            ),
          ),

          // 3. Dynamic Spacer
          SizedBox(width: isSmallMobile ? 4 : 12),

          // 4. Connect Button
          _menuItem(
            Icons.electrical_services_outlined,
            // ✅ Only show label if there is enough space
            isSmallMobile ? "" : (bluetooth.isConnected ? 'Connected' : 'Connect'),
            iconColor: bluetooth.isConnected ? Colors.green : Colors.grey[700],
            onTap: () => _showBluetoothDialog(context),
          ),

          const Spacer(),

          // 5. Action Buttons (Test & Reset)
          // ✅ Wrapped in a Row with mainAxisSize.min to stay compact
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionButton(
                icon: Icons.check_circle_outline,
                label: 'Test',
                isMobile: isSmallMobile,
                color: const Color(0xFF007AFF),
                onPressed: () => bluetooth.sendData("F"),
              ),
              const SizedBox(width: 8),
              _actionButton(
                icon: Icons.refresh,
                label: 'Reset',
                isMobile: isSmallMobile,
                color: Colors.grey[700]!,
                onPressed: () => provider.resetRobotPosition(),
                isOutlined: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Helper for Test/Reset buttons to switch between Icon and Text
  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool isMobile,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(color: Colors.grey[400]!),
          minimumSize: const Size(40, 40),
        ),
        child: isMobile ? Icon(icon, color: color, size: 20) : Text(label, style: TextStyle(color: color)),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: color,
        minimumSize: const Size(40, 40),
      ),
      child: isMobile ? Icon(icon, color: Colors.white, size: 20) : Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  // ... (Bluetooth Dialog logic remains exactly the same as your original file)
  void _showBluetoothDialog(BuildContext context) {
    final bluetooth = context.read<BluetoothManager>();
    if (bluetooth.isConnected) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Disconnect?"),
            content: Text("Connected to ${bluetooth.connectedDevice?.platformName}"),
            actions: [
              TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
              TextButton(
                  child: const Text("Disconnect", style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    bluetooth.disconnect();
                    Navigator.pop(context);
                  }
              ),
            ],
          )
      );
      return;
    }
    bluetooth.startScan();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Connect to Robot"),
          content: SizedBox(
            width: 400,
            height: 300,
            child: Column(
              children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<List<ScanResult>>(
                    stream: bluetooth.scanResults,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Scanning..."));
                      final results = snapshot.data!
                          .where((r) => r.device.platformName.toLowerCase().contains("little emmi"))
                          .toList();
                      if (results.isEmpty) return const Center(child: Text("No robots found."));
                      return ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final device = results[index].device;
                          return ListTile(
                            leading: const Icon(Icons.smart_toy, color: Colors.indigo),
                            title: Text(device.platformName),
                            trailing: ElevatedButton(
                              child: const Text("Connect"),
                              onPressed: () async {
                                Navigator.pop(context);
                                await bluetooth.connectToDevice(device);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(child: const Text("Close"), onPressed: () => Navigator.pop(context))
          ],
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String title, {required VoidCallback onTap, Color? iconColor}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey[700]),
          if (title.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(title, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}