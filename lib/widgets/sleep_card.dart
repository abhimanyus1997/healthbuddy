import 'package:flutter/material.dart';
import '../utils/health_service.dart';

class SleepCard extends StatefulWidget {
  final String sleepDuration; // Default/Latest
  final List<SleepDailyData> weeklySleep; // List of data objects
  final List<SleepDailyData>? monthlySleep; // Optional monthly data
  final String? rawData;
  final Function(String)? onViewModeChanged;

  const SleepCard({
    super.key,
    this.sleepDuration = "0h 0m",
    this.weeklySleep = const [],
    this.monthlySleep,
    this.rawData,
    this.onViewModeChanged,
  });

  @override
  State<SleepCard> createState() => _SleepCardState();
}

class _SleepCardState extends State<SleepCard> {
  String? _selectedDay;
  String? _displayDuration;
  String? _displayEfficiency;
  SleepDailyData? _selectedData;
  String _viewMode = "Weekly"; // Dropdown state

  @override
  void initState() {
    super.initState();
    _updateDisplay();
  }

  // Update state when widget updates
  @override
  void didUpdateWidget(SleepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sleepDuration != widget.sleepDuration ||
        oldWidget.weeklySleep != widget.weeklySleep ||
        oldWidget.monthlySleep != widget.monthlySleep) {
      _updateDisplay();
    }
  }

  void _updateDisplay() {
    setState(() {
      // Determine which dataset to use
      List<SleepDailyData> currentData = _viewMode == "Weekly"
          ? widget.weeklySleep
          : (widget.monthlySleep ?? []);

      _displayDuration = widget.sleepDuration;
      if (currentData.isNotEmpty) {
        _selectedData = currentData.last; // Assume last is today/newest
        _selectedDay = _selectedData?.dayName;
        _displayEfficiency = _selectedData?.efficiency;
      } else {
        _selectedDay = _getCurrentDay();
        _displayEfficiency = "--";
      }
    });
  }

  String _getCurrentDay() {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[DateTime.now().weekday - 1];
  }

  void _onDaySelected(SleepDailyData data) {
    setState(() {
      _selectedData = data;
      _selectedDay = data.dayName;
      int h = data.durationHours.floor();
      int m = ((data.durationHours - h) * 60).round();
      _displayDuration = "${h}h ${m}m";
      _displayEfficiency = data.efficiency;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which dataset to use
    List<SleepDailyData> currentData = _viewMode == "Weekly"
        ? widget.weeklySleep
        : (widget.monthlySleep ?? []);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark BG
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bedtime, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Sleep Analysis",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              // Dropdown for Weekly/Monthly
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _viewMode,
                    dropdownColor: const Color(0xFF2C2C2C),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _viewMode = newValue;
                        });
                        if (widget.onViewModeChanged != null) {
                          widget.onViewModeChanged!(newValue);
                        }
                        _updateDisplay(); // Refresh display with new mode
                      }
                    },
                    items: <String>['Weekly', 'Monthly']
                        .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              _buildStat(
                _displayEfficiency ?? "--",
                "",
                "Sleep Efficiency",
                const Color(0xFFD7FF64),
              ),
              const SizedBox(width: 30),
              _buildStat(
                _displayDuration ?? "0h 0m",
                "",
                "Sleep Duration",
                const Color(0xFFC7B9FF),
              ),
            ],
          ),
          // Tooltip / Phase Stats
          if (_selectedData != null)
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPhaseInfo(
                      "Deep",
                      _selectedData!.deepSleep,
                      Colors.purpleAccent,
                    ),
                    _buildPhaseInfo(
                      "Light",
                      _selectedData!.lightSleep,
                      Colors.blueAccent,
                    ),
                    _buildPhaseInfo(
                      "REM",
                      _selectedData!.remSleep,
                      Colors.tealAccent,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),
          // Bar Chart
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Scrollable for monthly view
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ...currentData.map((data) {
                    double height = data.durationHours / 10.0;
                    if (height > 1.0) height = 1.0;
                    if (height < 0.1) height = 0.1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () => _onDaySelected(data),
                        child: _buildBar(
                          data.dayName,
                          height,
                          isSelected: data.dayName == _selectedDay,
                        ),
                      ),
                    );
                  }),

                  if (currentData.isEmpty) ...[
                    // Placeholder if empty
                    _buildBar("No Data", 0.1),
                  ],
                ],
              ),
            ),
          ),
          if (widget.rawData != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                widget.rawData!,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildStat(
    String value,
    String unit,
    String label,
    Color indicatorColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildBar(
    String label,
    double heightFactor, {
    bool isSelected = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 80 * heightFactor,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD7FF64)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: isSelected && heightFactor > 0.6
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: Container(color: const Color(0xFFD7FF64))),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
