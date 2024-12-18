import 'package:chromaniac/utils/export_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:chromaniac/providers/theme_provider.dart';
import 'package:chromaniac/widgets/color_picker.dart';
import 'package:chromaniac/widgets/palette_generator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Color> _palette = [];
  Color _currentColor = Colors.blue;
  PaletteType selectedPaletteType = PaletteType.auto;

  @override
  void initState() {
    super.initState();
    _generateRandomPalette();
  }

  void _addColorToPalette(Color color) {
    setState(() {
      if (_palette.length < 5) {
        _palette.add(color);
      }
    });
  }

  void _removeColorFromPalette(int index) {
    setState(() {
      _palette.removeAt(index);
    });
  }

  void _updateCurrentColor(Color color) {
    setState(() {
      _currentColor = color;
    });
  }

  bool isValidHexColor(String hexColor) {
    final hexRegExp = RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
    return hexRegExp.hasMatch(hexColor);
  }


  Color _generateRandomColor() {
    final random = Random();
    return Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  void _generateRandomPalette() {
    setState(() {
      _palette.clear();
      _palette.addAll(generatePalette(selectedPaletteType, _generateRandomColor()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      drawer: _buildNavigationDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            children: [
              _buildPaletteDisplay(),
              _buildPaletteControls(),
              _buildColorPickerSection(),
              _buildCurrentColorDisplay(),
              _buildExportButton(),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(ThemeProvider themeProvider) {
    return AppBar(
      title: const Text('Chromaniac - Color Palette Creator'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
          onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
        ),
      ],
    );
  }

  Drawer _buildNavigationDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildDrawerHeader(context),
          _buildDrawerItem(Icons.home, 'Home', context),
          _buildDrawerItem(Icons.settings, 'Settings', context),
        ],
      ),
    );
  }

  DrawerHeader _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: const Text(
        'Menu',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.pop(context),
    );
  }

  Widget _buildPaletteDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _palette.asMap().entries.map((entry) {
          return _buildPaletteColorItem(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildPaletteColorItem(int index, Color color) {
    bool isDarkColor = color.computeLuminance() < 0.5;
    return Container(
      height: 50,
      width: double.infinity,
      color: color,
      child: Row(
        children: [
          _buildRemoveColorButton(index, isDarkColor),
          _buildColorHexCode(color, isDarkColor),
        ],
      ),
    );
  }

  IconButton _buildRemoveColorButton(int index, bool isDarkColor) {
    return IconButton(
      icon: Icon(Icons.close, color: isDarkColor ? Colors.white : Colors.black),
      onPressed: () => _removeColorFromPalette(index),
    );
  }

  Expanded _buildColorHexCode(Color color, bool isDarkColor) {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(
            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
            style: TextStyle(
              color: isDarkColor ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _generateRandomPalette,
              child: const Text('Generate Random Palette'),
            ),
          ),
          const SizedBox(width: 16),
          _buildPaletteTypeDropdown(),
        ],
      ),
    );
  }

  DropdownButton<PaletteType> _buildPaletteTypeDropdown() {
    return DropdownButton<PaletteType>(
      value: selectedPaletteType,
      onChanged: (PaletteType? newValue) {
        setState(() {
          selectedPaletteType = newValue!;
        });
      },
      items: PaletteType.values.map((PaletteType type) {
        return DropdownMenuItem<PaletteType>(
          value: type,
          child: Text(type.toString().split('.').last),
        );
      }).toList(),
    );
  }

  Widget _buildColorPickerSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ColorPickerWidget(
        currentColor: _currentColor,
        onColorSelected: _updateCurrentColor,
      ),
    );
  }

  Widget _buildCurrentColorDisplay() {
    return Container(
      height: 100,
      width: double.infinity,
      color: _currentColor,
      child: Center(
        child: ElevatedButton(
          onPressed: () => _addColorToPalette(_currentColor),
          child: const Text('Add to Palette'),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => exportPalette(context, _palette),
        child: const Text('Export'),
      ),
    );
  }
}
