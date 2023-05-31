import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_drawing/path_drawing.dart';

import 'data.dart';
import 'painter.dart';

final GlobalKey globalKey = new GlobalKey();

PainterController controller = new PainterController();
PainterController _controller;

setPaintController() {
  _controller = _newController();
}

PainterController _newController() {
  controller.thickness = penThickness;
  controller.drawColor = selectedColor;
  controller.backgroundColor = Colors.white;
  return controller;
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Widget paintScreen() {
    return RepaintBoundary(
      key: globalKey,
      child: Container(height: MediaQuery.of(context).size.height - 200, child: Painter(_controller)),
    );
  }

  @override
  void initState() {
    super.initState();
    setPaintController();
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(138, 35, 135, 1.0),
                  Color.fromRGBO(73, 64, 182, 1.0),
                  Color.fromRGBO(51, 98, 193, 1.0),
                  Color.fromRGBO(51, 148, 193, 1.0),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  width: w * 0.9,
                  height: h * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 5.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    child: paintScreen(),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                  width: w * 0.9,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            color: selectedColor,
                            onPressed: () {
                              selectColor();
                            },
                            tooltip: "Palette",
                            icon: Image.asset('assets/images/palette.png'),
                          ),
                          IconButton(
                            onPressed: () {
                              _showInstrumentPicker();
                            },
                            tooltip: "Figures",
                            icon: Image.asset('assets/images/shape.png'),
                          ),
                          IconButton(
                            icon: Image.asset('assets/images/eraser.png'),
                            onPressed: () {
                              selectedColor = Colors.white;
                              setPaintController();
                            },
                            tooltip: "Eraser",
                          ),
                          IconButton(
                            onPressed: () {
                              controller.clear();
                            },
                            tooltip: "Clear all",
                            icon: Icon(Icons.layers_clear),
                          ),
                          IconButton(
                            onPressed: () {
                              controller.undo();
                            },
                            tooltip: "Undo",
                            icon: Icon(Icons.undo),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Slider(
                              min: 2.0,
                              max: 50.0,
                              activeColor: selectedColor,
                              value: penThickness,
                              onChanged: (value) {
                                setState(() {
                                  penThickness = value;
                                  setPaintController();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void selectColor() {
    showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return AlertDialog(
          title: const Text('Choose color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                  setPaintController();
                });
              },
            ),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _dismissInstrumentsDialog() {
    _showToast(mode.toString());
    Navigator.pop(context, false);
  }

  void _showToast(String mode) {
    Fluttertoast.showToast(
      msg: mode,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _showInstrumentPicker() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Figure'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Container(
                  child: Row(
                    children: [
                      SizedBox(
                        height: 80.0,
                        width: 80.0,
                        child: IconButton(
                          onPressed: () {
                            mode = DrawMode.pencil;
                            _dismissInstrumentsDialog();
                          },
                          tooltip: "Pencil",
                          icon: Image.asset('assets/images/shape.png'),
                        ),
                      ),
                      SizedBox(
                        height: 80.0,
                        width: 80.0,
                        child: IconButton(
                          onPressed: () {
                            mode = DrawMode.rect;
                            _dismissInstrumentsDialog();
                          },
                          tooltip: "Rectangle",
                          icon: Image.asset('assets/images/shape.png'),
                        ),
                      ),
                      SizedBox(
                        height: 80.0,
                        width: 80.0,
                        child: IconButton(
                          onPressed: () {
                            mode = DrawMode.line;
                            _dismissInstrumentsDialog();
                          },
                          tooltip: "Line",
                          icon: Image.asset('assets/images/shape.png'),
                        ),
                      ),
                      SizedBox(
                        height: 80.0,
                        width: 80.0,
                        child: IconButton(
                          onPressed: () {
                            mode = DrawMode.triangle;
                            _dismissInstrumentsDialog();
                          },
                          tooltip: "Triangle",
                          icon: Image.asset('assets/images/shape.png'),
                        ),
                      ),
                      SizedBox(
                        height: 80.0,
                        width: 80.0,
                        child: IconButton(
                          onPressed: () {
                            mode = DrawMode.circle;
                            _dismissInstrumentsDialog();
                          },
                          tooltip: "Circle",
                          icon: Image.asset('assets/images/shape.png'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Exit'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
