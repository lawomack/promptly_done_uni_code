Promptly Done Code

This folder contains all the files that have been created and modified by the researcher to produce the Promptly Done App. The language used is Dart with the Flutter Framework. 

This folder does not contain all the Flutter files needed to run as an app - the size and number of files made this impractical to upload to moodle given its limits. These additional files are generated automatically on the creation of a Flutter project and have not been modified since. The complete folder, including all the Flutter files and code produce by the researcher needed to run the app, can be found at the following link. 

https://drive.google.com/file/d/1Eeh2eHUJwsX_e-a20wOMsfetMI5l_HO2/view?usp=sharing



In order to run this code as an app, it will be necessary to run the code either on an emulator or install it on a smartphone. The code has been tested for Android OS only - it is not guaranteed to work on Apple iOS. 



To Install Promptly Done on an Android Device

Prepare the Android device by enabling developer options. This can be done by navigating to Settings > About phone. Tap “Build Number” 7 times until “You are now a developer!” appears. Within Settings, navigate to System > Developer Options and set USB debugging to On.

Open the “uni_project” folder (available at the link above) in an IDE such as VS Code. Ensure that Flutter is correctly installed.  

Connect the smartphone to the computer. When prompted, select “allow USB debugging”. To ensure the smartphone has connected successfully, type in the following command. It should appear as one of the connected devices.

“flutter devices”

To create a release version of the app, enter the following command:

“flutter build apk --release"

Once the build is complete, install it with the following command:

“flutter install”

The app should now be successfully installed and ready for use. 


In order for the smartphone to detect the beacon, ensure that the Beacon Scanner Class code has the target UUID modified to match the UUID of the beacon you wish to detect. 



Running the Code on an Android Emulator

It is possible to run the code on an Android emulator. As the emulator cannot detect the beacon, some code has been written for a “Simulate Beacon Detection” button. This can be found at lines 462-478 in the promptly_done.dart file and has been commented out. By adding this code back in, it will allow for the emulator to show how the app will behave if the beacon is detected, including generating a notification pop-up, playing the alarm noise, and marking the activated prompt card grey. 

To install on the emulator, ensure it is recognised by the IDE using the “flutter devices” command. It should appear as one of the connected devices. To run the code on the emulator, enter the following command:

“flutter run”

