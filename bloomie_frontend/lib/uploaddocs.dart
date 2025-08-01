import 'package:flutter/material.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UploadDocumentsPage(),
    );
  }
}

class UploadDocumentsPage extends StatefulWidget {
  @override
  _UploadDocumentsPageState createState() => _UploadDocumentsPageState();
}

class _UploadDocumentsPageState extends State<UploadDocumentsPage> {
  bool isUploading = false;
  bool showFiles = false;
  
  List<String> uploadedFiles = [
    'Amy Hartanto DNA Report.pdf',
    'Amy Hartanto Health Report.pdf',
    'Amy Hartanto Test Reports.pdf',
  ];

  void _uploadDocuments() async {
    setState(() {
      isUploading = true;
    });
    
    // Wait for 2 seconds to simulate upload processing
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      isUploading = false;
      showFiles = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // Bloomie background image
          image: DecorationImage(
            image: AssetImage('assets/images/bloomie_background.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Bloomie logo - centered
              Container(
                width: 248,
                height: 62,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bloomie_icon.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title - centered and equally spaced
              Text(
                'Upload Documents',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF717070),
                  fontSize: 35,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Subtitle - moved down
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Please upload your baby\'s DNA document',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF818181),
                    fontSize: 25,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Main content area - changes based on state
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isUploading) 
                        _buildLoadingContent()
                      else if (showFiles)
                        _buildFilesContent()
                      else
                        _buildUploadContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadContent() {
    return Transform.translate(
      offset: Offset(0, -20), // Move up by 20px
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30), // Even spacing after subtitle
          
          // Upload icon with baby image - centered
          GestureDetector(
          onTap: _uploadDocuments,
          child: Container(
            width: 252,
            height: 233,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/uploadfiles.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Upload doc button - centered
        GestureDetector(
          onTap: _uploadDocuments,
          child: Container(
            width: 159,
            height: 55,
            decoration: ShapeDecoration(
              color: const Color(0xFFFAB494),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Center(
              child: Text(
                'Upload doc',
                style: TextStyle(
                  color: const Color(0xFF995444),
                  fontSize: 20,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Skip first option - centered
        GestureDetector(
          onTap: () {
            setState(() {
              showFiles = true;
            });
          },
          child: Text(
            'Skip first',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF818181),
              fontSize: 12,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildLoadingContent() {
    return Transform.translate(
      offset: Offset(0, -20), // Move up by 20px
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30), // Even spacing after subtitle
          
          // Loading animation
          Container(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            color: Color(0xFFFAB494),
            strokeWidth: 4,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Uploading documents...',
          style: TextStyle(
            color: Color(0xFF717070),
            fontSize: 18,
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildFilesContent() {
    return Transform.translate(
      offset: Offset(0, -30), // Shift everything up by 30px
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30), // Even spacing after subtitle
          
          // Uploaded files list - centered and shifted higher
          Column(
            children: [
              for (int i = 0; i < uploadedFiles.length; i++)
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  width: 252,
                  height: 29,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFD9D9D9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: Text(
                      uploadedFiles[i],
                      style: TextStyle(
                        color: const Color(0xFF818181),
                        fontSize: 15,
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 25),
        
        // Continue button - centered
        GestureDetector(
          onTap: () {
            // Navigate to next screen
            print("Continue to next screen");
          },
          child: Container(
            width: 159,
            height: 55,
            decoration: ShapeDecoration(
              color: const Color(0xFFFAB494),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Center(
              child: Text(
                'Continue',
                style: TextStyle(
                  color: const Color(0xFF995444),
                  fontSize: 20,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Upload more option - very close to center
        GestureDetector(
          onTap: () {
            // Handle upload more functionality
            print("Upload more documents");
          },
          child: Text(
            'Upload more',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF818181),
              fontSize: 12,
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ),
    );
  }
}