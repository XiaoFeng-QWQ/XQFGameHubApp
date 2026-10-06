import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/palette.dart';
import 'app_icon.dart';

/// 手绘输入框。对应 Web 端 `.input-line input` / `.acc-inline input`：
/// `background: var(--bg-input); border: 2px solid var(--ink-black);
/// border-radius: 8px 3px 8px 3px;`，聚焦时描边转蓝。
class DoodleField extends StatefulWidget {
  const DoodleField({
    super.key,
    required this.controller,
    this.hint,
    this.label,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.onSubmitted,
    this.suffix,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints,
    this.fontSize = 15,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hint;
  final String? label;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final double fontSize;
  final int maxLines;

  @override
  State<DoodleField> createState() => _DoodleFieldState();
}

class _DoodleFieldState extends State<DoodleField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    final Widget field = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
      decoration: BoxDecoration(
        color: p.bgInput,
        border: Border.all(color: _focused ? p.inkBlue : p.inkBlack, width: 2),
        borderRadius: XqfRadii.input,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              maxLength: widget.maxLength,
              maxLines: widget.obscure ? 1 : widget.maxLines,
              onSubmitted: widget.onSubmitted,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              cursorColor: p.inkBlack,
              cursorWidth: 2,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: widget.fontSize,
                color: p.inkBlack,
              ),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: widget.fontSize,
                  color: p.textAa,
                ),
              ),
            ),
          ),
          if (widget.suffix != null) widget.suffix!,
        ],
      ),
    );

    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label!,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: p.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        field,
      ],
    );
  }
}

/// 手绘复选框（对应 `.acc-msg-allow`）。
class DoodleCheckbox extends StatelessWidget {
  const DoodleCheckbox({
    super.key,
    required this.value,
    required this.label,
    this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final XqfPalette p = XqfPalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? p.inkBlue : p.surfaceWhite,
              border: Border.all(color: p.inkBlack, width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.elliptical(6, 2),
                topRight: Radius.elliptical(2, 6),
                bottomRight: Radius.elliptical(6, 2),
                bottomLeft: Radius.elliptical(2, 6),
              ),
            ),
            child: value
                ? Center(
                    child: AppIcon('check', size: 13, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: p.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}
