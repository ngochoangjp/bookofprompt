import 'package:flutter/material.dart';
import 'package:prompt_manager/features/prompt_management/presentation/widgets/sidebar_tree_panel.dart';
import 'package:prompt_manager/features/prompt_management/presentation/widgets/main_content_panel.dart';
import 'package:prompt_manager/features/prompt_management/presentation/widgets/history_panel.dart';

class PromptManagerScreen extends StatelessWidget {
  const PromptManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout as per document
          if (constraints.maxWidth > 1200) {
            // Desktop: 3-column layout
            return const Row(
              children: [
                SizedBox(
                  width: 300,
                  child: SidebarTreePanel(),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  flex: 3,
                  child: MainContentPanel(),
                ),
                VerticalDivider(width: 1),
                SizedBox(
                  width: 350,
                  child: HistoryPanel(),
                ),
              ],
            );
          } else if (constraints.maxWidth > 800) {
            // Tablet: 2-column layout (Sidebar + Main/History)
             return const Row(
              children: [
                SizedBox(
                  width: 280,
                  child: SidebarTreePanel(),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  child: MainContentPanel(), // History could be an overlay or a tab here
                ),
              ],
            );
          } else {
            // Mobile: Tabbed layout
            return const MobileTabLayout();
          }
        },
      ),
    );
  }
}

// Mobile layout implementation
class MobileTabLayout extends StatefulWidget {
  const MobileTabLayout({super.key});

  @override
  State<MobileTabLayout> createState() => _MobileTabLayoutState();
}

class _MobileTabLayoutState extends State<MobileTabLayout> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    SidebarTreePanel(),
    MainContentPanel(),
    HistoryPanel(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy_outlined),
            label: 'Prompts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: 'Editor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
} 