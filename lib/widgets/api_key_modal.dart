import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groq_service.dart';

/// Modal bottom sheet to manage the Groq API key directly on device.
class ApiKeyModal extends StatefulWidget {
  final VoidCallback? onKeySaved;

  const ApiKeyModal({super.key, this.onKeySaved});

  static Future<void> show(BuildContext context, {VoidCallback? onKeySaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApiKeyModal(onKeySaved: onKeySaved),
    );
  }

  @override
  State<ApiKeyModal> createState() => _ApiKeyModalState();
}

class _ApiKeyModalState extends State<ApiKeyModal> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  bool _isLoading = true;
  String? _savedKey;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await GroqService.getSavedApiKey();
    if (mounted) {
      setState(() {
        _savedKey = key;
        if (key != null) {
          _controller.text = key;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Groq API Key or use Demo Mode.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    await GroqService.saveApiKey(key);
    if (mounted) {
      widget.onKeySaved?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Groq API Key saved successfully.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _clear() async {
    await GroqService.clearApiKey();
    if (mounted) {
      setState(() {
        _savedKey = null;
        _controller.clear();
      });
      widget.onKeySaved?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const orange = Color(0xFFFF5E00);
    const emerald = Color(0xFF10B981);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C10),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border(
          top: BorderSide(color: Color(0xFF27272A), width: 1.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3F3F46),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GROQ API KEY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _savedKey != null
                      ? emerald.withValues(alpha: 0.16)
                      : orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _savedKey != null ? emerald : orange,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _savedKey != null ? 'CONNECTED' : 'NOT SET',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _savedKey != null ? emerald : orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Trim communicates directly with Groq (openai/gpt-oss-120b). Your key is stored securely only on your device.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: const Color(0xFFA1A1AA),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Input field
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: orange),
              ),
            )
          else
            TextField(
              controller: _controller,
              obscureText: _obscure,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF141419),
                hintText: 'gsk_...',
                hintStyle: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF52525B),
                  fontSize: 13.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF71717A),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF27272A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: orange, width: 1.5),
                ),
              ),
            ),
          const SizedBox(height: 18),

          // Action buttons
          Row(
            children: [
              if (_savedKey != null) ...[
                OutlinedButton(
                  onPressed: _clear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFF3F3F46)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                  ),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.jetBrainsMono(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Key',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
