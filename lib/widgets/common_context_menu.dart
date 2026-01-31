import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// アプリ全体で使用する共通のコンテキストメニュービルダー
/// 
/// iOS では「Scan Text」を除外したカスタムメニューを表示し、
/// Android では標準のコンテキストメニューをそのまま使用します。
Widget buildFamicaContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  // Android や Web などの場合は標準のメニューを使用
  if (!Platform.isIOS) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }

  // iOS の場合はカスタムメニューを構築（Scan Text を除外）
  final List<ContextMenuButtonItem> buttonItems = [];

  // Cut（切り取り）- テキストが選択されている場合のみ
  if (editableTextState.cutEnabled) {
    buttonItems.add(
      ContextMenuButtonItem(
        type: ContextMenuButtonType.cut,
        onPressed: () {
          editableTextState.cutSelection(SelectionChangedCause.toolbar);
        },
      ),
    );
  }

  // Copy（コピー）- テキストが選択されている場合のみ
  if (editableTextState.copyEnabled) {
    buttonItems.add(
      ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        onPressed: () {
          editableTextState.copySelection(SelectionChangedCause.toolbar);
        },
      ),
    );
  }

  // Paste（ペースト）- クリップボードにテキストがある場合のみ
  if (editableTextState.pasteEnabled) {
    buttonItems.add(
      ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {
          editableTextState.pasteText(SelectionChangedCause.toolbar);
        },
      ),
    );
  }

  // Select All（すべて選択）- テキストがある場合のみ
  if (editableTextState.selectAllEnabled) {
    buttonItems.add(
      ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {
          editableTextState.selectAll(SelectionChangedCause.toolbar);
        },
      ),
    );
  }

  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}
