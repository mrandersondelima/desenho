import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/project.dart';
import '../services/project_service.dart';

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

  // Projeto atual
  Rx<Project?> currentProject = Rx<Project?>(null);
  final ProjectService _projectService = ProjectService();

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
        _autoSave();
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao selecionar imagem: $e');
    }
  }

  void updateOpacity(double value) {
    imageOpacity.value = value;
    _autoSave();
  }

  void updatePosition(double x, double y) {
    imagePositionX.value = x;
    imagePositionY.value = y;
    _autoSave();
  }

  void updateScale(double value) {
    imageScale.value = value;
    _autoSave();
  }

  void updateRotation(double value) {
    imageRotation.value = value;
    // Atualiza o campo de texto sem triggar o listener
    rotationTextController.text = value.round().toString();
    _autoSave();
  }

  void updateRotationFromText(String text) {
    final double? value = double.tryParse(text);
    if (value != null) {
      // Normaliza o valor para ficar entre 0 e 360
      final normalizedValue = value % 360;
      imageRotation.value = normalizedValue < 0
          ? normalizedValue + 360
          : normalizedValue;
      _autoSave();
    }
  }

  void rotateImage(double degrees) {
    final newRotation = (imageRotation.value + degrees) % 360;
    imageRotation.value = newRotation;
    rotationTextController.text = newRotation.round().toString();
    _autoSave();
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
    // Salva após terminar o gesto
    _autoSave();
  }

  void toggleOverlayVisibility() {
    showOverlayImage.value = !showOverlayImage.value;
    _autoSave();
  }

  // Métodos de gerenciamento de projeto
  void loadProject(Project project) {
    currentProject.value = project;

    // Carrega as configurações do projeto
    if (project.overlayImagePath != null &&
        project.overlayImagePath!.isNotEmpty) {
      selectedImagePath.value = project.overlayImagePath!;
    }
    imageOpacity.value = project.imageOpacity;
    imagePositionX.value = project.imagePositionX;
    imagePositionY.value = project.imagePositionY;
    imageScale.value = project.imageScale;
    imageRotation.value = project.imageRotation;
    showOverlayImage.value = project.showOverlayImage;

    // Atualiza o controller de texto
    rotationTextController.text = project.imageRotation.toInt().toString();
  }

  Future<void> saveCurrentProject() async {
    if (currentProject.value != null) {
      await _projectService.initialize();

      // Atualiza o projeto com as configurações atuais
      final updatedProject = currentProject.value!.copyWith(
        overlayImagePath: selectedImagePath.value.isNotEmpty
            ? selectedImagePath.value
            : null,
        imageOpacity: imageOpacity.value,
        imagePositionX: imagePositionX.value,
        imagePositionY: imagePositionY.value,
        imageScale: imageScale.value,
        imageRotation: imageRotation.value,
        showOverlayImage: showOverlayImage.value,
        lastModified: DateTime.now(),
      );

      final success = await _projectService.saveProject(updatedProject);
      if (success) {
        currentProject.value = updatedProject;
      }
    }
  }

  // Auto-save a cada mudança importante
  void _autoSave() {
    if (currentProject.value != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        saveCurrentProject();
      });
    }
  }

  // Novos métodos para incluir auto-save
  void setImageOpacity(double value) {
    imageOpacity.value = value;
    _autoSave();
  }

  void updateImagePosition(double deltaX, double deltaY) {
    imagePositionX.value += deltaX;
    imagePositionY.value += deltaY;
    _autoSave();
  }

  void updateImageScale(double scale) {
    imageScale.value = scale;
    _autoSave();
  }

  void updateImageRotation(double rotation) {
    imageRotation.value = rotation;
    rotationTextController.text = rotation.toInt().toString();
    _autoSave();
  }

  void resetImageTransform() {
    imagePositionX.value = 0.0;
    imagePositionY.value = 0.0;
    imageScale.value = 1.0;
    imageRotation.value = 0.0;
    imageOpacity.value = 0.5;
    rotationTextController.text = '0';
    _autoSave();
  }
}
