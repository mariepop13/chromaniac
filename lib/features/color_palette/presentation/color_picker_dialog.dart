import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../services/premium_service.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;
  final int currentPaletteSize;
  final bool isEditing;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    required this.currentPaletteSize,
    this.isEditing = false,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _currentColor;
  int _currentPickerType = 0;
  final List<String> _pickerTypes = ['Wheel', 'Material', 'Block', 'Slider'];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  void _handleAddColor() {
    final isPremium = context.read<PremiumService>().isPremium;
    final maxColors = isPremium 
        ? AppConstants.maxPaletteColors 
        : AppConstants.defaultPaletteSize;

    if (!widget.isEditing && widget.currentPaletteSize >= maxColors) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Palette Full'),
          content: Text(
            isPremium 
              ? 'You\'ve reached the maximum limit of ${AppConstants.maxPaletteColors} colors.'
              : 'You\'ve reached the maximum of ${AppConstants.defaultPaletteSize} colors. '
                'Upgrade to premium to add up to ${AppConstants.maxPaletteColors} colors!'
          ),
          actions: [
            if (!isPremium) ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<PremiumService>().unlockPremium();
                },
                child: const Text('Upgrade Now'),
              ),
            ] else
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
          ],
        ),
      );
    } else {
      widget.onColorSelected(_currentColor);
    }
  }

  Widget _buildColorPicker() {
    switch (_currentPickerType) {
      case 0:
        return ColorPicker(
          pickerColor: _currentColor,
          onColorChanged: (color) => setState(() => _currentColor = color),
          pickerAreaHeightPercent: 0.7,
          enableAlpha: true,
          labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
          displayThumbColor: true,
          portraitOnly: true,
        );
      case 1:
        return MaterialPicker(
          pickerColor: _currentColor,
          onColorChanged: (color) => setState(() => _currentColor = color),
          enableLabel: true,
        );
      case 2:
        return BlockPicker(
          pickerColor: _currentColor,
          onColorChanged: (color) => setState(() => _currentColor = color),
          availableColors: const [
            Colors.red,
            Colors.pink,
            Colors.purple,
            Colors.deepPurple,
            Colors.indigo,
            Colors.blue,
            Colors.lightBlue,
            Colors.cyan,
            Colors.teal,
            Colors.green,
            Colors.lightGreen,
            Colors.lime,
            Colors.yellow,
            Colors.amber,
            Colors.orange,
            Colors.deepOrange,
            Colors.brown,
            Colors.grey,
            Colors.blueGrey,
            Colors.black,
          ],
        );
      case 3:
        return SlidePicker(
          pickerColor: _currentColor,
          onColorChanged: (color) => setState(() => _currentColor = color),
          enableAlpha: true,
          showParams: true,
          showIndicator: true,
          indicatorBorderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    _pickerTypes.length,
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppConstants.smallPadding / 2),
                      child: ChoiceChip(
                        label: Text(_pickerTypes[index]),
                        selected: _currentPickerType == index,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _currentPickerType = index);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppConstants.smallPadding),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildColorPicker(),
                ),
              ),
              SizedBox(height: AppConstants.smallPadding),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _currentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(height: AppConstants.smallPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                  SizedBox(width: AppConstants.smallPadding),
                  ElevatedButton(
                    onPressed: _handleAddColor,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
