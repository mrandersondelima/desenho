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
          onPressed: () => Get.back(),
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
            // Camera Preview - Versão simplificada
            Positioned.fill(
              child: CameraPreview(controller.cameraController.value!),
            ),

            // Overlay Image
            if (controller.selectedImagePath.value.isNotEmpty &&
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
                          opacity: controller.imageOpacity.value,
                          child: Center(
                            child: Image.file(
                              File(controller.selectedImagePath.value),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Opacity Slider
                    if (controller.selectedImagePath.value.isNotEmpty)
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
                              onChanged: controller.updateOpacity,
                            ),
                          ),
                          Text(
                            '${(controller.imageOpacity.value * 100).round()}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),

                    // Rotation Slider and Text Input
                    if (controller.selectedImagePath.value.isNotEmpty)
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
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.orange,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.orange,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                        // Pick Image Button
                        FloatingActionButton(
                          heroTag: 'pick_image',
                          onPressed: controller.pickImage,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.image),
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
                        if (controller.selectedImagePath.value.isNotEmpty)
                          FloatingActionButton(
                            heroTag: 'toggle_overlay',
                            onPressed: controller.toggleOverlayVisibility,
                            backgroundColor: controller.showOverlayImage.value
                                ? Colors.orange
                                : Colors.grey,
                            child: Icon(
                              controller.showOverlayImage.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),

                        // Reset Transform Button
                        if (controller.selectedImagePath.value.isNotEmpty)
                          FloatingActionButton(
                            heroTag: 'reset_transform',
                            onPressed: controller.resetImageTransform,
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.refresh),
                          ),
                      ],
                    ),

                    // Rotation Quick Buttons (when image is selected)
                    if (controller.selectedImagePath.value.isNotEmpty)
                      const SizedBox(height: 12),
                    if (controller.selectedImagePath.value.isNotEmpty)
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
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Instructions
            if (controller.selectedImagePath.value.isEmpty)
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

            // Image manipulation instructions
            if (controller.selectedImagePath.value.isNotEmpty &&
                controller.showOverlayImage.value)
              const Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Card(
                  color: Colors.black54,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Arraste para mover • Pinça para redimensionar • Slider/campo de texto para rotação • Botões roxos para rotação rápida',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
