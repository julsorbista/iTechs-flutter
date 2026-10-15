import 'package:flutter/material.dart';

import 'glob/audio.dart';
import 'glob/class_data.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  Widget tableRow(String rank, String name, String stars, bool header) {
    return Container(
      margin: EdgeInsets.only(top: header ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: header ? const Color(0xFF383E43) : const Color(0xFF724964),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: header ? const Color(0xFFF5D64D) : const Color(0xFFF5E9CC),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(rank)),
            Expanded(
              flex: 5,
              child: Center(
                child: SizedBox(
                  width: 105,
                  child: Text(name, textAlign: TextAlign.center),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: header
                  ? Text(stars, textAlign: TextAlign.center)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFF5D64D),
                          size: 19,
                        ),
                        const SizedBox(width: 4),
                        Flexible(child: Text(stars)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> rankings = [];
    List<Map<String, dynamic>> records = ClassData.leaderboardRecords();
    for (int i = 0; i < records.length; i++) {
      rankings.add(records[i]);
    }
    for (int i = 0; i < rankings.length; i++) {
      for (int j = i + 1; j < rankings.length; j++) {
        int firstStars = rankings[i]['totalStars'];
        int nextStars = rankings[j]['totalStars'];
        int firstCompleted = rankings[i]['completedActivities'];
        int nextCompleted = rankings[j]['completedActivities'];
        String firstName = rankings[i]['studentName'];
        String nextName = rankings[j]['studentName'];
        if (nextStars > firstStars ||
            (nextStars == firstStars && nextCompleted > firstCompleted) ||
            (nextStars == firstStars &&
                nextCompleted == firstCompleted &&
                nextName.toLowerCase().compareTo(firstName.toLowerCase()) <
                    0)) {
          Map<String, dynamic> temporary = rankings[i];
          rankings[i] = rankings[j];
          rankings[j] = temporary;
        }
      }
    }
    List<Widget> rows = [];
    for (int i = 0; i < rankings.length; i++) {
      rows.add(
        KeyedSubtree(
          key: ValueKey('rank-${i + 1}'),
          child: tableRow(
            '#${i + 1}',
            rankings[i]['studentName'],
            '${rankings[i]['totalStars']}',
            false,
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/menu-background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xBA4F3347), BlendMode.srcOver),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 20),
            child: Center(
              child: SizedBox(
                width: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4A3040),
                            offset: Offset(5, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          AppAudio.click();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(color: Colors.white, width: 4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back, size: 16),
                            SizedBox(width: 10),
                            Text(
                              'BACK TO MENU',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xF0E7CF99),
                        border: Border.all(
                          color: const Color(0xFF6B4D72),
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF4A3040),
                            offset: Offset(6, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Class Standing',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2A1C23),
                            ),
                          ),
                          const Text(
                            'Leaderboards',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2A1C23),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2E6C2),
                                border: Border.all(
                                  color: const Color(0xFF6B4D72),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '${rankings.length} students ranked',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2A1C23),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          tableRow(
                            'Star\nRank',
                            'Student Name',
                            'Total\nStars',
                            true,
                          ),
                          Column(children: rows),
                          if (rankings.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No leaderboard data available yet.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
