import 'package:flutter/material.dart';

class StatusToggle extends StatelessWidget {
  final bool isOnline;
  final Function(bool) onToggle;
  
  const StatusToggle({
    super.key, 
    required this.isOnline, 
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOnline ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: isOnline,
            onChanged: onToggle,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}