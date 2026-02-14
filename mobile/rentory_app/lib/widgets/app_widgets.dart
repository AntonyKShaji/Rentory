import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class RemoteOrDataImage extends StatelessWidget {
  const RemoteOrDataImage({
    super.key,
    required this.imageRef,
    this.height = 160,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  final String? imageRef;
  final double height;
  final double width;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageBytes = _parseDataUri(imageRef);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFE4ECEC),
        child: imageBytes != null
            ? Image.memory(imageBytes, fit: fit)
            : imageRef?.isNotEmpty == true
                ? Image.network(
                    imageRef!,
                    fit: fit,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
                  )
                : const Center(child: Icon(Icons.image_outlined, size: 34)),
      ),
    );
  }

  Uint8List? _parseDataUri(String? value) {
    if (value == null || !value.startsWith('data:image')) return null;
    final comma = value.indexOf(',');
    if (comma == -1) return null;
    final payload = value.substring(comma + 1);
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.isMine,
    required this.sender,
    required this.text,
    this.imageUrl,
  });

  final bool isMine;
  final String sender;
  final String? text;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? const Color(0xFFDCF8C6) : Colors.white;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(sender, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A))),
              ),
            if (imageUrl?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: RemoteOrDataImage(imageRef: imageUrl, height: 140, width: 200, borderRadius: BorderRadius.circular(12)),
              ),
            if (text?.isNotEmpty == true) Text(text!, style: const TextStyle(height: 1.28)),
          ],
        ),
      ),
    );
  }
}

class FieldWithTopError extends StatelessWidget {
  const FieldWithTopError({
    super.key,
    required this.child,
    this.errorText,
  });

  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        child,
      ],
    );
  }
}
