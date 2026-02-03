import 'package:flutter/material.dart';
import '../s.dart';
import 'package:flutter/services.dart';
import '../globals.dart';

class Comments extends StatefulWidget {
  static final Comments _singleton = Comments._internal();

  factory Comments() {
    return _singleton;
  }

  Comments._internal();

  final _focusNode = FocusNode();
  final TextEditingController commentsController =
      TextEditingController(text: "#$appName");

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    widget.commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: widget._focusNode,
      controller: widget.commentsController,
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      decoration: InputDecoration(
          prefixIconColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.all(10.0),
          suffixIcon: IconButton(
              onPressed: widget.commentsController.clear,
              icon: const Icon(Icons.clear)),
          suffixIconColor: Theme.of(context).colorScheme.primary,
          labelText: S.of(context).comments,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
          hintText: S.of(context).enterYourComments,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
          border: const UnderlineInputBorder()),
    );
  }
}

class CommentsSimple extends StatefulWidget {
  CommentsSimple({required this.comments, super.key});

  String comments;

  @override
  State<CommentsSimple> createState() => _CommentsSimpleState();
}

class _CommentsSimpleState extends State<CommentsSimple> {
  late final TextEditingController _commentsController;
  final _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    // Инициализация контроллера ОДИН РАЗ в initState
    _commentsController = TextEditingController(text: widget.comments);

    // Опционально: сохраняем текст при потере фокуса
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        widget.comments = _commentsController.text;
      }
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      controller: _commentsController,
      keyboardType: TextInputType.multiline,
      maxLines: 5,
      decoration: InputDecoration(
          prefixIconColor: Theme.of(context).colorScheme.primary,
          contentPadding: const EdgeInsets.all(10.0),
          suffixIcon: IconButton(
              onPressed: _commentsController.clear,
              icon: const Icon(Icons.clear)),
          suffixIconColor: Theme.of(context).colorScheme.primary,
          labelText: S.of(context).comments,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
          hintText: S.of(context).enterYourComments,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
          border: const UnderlineInputBorder()),
    );
  }
}
