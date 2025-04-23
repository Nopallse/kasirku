import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function()? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final String? initialValue;
  final bool autofocus;

  const CustomTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.borderRadius,
    this.contentPadding,
    this.inputFormatters,
    this.enabled = true,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.initialValue,
    this.autofocus = false, required String? Function(dynamic value) validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2.0,
          ),
        ),
        filled: true,
        fillColor: enabled 
            ? theme.colorScheme.surface
            : theme.colorScheme.surface.withOpacity(0.1),
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      cursorColor: theme.primaryColor,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      enabled: enabled,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool showClearButton;
  final FocusNode? focusNode;

  const SearchTextField({
    Key? key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.showClearButton = true,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: showClearButton && (controller?.text.isNotEmpty ?? false)
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller?.clear();
                  if (onClear != null) {
                    onClear!();
                  } else if (onChanged != null) {
                    onChanged!('');
                  }
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      autofocus: autofocus,
      focusNode: focusNode,
    );
  }
}

class MoneyTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String currency;
  final bool readOnly;
  final bool enabled;

  const MoneyTextField({
    Key? key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.currency = 'Rp',
    this.readOnly = false,
    this.enabled = true, required String? Function(dynamic value) validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      prefixIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          currency,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
      readOnly: readOnly,
      enabled: enabled, validator: (value) { 
        
       },
    );
  }
}

class QuantityTextField extends StatelessWidget {
  final TextEditingController controller;
  final int value;
  final int minValue;
  final int? maxValue;
  final Function(int) onChanged;
  final bool small;

  const QuantityTextField({
    Key? key,
    required this.controller,
    required this.value,
    this.minValue = 0,
    this.maxValue,
    required this.onChanged,
    this.small = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    controller.text = value.toString();
    
    final buttonSize = small ? 28.0 : 36.0;
    final iconSize = small ? 16.0 : 20.0;
    final containerWidth = small ? 120.0 : 140.0;
    
    return Container(
      width: containerWidth,
      height: buttonSize,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildButton(
            context,
            Icons.remove,
            buttonSize,
            iconSize,
            () {
              if (value > minValue) {
                onChanged(value - 1);
              }
            },
            value <= minValue,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (text) {
                final newValue = int.tryParse(text) ?? minValue;
                if (maxValue != null && newValue > maxValue!) {
                  onChanged(maxValue!);
                } else if (newValue < minValue) {
                  onChanged(minValue);
                } else {
                  onChanged(newValue);
                }
              },
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _buildButton(
            context,
            Icons.add,
            buttonSize,
            iconSize,
            () {
              if (maxValue == null || value < maxValue!) {
                onChanged(value + 1);
              }
            },
            maxValue != null && value >= maxValue!,
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    IconData icon,
    double size,
    double iconSize,
    VoidCallback onTap,
    bool disabled,
  ) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: disabled
              ? Theme.of(context).disabledColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: disabled
              ? Theme.of(context).disabledColor
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}