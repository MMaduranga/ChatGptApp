import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart';
import 'chat_message.dart';

class PdfCreator {
  static Future<File> generate(List<ChatMessage> messages, String name) async {
    final pdf = Document();
    pdf.addPage(MultiPage(build: (context) => createWidget(messages)));

    return saveDocument(name: '$name.pdf', pdf: pdf);
  }

  static Future<File> saveDocument(
      {required String name, required Document pdf}) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future openFile(File file) async {
    final url = file.path;
    await OpenFile.open(url);
  }

  static List<Widget> createWidget(List<ChatMessage> messages) {
    List<Widget> widgetList = [];
    for (ChatMessage msg in messages.reversed) {
      if(msg.sender =='user'){
        widgetList.add(Header(text: '${msg.text}\n'));
      }else{
        widgetList.add(Paragraph(text: '${msg.text}\n'));
      }

    }
    return widgetList;
  }
}
