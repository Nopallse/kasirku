import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onMenuPressed,
    this.leading,
    this.bottom,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget;

    if (leading != null) {
      leadingWidget = leading;
    } else if (showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      );
    } else if (onMenuPressed != null) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: onMenuPressed,
      );
    }

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: leadingWidget,
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      bottom: bottom,
      scrolledUnderElevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0.0)
  );
}

// Example of a search app bar
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Function(String) onSearch;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final String hintText;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;

  const SearchAppBar({
    Key? key,
    required this.title,
    required this.onSearch,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.hintText = 'Search...',
    this.onMenuPressed,
    required this.showBackButton,
  }) : super(key: key);

  @override
  SearchAppBarState createState() => SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SearchAppBarState extends State<SearchAppBar> {
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSearch) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _searchController.clear();
              _showSearch = false;
              widget.onSearch('');
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: InputBorder.none,
            hintStyle: const TextStyle(
              color: Colors.white70,
            ),
          ),
          style: const TextStyle(
            color: Colors.white,
          ),
          cursorColor: Colors.white,
          onChanged: widget.onSearch,
          autofocus: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              widget.onSearch('');
            },
          ),
        ],
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      );
    } else {
      Widget? leadingWidget;
      if (widget.automaticallyImplyLeading) {
        if (Navigator.of(context).canPop()) {
          leadingWidget = IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          );
        } else if (widget.onMenuPressed != null) {
          leadingWidget = IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: widget.onMenuPressed,
          );
        }
      }

      return AppBar(
        leading: leadingWidget,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSearch = true;
              });
            },
          ),
          ...?widget.actions,
        ],
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      );
    }
  }
}