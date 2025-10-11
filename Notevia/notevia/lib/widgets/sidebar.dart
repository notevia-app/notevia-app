import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';

class Sidebar extends StatefulWidget {
  final VoidCallback? onUserDataChanged;
  
  const Sidebar({super.key, this.onUserDataChanged});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return _buildHeader(context, userProvider.userName);
                },
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMenuItem(
                        context: context,
                        icon: Icons.home_outlined,
                        title: AppLocalizations.of(context)!.homePage,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        isActive: true,
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.add_circle_outline,
                        title: AppLocalizations.of(context)!.addNote,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/add-note');
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.menu_book_outlined,
                        title: AppLocalizations.of(context)!.myDiary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/diary');
                        },
                      ),

                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.settings_outlined,
                        title: AppLocalizations.of(context)!.settings,
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.pushNamed(context, '/settings');
                          // UserProvider otomatik olarak güncellenir
                          if (context.mounted && widget.onUserDataChanged != null) {
                            widget.onUserDataChanged!();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_outline,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName.isNotEmpty ? userName : AppLocalizations.of(context)!.user,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.appName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Text(
        '${AppLocalizations.of(context)!.appName} v1.0.0',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppLocalizations.of(context)!.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.edit_note, color: Colors.white, size: 30),
      ),
      children: [
        Text(
          AppLocalizations.of(context)!.appDescription,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.developerInfo,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
