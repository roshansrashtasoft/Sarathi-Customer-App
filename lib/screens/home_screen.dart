import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  final List<Map<String, dynamic>> designs = [
    {
      'title': 'Modern Minimalist',
      'description': 'Clean lines and minimal decoration',
      'icon': Icons.home_outlined,
    },
    {
      'title': 'Smart Home Solutions',
      'description': 'Automated and connected living spaces',
      'icon': Icons.smart_toy_outlined,
    },
    {
      'title': 'Eco-Friendly Designs',
      'description': 'Sustainable and energy-efficient homes',
      'icon': Icons.eco_outlined,
    },
    {
      'title': 'Luxury Interiors',
      'description': 'Premium finishes and elegant spaces',
      'icon': Icons.diamond_outlined,
    },
    {
      'title': 'Luxury Interiors',
      'description': 'Premium finishes and elegant spaces',
      'icon': Icons.diamond_outlined,
    },
    {
      'title': 'Luxury Interiors',
      'description': 'Premium finishes and elegant spaces',
      'icon': Icons.diamond_outlined,
    },
    {
      'title': 'Luxury Interiors',
      'description': 'Premium finishes and elegant spaces',
      'icon': Icons.diamond_outlined,
    },
    {
      'title': 'Luxury Interiors',
      'description': 'Premium finishes and elegant spaces',
      'icon': Icons.diamond_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 0 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 0 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Sarathi Innovations',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: _isScrolled ? 4 : 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(children: [_buildHeader(), _buildDesignsList()]),
      ),
    );
  }

  Widget _buildDesignsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: designs.length,
      itemBuilder: (context, index) {
        return _buildDesignCard(designs[index]);
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Best Furniture and Decor',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We pride ourselves on being builders - creating architectural and creative solutions to help people realize their vision',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignCard(Map<String, dynamic> design) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(design['icon'], size: 32, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      design['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      design['description'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
