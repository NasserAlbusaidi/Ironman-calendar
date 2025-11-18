import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/plan_service.dart';
import 'services/strava_service.dart';
import 'services/logistics_service.dart';
import 'widgets/taper_chart.dart';
import 'widgets/predictor_card.dart';
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(IronmanApp());
}

class IronmanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ironman Runway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.redAccent,
        cardColor: Colors.grey[900],
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  
  List<Map<String, dynamic>> fullSchedule = [];
  List<Map<String, dynamic>> upcomingSchedule = [];
  List<Map<String, dynamic>> logisticsTasks = [];
  
  Map<String, double> confidenceBank = {"Swim": 0.0, "Bike": 0.0, "Run": 0.0};
  int totalDebtMinutes = 0;
  DateTime lastResetDate = DateTime(2024, 1, 1);
  Map<String, double> averagePaces = {"Swim": 0.0, "Bike": 0.0, "Run": 0.0};
  // CONFIG: Race Date
  final DateTime raceDate = DateTime(2026, 2, 14); 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadSettings(); // Load the "Fresh Start" date

    PlanService planService = PlanService();
    StravaService stravaService = StravaService();
    LogisticsService logisticsService = LogisticsService();

    try {
      var planData = await planService.fetchPlan();
      var stravaData = await stravaService.getActivities();
      
      int weeksOut = raceDate.difference(DateTime.now()).inDays ~/ 7;
      var logistics = await logisticsService.getPendingTasks(weeksOut);

      _processTrainingData(planData, stravaData);

      setState(() {
        logisticsTasks = logistics;
        isLoading = false;
      });

    } catch (e) {
      print("CRITICAL ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int? timestamp = prefs.getInt('last_reset_timestamp');
    if (timestamp != null) {
      lastResetDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  void _processTrainingData(List plan, List actuals) {
    // 1. CONFIDENCE BANK & PREDICTOR DATA
    Map<String, double> bank = {"Swim": 0.0, "Bike": 0.0, "Run": 0.0};
    
    // Temp variables for calculating averages
    double swimTime = 0; double swimDist = 0;
    double bikeTime = 0; double bikeDist = 0;
    double runTime = 0; double runDist = 0;

    for (var act in actuals) {
      String type = act['type'];
      if (type == 'Ride') type = 'Bike';
      
      double movingTime = act['moving_time'].toDouble(); // seconds
      double distance = act['distance'].toDouble(); // meters

      if (bank.containsKey(type)) {
        // Bank Hours
        bank[type] = bank[type]! + (movingTime / 3600.0);
        
        // Accumulate for Averages
        if (type == 'Swim') { swimTime += movingTime; swimDist += distance; }
        if (type == 'Bike') { bikeTime += movingTime; bikeDist += distance; }
        if (type == 'Run')  { runTime += movingTime; runDist += distance; }
      }
    }

    // Calculate Paces (Seconds per Meter)
    // Avoid division by zero
    Map<String, double> paces = {
      "Swim": swimDist > 0 ? swimTime / swimDist : 0.0,
      "Bike": bikeDist > 0 ? bikeTime / bikeDist : 0.0,
      "Run": runDist > 0 ? runTime / runDist : 0.0,
    };

    // 2. COMPLIANCE & DEBT (Logic remains the same)
    List<Map<String, dynamic>> tempFullSchedule = [];
    int debt = 0;

    for (var plannedItem in plan) {
      DateTime pDate = plannedItem['date'];
      String type = plannedItem['type'];
      int plannedMins = plannedItem['plannedMinutes'];

      var match = actuals.cast<Map<String, dynamic>>().firstWhere(
        (act) {
          DateTime aDate = act['date'];
          return aDate.year == pDate.year && 
                 aDate.month == pDate.month && 
                 aDate.day == pDate.day &&
                 (act['type'] == type || (type == "Bike" && act['type'] == "Ride"));
        }, 
        orElse: () => {}
      );

      bool foundMatch = match.isNotEmpty;
      int actualMins = foundMatch ? (match['moving_time'] / 60).round() : 0;

      int deficit = 0;
      bool isAfterReset = pDate.isAfter(lastResetDate);

      if (DateTime.now().difference(pDate).inDays > 0 && !foundMatch && plannedMins > 0) {
        deficit = plannedMins;
        if (isAfterReset) debt += deficit;
      } else if (foundMatch && actualMins < (plannedMins * 0.8)) {
        deficit = plannedMins - actualMins;
        if (isAfterReset) debt += deficit;
      }

      tempFullSchedule.add({
        'date': pDate,
        'title': plannedItem['title'],
        'type': type,
        'planned': plannedMins,
        'actual': actualMins,
        'status': deficit > 0 ? 'Behind' : (foundMatch ? 'Complete' : 'Pending')
      });
    }

    var tempUpcoming = tempFullSchedule.where((item) => item['date'].isAfter(DateTime.now().subtract(Duration(days: 1)))).toList();

    setState(() {
      fullSchedule = tempFullSchedule;
      upcomingSchedule = tempUpcoming;
      confidenceBank = bank;
      totalDebtMinutes = debt;
      averagePaces = paces; // SAVE THE PACES
    });
  }

  void _completeLogisticsTask(int index) async {
    LogisticsService ls = LogisticsService();
    await ls.markTaskComplete(logisticsTasks[index]['id']);
    setState(() {
      logisticsTasks.removeAt(index);
    });
  }

  void _toggleWorkoutStatus(int index) {
    setState(() {
      var item = upcomingSchedule[index];
      if (item['status'] != 'Complete') {
        item['status'] = 'Complete';
        if (totalDebtMinutes > 0) {
           totalDebtMinutes = (totalDebtMinutes - (item['planned'] as int)).clamp(0, 9999);
        }
      } else {
        item['status'] = 'Pending';
      }
    });
  }

  void _resetDebt() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    await prefs.setInt('last_reset_timestamp', now.millisecondsSinceEpoch);
    
    setState(() {
      lastResetDate = now;
      totalDebtMinutes = 0; 
    });
    _loadData(); // Refresh list
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    int daysLeft = raceDate.difference(DateTime.now()).inDays;
    // ENTROPY: Blurry when far, sharp when close (Max blur 10 at 100 days out)
    double blurValue = (daysLeft / 100 * 10).clamp(0.0, 10.0);

    if (isLoading) return Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.redAccent)));

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1517649763962-0c623066013b?q=80&w=2070&auto=format&fit=crop", 
              fit: BoxFit.cover,
            ),
          ),
          // 2. ENTROPY BLUR
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
              child: Container(
                color: Colors.black.withOpacity(0.80), // 80% black overlay
              ),
            ),
          ),
          
          // 3. UI CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("RACE PROTOCOL", style: TextStyle(color: Colors.white70, letterSpacing: 2, fontSize: 12)),
                          Text("$daysLeft DAYS", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                        ],
                      ),
                      if (totalDebtMinutes > 30) _buildPanicButton()
                    ],
                  ),
                  
                  SizedBox(height: 20),

                  if (logisticsTasks.isNotEmpty)
                    _buildLogisticsCard(),

                  SizedBox(height: 15),

                  Container(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("Swim", "${confidenceBank['Swim']!.toStringAsFixed(1)}h", Icons.waves),
                        _buildStat("Bike", "${confidenceBank['Bike']!.toStringAsFixed(1)}h", Icons.directions_bike),
                        _buildStat("Run", "${confidenceBank['Run']!.toStringAsFixed(1)}h", Icons.directions_run),
                      ],
                    ),
                  ),

                   PredictorCard(paces: averagePaces), // <--- INSERT THIS HERE

                  SizedBox(height: 20),

                  if (fullSchedule.isNotEmpty)
                    Flexible(flex: 2, child: TaperChart(schedule: fullSchedule)),

                  SizedBox(height: 10),
                  Text("UPCOMING MISSIONS", style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(height: 10),

                  Expanded(
                    flex: 3,
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: 20),
                      itemCount: upcomingSchedule.length > 20 ? 20 : upcomingSchedule.length, 
                      itemBuilder: (context, index) {
                        var item = upcomingSchedule[index];
                        bool isToday = DateTime.now().day == item['date'].day && DateTime.now().month == item['date'].month;
                        
                        return Card(
                          color: isToday ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                          margin: EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            side: isToday ? BorderSide(color: Colors.redAccent) : BorderSide.none,
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: ListTile(
                            dense: true,
                            leading: _getIcon(item['type']),
                            title: Text(item['title'], 
                              style: TextStyle(color: Colors.white, fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              "${DateFormat('MMM d').format(item['date'])} • Planned: ${item['planned']}m", 
                              style: TextStyle(color: Colors.white70, fontSize: 12)
                            ),
                            trailing: InkWell(
                              onTap: () => _toggleWorkoutStatus(index),
                              child: Icon(
                                item['status'] == 'Complete' ? Icons.check_circle : Icons.circle_outlined,
                                color: item['status'] == 'Complete' ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsCard() {
    var task = logisticsTasks.first;
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A2980), Color(0xFF26D0CE)]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("RACE OPS: ${task['weeksOut']} WEEKS OUT", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(task['title'], style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: () => _completeLogisticsTask(0),
          )
        ],
      ),
    );
  }

  Widget _buildPanicButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
      onPressed: () {
        showDialog(context: context, builder: (_) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text("PROTOCOL BREACHED", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text(
            "You have accumulated ${totalDebtMinutes}m of debt.\n\n"
            "Option A: The Cram (Try to make it up)\n"
            "Option B: Fresh Start (Write it off)",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(child: Text("I'LL CRAM"), onPressed: () => Navigator.pop(context)),
            TextButton(
              child: Text("FRESH START", style: TextStyle(color: Colors.red)), 
              onPressed: _resetDebt
            ),
          ],
        ));
      },
      icon: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
      label: Text("DEBT"),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.redAccent, size: 16),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Icon _getIcon(String type) {
    if (type == 'Swim') return Icon(Icons.waves, color: Colors.blue, size: 18);
    if (type == 'Bike') return Icon(Icons.directions_bike, color: Colors.orange, size: 18);
    if (type == 'Run') return Icon(Icons.directions_run, color: Colors.green, size: 18);
    return Icon(Icons.fitness_center, color: Colors.grey, size: 18);
  }
}