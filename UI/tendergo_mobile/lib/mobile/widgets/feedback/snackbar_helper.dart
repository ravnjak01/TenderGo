import 'package:flutter/material.dart';

class SnackbarHelper {
	SnackbarHelper._();

	static void show(
		BuildContext context,
		String message, {
		bool isError = false,
	}) {
		final isSmallScreen = MediaQuery.sizeOf(context).width < 600;

		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(
				content: Row(
					children: [
						Icon(
							isError ? Icons.error_outline : Icons.check_circle_outline,
							color: Colors.white,
						),
						const SizedBox(width: 12),
						Expanded(
							child: Text(
								message,
								style: const TextStyle(fontWeight: FontWeight.w500),
							),
						),
					],
				),
				backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
				behavior: SnackBarBehavior.floating,
				margin: isSmallScreen
						? const EdgeInsets.all(12)
						: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(12),
				),
				duration: const Duration(seconds: 3),
				elevation: 6,
				dismissDirection: DismissDirection.horizontal,
			),
		);
	}
}