import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:ftpconnect/ftpconnect.dart';

class Lab8FTPClient extends StatefulWidget {
  const Lab8FTPClient({super.key});

  @override
  State<Lab8FTPClient> createState() => _Lab8FTPClientState();
}

class _Lab8FTPClientState extends State<Lab8FTPClient> {
  final FTPConnect _ftpConnect = FTPConnect(
    "students.yss.su",
    user: "ftpiu8",
    pass: "3Ru7yOTA",
    debug: true,
    timeout: 120,
    port: 21,
  );

  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;
  bool _isLoading = false;
  List<FTPEntry> _directoryContent = [];

  @override
  void initState() {
    super.initState();
    _log('FTP Client initialized');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disconnectIfNeeded();
    super.dispose();
  }

  Future<void> _disconnectIfNeeded() async {
    if (_isConnected) {
      try {
        await _ftpConnect.disconnect();
      } catch (_) {}
    }
  }

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal().toString().substring(11, 19)} - $message');
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<File> _createMockFile({String fileName = 'test.txt', String content = 'Test file content'}) async {
    try {
      final Directory tempDir = Directory.systemTemp;
      final Directory testDir = Directory('${tempDir.path}/ftp_test')..createSync(recursive: true);
      final File file = File('${testDir.path}/$fileName');
      await file.writeAsString(content);
      return file;
    } catch (e) {
      _log('Error creating mock file: $e');
      rethrow;
    }
  }

  Future<void> _connectToFTP() async {
    if (_isConnected) {
      _showAlert('Already connected to FTP server');
      return;
    }

    setState(() => _isLoading = true);
    try {
      _log('Connecting to FTP server...');
      await _ftpConnect.connect();
      setState(() => _isConnected = true);
      _log('Connected successfully!');
      await _listDirectory();
    } catch (e) {
      _log('Connection failed: $e');
      _showAlert('Connection failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectFromFTP() async {
    if (!_isConnected) {
      _showAlert('Not connected to FTP server');
      return;
    }

    setState(() => _isLoading = true);
    try {
      _log('Disconnecting from FTP server...');
      await _ftpConnect.disconnect();
      setState(() {
        _isConnected = false;
        _directoryContent.clear();
      });
      _log('Disconnected successfully!');
    } catch (e) {
      _log('Disconnect failed: $e');
      _showAlert('Disconnect failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _listDirectory() async {
    if (!_isConnected) {
      _showAlert('Please connect to FTP server first');
      return;
    }

    setState(() => _isLoading = true);
    try {
      _log('Listing directory contents...');
      List<FTPEntry> entries = await _ftpConnect.listDirectoryContent();
      setState(() {
        _directoryContent = entries;
      });
      _log('Found ${entries.length} items in directory');
    } catch (e) {
      _log('Directory listing failed: $e');
      _showAlert('Directory listing failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    if (!_isConnected) {
      _showAlert('Please connect to FTP server first');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final String fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.txt';
      final String content = 'Uploaded at ${DateTime.now()}\nTest content from Flutter FTP client';

      _log('Creating test file: $fileName');
      File fileToUpload = await _createMockFile(fileName: fileName, content: content);

      _log('Uploading file...');
      bool result = await _ftpConnect.uploadFileWithRetry(fileToUpload, pRetryCount: 2);

      if (result) {
        _log('File uploaded successfully: $fileName');
        _showAlert('File uploaded successfully!');
        await _listDirectory();
      } else {
        _log('File upload failed');
        _showAlert('File upload failed');
      }
    } catch (e) {
      _log('Upload error: $e');
      _showAlert('Upload error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFile(String fileName) async {
    if (!_isConnected) {
      _showAlert('Please connect to FTP server first');
      return;
    }

    setState(() => _isLoading = true);
    try {
      _log('Downloading file: $fileName');

      final Directory tempDir = Directory.systemTemp;
      final Directory downloadDir = Directory('${tempDir.path}/ftp_downloads')..createSync(recursive: true);
      File downloadedFile = File('${downloadDir.path}/$fileName');

      bool result = await _ftpConnect.downloadFileWithRetry(fileName, downloadedFile, pRetryCount: 2);

      if (result) {
        _log('File downloaded successfully: ${downloadedFile.path}');

        // Read file content
        String content = await downloadedFile.readAsString();
        _log('File content preview: ${content.substring(0, content.length > 50 ? 50 : content.length)}...');

        // Show file content in dialog
        _showFileContentDialog(fileName, content, downloadedFile.path);
      } else {
        _log('File download failed');
        _showAlert('File download failed');
      }
    } catch (e) {
      _log('Download error: $e');
      _showAlert('Download error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('FTP Client'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showFileContentDialog(String fileName, String content, String filePath) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Downloaded: $fileName'),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Path: $filePath',
                  style: const TextStyle(fontSize: 9, color: CupertinoColors.systemGrey),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Content:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Courier'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Copy to Clipboard'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (!context.mounted) return;
              Navigator.of(context).pop();
              _log('Content copied to clipboard');
              _showAlert('File content copied to clipboard!');
            },
          ),
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Lab 8 - FTP Client'),
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Connection status bar
            Container(
              padding: const EdgeInsets.all(12),
              color: _isConnected
                  ? CupertinoColors.systemGreen.withOpacity(0.2)
                  : CupertinoColors.systemRed.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isConnected ? CupertinoIcons.check_mark_circled : CupertinoIcons.xmark_circle,
                        color: _isConnected ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isConnected ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'students.yss.su',
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ),

            // Control buttons
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: _isLoading ? null : _connectToFTP,
                    child: const Text('Connect', style: TextStyle(fontSize: 14)),
                  ),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: _isLoading ? null : _disconnectFromFTP,
                    child: const Text('Disconnect', style: TextStyle(fontSize: 14)),
                  ),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: (_isLoading || !_isConnected) ? null : _listDirectory,
                    child: const Text('List Files', style: TextStyle(fontSize: 14)),
                  ),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onPressed: (_isLoading || !_isConnected) ? null : _uploadFile,
                    child: const Text('Upload Test File', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),

            // Directory listing
            if (_directoryContent.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Directory Contents:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CupertinoScrollbar(
                  child: ListView.builder(
                    itemCount: _directoryContent.length,
                    itemBuilder: (context, index) {
                      final entry = _directoryContent[index];
                      final isDirectory = entry.type == FTPEntryType.DIR;

                      final fileName = entry.name ?? 'unknown';
                      return CupertinoListTile(
                        leading: Icon(
                          isDirectory ? CupertinoIcons.folder : CupertinoIcons.doc,
                          color: isDirectory ? CupertinoColors.systemYellow : CupertinoColors.systemBlue,
                        ),
                        title: Text(fileName),
                        subtitle: Text(
                          '${isDirectory ? 'Directory' : 'File'} - ${entry.size ?? 0} bytes',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: !isDirectory
                            ? CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(CupertinoIcons.cloud_download),
                                onPressed: () => _downloadFile(fileName),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],

            // Logs section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Activity Log:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _clearLogs,
                          child: const Text('Clear', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        border: Border.all(color: CupertinoColors.systemGrey4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CupertinoScrollbar(
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                  color: CupertinoColors.black,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
