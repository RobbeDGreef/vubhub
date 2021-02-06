import 'package:flutter/material.dart';
import 'package:pdf_text/pdf_text.dart';

import 'infohandler.dart';

class ExamView extends StatefulWidget {
  InfoHandler info;

  ExamView(this.info);
  @override
  _ExamViewState createState() => _ExamViewState(this.info);
}

class _ExamViewState extends State<ExamView> {
  InfoHandler info;

  _ExamViewState(this.info);

  void test() async {
    PDFDoc doc = await PDFDoc.fromURL(
        'https://we.vub.ac.be/sites/default/files/images/BA-Examenrooster_Januari%202021_30112020_OP%20RICHTING_1.pdf');

    print("amount of pages: ${doc.length}");
    print(await doc.text);
  }

  @override
  Widget build(BuildContext context) {
    test();
    return Scaffold(
      appBar: AppBar(title: Text("Exams")),
      body: Text("test"),
    );
  }
}
