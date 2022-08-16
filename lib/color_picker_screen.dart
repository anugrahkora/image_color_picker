import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

class Marker {
  final double x;
  final double y;

  Marker({this.x = 0.0, this.y = 0.0});
}

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({Key? key}) : super(key: key);

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  String imagePath = 'assets/images/image2.jpg';
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();
  bool useSnapshot = false;
  GlobalKey currentKey = GlobalKey();

  final StreamController<Color> _stateController = StreamController<Color>();
  final StreamController<Marker> _gestureController =
      StreamController<Marker>();
  img.Image? photo;

  @override
  void initState() {
    currentKey = useSnapshot ? paintKey : imageKey;
    _gestureController.add(Marker(x: 0.0, y: 0.0));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Color picker ")),
        body: StreamBuilder(
            initialData: Colors.green[500],
            stream: _stateController.stream,
            builder: (buildContext, AsyncSnapshot<Color> snapshot) {
              Color selectedColor = snapshot.data ?? Colors.green;
              return StreamBuilder<Marker>(
                  stream: _gestureController.stream,
                  builder: (context, position) {
                    return Stack(
                      children: <Widget>[
                        RepaintBoundary(
                          key: paintKey,
                          child: GestureDetector(
                            onTapDown: (details) {
                              searchPixel(details.globalPosition,
                                  details.localPosition);
                            },
                            onPanDown: (details) {
                              searchPixel(details.globalPosition,
                                  details.localPosition);
                            },
                            onPanUpdate: (details) {
                              searchPixel(details.globalPosition,
                                  details.localPosition);
                            },
                            child: Center(
                              child: Image.asset(
                                imagePath,
                                key: imageKey,
                                //color: Colors.red,
                                //colorBlendMode: BlendMode.hue,
                                //alignment: Alignment.bottomRight,
                                fit: BoxFit.contain,
                                //scale: .8,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: position.data?.x,
                          top: position.data?.y,
                          child: Container(
                            // margin: const EdgeInsets.all(70),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedColor,
                                border:
                                    Border.all(width: 2.0, color: Colors.white),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2))
                                ]),
                          ),
                        ),
                        Positioned(
                          left: 100.0,
                          top: 100.0,
                          child: Text('$selectedColor',
                              style: const TextStyle(
                                  color: Colors.white,
                                  backgroundColor: Colors.black54)),
                        ),
                      ],
                    );
                  });
            }),
      ),
    );
  }

  void searchPixel(Offset globalPosition, Offset localPosition) async {
    if (photo == null) {
      await (useSnapshot ? loadSnapshotBytes() : loadImageBundleBytes());
    }
    _calculatePixel(globalPosition, localPosition);
  }

  void _calculatePixel(Offset globalPosition, Offset gesturePosition) {
    RenderBox box = currentKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(globalPosition);
    // print("${localPosition.dx.toInt()}  ${localPosition.dy.toInt()}");

    double px = localPosition.dx;
    double py = localPosition.dy;

    if (!useSnapshot) {
      double widgetScale = box.size.width / photo!.width;
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    int pixel32 = photo!.getPixelSafe(px.toInt(), py.toInt());
    int hex = abgrToArgb(pixel32);

    _stateController.add(Color(hex));
    _gestureController
        .add(Marker(x: gesturePosition.dx, y: gesturePosition.dy));
  }

  Future<void> loadImageBundleBytes() async {
    ByteData imageBytes = await rootBundle.load(imagePath);
    setImageBytes(imageBytes);
  }

  Future<void> loadSnapshotBytes() async {
    RenderRepaintBoundary boxPaint =
        paintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image capture = await boxPaint.toImage();
    ByteData? imageBytes =
        await capture.toByteData(format: ui.ImageByteFormat.png);
    setImageBytes(imageBytes);
    capture.dispose();
  }

  void setImageBytes(ByteData? imageBytes) {
    List<int> values = imageBytes!.buffer.asUint8List();
    photo = null;
    photo = img.decodeImage(values);
  }
}

// image lib uses uses KML color format, convert #AABBGGRR to regular #AARRGGBB

int abgrToArgb(int argbColor) {
  int r = (argbColor >> 16) & 0xFF;
  int b = argbColor & 0xFF;
  return (argbColor & 0xFF00FF00) | (b << 16) | r;
}
