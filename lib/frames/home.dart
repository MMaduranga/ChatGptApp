import 'dart:async';
import 'dart:io';
import 'package:chatgpt_flutter/frames/pdf_creator.dart';
import 'package:chatgpt_flutter/frames/three_dots.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'answer_model.dart';
import 'chat_message.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String apiKey = "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";
  final TextEditingController textController = TextEditingController();
  final TextEditingController _textFieldController = TextEditingController();
  final List<ChatMessage> messages = <ChatMessage>[];
  StreamSubscription? subscription;
  bool isTyping = false;
  List fileNames = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getFilesPath();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    subscription?.cancel();
    super.dispose();
  }

  void sendMessage() {
    if (textController.text.isEmpty) return;
    ChatMessage message = ChatMessage(
      text: textController.text,
      sender: "user",
    );
    messages.insert(0, message);
    isTyping = true;
    apiCall(msg: textController.text.trim());
    setState(() {
      textController.clear();
    });

  }

  void insertNewData(String response) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
    );

    isTyping = false;
    messages.insert(0, botMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromRGBO(190, 190, 190, 1.0),
        drawer: naviDrawer(),
        appBar: AppBar(
            elevation: 0,
            actions: <Widget>[
              IconButton(
                  onPressed: () {
                    setState(() {
                      messages.clear();
                    });
                  },
                  icon: const Icon(Icons.add)),
              IconButton(
                  onPressed: () {
                    setState(() {
                      fileNames.clear();
                      getFilesPath();
                    });
                  },
                  icon: const Icon(Icons.refresh)),
              IconButton(
                  onPressed: () async {
                    _textFieldController.clear();
                    await displayTextInputDialog(context);
                  },
                  icon: const Icon(Icons.save_alt_sharp))
            ],
            backgroundColor: Colors.black,
            title: const Text(
              "Chat",
              style: TextStyle(color: Colors.white),
            )),
        body: SafeArea(
          child: Column(
            children: [
              Flexible(
                  child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return messages[index];
                },
              )),
              if (isTyping) const ThreeDots(),
              const Divider(
                height: 1.0,
              ),
              Card(
                child: buildChatTextEditor(),
              )
            ],
          ),
        ));
  }

  Widget buildChatTextEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              onSubmitted: (value) => sendMessage(),
              decoration: const InputDecoration.collapsed(
                  hintText: "Ask question here..."),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5, bottom: 5),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.black),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              onPressed: () {
                sendMessage();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget naviDrawer() {
    return Drawer(
      child: ListView.builder(
          itemCount: fileNames.length,
          itemBuilder: (BuildContext context, int index) {
            return getListTile(index);
          }),
    );
  }

  getListTile(int index) {
    var name = fileNames[index].toString().replaceFirst('\'', '');
    return GestureDetector(
      onTap: () async {
        final dir = await getApplicationDocumentsDirectory();
        File file = File('${dir.path}/$name');
        PdfCreator.openFile(file);
      },
      child: ListTile(
          leading: const Icon(Icons.list),
          title: Text(
            name,
            style: const TextStyle(fontSize: 15),
          )),
    );
  }

  saveDoc(String name) async {
    if (messages.isNotEmpty) {
      final pdfCreate = await PdfCreator.generate(messages, name);
      //PdfCreator.openFile(pdfCreate);
    }
  }

  Future getFilesPath() async {
    final dir = await getApplicationDocumentsDirectory();
    Directory direct = Directory(dir.path);
    List<FileSystemEntity> files = direct.listSync(recursive: false);
    for (FileSystemEntity file in files) {
      var regExp = RegExp(r'.pdf');
      String str = file.absolute.toString();
      var match = regExp.stringMatch(str);
      if (match != null) {
        fileNames.add(str.split('/').last);
      }
    }
    setState(() {});
  }


  void apiCall({required String msg}) async {
    Dio dio = Dio();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["authorization"] = "Bearer $apiKey";

    Map<String, dynamic> data = {
      "model": "text-davinci-003",
      "prompt": msg,
      "temperature": 0,
      "max_tokens": 800
    };

    var response =
        await dio.post("https://api.openai.com/v1/completions", data: data);
    AnswerModel answerModel = AnswerModel.fromJson(response.data);
    insertNewData(answerModel.choices?.first.text?.trim() ?? "");
    setState(() {});
  }

  Future<void> displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Save Doc As?'),
            content: TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: ""),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.add),
                color: Colors.green,
                onPressed: () async {
                  await saveDoc(_textFieldController.text.trim());
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }
}
