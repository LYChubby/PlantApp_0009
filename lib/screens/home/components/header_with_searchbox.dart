import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:plantsapp/bloc_camera/camera_bloc.dart';
import 'package:plantsapp/bloc_camera/camera_event.dart';
import 'package:plantsapp/bloc_camera/camera_state.dart';
import 'package:plantsapp/constanst.dart';

class HeaderWithSearchBox extends StatelessWidget {
  const HeaderWithSearchBox({super.key, required this.size});

  final Size size;

  void _showImagePickerDialog(BuildContext context) {
    final cameraBloc = BlocProvider.of<CameraBloc>(context);
    final imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pilih Sumber Gambar"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text("Ambil Foto dengan Kamera"),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      // Cek permission kamera
                      if (await Permission.camera.request().isGranted) {
                        if (cameraBloc.state is! CameraReady) {
                          cameraBloc.add(InitializeCamera());
                        }
                        cameraBloc.add(OpenCameraAndCapture(context));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Izin kamera ditolak')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text("Pilih dari Galeri"),
                  onTap: () async {
                    final currentContext =
                        context; // Simpan context sebelum navigasi
                    Navigator.pop(currentContext);

                    try {
                      if (await Permission.photos.request().isGranted) {
                        final pickedFile = await imagePicker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1800,
                          maxHeight: 1800,
                        );

                        if (pickedFile != null) {
                          if (currentContext.mounted) {
                            // Periksa apakah widget masih aktif
                            cameraBloc.add(PickImageFromGallery());
                          }
                        }
                      } else if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(content: Text('Izin galeri ditolak')),
                        );
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: kDefaultPadding * 2.5),
      height: size.height * 0.2,
      child: Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(
              left: kDefaultPadding,
              right: kDefaultPadding,
              bottom: 36 + kDefaultPadding,
            ),
            height: size.height * 0.2 - 27,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  "Hi Fauzi !",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                CircleAvatar(
                  radius: 50, // Ukuran radius
                  backgroundImage: AssetImage("assets/images/profile.jpeg"),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: kDefaultPadding),
              padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 10),
                    blurRadius: 50,
                    color: kPrimaryColor.withOpacity(0.23),
                  ),
                ],
              ),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(color: kPrimaryColor.withOpacity(0.5)),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: IconButton(
                    icon: Icon(Icons.camera_alt_outlined, color: kPrimaryColor),
                    onPressed: () {
                      _showImagePickerDialog(context);
                    },
                  ),
                  suffixIcon: Icon(Icons.search, color: kPrimaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
