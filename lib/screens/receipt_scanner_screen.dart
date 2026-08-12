import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/expense.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState
    extends State<ReceiptScannerScreen> {
  final ImagePicker picker = ImagePicker();
  final OCRService ocr = OCRService();

  File? image;
  String extractedText = "";
  Expense? detectedExpense;

  bool scanning = false;

  Future<void> pickImage() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        image = File(picked.path);
        extractedText = "";
        detectedExpense = null;
        scanning = true;
      });

      final text = await ocr.recognizeText(image!);

      final expense = ReceiptParser.parseReceipt(text);

      if (!mounted) return;

      setState(() {
        extractedText = text;
        detectedExpense = expense;
        scanning = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        scanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Unable to scan receipt: $e",
          ),
        ),
      );
    }
  }

  void saveDetectedExpense() {
    if (detectedExpense == null) return;

    Navigator.pop(
      context,
      detectedExpense,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipt Scanner"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: scanning ? null : pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  scanning
                      ? "Scanning..."
                      : "Scan Receipt",
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 15),

            if (scanning)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("Reading receipt..."),
                ],
              ),

            if (!scanning && detectedExpense != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Detected Expense",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListTile(
                                leading:
                                    const Icon(Icons.store),
                                title: const Text("Title"),
                                subtitle: Text(
                                  detectedExpense!.title,
                                ),
                              ),

                              ListTile(
                                leading:
                                    const Icon(
                                  Icons.payments,
                                ),
                                title:
                                    const Text("Amount"),
                                subtitle: Text(
                                  "Rs. ${detectedExpense!.amount.toStringAsFixed(0)}",
                                ),
                              ),

                              ListTile(
                                leading:
                                    const Icon(
                                  Icons.category,
                                ),
                                title:
                                    const Text("Category"),
                                subtitle: Text(
                                  detectedExpense!.category,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              saveDetectedExpense,
                          icon: const Icon(Icons.save),
                          label: const Text(
                            "Use This Expense",
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Extracted Receipt Text",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      SelectableText(
                        extractedText,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!scanning &&
                extractedText.isNotEmpty &&
                detectedExpense == null)
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    extractedText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ocr.dispose();
    super.dispose();
  }
}