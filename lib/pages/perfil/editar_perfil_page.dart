import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// Import con alias para evitar conflictos con el modelo User del auth
import '../../models/user_model.dart' as models;
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class EditarPerfilPage extends StatefulWidget {
  final models.User user;
  final Function(models.User) onUserUpdated;

  const EditarPerfilPage({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final ImagePicker _imagePicker = ImagePicker();

  late models.User _user;
  XFile? _selectedImage;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _user = widget.user;

    if (_user.fechaNacimiento != null) {
      _selectedDate = DateTime.tryParse(_user.fechaNacimiento!);
    }
  }

  // ---------------------------------------------------
  // GUARDAR IMAGEN USANDO EL SERVICIO LOCAL
  // ---------------------------------------------------
  Future<String?> _uploadImage(String imagePath) async {
    final localPath = await UserService.uploadAvatar(imagePath);
    if (localPath == null) {
      _showErrorDialog("No se pudo guardar la imagen en el dispositivo.");
    }
    return localPath;
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final img = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (img != null) setState(() => _selectedImage = img);
    } catch (e) {
      _showPermissionDialog(
        "Permiso requerido",
        "Debes permitir acceso a tus fotos para usar la galería.",
      );
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final img = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (img != null) setState(() => _selectedImage = img);
    } catch (e) {
      _showPermissionDialog(
        "Permiso requerido",
        "Debes permitir acceso a la cámara.",
      );
    }
  }

  // ---------------------------------------------------
  // FECHA DE NACIMIENTO
  // ---------------------------------------------------
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _user = _user.copyWith(fechaNacimiento: picked.toIso8601String());
      });
    }
  }

  // ---------------------------------------------------
  // DIALOGOS
  // ---------------------------------------------------
  void _showPermissionDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text("Abrir configuración"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text("Error"), content: Text(msg)),
    );
  }

  // ---------------------------------------------------
  // GUARDAR CAMBIOS EN SUPABASE - CORREGIDO
  // ---------------------------------------------------
  Future<void> _guardarCambios() async {
    try {
      String? imageUrl = _user.profileImage;

      if (_selectedImage != null) {
        final uploaded = await _uploadImage(_selectedImage!.path);
        if (uploaded != null) {
          imageUrl = uploaded;
          _user = _user.copyWith(profileImage: imageUrl);
        }
      }

      final success = await UserService.updateProfile(_user);

      if (success) {
        widget.onUserUpdated(_user);
        if (mounted) Navigator.pop(context);
      } else {
        _showErrorDialog("No se pudo actualizar el perfil en la base de datos.");
      }
    } catch (e) {
      _showErrorDialog("Error al guardar: $e");
    }
  }

  // ---------------------------------------------------
  // UI
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        actions: [
          TextButton(
            onPressed: _guardarCambios,
            child: const Text("Guardar", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildForm(),
      ),
    );
  }

  // ---------------------------------------------------
  // FORMULARIO
  // ---------------------------------------------------
  Widget _buildForm() {
    return Column(
      children: [
        _buildProfilePhoto(),
        const SizedBox(height: 20),
        _textField("Nombre", _user.name ?? "",
            (v) => setState(() => _user = _user.copyWith(name: v))),
        const SizedBox(height: 16),
        _textField("Correo", _user.email, (v) {}),
        const SizedBox(height: 16),
        _textField("Matrícula", _user.matricula ?? "",
            (v) => setState(() => _user = _user.copyWith(matricula: v))),
        const SizedBox(height: 16),
        _dropdown(
            "Sexo",
            _user.sexo,
            ["Masculino", "Femenino", "Otro", "Prefiero no decir"],
            (v) => setState(() => _user = _user.copyWith(sexo: v))),
        const SizedBox(height: 16),
        _dropdown(
            "Carrera",
            _user.career,
            [
              'Ing. Sistemas Computacionales',
              'Ing. Biomédica',
              'Ing. Ambiental',
              'Ing. Electrónica',
              'Ing. Informática',
              'Administración',
              'Arquitectura'
            ],
            (v) => setState(() => _user = _user.copyWith(career: v))),
        const SizedBox(height: 16),
        _dropdown(
          "Semestre",
          _user.semestre?.toString(),
          ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
          (v) => setState(() => _user =
              _user.copyWith(semestre: v != null ? int.tryParse(v) : null)),
        ),
        const SizedBox(height: 16),
        _buildDateSelector(),
        const SizedBox(height: 20),
        _buildSwitches(),
      ],
    );
  }

  // ---------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------
  Widget _buildProfilePhoto() {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(File(_selectedImage!.path));
    } else if (_user.profileImage != null &&
        _user.profileImage!.startsWith("http")) {
      imageProvider = NetworkImage(_user.profileImage!);
    } else if (_user.profileImage != null && _user.profileImage!.isNotEmpty) {
      final file = File(_user.profileImage!);
      if (file.existsSync()) imageProvider = FileImage(file);
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePicker,
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 45, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
            onPressed: _showImagePicker, child: const Text("Cambiar foto")),
      ],
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Galería"),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Cámara"),
            onTap: () {
              Navigator.pop(context);
              _takePhotoWithCamera();
            },
          ),
          if (_user.profileImage != null)
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text("Eliminar foto"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedImage = null;
                  _user = _user.copyWith(profileImage: null);
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _textField(String label, String value, Function(String) onChanged) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }

  Widget _dropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? "Seleccionar fecha"
                  : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSwitches() {
    return Column(
      children: [
        SwitchListTile(
          activeColor: AppColors.primary,
          value: _user.dailyReminders,
          onChanged: (v) => setState(() {
            _user = _user.copyWith(dailyReminders: v);
          }),
          title: const Text("Recordatorios diarios"),
        ),
        SwitchListTile(
          activeColor: AppColors.primary,
          value: _user.shareProgress,
          onChanged: (v) => setState(() {
            _user = _user.copyWith(shareProgress: v);
          }),
          title: const Text("Compartir progreso"),
        ),
        SwitchListTile(
          activeColor: AppColors.primary,
          value: _user.achievementNotifications,
          onChanged: (v) => setState(() {
            _user = _user.copyWith(achievementNotifications: v);
          }),
          title: const Text("Notificaciones de logros"),
        ),
      ],
    );
  }
}
