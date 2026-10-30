import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Search bar putih ber-border dengan tombol filter gelap di kanan.
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
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(18, 7, 8, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E1946),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppTheme.muted, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: const TextStyle(fontSize: 14, color: AppTheme.ink),
              decoration: InputDecoration(
                filled: false,
                isDense: true,
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: AppTheme.textFaint,
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_hasText)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded,
                  size: 17, color: AppTheme.textFaint),
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
            ),
          if (widget.onFilterTap != null)
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
