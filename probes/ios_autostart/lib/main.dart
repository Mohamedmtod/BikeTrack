import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ProbeApp());
}

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});

  static const String appTitle = 'BikeTrack Probe';
  static const String buildNumber = '1.0.0+1';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: appTitle, home: ProbeHomePage());
  }
}

class ProbeHomePage extends StatefulWidget {
  const ProbeHomePage({super.key});

  @override
  State<ProbeHomePage> createState() => _ProbeHomePageState();
}

class _ProbeHomePageState extends State<ProbeHomePage> {
  static const _channel = MethodChannel('biketrack/probe');

  Map<String, dynamic> _status = const {};
  List<String> _logLines = const [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() => _run(_loadStatus);

  Future<void> _loadStatus() async {
    final status = await _channel.invokeMapMethod<String, dynamic>('status');
    final logLines = await _channel.invokeListMethod<String>('readLogTail', {
      'count': 30,
    });
    if (!mounted) {
      return;
    }
    setState(() {
      _status = status ?? const {};
      _logLines = logLines ?? const [];
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _error = 'The native probe channel is unavailable.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _start() async {
    await _run(() async {
      final response = await _channel.invokeMapMethod<String, dynamic>('start');
      if (response?['started'] != true) {
        throw PlatformException(
          code: 'start_failed',
          message: response?['reason'] as String? ?? 'Unknown failure',
        );
      }
      await _loadStatus();
    });
  }

  Future<void> _stop() async {
    await _run(() async {
      await _channel.invokeMethod<void>('stop');
      await _loadStatus();
    });
  }

  Future<void> _clearLog() async {
    await _run(() async {
      await _channel.invokeMethod<bool>('clearLog');
      await _loadStatus();
    });
  }

  Future<void> _request(String method) async {
    await _run(() async {
      await _channel.invokeMethod<Object?>(method);
      await _loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _status.isEmpty
        ? 'Loading native status…'
        : const JsonEncoder.withIndent('  ').convert(_status);

    return Scaffold(
      appBar: AppBar(
        title: const Text(ProbeApp.appTitle),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            ProbeApp.buildNumber,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : _start,
                child: const Text('Start ride'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _stop,
                child: const Text('Stop ride'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _clearLog,
                child: const Text('Clear log'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _request('shareLog'),
                child: const Text('Share log'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => _request('requestWhenInUse'),
                child: const Text('When in use'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _request('requestAlways'),
                child: const Text('Always'),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _request('requestNotifications'),
                child: const Text('Notifications'),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          Text('Native status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(statusText),
          const SizedBox(height: 20),
          Text('Log tail (30)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            _logLines.isEmpty ? 'No log entries.' : _logLines.join('\n'),
          ),
        ],
      ),
    );
  }
}
