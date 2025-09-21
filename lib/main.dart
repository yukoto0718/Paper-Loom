import 'package:flutter/material.dart';
import 'screens/pdf_reader_screen.dart';
import 'services/pdf_service.dart';
import 'models/pdf_document.dart';

void main() {
  runApp(const PaperLoomApp());
}

class PaperLoomApp extends StatelessWidget {
  const PaperLoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paper Loom - PDF阅读器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 使用现代化的Material 3设计
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/pdf-reader':
            final document = settings.arguments as PDFDocument;
            return MaterialPageRoute(
              builder: (context) => PDFReaderScreen(document: document),
            );
          default:
            return null;
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PDFDocument> _recentFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  /// 加载最近文件
  Future<void> _loadRecentFiles() async {
    try {
      final recentFiles = await PDFService.getRecentFiles();
      if (mounted) {
        setState(() {
          _recentFiles = recentFiles;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('加载最近文件失败: $e');
      }
    }
  }

  /// 选择并打开PDF文件
  Future<void> _pickAndOpenPDFFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filePath = await PDFService.pickPDFFile();
      
      if (filePath != null) {
        final document = await PDFService.createPDFDocument(filePath);
        
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/pdf-reader',
            arguments: document,
          ).then((_) {
            _loadRecentFiles();
          });
        }
      }
    } on PDFServiceException catch (e) {
      if (mounted) {
        _showSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('打开文件失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 打开最近文件
  Future<void> _openRecentFile(PDFDocument document) async {
    try {
      // 检查文件是否仍然存在
      if (!await PDFService.isValidPDFFile(document.filePath)) {
        _showSnackBar('文件不存在或已损坏');
        await PDFService.removeFromRecentFiles(document.filePath);
        _loadRecentFiles();
        return;
      }

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/pdf-reader',
          arguments: document,
        ).then((_) {
          _loadRecentFiles();
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('打开文件失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories, size: 28),
            SizedBox(width: 8),
            Text(
              'Paper Loom',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: 实现设置菜单
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 欢迎图标
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),
              
              // 欢迎文本
              Text(
                '欢迎使用 Paper Loom',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '您的专业PDF阅读器',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // 操作按钮
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _pickAndOpenPDFFile,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.folder_open),
                      label: Text(_isLoading ? '正在加载...' : '打开PDF文件'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _recentFiles.isNotEmpty ? _showRecentFiles : null,
                      icon: const Icon(Icons.history),
                      label: Text('最近阅读 (${_recentFiles.length})'),
                    ),
                  ),
                ],
              ),
              
              // 最近文件列表
              if (_recentFiles.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildRecentFilesList(),
              ],
              
              const SizedBox(height: 32),
              
              // 功能介绍卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主要功能',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _FeatureItem(
                        icon: Icons.zoom_in,
                        title: '缩放查看',
                        description: '支持手势缩放和精确查看',
                      ),
                      const _FeatureItem(
                        icon: Icons.bookmark,
                        title: '书签管理',
                        description: '添加和管理阅读书签',
                      ),
                      const _FeatureItem(
                        icon: Icons.dark_mode,
                        title: '夜间模式',
                        description: '保护眼睛的暗色主题',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 构建最近文件列表
  Widget _buildRecentFilesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Text(
                  '最近阅读',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showRecentFiles,
                  child: const Text('查看全部'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_recentFiles.take(3).map((document) => _buildRecentFileItem(document))),
          ],
        ),
      ),
    );
  }

  /// 构建最近文件条目
  Widget _buildRecentFileItem(PDFDocument document) {
    return InkWell(
      onTap: () => _openRecentFile(document),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '第${document.currentPage}页',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
            Text(
                        document.progressPercentage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (document.isFavorite)
              Icon(
                Icons.favorite,
                color: Colors.red[300],
                size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 显示最近文件对话框
  void _showRecentFiles() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '最近阅读',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _recentFiles.isEmpty
                    ? Center(
                        child: Text(
                          '暂无最近阅读的文件',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _recentFiles.length,
                        itemBuilder: (context, index) {
                          final document = _recentFiles[index];
                          return _buildRecentFileItem(document);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}