import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String get apiBaseUrl {
	const configuredUrl = String.fromEnvironment('API_BASE_URL');
	if (configuredUrl.isNotEmpty) return configuredUrl;
	if (kIsWeb) return 'http://localhost:3000/api';
	if (defaultTargetPlatform == TargetPlatform.android) {
		return 'http://10.0.2.2:3000/api';
	}
	return 'http://localhost:3000/api';
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'CareerIQ',
			debugShowCheckedModeBanner: false,
			theme: ThemeData(
				colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E69)),
				useMaterial3: true,
			),
			home: const ConnectionPage(),
		);
	}
}

class ConnectionPage extends StatefulWidget {
	const ConnectionPage({super.key});

	@override
	State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
	bool _isChecking = true;
	String? _error;
	Map<String, dynamic>? _health;

	@override
	void initState() {
		super.initState();
		_checkConnection();
	}

	Future<void> _checkConnection() async {
		setState(() {
			_isChecking = true;
			_error = null;
		});

		try {
			final response = await http
					.get(Uri.parse('$apiBaseUrl/health'))
					.timeout(const Duration(seconds: 5));
			if (response.statusCode != 200) {
				throw Exception('Server returned ${response.statusCode}');
			}
			setState(() {
				_health = jsonDecode(response.body) as Map<String, dynamic>;
			});
		} catch (_) {
			setState(() {
				_health = null;
				_error = 'Could not connect to the CareerIQ backend.';
			});
		} finally {
			if (mounted) setState(() => _isChecking = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final connected = _health != null;
		return Scaffold(
			appBar: AppBar(title: const Text('CareerIQ')),
			body: Center(
				child: ConstrainedBox(
					constraints: const BoxConstraints(maxWidth: 520),
					child: Padding(
						padding: const EdgeInsets.all(24),
						child: Column(
							mainAxisAlignment: MainAxisAlignment.center,
							crossAxisAlignment: CrossAxisAlignment.stretch,
							children: [
								const Icon(Icons.school_outlined, size: 72),
								const SizedBox(height: 20),
								Text(
									'Welcome to CareerIQ',
									textAlign: TextAlign.center,
									style: Theme.of(context).textTheme.headlineMedium,
								),
								const SizedBox(height: 12),
								Text(
									connected
											? 'Your app is connected and ready.'
											: (_error ?? 'Checking backend...'),
									textAlign: TextAlign.center,
								),
								const SizedBox(height: 24),
								Card(
									child: ListTile(
										leading: Icon(
											connected ? Icons.check_circle : Icons.cloud_off,
											color: connected ? Colors.green : Colors.orange,
										),
										title: Text(
											connected ? 'Backend connected' : 'Backend unavailable',
										),
										subtitle: Text(apiBaseUrl),
									),
								),
								const SizedBox(height: 16),
								FilledButton.icon(
									onPressed: _isChecking ? null : _checkConnection,
									icon: _isChecking
											? const SizedBox.square(
													dimension: 18,
													child: CircularProgressIndicator(strokeWidth: 2),
												)
											: const Icon(Icons.refresh),
									label: Text(_isChecking ? 'Checking...' : 'Check connection'),
								),
								if (connected) ...[
									const SizedBox(height: 12),
									Text(
										'Service: ${_health!['service']}',
										textAlign: TextAlign.center,
									),
								],
							],
						),
					),
				),
			),
		);
	}
}
