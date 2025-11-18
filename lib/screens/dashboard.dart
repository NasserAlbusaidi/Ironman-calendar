import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class Dashboard extends StatelessWidget {
  final int daysUntilRace = DateTime(2024, 6, 1).difference(DateTime.now()).inDays; // Set your race date
  final int totalDebtMinutes = 45; // Calculated from ComplianceEngine

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Ironman aesthetic
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THE HEADLINE
              Text("IRONMAN PROTOCOL", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$daysUntilRace DAYS", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  // 2. THE PANIC BUTTON (Only shows if Debt > 0)
                  if (totalDebtMinutes > 0)
                    ElevatedButton.icon(
                      onPressed: () => _showPanicOptions(context),
                      icon: Icon(Icons.warning, color: Colors.white),
                      label: Text("DEBT: ${totalDebtMinutes}m"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    )
                ],
              ),
              
              SizedBox(height: 40),
              
              // 3. THE CONFIDENCE BANK (Visualizing what you HAVE done)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.3))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CONFIDENCE BANK", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statMetric("Swim", "32km"),
                        _statMetric("Bike", "1,200km"),
                        _statMetric("Run", "150km"),
                      ],
                    )
                  ],
                ),
              ),

              SizedBox(height: 40),

              // 4. TODAY'S PROTOCOL
              Text("TODAY'S MISSION", style: TextStyle(color: Colors.white, fontSize: 20)),
              SizedBox(height: 10),
              ListTile(
                tileColor: Colors.grey[850],
                leading: Icon(Icons.directions_run, color: Colors.white),
                title: Text("Long Run - Zone 2", style: TextStyle(color: Colors.white)),
                subtitle: Text("Planned: 90 mins", style: TextStyle(color: Colors.grey)),
                trailing: CircularPercentIndicator(
                  radius: 20.0,
                  lineWidth: 5.0,
                  percent: 0.0, // Hook this to real data
                  center: Text("0%", style: TextStyle(color: Colors.white, fontSize: 10)),
                  progressColor: Colors.blue,
                  backgroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showPanicOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.grey[900],
          height: 250,
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text("Write it off (Accept Failure)", style: TextStyle(color: Colors.white)),
                onTap: () { /* Logic to clear debt but log a 'Miss' */ },
              ),
              ListTile(
                leading: Icon(Icons.compress, color: Colors.orange),
                title: Text("The Squeeze (Add to Sunday)", style: TextStyle(color: Colors.white)),
                onTap: () { /* Logic to add minutes to next long workout */ },
              ),
            ],
          ),
        );
      }
    );
  }
}