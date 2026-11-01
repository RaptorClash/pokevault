import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/main.dart';

void main() {
  group('Global Desktop Shortcuts & Focus Tests', () {
    testWidgets('Escape key unfocuses active TextField without popping route', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: appNavigatorKey,
          builder: (context, child) {
            return Focus(
              canRequestFocus: false,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    final currentFocus = FocusManager.instance.primaryFocus;
                    if (currentFocus != null && currentFocus.hasFocus) {
                      final isTextFieldActive =
                          currentFocus.context?.widget is EditableText ||
                          currentFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null ||
                          currentFocus.context?.findAncestorWidgetOfExactType<TextField>() != null;

                      if (isTextFieldActive) {
                        currentFocus.unfocus();
                        return KeyEventResult.handled;
                      }
                    }
                    if (appNavigatorKey.currentState?.canPop() ?? false) {
                      appNavigatorKey.currentState?.maybePop();
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: child ?? const SizedBox(),
            );
          },
          home: Scaffold(
            body: TextField(
              focusNode: focusNode,
              autofocus: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      // Send Escape key event
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('Escape key pops route when no TextField is focused', (tester) async {
      bool popped = false;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: appNavigatorKey,
          builder: (context, child) {
            return Focus(
              canRequestFocus: false,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    final currentFocus = FocusManager.instance.primaryFocus;
                    bool isTextFieldActive = false;
                    if (currentFocus != null && currentFocus.context != null) {
                      isTextFieldActive =
                          currentFocus.context!.widget is EditableText ||
                          currentFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null ||
                          currentFocus.context!.findAncestorWidgetOfExactType<TextField>() != null;
                    }
                    if (isTextFieldActive) {
                      currentFocus?.unfocus();
                      return KeyEventResult.handled;
                    }
                    if (appNavigatorKey.currentState?.canPop() ?? false) {
                      appNavigatorKey.currentState?.maybePop();
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: child ?? const SizedBox(),
            );
          },
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PopScope(
                      canPop: true,
                      onPopInvokedWithResult: (didPop, result) {
                        if (didPop) popped = true;
                      },
                      child: const Scaffold(body: Text('Second Page')),
                    ),
                  ),
                );
              },
              child: const Text('Go to 2nd'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to 2nd'));
      await tester.pumpAndSettle();
      expect(find.text('Second Page'), findsOneWidget);

      // Send Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.text('Second Page'), findsNothing);
    });

    testWidgets('Ctrl+F / Cmd+F shortcut focuses search FocusNode', (tester) async {
      final searchFocusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
                  searchFocusNode.requestFocus();
                },
                const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
                  searchFocusNode.requestFocus();
                },
              },
              child: FocusScope(
                autofocus: true,
                child: Column(
                  children: [
                    TextField(focusNode: searchFocusNode),
                    const Text('Content area'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(searchFocusNode.hasFocus, isFalse);

      // Simulate Ctrl+F key combination
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(searchFocusNode.hasFocus, isTrue);
    });
  });
}
