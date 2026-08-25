import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/firestore_service.dart';
import '../utils/dialogs.dart';
import '../theme/theme_toggle_button.dart';
import '../widgets/client_card.dart';
import 'add_client_screen.dart';


class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

enum _VehicleFilter { all, scooter, motorcycle }

class _ClientsListScreenState extends State<ClientsListScreen> {
  final _service = FirestoreService();
  _VehicleFilter _filter = _VehicleFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كل المتدربين'),
        actions: const [ThemeToggleButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _filterChip('الكل', _VehicleFilter.all)),
                const SizedBox(width: 8),
                Expanded(
                  child: _filterChip('سكوتر', _VehicleFilter.scooter, icon: Icons.electric_scooter),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _filterChip('موتوسيكل', _VehicleFilter.motorcycle, icon: Icons.two_wheeler),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ClientModel>>(
              stream: _service.streamAllClients(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var clients = snapshot.data!;
                if (_filter == _VehicleFilter.scooter) {
                  clients = clients.where((c) => c.vehicleType == 'scooter').toList();
                } else if (_filter == _VehicleFilter.motorcycle) {
                  clients = clients.where((c) => c.vehicleType == 'motorcycle').toList();
                }

                if (clients.isEmpty) {
                  return const Center(
                    child: Text('مفيش متدربين هنا', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final c = clients[index];

                      return ClientCard(
                        client: c,

                        onNewAppointment: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddClientScreen(prefillClient: c),
                            ),
                          );
                        },

                        onAddSessions: () =>
                            showAddSessionsDialog(context, _service, c),

                        onDelete: () async {
                          await _service.deleteClientPermanently(c.id);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("تم حذف المتدرب"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _VehicleFilter value, {IconData? icon}) {
    final selected = _filter == value;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: selected ? Colors.white : onSurface, fontSize: 12)),
        ],
      ),
      selected: selected,
      selectedColor: Colors.purple,
      backgroundColor: Theme.of(context).cardColor,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
