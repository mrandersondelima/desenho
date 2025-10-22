import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraOverlayController extends GetxController {
  // Observable variables
  RxList<CameraDescription> cameras = <CameraDescription>[].obs;
  Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  RxBool isCameraInitialized = false.obs;
  RxBool isLoading = true.obs;
  RxString selectedImagePath = ''.obs;
  RxDouble imageOpacity = 0.5.obs;
  RxDouble imagePositionX = 0.0.obs;
  RxDouble imagePositionY = 0.0.obs;
  RxDouble imageScale = 1.0.obs;
  RxDouble imageRotation = 0.0.obs; // Nova variável para rotação
  RxBool showOverlayImage = true.obs;

  // TextEditingController para input de rotação
  final TextEditingController rotationTextController = TextEditingController();

  // Internal gesture tracking
  late Offset _startFocalPoint;
  double _initialScale = 1.0;
  double _initialX = 0.0;
  double _initialY = 0.0;

  @override
  void onInit() {
    super.onInit();
    rotationTextController.text = '0';
    initializeCamera();
  }

  @override
  void onClose() {
    cameraController.value?.dispose();
    rotationTextController.dispose();
    super.onClose();
  }

  Future<void> initializeCamera() async {
    try {
      isLoading.value = true;

      // Solicita permissão da câmera
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        Get.snackbar('Erro', 'Permissão da câmera é necessária');
        return;
      }

      // Lista câmeras disponíveis
      cameras.value = await availableCameras();
      if (cameras.isEmpty) {
        Get.snackbar('Erro', 'Nenhuma câmera encontrada');
        return;
      }

      // Inicializa a câmera traseira (índice 0 geralmente é a traseira)
      await _setupCamera(cameras.first);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao inicializar câmera: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    if (cameraController.value != null) {
      await cameraController.value!.dispose();
    }

    cameraController.value = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await cameraController.value!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao configurar câmera: $e');
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    final currentCamera = cameraController.value?.description;
    CameraDescription newCamera;

    if (currentCamera == cameras.first) {
      newCamera = cameras.last;
    } else {
      newCamera = cameras.first;
    }

    await _setupCamera(newCamera);
  }

  Future<void> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        selectedImagePath.value = result.files.single.path ?? '';
        // Reset position and scale when new image is selected
        imagePositionX.value = 0.0;
        imagePositionY.value = 0.0;
        imageScale.value = 1.0;
        imageRotation.value = 0.0;
        rotationTextController.text = '0';
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao selecionar imagem: $e');
    }
  }

  void updateOpacity(double value) {
    imageOpacity.value = value;
  }

  void updatePosition(double x, double y) {
    imagePositionX.value = x;
    imagePositionY.value = y;
  }

  void updateScale(double value) {
    imageScale.value = value;
  }

  void updateRotation(double value) {
    imageRotation.value = value;
    // Atualiza o campo de texto sem triggar o listener
    rotationTextController.text = value.round().toString();
  }

  void updateRotationFromText(String text) {
    final double? value = double.tryParse(text);
    if (value != null) {
      // Normaliza o valor para ficar entre 0 e 360
      final normalizedValue = value % 360;
      imageRotation.value = normalizedValue < 0
          ? normalizedValue + 360
          : normalizedValue;
    }
  }

  void rotateImage(double degrees) {
    final newRotation = (imageRotation.value + degrees) % 360;
    imageRotation.value = newRotation;
    rotationTextController.text = newRotation.round().toString();
  }

  // Gesture handlers for ScaleGestureRecognizer (covers pan + scale)
  void onScaleStart(ScaleStartDetails details) {
    _startFocalPoint = details.focalPoint;
    _initialScale = imageScale.value;
    _initialX = imagePositionX.value;
    _initialY = imagePositionY.value;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    // Update scale (pinch)
    final double newScale = (_initialScale * details.scale).clamp(0.2, 5.0);
    imageScale.value = newScale;

    // Update position (drag) — calculate delta from start focal point
    final dx = details.focalPoint.dx - _startFocalPoint.dx;
    final dy = details.focalPoint.dy - _startFocalPoint.dy;
    imagePositionX.value = _initialX + dx;
    imagePositionY.value = _initialY + dy;
  }

  void onScaleEnd(ScaleEndDetails details) {
    // Nothing special for now; could add inertia or snapping here.
  }

  void toggleOverlayVisibility() {
    showOverlayImage.value = !showOverlayImage.value;
  }

  void resetImageTransform() {
    imagePositionX.value = 0.0;
    imagePositionY.value = 0.0;
    imageScale.value = 1.0;
    imageRotation.value = 0.0;
    imageOpacity.value = 0.5;
    rotationTextController.text = '0';
  }
}
