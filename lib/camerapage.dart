import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}
class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Fetch the available cameras
      final cameras = await availableCameras();
      // Check if cameras are available
      if (cameras.isNotEmpty) {
        // Initialize the controller with the first camera
        _controller = CameraController(
          cameras[0],
          ResolutionPreset.high,
        );
        _initializeControllerFuture = _controller.initialize();
        setState(() {}); // Refresh the UI after initialization
      } else {
        print("No cameras available");
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture; // Ensure camera is initialized
      final image = await _controller.takePicture();
      print("Picture taken: ${image.path}");
      // Optionally return the image path to the previous screen
      Navigator.pop(context, image.path);
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Page'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Display the camera preview
            return CameraPreview(_controller);
          } else if (snapshot.hasError) {
            // Handle errors gracefully
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            // Otherwise, show a loading indicator
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: Icon(Icons.camera),
      ),
    );
  }
}
