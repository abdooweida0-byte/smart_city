import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});
  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _map = MapController();
  String _category = categories.first;
  File? _image;
  LatLng? _pos;
  bool _locating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _msg('شغّل الـ GPS');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _msg('محتاجين إذن الموقع. تقدر تختار المكان من الخريطة.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _pos = LatLng(pos.latitude, pos.longitude));
      _map.move(_pos!, 16);
    } catch (e) {
      _msg('تعذر تحديد الموقع، اختار المكان من الخريطة');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickImage(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, imageQuality: 70);
    if (x == null) return;
    // Copy into app storage so the photo stays available.
    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(
        dir.path, 'report_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final saved = await File(x.path).copy(dest);
    if (mounted) setState(() => _image = saved);
  }

  void _chooseSource() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('الكاميرا'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('المعرض'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_pos == null) {
      _msg('حدد موقع المشكلة (GPS أو اضغط على الخريطة)');
      return;
    }
    setState(() => _saving = true);
    await context.read<AppProvider>().addReport(
          title: _title.text.trim(),
          description: _desc.text.trim(),
          category: _category,
          lat: _pos!.latitude,
          lng: _pos!.longitude,
          imagePath: _image?.path,
        );
    if (!mounted) return;
    Navigator.pop(context);
    _msg('تم إرسال البلاغ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بلاغ جديد')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _chooseSource,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo, size: 40),
                            SizedBox(height: 8),
                            Text('اضغط لإضافة صورة'),
                          ],
                        ),
                      )
                    : Image.file(_image!,
                        fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'عنوان البلاغ', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب عنوان' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                  labelText: 'النوع', border: OutlineInputBorder()),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c, child: Text(c))
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'الوصف', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اكتب وصف' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                    child: Text('الموقع (اضغط على الخريطة لتعديله)',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                TextButton.icon(
                  onPressed: _locating ? null : _getLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: const Text('GPS'),
                ),
              ],
            ),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _pos ?? const LatLng(30.0444, 31.2357),
                    initialZoom: 14,
                    onTap: (_, point) => setState(() => _pos = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smartcity.smart_city',
                    ),
                    if (_pos != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: _pos!,
                          width: 44,
                          height: 44,
                          child: const Icon(Icons.location_on,
                              size: 44, color: Colors.red),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
            if (_pos != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    '${_pos!.latitude.toStringAsFixed(5)}, ${_pos!.longitude.toStringAsFixed(5)}',
                    textDirection: TextDirection.ltr),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Icons.send),
              label: const Text('إرسال البلاغ'),
            ),
          ],
        ),
      ),
    );
  }
}
