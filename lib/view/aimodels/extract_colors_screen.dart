import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit_example/model_view/cubit/modelAi/extract_color_cubit.dart';
import 'package:google_ml_kit_example/model_view/cubit/modelAi/extract_color_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';



class ExtractColorsScreen extends StatefulWidget {

  @override
  State<ExtractColorsScreen> createState() => _ExtractColorsScreenState();
}

class _ExtractColorsScreenState extends State<ExtractColorsScreen> {
  late FlutterTts flutterTts;
  bool isTtsInitialized = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    initTts();
    openCamera();
  }

  Future<void> initTts() async {
    flutterTts.setStartHandler(() {
      setState(() {
        isTtsInitialized = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isTtsInitialized = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      setState(() {
        isTtsInitialized = false;
      });
    });

    await configureTts();
  }

  Future<void> configureTts() async {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    setState(() {
      isTtsInitialized = true;
    });
  }

  Future<void> speakText(String text) async {
    if (isTtsInitialized) {
      var result = await flutterTts.speak(text);
      print("Speak result: $result");
    } else {
      print("TTS engine is not initialized");
    }
  }

  Future<void> openCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      var pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        var cubit = ExtractColorCubit.get(context);
        cubit.picture = File(pickedFile.path);
        cubit.sendImage(); // Change this line to call the correct method
      }
    } else {
      print("Camera permission denied");
      speakText("Camera permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            BlocBuilder<ExtractColorCubit, ExtractColorState>(
              builder: (context, state) {
                var cubit = ExtractColorCubit.get(context);
                if (state is ExtractColorLoaded) {
                  speakText('Detected Colors: ${state.colors.join(', ')}');
                }
                return Column(
                  children: [
                    SizedBox(height: 100.h,),
                    Center(
                      child: Column(
                        children: [
                          if (cubit.picture != null)
                            Image.file(cubit.picture!, height: 200.h),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h,),
                    if (state is ExtractColorLoading)
                      const CircularProgressIndicator(),
                    if (state is ExtractColorLoaded)
                      Text('Detected Colors: ${state.colors.join(', ')}', style: const TextStyle(fontSize: 24, color: Colors.white)),
                    if (state is ExtractColorError)
                      Text('Error: ${state.message}', style: const TextStyle(fontSize: 24, color: Colors.red)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}