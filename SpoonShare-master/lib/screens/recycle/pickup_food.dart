// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spoonshare/constants/app_constants.dart';
import 'package:spoonshare/l10n/app_localization.dart';
import 'package:spoonshare/models/users/user.dart';
import 'package:spoonshare/screens/donate/thank_you.dart';
import 'package:spoonshare/utils/label_keys.dart';
import 'package:spoonshare/widgets/auto_complete.dart';
import 'package:spoonshare/widgets/custom_text_field.dart';
import 'package:spoonshare/widgets/loader.dart';
import 'package:spoonshare/widgets/snackbar.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:uuid/uuid.dart';

class RecycleFoodScreenContent extends StatefulWidget {
  const RecycleFoodScreenContent({super.key});

  @override
  _RecycleFoodScreenContentState createState() =>
      _RecycleFoodScreenContentState();
}

class _RecycleFoodScreenContentState extends State<RecycleFoodScreenContent> {
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _pickuplocationController =
      TextEditingController();
  final TextEditingController _foodlifeController = TextEditingController();
  final TextEditingController _fooddescriptionController =
      TextEditingController();
  final TextEditingController _foodquantityController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _toTimeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _imageFile;
  String _selectedFoodType = '';
  late double lat;
  late double lng;
  bool _addressSelected = false;

  String tokenForSession = "12345";
  List<Map<String, dynamic>> listForPlaces = [];
  var uuid = const Uuid();

  Future<void> makeSuggestions(String input) async {
    try {
      var suggestions = await PlaceApi.getSuggestions(input);
      setState(() {
        listForPlaces = suggestions;
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _addressController.addListener(onModify);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void onModify() {
    if (tokenForSession.isEmpty) {
      setState(() {
        tokenForSession = uuid.v4();
      });
    }
    makeSuggestions(_addressController.text);
  }

  Future<void> handleListItemTap(int index) async {
    String placeId = listForPlaces[index]['place_id'];
    var placeDetails = await PlaceApi.getPlaceDetails(placeId);
    double selectedLat = placeDetails['geometry']['location']['lat'];
    double selectedLng = placeDetails['geometry']['location']['lng'];
    String selectedAddress = listForPlaces[index]['description'];

    setState(() {
      _addressController.text = selectedAddress;
      lat =
          selectedLat; // Update the class-level variables with the selected values
      lng = selectedLng;
      _addressSelected = true; // Set _addressSelected to true
    });
  }

  @override
  Widget build(BuildContext context) {
    bool showExpandedList =
        _addressController.text.isNotEmpty && !_addressSelected;
    var localization = AppLocalization.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        _buildImageUploadBox(),
        const SizedBox(
          height: 8,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: localization!.translate(LabelKey.pickupLocation)!,
          controller: _pickuplocationController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
            label: localization.translate(LabelKey.pickupAddress)!,
            controller: _addressController),
        if (showExpandedList)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.builder(
              itemCount: listForPlaces.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () async {
                    _addressSelected = true;
                    await handleListItemTap(index);
                  },
                  title: Text(
                    listForPlaces[index]['description'],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        CustomTextField(
          label: localization.translate(LabelKey.foodLifeRecycle)!,
          controller: _foodlifeController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: localization.translate(LabelKey.foodDescription)!,
          controller: _fooddescriptionController,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: localization.translate(LabelKey.foodQuantity)!,
          controller: _foodquantityController,
        ),
        const SizedBox(height: 16),
        _buildDateAndTimeInputs(context),
        const SizedBox(height: 16),
        _buildDropdownInput(),
        const SizedBox(height: 16),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildDateAndTimeInputs(BuildContext context) {
    var localization = AppLocalization.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
                child: TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () async {
                    DateTime? selectedDate =
                        await _selectDate(context, _dateController);
                    if (selectedDate != null) {
                      _dateController.text =
                          selectedDate.toLocal().toString().split(' ')[0];
                    }
                  },
                  decoration: InputDecoration(
                    hintText: localization!.translate(LabelKey.pickupDate)!,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF9F1C),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF9F1C),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
                child: TextFormField(
                  controller: _toTimeController,
                  readOnly: true,
                  onTap: () async {
                    TimeOfDay? selectedTime =
                        await _selectTime(context, _toTimeController);
                    if (selectedTime != null) {
                      _toTimeController.text = selectedTime.format(context);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: localization.translate(LabelKey.pickupTimeTill)!,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF9F1C),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF9F1C),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<DateTime?> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      controller.text = picked.toLocal().toString().split(' ')[0];
    }

    return picked;
  }

  Future<TimeOfDay?> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      controller.text = picked.format(context);
    }

    return picked;
  }

  Widget _buildImageUploadBox() {
    var localization = AppLocalization.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              pickFile();
            },
            child: Container(
              width: 280,
              height: 180,
              decoration: ShapeDecoration(
                color: Colors.black.withOpacity(0.07999999821186066),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: Colors.black.withOpacity(0.6000000238418579),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _imageFile == null
                  ? const Icon(
                      Icons.camera_alt,
                      size: 48,
                      color: Colors.grey,
                    )
                  : Image.file(
                      _imageFile!,
                      width: 48, // Adjust the size as needed
                      height: 48, // Adjust the size as needed
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              localization!.translate(LabelKey.requiredFileds)!,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickFile() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    late final Map<Permission, PermissionStatus> status;
    if (androidInfo.version.sdkInt <= 32) {
      status = await [
        Permission.storage,
        Permission
            .camera, // Request camera permission for devices with SDK <= 32
      ].request();
    } else {
      status = await [
        Permission.photos,
        Permission.camera,
        Permission.notification,
      ].request();
    }

    var allAccepted = true;
    status.forEach((permission, status) {
      if (status != PermissionStatus.granted) {
        allAccepted = false;
      }
    });

    if (allAccepted) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          var localization = AppLocalization.of(context)!;
          return Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo),
                title: Text(localization.translate(LabelKey.pickGallery)!),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera),
                title: Text(localization.translate(LabelKey.captureCamera)!),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(ImageSource.camera);
                },
              ),
            ],
          );
        },
      );
    } else {}
  }

  Future<void> _pickImage(ImageSource source) async {
    XFile? pickedImage = await ImagePicker().pickImage(
      source: source,
    );

    if (pickedImage != null) {
      _imageFile = File(pickedImage.path);
      _imageController.text = _imageFile!.path;
      setState(() {});
    }
  }

  Widget _buildSubmitButton() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    var localization = AppLocalization.of(context);
    return Container(
      width: screenWidth * 0.8667,
      height: screenHeight * 0.05625,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.kGreenColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: InkWell(
        onTap: () {
          submitFood();
        },
        child:  Center(
          child: Text(
            localization!.translate(LabelKey.submitButton)!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.36,
            ),
          ),
        ),
      ),
    );
  }

  void submitFood() async {
    // Check if all required fields are filled
    if (_imageFile == null ||
        _selectedFoodType.isEmpty ||
        _pickuplocationController.text.isEmpty ||
        _imageController.text.isEmpty ||
        _foodlifeController.text.isEmpty ||
        _fooddescriptionController.text.isEmpty ||
        _foodquantityController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _toTimeController.text.isEmpty) {
      showErrorSnackbar(context, 'Please fill all required fields');
      return;
    }

    try {
      showLoadingDialog(context);

      String userId = FirebaseAuth.instance.currentUser!.uid;
      UserProfile userProfile = UserProfile();
      String fullName = userProfile.getFullName();
      String pickup = _pickuplocationController.text;
      String address = _addressController.text;
      String foodlife = _foodlifeController.text;
      String fooddescription = _fooddescriptionController.text;
      String foodquantity = _foodquantityController.text;
      String date = _dateController.text;
      String toTime = _toTimeController.text;

      // Upload the image to Firebase Storage
      String imageurl = await uploadImageToFirebaseStorage(_imageFile, userId);
      // Create a map with food details, including a timestamp

      GeoPoint location = GeoPoint(lat, lng);

      Map<String, dynamic> foodData = {
        'userId': userId,
        'fullName': fullName,
        'pickup': pickup,
        'address': address,
        'image': imageurl,
        'location': location,
        'foodlife': foodlife,
        'fooddescription': fooddescription,
        'foodquantity': foodquantity,
        'foodType': _selectedFoodType,
        'date': date,
        'toTime': toTime,
        'verified': false,
        'timestamp': FieldValue.serverTimestamp(),
      };
      // Save food data under the user's document in the 'sharedFood' collection
      await FirebaseFirestore.instance
          .collection('food')
          .doc('recyclefood')
          .collection("foodData")
          .add(foodData);

      Navigator.of(context).pop();
      showSuccessSnackbar(context, 'Food submitted successfully!');
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ThankYouScreen()));
    } catch (e) {
      showErrorSnackbar(context, 'Error submitting food');
    } finally {
      _pickuplocationController.clear();
      _foodlifeController.clear();
      _foodquantityController.clear();
      _imageController.clear();
      _dateController.clear();
      _toTimeController.clear();
      _imageFile = null;

      setState(() {
        _selectedFoodType = '';
      });
    }
  }

  Widget _buildDropdownInput() {
    return Container(
      width: double.infinity,
      height: 46,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonFormField<String>(
          value: _selectedFoodType.isNotEmpty ? _selectedFoodType : null,
          hint: const Text('Food Type'),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Color(0xFFFF9F1C),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Color(0xFFFF9F1C),
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _selectedFoodType = value!;
            });
          },
          items: const [
            DropdownMenuItem<String>(
              value: 'veg',
              child: Text('Veg'),
            ),
            DropdownMenuItem<String>(
              value: 'nonveg',
              child: Text('Non-Veg'),
            ),
            DropdownMenuItem<String>(
              value: 'both',
              child: Text('Both'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> uploadImageToFirebaseStorage(
      File? imageFile, String venue) async {
    if (imageFile == null) {
      throw Exception('Image file is null');
    }

    try {
      String fileName = 'food/recycle_food/$venue.jpg';
      firebase_storage.Reference storageReference =
          firebase_storage.FirebaseStorage.instance.ref().child(fileName);

      await storageReference.putFile(imageFile);

      String downloadURL = await storageReference.getDownloadURL();

      return downloadURL;
    } catch (e) {
      throw Exception('Error uploading image to Firebase Storage');
    }
  }
}

class RecycleFoodScreen extends StatelessWidget {
  const RecycleFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Food'),
        backgroundColor: const Color(0xFF06D801),
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontSize: 18,
            fontWeight: FontWeight.w700),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(right: 20, left: 20, bottom: 20),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              RecycleFoodScreenContent(),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: const BottomNavBar()
    );
  }
}
