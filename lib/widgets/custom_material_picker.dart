import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CustomMaterialPicker extends StatefulWidget {
  const CustomMaterialPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.onPrimaryChanged,
    this.enableLabel = false,
    this.portraitOnly = false,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<Color>? onPrimaryChanged;
  final bool enableLabel;
  final bool portraitOnly;

  @override
  State<CustomMaterialPicker> createState() => _CustomMaterialPickerState();
}

class _CustomMaterialPickerState extends State<CustomMaterialPicker> {
  final List<List<Color>> colorTypes = [
    [Colors.red, Colors.redAccent],
    [Colors.pink, Colors.pinkAccent],
    [Colors.purple, Colors.purpleAccent],
    [Colors.deepPurple, Colors.deepPurpleAccent],
    [Colors.indigo, Colors.indigoAccent],
    [Colors.blue, Colors.blueAccent],
    [Colors.lightBlue, Colors.lightBlueAccent],
    [Colors.cyan, Colors.cyanAccent],
    [Colors.teal, Colors.tealAccent],
    [Colors.green, Colors.greenAccent],
    [Colors.lightGreen, Colors.lightGreenAccent],
    [Colors.lime, Colors.limeAccent],
    [Colors.yellow, Colors.yellowAccent],
    [Colors.amber, Colors.amberAccent],
    [Colors.orange, Colors.orangeAccent],
    [Colors.deepOrange, Colors.deepOrangeAccent],
    [Colors.brown],
    [Colors.grey],
    [Colors.blueGrey],
    [Colors.black],
  ];

  List<Color> currentColorType = [Colors.red, Colors.redAccent];
  Color currentShading = Colors.transparent;

  List<Map<Color, String>> shadingTypes(List<Color> colors) {
    List<Map<Color, String>> result = [];

    for (Color colorType in colors) {
      if (colorType == Colors.grey) {
        result.addAll([50, 100, 200, 300, 350, 400, 500, 600, 700, 800, 850, 900]
            .map((int shade) => {Colors.grey[shade]!: shade.toString()})
            .toList());
      } else if (colorType == Colors.black || colorType == Colors.white) {
        result.addAll([
          {Colors.black: ''},
          {Colors.white: ''}
        ]);
      } else if (colorType is MaterialAccentColor) {
        result.addAll([100, 200, 400, 700]
            .map((int shade) => {colorType[shade]!: 'A$shade'})
            .toList());
      } else if (colorType is MaterialColor) {
        result.addAll([50, 100, 200, 300, 400, 500, 600, 700, 800, 900]
            .map((int shade) => {colorType[shade]!: shade.toString()})
            .toList());
      } else {
        result.add({const Color(0x00000000): ''});
      }
    }

    return result;
  }

  String colorToHex(Color color) {
    final rgbInt = ((color.r * 255).round() << 16) |
                   ((color.g * 255).round() << 8) |
                   (color.b * 255).round();
    return '#${rgbInt.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    for (List<Color> colors in colorTypes) {
      shadingTypes(colors).forEach((Map<Color, String> color) {
        final firstColor = color.keys.first;
        if (widget.pickerColor.r == firstColor.r &&
            widget.pickerColor.g == firstColor.g &&
            widget.pickerColor.b == firstColor.b &&
            widget.pickerColor.a == firstColor.a) {
          setState(() {
            currentColorType = colors;
            currentShading = firstColor;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait || widget.portraitOnly;

    Widget colorList() {
      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Container(
          margin: isPortrait ? const EdgeInsets.only(right: 10) : const EdgeInsets.only(bottom: 10),
          width: isPortrait ? 60 : null,
          height: isPortrait ? null : 60,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(color: (Theme.of(context).brightness == Brightness.light) ? Colors.grey[300]! : Colors.black38, blurRadius: 10)],
            border: isPortrait
                ? Border(right: BorderSide(color: (Theme.of(context).brightness == Brightness.light) ? Colors.grey[300]! : Colors.black38, width: 1))
                : Border(top: BorderSide(color: (Theme.of(context).brightness == Brightness.light) ? Colors.grey[300]! : Colors.black38, width: 1)),
          ),
          child: ListView(
            scrollDirection: isPortrait ? Axis.vertical : Axis.horizontal,
            children: [
              isPortrait
                  ? const Padding(padding: EdgeInsets.only(top: 7))
                  : const Padding(padding: EdgeInsets.only(left: 7)),
              ...colorTypes.map((List<Color> colors) {
                Color colorType = colors[0];
                return GestureDetector(
                  onTap: () {
                    if (widget.onPrimaryChanged != null) widget.onPrimaryChanged!(colorType);
                    setState(() => currentColorType = colors);
                  },
                  child: Container(
                    color: const Color(0x00000000),
                    padding:
                    isPortrait ? const EdgeInsets.fromLTRB(0, 7, 0, 7) : const EdgeInsets.fromLTRB(7, 0, 7, 0),
                    child: Align(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: colorType,
                          shape: BoxShape.circle,
                          boxShadow: currentColorType == colors
                              ? [
                            colorType == Theme.of(context).cardColor
                                ? BoxShadow(
                              color: (Theme.of(context).brightness == Brightness.light) ? Colors.grey[300]! : Colors.black38,
                              blurRadius: 10,
                            )
                                : BoxShadow(
                              color: colorType,
                              blurRadius: 10,
                            ),
                          ]
                              : null,
                          border: colorType == Theme.of(context).cardColor
                              ? Border.all(color: (Theme.of(context).brightness == Brightness.light) ? Colors.grey[300]! : Colors.black38, width: 1)
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              isPortrait
                  ? const Padding(padding: EdgeInsets.only(top: 5))
                  : const Padding(padding: EdgeInsets.only(left: 5)),
            ],
          ),
        ),
      );
    }

    Widget shadingList() {
      return ListView(
        scrollDirection: isPortrait ? Axis.vertical : Axis.horizontal,
        children: [
          isPortrait
              ? const Padding(padding: EdgeInsets.only(top: 15))
              : const Padding(padding: EdgeInsets.only(left: 15)),
          ...shadingTypes(currentColorType).map((Map<Color, String> color) {
            final Color selectedColor = color.keys.first;
            return GestureDetector(
              onTap: () {
                setState(() => currentShading = selectedColor);
                widget.onColorChanged(selectedColor);
              },
              child: Container(
                color: const Color(0x00000000),
                margin: isPortrait ? const EdgeInsets.only(right: 10) : const EdgeInsets.only(bottom: 10),
                padding: isPortrait ? const EdgeInsets.fromLTRB(0, 7, 0, 7) : const EdgeInsets.fromLTRB(7, 0, 7, 0),
                child: Align(
                  child: AnimatedContainer(
                    curve: Curves.fastOutSlowIn,
                    duration: const Duration(milliseconds: 500),
                    width:
                    isPortrait ? (currentShading == selectedColor ? 250 : 230) : (currentShading == selectedColor ? 50 : 30),
                    height: isPortrait ? 50 : 220,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      boxShadow: currentShading == selectedColor
                          ? [
                        (selectedColor == Colors.white) || (selectedColor == Colors.black)
                            ? BoxShadow(
                          color: (Theme.of(context).brightness == Brightness.light) ? Colors.grey[300]! : Colors.black38,
                          blurRadius: 10,
                        )
                            : BoxShadow(
                          color: selectedColor,
                          blurRadius: 10,
                        ),
                      ]
                          : null,
                      border: (selectedColor == Colors.white) || (selectedColor == Colors.black)
                          ? Border.all(color: (Theme.of(context).brightness == Brightness.light) ? Colors.grey[300]! : Colors.black38, width: 1)
                          : null,
                    ),
                    child: widget.enableLabel
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(
                                  color.values.first,
                                  style: TextStyle(
                                    color: useWhiteForeground(selectedColor) ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Text(
                                  colorToHex(selectedColor),
                                  style: TextStyle(
                                    color: useWhiteForeground(selectedColor) ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
                  ),
                ),
              ),
            );
          }),
          isPortrait
              ? const Padding(padding: EdgeInsets.only(top: 15))
              : const Padding(padding: EdgeInsets.only(left: 15)),
        ],
      );
    }

    if (isPortrait) {
      return SizedBox(
        width: 350,
        height: 500,
        child: Row(
          children: <Widget>[
            colorList(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: shadingList(),
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox(
        width: 500,
        height: 300,
        child: Column(
          children: <Widget>[
            colorList(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: shadingList(),
              ),
            ),
          ],
        ),
      );
    }
  }
}
