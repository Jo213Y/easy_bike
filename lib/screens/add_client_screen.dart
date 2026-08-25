import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import '../services/firestore_service.dart';
import '../utils/time_format.dart';
import '../utils/dialogs.dart';
import '../theme/theme_toggle_button.dart';
import '../widgets/client_card.dart';

class AddClientScreen extends StatefulWidget {
  final ClientModel? prefillClient;

  const AddClientScreen({super.key, this.prefillClient});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _scrollController = ScrollController();

  final _nameCtrl = TextEditingController();
  final _referredByCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _sessionsCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _totalPriceCtrl = TextEditingController();

  DateTime _selectedDay = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String _vehicleType = 'scooter';

  ClientModel? _editingClient;

  @override
  void initState() {
    super.initState();
    if (widget.prefillClient != null) {
      _startEditing(widget.prefillClient!);
    }
  }

  void _startEditing(ClientModel client) {
    _editingClient = client;
    _nameCtrl.text = client.name;
    _referredByCtrl.text = client.referredBy;
    _phoneCtrl.text = client.phone;
    _sessionsCtrl.text = client.totalSessions.toString();
    _totalPriceCtrl.text = client.totalPrice.toString();
    _paidCtrl.text = client.amountPaid.toString();
    _selectedDay = client.day;
    final startParts = client.startTime.split(':');
    final endParts = client.endTime.split(':');
    _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    _vehicleType = client.vehicleType;
  }

  void _cancelEditing() {
    setState(() {
      _editingClient = null;
      _nameCtrl.clear();
      _referredByCtrl.clear();
      _phoneCtrl.clear();
      _sessionsCtrl.clear();
      _paidCtrl.clear();
      _totalPriceCtrl.clear();
      _vehicleType = 'scooter';
      _selectedDay = DateTime.now();
      _startTime = const TimeOfDay(hour: 10, minute: 0);
      _endTime = const TimeOfDay(hour: 11, minute: 0);
    });
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDay = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final editing = _editingClient;

    if (editing != null) {
      final updated = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'referredBy': _referredByCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'totalSessions': int.tryParse(_sessionsCtrl.text) ?? 0,
        'amountPaid': double.tryParse(_paidCtrl.text) ?? 0,
        'totalPrice': double.tryParse(_totalPriceCtrl.text) ?? 0,
        'day': Timestamp.fromDate(_selectedDay),
        'startTime': _fmt(_startTime),
        'endTime': _fmt(_endTime),
        'vehicleType': _vehicleType,
        'isCancelled': false,
      };

      await _service.updateClient(editing.id, updated);

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          _cancelEditing();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تعديل بيانات الموعد بنجاح')),
          );
        }
      }
      return;
    }


    final client = ClientModel(
      id: '',
      name: _nameCtrl.text.trim(),
      referredBy: _referredByCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      totalSessions: int.tryParse(_sessionsCtrl.text) ?? 0,
      usedSessions: 0,
      amountPaid: double.tryParse(_paidCtrl.text) ?? 0,
      totalPrice: double.tryParse(_totalPriceCtrl.text) ?? 0,
      day: _selectedDay,
      startTime: _fmt(_startTime),
      endTime: _fmt(_endTime),
      vehicleType: _vehicleType,
      createdAt: DateTime.now(),
    );

    await _service.addClient(client);

    if (mounted) {
      _nameCtrl.clear();
      _referredByCtrl.clear();
      _phoneCtrl.clear();
      _sessionsCtrl.clear();
      _paidCtrl.clear();
      _totalPriceCtrl.clear();
      setState(() => _vehicleType = 'scooter');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الموعد بنجاح')),
      );
    }
  }


  void _openEditForm(ClientModel client) {
    setState(() => _startEditing(client));

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('عدّل بيانات الموعد وبعدين دوس حفظ التعديلات')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingClient != null ? 'تعديل موعد ${_editingClient!.name}' : 'إضافة متدرب'),
        actions: [
          if (_editingClient != null)
            IconButton(
              tooltip: 'إلغاء التعديل',
              icon: const Icon(Icons.close),
              onPressed: _cancelEditing,
            ),
          const ThemeToggleButton(),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(_nameCtrl, 'اسم المتدرب', required: true),
                  _buildTextField(_referredByCtrl, 'جاي من طرف مين'),
                  _buildTextField(_phoneCtrl, 'رقم التلفون', keyboardType: TextInputType.phone),
                  _buildTextField(_sessionsCtrl, 'عدد السيشنات (كام مره حاجز)',
                      keyboardType: TextInputType.number, required: true),
                  _buildTextField(_totalPriceCtrl, 'السعر الكلي المتفق عليه',
                      keyboardType: TextInputType.number, required: true),
                  _buildTextField(_paidCtrl, 'المبلغ المدفوع دلوقتي',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            value: 'scooter',
                            groupValue: _vehicleType,
                            activeColor: Colors.purple,
                            title: Row(
                              children: [
                                Icon(Icons.electric_scooter,
                                    color: Theme.of(context).colorScheme.onSurface, size: 18),
                                const SizedBox(width: 6),
                                Text('سكوتر',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                              ],
                            ),
                            onChanged: (v) => setState(() => _vehicleType = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            value: 'motorcycle',
                            groupValue: _vehicleType,
                            activeColor: Colors.purple,
                            title: Row(
                              children: [
                                Icon(Icons.two_wheeler,
                                    color: Theme.of(context).colorScheme.onSurface, size: 18),
                                const SizedBox(width: 6),
                                Text('موتوسيكل',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
                              ],
                            ),
                            onChanged: (v) => setState(() => _vehicleType = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor: Theme.of(context).cardColor,
                    title: Text('اليوم',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    subtitle: Text(
                      '${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurface),
                    onTap: _pickDay,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          tileColor: Theme.of(context).cardColor,
                          title: Text('من',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text(formatTime12h(_fmt(_startTime)),
                              style: const TextStyle(color: Colors.grey)),
                          onTap: () => _pickTime(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ListTile(
                          tileColor: Theme.of(context).cardColor,
                          title: Text('لحد',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Text(formatTime12h(_fmt(_endTime)),
                              style: const TextStyle(color: Colors.grey)),
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_editingClient != null ? 'حفظ التعديلات' : 'حفظ الموعد'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('المتدربين اللي حجزوا قبل كده',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<List<ClientModel>>(
              stream: _service.streamAllClients(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final clients = snapshot.data!;
                if (clients.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لسه مفيش حد متسجل', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: clients
                      .map((c) => ClientCard(
                            client: c,
                            onNewAppointment: () => _openEditForm(c),
                            onAddSessions: () => showAddSessionsDialog(context, _service, c),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTextField(TextEditingController ctrl, String label,
      {TextInputType? keyboardType, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
