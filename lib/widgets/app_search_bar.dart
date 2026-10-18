import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final String hint;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
    this.hint = 'Cari event, kategori, atau lokasi...',
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      final has = _controller.text.isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.field,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
        decoration: InputDecoration(
          filled: false,
          hintText: widget.hint,
          hintStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 13.5),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppTheme.textGrey, size: 21),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasText)
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 17, color: AppTheme.textGrey),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                ),
              if (widget.onFilterTap != null)
                IconButton(
                  icon: const Icon(Icons.tune_rounded,
                      size: 19, color: AppTheme.textMuted),
                  onPressed: widget.onFilterTap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        ),
      ),
    );
  }
}
