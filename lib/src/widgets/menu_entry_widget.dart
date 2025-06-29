import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/models/context_menu_entry.dart';
import '../core/models/context_menu_item.dart';
import '../core/utils/shortcuts/menu_item_shortcuts.dart';
import 'context_menu_state.dart';

/// A widget that represents a single item in a context menu.
///
/// This widget is used internally by the `ContextMenu` contextMenu.
class MenuEntryWidget<T> extends StatefulWidget {
  final ContextMenuEntry<T> entry;
  const MenuEntryWidget({super.key, required this.entry});

  @override
  State<MenuEntryWidget<T>> createState() => _MenuEntryWidgetState<T>();
}

class _MenuEntryWidgetState<T> extends State<MenuEntryWidget<T>> {
  late final FocusNode focusNode;

  ContextMenuEntry get entry => widget.entry;

  @override
  void initState() {
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ContextMenuState.of(context);

    return MouseRegion(
      onEnter: (event) => _onMouseEnter(context, event, menuState),
      onExit: (event) => widget.entry.onMouseExit(event, menuState),
      onHover: (event) => _onMouseHover(event, menuState),
      child: Builder(
        builder: (_) {
          if (entry is ContextMenuItem) {
            final item = entry as ContextMenuItem;

            return CallbackShortcuts(
              bindings: defaultMenuItemShortcuts(context, item, menuState),
              child: Focus(
                canRequestFocus: item.enabled ? item.autoHandleFocus : false,
                focusNode: item.autoHandleFocus ? focusNode : null,
                onFocusChange: (value) {
                  if (value) {
                    _ensureFocused(item, menuState, focusNode);
                  }
                },
                child: item.builder(context, menuState, focusNode),
              ),
            );
          } else {
            return entry.builder(context, menuState);
          }
        },
      ),
    );
  }

  /// Handles the mouse enter event for the context menu entry.
  ///
  /// This method is called when the mouse pointer enters the area of the context menu entry.
  /// - If the entry is a submenu, it shows the submenu if it is not already opened.
  /// - If the entry is not a submenu, it closes the current context menu.
  void _onMouseEnter(
    BuildContext context,
    PointerEnterEvent event,
    ContextMenuState menuState,
  ) {
    if (widget.entry is ContextMenuItem) {
      final item = widget.entry as ContextMenuItem;
      final isSubmenuItem = item.isSubmenuItem;
      final isOpenedSubmenu = menuState.isOpened(item);
      final isFocused = menuState.isFocused(item);

      if (!isSubmenuItem && !isFocused) {
        menuState.closeSubmenu();
      } else if (isSubmenuItem && !isOpenedSubmenu) {
        menuState.showSubmenu(context: context, parent: item);
      }

      menuState.setFocusedEntry(item);
    }
    widget.entry.onMouseEnter(event, menuState);
  }

  void _onMouseHover(PointerHoverEvent event, ContextMenuState menuState) {
    if (menuState.isFocused(entry)) {
      _ensureFocused(entry, menuState, focusNode);
    }
    widget.entry.onMouseHover(event, menuState);
  }

  void _ensureFocused(
      ContextMenuEntry entry, ContextMenuState menuState, FocusNode focusNode) {
    menuState.focusScopeNode.requestFocus(focusNode);
    menuState.setFocusedEntry(entry);
  }
}
