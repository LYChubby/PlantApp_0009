import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:plantsapp/bloc_camera/camera_event.dart';
import 'package:plantsapp/components/camera_page.dart';

import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  late final List<CameraDescription> _cameras;

  CameraBloc() : super(CameraInitial()) {
    on<InitializeCamera>(_onInit);
    on<SwitchCamera>(_onSwitch);
    on<ToogleFlash>(_onToggleFlash);
    on<TakePicture>(_onTakePicture);
    on<TapToFocus>(_onTapFocus);
    on<PickImageFromGallery>(_onPickGallery);
    on<OpenCameraAndCapture>(_onOpenCamera);
    on<DeleteImage>(_onDeleteImage);
    on<ClearSnackbar>(_onClearSnackbar);
    on<RequestPermission>(_onRequestPermission);
  }

  Future<void> _onInit(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    _cameras = await availableCameras();

    await _setupController(0, emit);
  }

  Future<void> _onSwitch(SwitchCamera event, Emitter<CameraState> emit) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final next = (s.selectedIndex + 1) % _cameras.length;
    await _setupController(next, emit, previous: s);
  }

  Future<void> _onToggleFlash(
    ToogleFlash event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final next =
        s.flashMode == FlashMode.off
            ? FlashMode.auto
            : s.flashMode == FlashMode.auto
            ? FlashMode.always
            : FlashMode.off;
    await s.controller.setFlashMode(next);
    emit(s.copyWith(flashMode: next));
  }

  Future<void> _onTakePicture(
    TakePicture event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final file = await s.controller.takePicture();
    event.onPictureTaken(File(file.path));
  }

  Future<void> _onTapFocus(TapToFocus event, Emitter<CameraState> emit) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    final relative = Offset(
      event.position.dx / event.previewSize.width,
      event.position.dy / event.previewSize.height,
    );
    await s.controller.setFocusPoint(relative);
    await s.controller.setExposurePoint(relative);
  }

  Future<void> _onPickGallery(
    PickImageFromGallery event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;

    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        emit(
          (state as CameraReady).copyWith(
            snackbarMessage: 'Izin galeri ditolak',
          ),
        );
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (picked != null) {
        emit(
          (state as CameraReady).copyWith(
            imageFile: File(picked.path),
            snackbarMessage: 'Berhasil memilih dari galeri',
          ),
        );
      }
    } catch (e) {
      emit(
        (state as CameraReady).copyWith(
          snackbarMessage: 'Error: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onOpenCamera(
    OpenCameraAndCapture event,
    Emitter<CameraState> emit,
  ) async {
    try {
      if (state is! CameraReady) {
        await _onInit(InitializeCamera(), emit);
        if (state is! CameraReady) return;
      }

      final file = await Navigator.push<File?>(
        event.context,
        MaterialPageRoute(
          builder:
              (_) => BlocProvider.value(value: this, child: const CameraPage()),
        ),
      );

      if (file != null) {
        emit(
          (state as CameraReady).copyWith(
            imageFile: file,
            snackbarMessage: 'Foto berhasil diambil',
          ),
        );
      }
    } catch (e) {
      emit(
        (state as CameraReady).copyWith(
          snackbarMessage: 'Error kamera: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteImage(
    DeleteImage event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    await s.imageFile?.delete();
    emit(
      CameraReady(
        controller: s.controller,
        selectedIndex: s.selectedIndex,
        flashMode: s.flashMode,
        imageFile: null,
        snackbarMessage: 'Gambar Dihapus',
      ),
    );
  }

  Future<void> _onClearSnackbar(
    ClearSnackbar event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    final s = state as CameraReady;
    emit(s.copyWith(clearSnackbar: true));
  }

  Future<void> _setupController(
    int index,
    Emitter<CameraState> emit, {
    CameraReady? previous,
  }) async {
    await previous?.controller.dispose();
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.max,
      enableAudio: false,
    );
    await controller.initialize();
    await controller.setFlashMode(previous?.flashMode ?? FlashMode.off);

    emit(
      CameraReady(
        controller: controller,
        selectedIndex: index,
        flashMode: previous?.flashMode ?? FlashMode.off,
        imageFile: previous?.imageFile,
        snackbarMessage: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    if (state is CameraReady) {
      await (state as CameraReady).controller.dispose();
    }
    return super.close();
  }

  Future<void> _onRequestPermission(
    RequestPermission event,
    Emitter<CameraState> emit,
  ) async {
    final statuses =
        await [
          Permission.camera,
          Permission.microphone,
          Permission.storage,
        ].request();

    final denied = statuses.entries.where((e) => !e.value.isGranted).toList();

    if (denied.isNotEmpty) {
      if (state is CameraReady) {
        emit(
          (state as CameraReady).copyWith(
            snackbarMessage: 'Izin Kamera Atau Penyimpanan Ditolak',
          ),
        );
      }
    }
  }
}
