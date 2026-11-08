import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'app_icon_button.dart';

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
  late final bool _ownsController;
  bool _hasText = false;

  void _handleControllerChanged() {
    final has = _controller.text.isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
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
              textInputAction: TextInputAction.search,
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
            AppIconButton(
              icon: Icons.close_rounded,
              label: 'Hapus pencarian',
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.textFaint,
              iconSize: 17,
            ),
          if (widget.onFilterTap != null)
            AppIconButton(
              icon: Icons.tune_rounded,
              label: 'Filter lokasi',
              onPressed: widget.onFilterTap,
              backgroundColor: AppTheme.ink,
              foregroundColor: Colors.white,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}
