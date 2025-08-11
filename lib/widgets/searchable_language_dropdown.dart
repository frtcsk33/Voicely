import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchableLanguageDropdown extends StatefulWidget {
  final String value;
  final String hint;
  final List<Map<String, String>> languages;
  final Function(String, String) onChanged;

  const SearchableLanguageDropdown({
    Key? key,
    required this.value,
    required this.hint,
    required this.languages,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SearchableLanguageDropdown> createState() => _SearchableLanguageDropdownState();
}

class _SearchableLanguageDropdownState extends State<SearchableLanguageDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, String>> _filteredLanguages = [];
  bool _isExpanded = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _filteredLanguages = widget.languages;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredLanguages = widget.languages;
      } else {
        _filteredLanguages = widget.languages
            .where((lang) => lang['label']!
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
    _updateOverlay();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isExpanded = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isExpanded = false;
    });
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 2,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Dil ara...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  // Language list
                  Flexible(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredLanguages.length,
                      itemBuilder: (context, index) {
                        final lang = _filteredLanguages[index];
                        final isSelected = lang['value'] == widget.value;
                        
                        return InkWell(
                          onTap: () {
                            widget.onChanged(lang['value']!, lang['label']!);
                            _removeOverlay();
                            _searchController.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[50] : null,
                            ),
                            child: Row(
                              children: [
                                Flag.fromString(
                                  lang['flag']!,
                                  height: 16,
                                  width: 24,
                                  borderRadius: 2,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    lang['label']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? Colors.blue[700] : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSelectedLanguageName() {
    final selected = widget.languages.firstWhere(
      (lang) => lang['value'] == widget.value,
      orElse: () => {'label': widget.hint, 'flag': 'UN'},
    );
    return selected['label']!;
  }

  String _getSelectedLanguageFlag() {
    final selected = widget.languages.firstWhere(
      (lang) => lang['value'] == widget.value,
      orElse: () => {'label': widget.hint, 'flag': 'UN'},
    );
    return selected['flag']!;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_isExpanded) {
            _removeOverlay();
          } else {
            _showOverlay();
            // Focus on search field after a brief delay
            Future.delayed(const Duration(milliseconds: 100), () {
              _focusNode.requestFocus();
            });
          }
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isExpanded ? Colors.blue : Colors.grey[300]!,
              width: _isExpanded ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flag.fromString(
                  _getSelectedLanguageFlag(),
                  height: 16,
                  width: 24,
                  borderRadius: 2,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSelectedLanguageName(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}