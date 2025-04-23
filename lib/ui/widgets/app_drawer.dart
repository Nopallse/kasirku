import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onNavigate;
  final int currentIndex;

  const AppDrawer({
    Key? key, 
    required this.onNavigate,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildOutletSection(context),
                  _buildNavigationSection(context),
                ],
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor,
      width: double.infinity,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'KasirKu Pro',
                  style: Theme.of(context).primaryTextTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutletSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OUTLETS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              InkWell(
                onTap: () {
                  // Navigate to add outlet screen
                  onNavigate(3); // Assuming management tab is index 3
                  Navigator.pop(context); // Close drawer
                  // You might need additional logic to navigate to the correct management sub-tab
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildOutletsList(context),
        ],
      ),
    );
  }

  Widget _buildOutletsList(BuildContext context) {
    // This would ideally come from your outlets provider
    final outlets = [
      {'name': 'Main Store', 'id': 1},
    ];

    return Column(
      children: outlets.map((outlet) {
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
          leading: const Icon(Icons.business),
          title: Text(outlet['name'] as String),
          onTap: () {
            // Set active outlet and close drawer
            // You would typically call a provider method here
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [

          _buildNavItem(
            context, 
            'Employees', 
            Icons.people, 
            4, 
            onTap: () => _handleNavigation(context, 4),
          ),
          _buildNavItem(
            context, 
            'Outlets', 
            Icons.store, 
            5, 
            onTap: () => _handleNavigation(context, 5),
          ),
          _buildNavItem(
            context, 
            'Reports', 
            Icons.bar_chart, 
            6, 
            onTap: () => _handleNavigation(context, 6),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, 
    String title, 
    IconData icon, 
    int index, {
    required Function() onTap,
  }) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      leading: Icon(
        icon,
        color: isSelected ? theme.primaryColor : null,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? theme.primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    onNavigate(index);
    Navigator.pop(context); // Close drawer
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                backgroundImage: const AssetImage('assets/images/placeholder_user.png'),
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Text('A', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin User',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'admin@kasirku.com',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              onPressed: () {
                // Call your auth provider logout method here
                // Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}