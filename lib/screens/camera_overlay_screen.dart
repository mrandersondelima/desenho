import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/camera_controller.dart';
import '../models/project.dart';

class CameraOverlayScreen extends StatelessWidget {
  final Project? project;
  final CameraOverlayController controller = Get.put(CameraOverlayController());

  CameraOverlayScreen({super.key, this.project});

  @override
  Widget build(BuildContext context) {
    // Carrega o projeto se fornecido
    if (project != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadProject(project!);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            // Força salvamento antes de voltar
            await controller.forceSave();
            Get.back();
          },
        ),
        title: Text(
          project?.name ?? 'Camera Overlay',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          if (project != null)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: controller.saveCurrentProject,
              tooltip: 'Salvar projeto',
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!controller.isCameraInitialized.value ||
            controller.cameraController.value == null) {
          return const Center(
            child: Text(
              'Erro ao inicializar câmera',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return Stack(
          children: [
            // Camera Preview com posicionamento
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(
                  controller.cameraPositionX.value,
                  controller.cameraPositionY.value,
                ),
                child: CameraPreview(controller.cameraController.value!),
              ),
            ),

            // Overlay Image
            if (controller.hasOverlayImages &&
                controller.showOverlayImage.value)
              Positioned.fill(
                child: GestureDetector(
                  onScaleStart: controller.onScaleStart,
                  onScaleUpdate: controller.onScaleUpdate,
                  onScaleEnd: controller.onScaleEnd,
                  child: Transform.translate(
                    offset: Offset(
                      controller.imagePositionX.value,
                      controller.imagePositionY.value,
                    ),
                    child: Transform.scale(
                      scale: controller.imageScale.value,
                      child: Transform.rotate(
                        angle:
                            controller.imageRotation.value *
                            3.14159 /
                            180, // Converte graus para radianos
                        child: Opacity(
                          opacity: controller.autoTransparencyValue.value,
                          child: Center(
                            child: Image.file(
                              File(controller.selectedImagePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            Positioned(
              top: 0,
              right: 0,
              child: FloatingActionButton(
                onPressed: controller.toggleVisibility,
                child: const Icon(Icons.remove_red_eye),
              ),
            ),

            // Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Obx(
                  () => Visibility(
                    visible: controller.areControlsVisible.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image Selection Slider (só aparece se houver múltiplas imagens)
                        if (controller.overlayImagePaths.length > 1)
                          Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.layers, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Imagem ${controller.currentImageIndex.value + 1} de ${controller.overlayImagePaths.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.image, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: controller.currentImageIndex.value
                                          .toDouble(),
                                      min: 0,
                                      max:
                                          (controller.overlayImagePaths.length -
                                                  1)
                                              .toDouble(),
                                      divisions:
                                          controller.overlayImagePaths.length -
                                          1,
                                      activeColor: Colors.green,
                                      inactiveColor: Colors.grey,
                                      onChanged: (value) {
                                        controller.selectImageByIndex(
                                          value.round(),
                                        );
                                      },
                                    ),
                                  ),
                                  Text(
                                    '${controller.currentImageIndex.value + 1}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        // Opacity Slider
                        if (controller.hasOverlayImages)
                          Row(
                            children: [
                              const Icon(Icons.opacity, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Slider(
                                  value: controller.imageOpacity.value,
                                  min: 0.0,
                                  max: 1.0,
                                  activeColor: Colors.blue,
                                  inactiveColor: Colors.grey,
                                  onChanged: controller.updateImageOpacity,
                                ),
                              ),
                              Text(
                                '${(controller.imageOpacity.value * 100).round()}%',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),

                        // Auto-transparency toggle (only in drawing mode)
                        if (controller.hasOverlayImages &&
                            controller.isDrawingMode.value)
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Auto Transparência',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value:
                                    controller.isAutoTransparencyEnabled.value,
                                activeColor: Colors.blue,
                                onChanged: (value) =>
                                    controller.toggleAutoTransparency(),
                              ),
                            ],
                          ),

                        // Rotation Slider and Text Input
                        if (controller.hasOverlayImages)
                          Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.rotate_right,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: controller.imageRotation.value,
                                      min: 0.0,
                                      max: 360.0,
                                      activeColor: Colors.orange,
                                      inactiveColor: Colors.grey,
                                      onChanged: controller.updateRotation,
                                    ),
                                  ),
                                  Text(
                                    '${controller.imageRotation.value.round()}°',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              // Text input for rotation
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Ângulo:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 35,
                                        child: TextField(
                                          controller:
                                              controller.rotationTextController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Colors.orange,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Colors.orange,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              borderSide: const BorderSide(
                                                color: Colors.orange,
                                                width: 2,
                                              ),
                                            ),
                                            suffixText: '°',
                                            suffixStyle: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          onSubmitted:
                                              controller.updateRotationFromText,
                                          onChanged:
                                              controller.updateRotationFromText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Pick Image Button (com suporte a múltiplas imagens)
                            GestureDetector(
                              onTap: controller.pickImage,
                              onLongPress:
                                  controller.pickMultipleImagesFromGallery,
                              child: FloatingActionButton(
                                heroTag: 'pick_image',
                                onPressed: null, // Usa GestureDetector ao invés
                                backgroundColor: Colors.blue,
                                child: Stack(
                                  children: [
                                    const Center(
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (controller.overlayImagePaths.length > 1)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${controller.overlayImagePaths.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Switch Camera Button
                            FloatingActionButton(
                              heroTag: 'switch_camera',
                              onPressed: controller.cameras.length > 1
                                  ? controller.switchCamera
                                  : null,
                              backgroundColor: controller.cameras.length > 1
                                  ? Colors.green
                                  : Colors.grey,
                              child: const Icon(Icons.switch_camera),
                            ),

                            // Toggle Overlay Button
                            if (controller.hasOverlayImages)
                              FloatingActionButton(
                                heroTag: 'toggle_overlay',
                                onPressed: controller.toggleOverlayVisibility,
                                backgroundColor:
                                    controller.showOverlayImage.value
                                    ? Colors.orange
                                    : Colors.grey,
                                child: Icon(
                                  controller.showOverlayImage.value
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),

                            // Reset Transform Button
                            if (controller.hasOverlayImages)
                              FloatingActionButton(
                                heroTag: 'reset_transform',
                                onPressed: controller.resetImageTransform,
                                backgroundColor: Colors.red,
                                child: const Icon(Icons.refresh),
                              ),
                          ],
                        ),

                        // Mode Toggle (when image is selected)
                        if (controller.hasOverlayImages) ...[
                          const SizedBox(height: 16),

                          // Mode Toggle Switch
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune,
                                  color: !controller.isDrawingMode.value
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ajuste',
                                  style: TextStyle(
                                    color: !controller.isDrawingMode.value
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Switch(
                                  value: controller.isDrawingMode.value,
                                  onChanged: (value) =>
                                      controller.toggleDrawingMode(),
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: Colors.grey.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Desenho',
                                  style: TextStyle(
                                    color: controller.isDrawingMode.value
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.draw,
                                  color: controller.isDrawingMode.value
                                      ? Colors.white
                                      : Colors.grey,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Rotation Quick Buttons (when image is selected)
                        if (controller.hasOverlayImages)
                          const SizedBox(height: 12),
                        if (controller.hasOverlayImages)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Rotate Left 90°
                              FloatingActionButton.small(
                                heroTag: 'rotate_left',
                                onPressed: () => controller.rotateImage(-90),
                                backgroundColor: Colors.purple,
                                child: const Icon(Icons.rotate_left, size: 20),
                              ),

                              // Rotate Right 90°
                              FloatingActionButton.small(
                                heroTag: 'rotate_right',
                                onPressed: () => controller.rotateImage(90),
                                backgroundColor: Colors.purple,
                                child: const Icon(Icons.rotate_right, size: 20),
                              ),

                              // Rotate 180°
                              FloatingActionButton.small(
                                heroTag: 'rotate_180',
                                onPressed: () => controller.rotateImage(180),
                                backgroundColor: Colors.purple,
                                child: const Icon(Icons.flip, size: 20),
                              ),

                              // Fine Tune Dimensions Button
                              FloatingActionButton.small(
                                heroTag: 'fine_tune_dimensions',
                                onPressed: controller.showDimensionsModal,
                                backgroundColor: Colors.teal,
                                child: const Icon(
                                  Icons.photo_size_select_large,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Instructions
            if (!controller.hasOverlayImages)
              const Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Card(
                  color: Colors.black54,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Toque no botão da imagem para selecionar uma foto e sobrepor na câmera',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // Mode and Zoom Status (when image is selected)
            if (controller.hasOverlayImages)
              Positioned(
                top: 100,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: controller.isDrawingMode.value
                          ? Colors.green
                          : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.isDrawingMode.value
                            ? Icons.draw
                            : Icons.tune,
                        color: controller.isDrawingMode.value
                            ? Colors.green
                            : Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.isDrawingMode.value
                            ? 'Modo Desenho'
                            : 'Modo Ajuste',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (controller.isDrawingMode.value) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.zoom_in, color: Colors.grey[300], size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${controller.cameraZoom.value.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Barra de instruções deslizante
            Obx(
              () => AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: controller.isMoveBarExpanded.value ? 50 : -30,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildToolbarButton(
                        label: "Imagem",
                        isActive: controller.isImageMoveButtonActive.value,
                        onPressed: () {
                          controller.toggleMoveImageButton();
                        },
                      ),
                      _buildToolbarButton(
                        label: "Câmera",
                        isActive: controller.isCameraMoveButtonActive.value,
                        onPressed: () {
                          controller.toggleMoveCameraButton();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Barra de opacidade deslizante
            Obx(
              () => AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: controller.isOpacityBarExpanded.value ? 50 : -30,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.opacity, color: Colors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: controller.imageOpacity.value,
                            min: 0.0,
                            max: 1.0,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey,
                            onChanged: controller.updateImageOpacity,
                          ),
                        ),
                        Text(
                          '${(controller.imageOpacity.value * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Barra de ferramentas inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão Mover
                    Obx(
                      () => _buildToolbarButton(
                        label: 'Mover',
                        isActive: controller.isMoveButtonActive.value,
                        onPressed: () {
                          controller.toggleMoveButton();
                          controller.isMoveBarExpanded.value =
                              !controller.isMoveBarExpanded.value;
                        },
                      ),
                    ),

                    // Botão Esconder
                    Obx(
                      () => _buildToolbarButton(
                        label: 'Esconder',
                        isActive: controller.isHideButtonActive.value,
                        onPressed: () {
                          controller.toggleHideButton();
                          Get.snackbar(
                            'Esconder',
                            'Funcionalidade em desenvolvimento',
                          );
                        },
                      ),
                    ),

                    // Botão Opacidade
                    Obx(
                      () => _buildToolbarButton(
                        label: 'Opacidade',
                        isActive: controller.isOpacityButtonActive.value,
                        onPressed: () {
                          controller.toggleOpacityButton();
                          controller.isOpacityBarExpanded.value =
                              !controller.isOpacityBarExpanded.value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildToolbarButton({
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
