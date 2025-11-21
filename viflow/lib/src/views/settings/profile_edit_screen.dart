import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Klavye formatı için
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// Dil Dosyası
import 'package:viflow/l10n/app_localizations.dart';
import 'package:viflow/src/providers/app_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  late String _selectedGender;
  late int _selectedActivityIndex;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Mevcut verileri controller'lara yükle
    _nameController = TextEditingController(text: provider.userName);
    _ageController = TextEditingController(text: provider.age.toString());
    _weightController = TextEditingController(text: provider.weight.toString());
    _heightController = TextEditingController(text: provider.height.toString());

    _selectedGender = provider.gender;
    _selectedActivityIndex = provider.activityIndex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // Basit Validasyon
    if (_nameController.text.isEmpty || _ageController.text.isEmpty || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen boş alan bırakmayınız.")),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    // Provider'daki güncelleme fonksiyonunu çağır
    // Bu fonksiyon arka planda su hedefini de otomatik günceller.
    provider.updateUserProfile(
      name: _nameController.text,
      age: int.tryParse(_ageController.text) ?? 25,
      weight: double.tryParse(_weightController.text) ?? 70,
      height: double.tryParse(_heightController.text) ?? 170,
      gender: _selectedGender,
      activityIdx: _selectedActivityIndex,
    );

    // Kullanıcıya Bildirim
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.profileUpdated),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Hedefin güncellendiğine dair 2. uyarı (Kullanıcı fark etsin diye)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.targetUpdated),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Karanlık Mod Renk Ayarları
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = theme.cardColor;
    final inputColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.transparent;

    return Scaffold(
      // Arkaplan temadan gelir
      appBar: AppBar(
        title: Text(
            l10n.editProfile,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KİŞİSEL BİLGİLER ---
            _buildSectionTitle(l10n.personalInfo, isDark),
            const Gap(15),
            _buildTextField(
                controller: _nameController,
                label: l10n.nameHint,
                icon: Icons.person_outline,
                inputColor: inputColor,
                textColor: textColor,
                theme: theme,
                isDark: isDark
            ),
            const Gap(15),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        controller: _ageController,
                        label: l10n.age,
                        icon: Icons.cake_outlined,
                        isNumeric: true,
                        inputColor: inputColor,
                        textColor: textColor,
                        theme: theme,
                        isDark: isDark
                    )
                ),
                const Gap(15),
                Expanded(
                    child: _buildGenderDropdown(context, l10n, inputColor, textColor, borderColor, isDark)
                ),
              ],
            ),

            const Gap(30),

            // --- VÜCUT ÖLÇÜLERİ ---
            _buildSectionTitle(l10n.bodyMeasurements, isDark),
            const Gap(15),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        controller: _weightController,
                        label: l10n.weight,
                        icon: Icons.monitor_weight_outlined,
                        isNumeric: true,
                        inputColor: inputColor,
                        textColor: textColor,
                        theme: theme,
                        isDark: isDark
                    )
                ),
                const Gap(15),
                Expanded(
                    child: _buildTextField(
                        controller: _heightController,
                        label: l10n.height,
                        icon: Icons.height,
                        isNumeric: true,
                        inputColor: inputColor,
                        textColor: textColor,
                        theme: theme,
                        isDark: isDark
                    )
                ),
              ],
            ),

            const Gap(30),

            // --- AKTİVİTE SEVİYESİ ---
            _buildSectionTitle(l10n.activityLevel, isDark),
            const Gap(15),
            _buildActivityDropdown(context, l10n, inputColor, textColor, borderColor, isDark),

            const Gap(40),

            // --- KAYDET BUTONU ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: theme.primaryColor.withOpacity(0.4),
                ),
                child: Text(
                    l10n.saveChanges,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color inputColor,
    required Color textColor,
    required ThemeData theme,
    required bool isDark,
    bool isNumeric = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.grey.shade700) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.name,
        // Sadece rakam ve nokta girişine izin ver
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : [],
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: theme.primaryColor.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(
      BuildContext context,
      AppLocalizations l10n,
      Color color,
      Color textColor,
      Color borderColor,
      bool isDark
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: borderColor) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          dropdownColor: color, // Açılır menü rengi
          icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
          isExpanded: true,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
          items: [
            DropdownMenuItem(value: 'male', child: Text(l10n.male)),
            DropdownMenuItem(value: 'female', child: Text(l10n.female)),
          ],
          onChanged: (val) => setState(() => _selectedGender = val!),
        ),
      ),
    );
  }

  Widget _buildActivityDropdown(
      BuildContext context,
      AppLocalizations l10n,
      Color color,
      Color textColor,
      Color borderColor,
      bool isDark
      ) {
    List<String> levels = [l10n.sedentary, l10n.moderate, l10n.active];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: borderColor) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedActivityIndex,
          dropdownColor: color,
          icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor),
          isExpanded: true,
          items: List.generate(levels.length, (index) {
            return DropdownMenuItem(
              value: index,
              child: Row(
                children: [
                  Icon(
                      index == 0 ? Icons.weekend : (index == 1 ? Icons.directions_walk : Icons.fitness_center),
                      size: 20,
                      color: Colors.grey
                  ),
                  const Gap(10),
                  Text(
                      levels[index],
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor)
                  ),
                ],
              ),
            );
          }),
          onChanged: (val) => setState(() => _selectedActivityIndex = val!),
        ),
      ),
    );
  }
}