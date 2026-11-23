import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// SHARED DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const _navy = Color(0xFF142B45);
const _yellow = Color(0xFFFFC928);
const _surface = Color(0xFFF5F7FA);
const _border = Color(0xFFE5E9EF);
const _slate = Color(0xFF8490A0);

/// Which unit of time is actively being edited on the picker.
enum TimePickerField { hour, minute }

// ─────────────────────────────────────────────────────────────
// PUBLIC DIALOG WIDGET
// ─────────────────────────────────────────────────────────────

/// A centred, production-quality dialog for picking a schedule time.
/// Supports Digital input and an animated Analog clock dial.
class ScheduleTimePickerDialog extends StatefulWidget {
  const ScheduleTimePickerDialog({
    super.key,
    required this.initialTime,
    this.initialIsDigital = false,
  });

  final TimeOfDay initialTime;
  final bool initialIsDigital;

  /// Convenience method: opens the centred dialog with a dark backdrop.
  static Future<TimeOfDay?> show({
    required BuildContext context,
    TimeOfDay? initialTime,
    bool initialIsDigital = false,
  }) {
    return showDialog<TimeOfDay>(
      context: context,
      barrierColor: const Color(0x99091522),
      barrierDismissible: true,
      builder: (_) => ScheduleTimePickerDialog(
        initialTime: initialTime ?? const TimeOfDay(hour: 6, minute: 58),
        initialIsDigital: initialIsDigital,
      ),
    );
  }

  @override
  State<ScheduleTimePickerDialog> createState() => _ScheduleTimePickerDialogState();
}

class _ScheduleTimePickerDialogState extends State<ScheduleTimePickerDialog> {
  late int _hour12;
  late int _minute;
  late DayPeriod _period;
  late bool _isDigitalMode;
  TimePickerField _activeField = TimePickerField.hour;

  @override
  void initState() {
    super.initState();
    _isDigitalMode = widget.initialIsDigital;
    _period = widget.initialTime.period;
    final h = widget.initialTime.hourOfPeriod;
    _hour12 = h == 0 ? 12 : h;
    _minute = widget.initialTime.minute;
  }

  void _onHourChanged(int hour) => setState(() => _hour12 = hour);
  void _onMinuteChanged(int minute) => setState(() => _minute = minute);
  void _onPeriodChanged(DayPeriod period) => setState(() => _period = period);
  void _onFieldChanged(TimePickerField field) => setState(() => _activeField = field);
  void _toggleInputMode() => setState(() => _isDigitalMode = !_isDigitalMode);

  void _confirm() {
    final hour24 = _period == DayPeriod.am
        ? (_hour12 == 12 ? 0 : _hour12)
        : (_hour12 == 12 ? 12 : _hour12 + 12);
    Navigator.of(context).pop(TimeOfDay(hour: hour24, minute: _minute));
  }

  void _cancel() => Navigator.of(context).pop(null);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 24.0,
      shadowColor: const Color(0x33091522),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. HEADER ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Schedule pickup',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20.0,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 3.0),
                        Text(
                          'Choose your preferred pickup time',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                            color: _slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Semantics(
                    button: true,
                    label: 'Close modal',
                    child: Material(
                      color: _surface,
                      shape: const CircleBorder(side: BorderSide(color: _border)),
                      child: InkWell(
                        onTap: _cancel,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 32.0,
                          height: 32.0,
                          child: Icon(Icons.close, size: 18.0, color: _navy),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // ── 2. PICKER BODY ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isDigitalMode
                    ? _DigitalPickerBody(
                        key: const ValueKey('digital'),
                        hour12: _hour12,
                        minute: _minute,
                        period: _period,
                        activeField: _activeField,
                        onHourChanged: _onHourChanged,
                        onMinuteChanged: _onMinuteChanged,
                        onPeriodChanged: _onPeriodChanged,
                        onFieldChanged: _onFieldChanged,
                      )
                    : _AnalogPickerBody(
                        key: const ValueKey('analog'),
                        hour12: _hour12,
                        minute: _minute,
                        period: _period,
                        activeField: _activeField,
                        onHourChanged: _onHourChanged,
                        onMinuteChanged: _onMinuteChanged,
                        onPeriodChanged: _onPeriodChanged,
                        onFieldChanged: _onFieldChanged,
                      ),
              ),

              const SizedBox(height: 10.0),

              // ── 3. MODE SWITCH ──
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleInputMode,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isDigitalMode ? Icons.schedule : Icons.keyboard_outlined,
                            size: 18.0,
                            color: _navy,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            _isDigitalMode ? 'Switch to analog clock' : 'Switch to digital input',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: _slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14.0),

              // ── 4. FOOTER BUTTONS ──
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50.0,
                      child: OutlinedButton(
                        onPressed: _cancel,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _surface,
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 50.0,
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _yellow,
                          foregroundColor: _navy,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Confirm time',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15.0,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIGITAL PICKER BODY
// No quick-adjust pills. Layout uses Flexible so it never overflows.
// ─────────────────────────────────────────────────────────────

class _DigitalPickerBody extends StatelessWidget {
  const _DigitalPickerBody({
    super.key,
    required this.hour12,
    required this.minute,
    required this.period,
    required this.activeField,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
    required this.onFieldChanged,
  });

  final int hour12;
  final int minute;
  final DayPeriod period;
  final TimePickerField activeField;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<DayPeriod> onPeriodChanged;
  final ValueChanged<TimePickerField> onFieldChanged;

  void _stepHour(int delta) {
    var h = hour12 + delta;
    if (h > 12) h = 1;
    if (h < 1) h = 12;
    onHourChanged(h);
  }

  void _stepMinute(int delta) {
    var m = (minute + delta) % 60;
    if (m < 0) m += 60;
    onMinuteChanged(m);
  }

  @override
  Widget build(BuildContext context) {
    final isHourActive = activeField == TimePickerField.hour;
    final isMinuteActive = activeField == TimePickerField.minute;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Hour Box ──
          _NumericBox(
            value: hour12.toString().padLeft(2, '0'),
            label: 'HOUR',
            isActive: isHourActive,
            onTap: () => onFieldChanged(TimePickerField.hour),
            onVerticalDrag: (d) {
              if (d < -5) _stepHour(1);
              if (d > 5) _stepHour(-1);
            },
          ),

          // ── Colon ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              ':',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 32.0,
                fontWeight: FontWeight.w800,
                color: _navy,
                height: 1.0,
              ),
            ),
          ),

          // ── Minute Box ──
          _NumericBox(
            value: minute.toString().padLeft(2, '0'),
            label: 'MINUTE',
            isActive: isMinuteActive,
            onTap: () => onFieldChanged(TimePickerField.minute),
            onVerticalDrag: (d) {
              if (d < -5) _stepMinute(1);
              if (d > 5) _stepMinute(-1);
            },
          ),

          const SizedBox(width: 8.0),

          // ── AM / PM vertical segmented control ──
          // Fixed width of 56 — small enough to never overflow even on 320px,
          // yet large enough to be tappable. The two numeric boxes are also
          // constrained so the total fits within the dialog's 320px minimum.
          SizedBox(
            width: 54.0,
            height: 84.0,
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(color: Color(0x08142B45), blurRadius: 4.0, offset: Offset(0, 1)),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _AmPmSegment(
                      label: 'AM',
                      isSelected: period == DayPeriod.am,
                      onTap: () => onPeriodChanged(DayPeriod.am),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Expanded(
                    child: _AmPmSegment(
                      label: 'PM',
                      isSelected: period == DayPeriod.pm,
                      onTap: () => onPeriodChanged(DayPeriod.pm),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NUMERIC BOX — fixed 80x84 so total row ≤ 80+6+80+8+54+20 = 248px
// (always fits inside 320-40=280px available content width)
// ─────────────────────────────────────────────────────────────

class _NumericBox extends StatelessWidget {
  const _NumericBox({
    required this.value,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.onVerticalDrag,
  });

  final String value;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ValueChanged<double> onVerticalDrag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) => onVerticalDrag(d.primaryDelta ?? 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 80.0,
            height: 84.0,
            decoration: BoxDecoration(
              color: isActive ? _navy : Colors.white,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: isActive ? const Color(0x66FFC928) : _border,
                width: isActive ? 2.0 : 1.0,
              ),
              boxShadow: isActive
                  ? const [
                      BoxShadow(color: Color(0x26142B45), blurRadius: 8.0, offset: Offset(0, 3)),
                    ]
                  : const [
                      BoxShadow(color: Color(0x06142B45), blurRadius: 3.0, offset: Offset(0, 1)),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 32.0,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : _navy,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _yellow : _slate,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmPmSegment extends StatelessWidget {
  const _AmPmSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              color: isSelected ? _navy : _slate,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANALOG PICKER BODY
// ─────────────────────────────────────────────────────────────

class _AnalogPickerBody extends StatelessWidget {
  const _AnalogPickerBody({
    super.key,
    required this.hour12,
    required this.minute,
    required this.period,
    required this.activeField,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
    required this.onFieldChanged,
  });

  final int hour12;
  final int minute;
  final DayPeriod period;
  final TimePickerField activeField;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<DayPeriod> onPeriodChanged;
  final ValueChanged<TimePickerField> onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final isHourMode = activeField == TimePickerField.hour;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Time summary + AM/PM row ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hour : Minute with active underline
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'TIME',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.0,
                      fontWeight: FontWeight.w700,
                      color: _slate,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  _TimeLabel(
                    value: hour12.toString().padLeft(2, '0'),
                    isActive: isHourMode,
                    onTap: () => onFieldChanged(TimePickerField.hour),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.0),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 22.0,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ),
                  _TimeLabel(
                    value: minute.toString().padLeft(2, '0'),
                    isActive: !isHourMode,
                    onTap: () => onFieldChanged(TimePickerField.minute),
                  ),
                ],
              ),
              // AM / PM pill row
              Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniAmPmButton(
                      label: 'AM',
                      isSelected: period == DayPeriod.am,
                      onTap: () => onPeriodChanged(DayPeriod.am),
                    ),
                    _MiniAmPmButton(
                      label: 'PM',
                      isSelected: period == DayPeriod.pm,
                      onTap: () => onPeriodChanged(DayPeriod.pm),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12.0),

        // ── Animated Clock Dial (responsive size via LayoutBuilder) ──
        LayoutBuilder(
          builder: (context, constraints) {
            // Dial fills available width, capped at 260px
            final dialSize = math.min(constraints.maxWidth, 260.0);
            return _AnalogClockDial(
              dialSize: dialSize,
              hour12: hour12,
              minute: minute,
              isHourMode: isHourMode,
              onHourSelected: (h) {
                onHourChanged(h);
                Future.delayed(const Duration(milliseconds: 340), () {
                  onFieldChanged(TimePickerField.minute);
                });
              },
              onMinuteSelected: onMinuteChanged,
            );
          },
        ),
      ],
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  final String value;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 150),
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 24.0,
          fontWeight: FontWeight.w800,
          color: isActive ? _navy : _slate,
          decoration: isActive ? TextDecoration.underline : TextDecoration.none,
          decorationColor: _yellow,
          decorationThickness: 3.5,
        ),
        child: Text(value),
      ),
    );
  }
}

class _MiniAmPmButton extends StatelessWidget {
  const _MiniAmPmButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isSelected ? _yellow : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11.0,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              color: isSelected ? _navy : _slate,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANIMATED ANALOG CLOCK DIAL
// Uses AnimationController + shortest-path angular interpolation
// ─────────────────────────────────────────────────────────────

class _AnalogClockDial extends StatefulWidget {
  const _AnalogClockDial({
    required this.dialSize,
    required this.hour12,
    required this.minute,
    required this.isHourMode,
    required this.onHourSelected,
    required this.onMinuteSelected,
  });

  final double dialSize;
  final int hour12;
  final int minute;
  final bool isHourMode;
  final ValueChanged<int> onHourSelected;
  final ValueChanged<int> onMinuteSelected;

  @override
  State<_AnalogClockDial> createState() => _AnalogClockDialState();
}

class _AnalogClockDialState extends State<_AnalogClockDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _angleAnim;

  /// Tracks the current rendered angle (radians) for the hand.
  double _currentAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _currentAngle = _targetAngle();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _angleAnim = AlwaysStoppedAnimation(_currentAngle);
  }

  @override
  void didUpdateWidget(covariant _AnalogClockDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newAngle = _targetAngle();
    if (newAngle != _currentAngle ||
        oldWidget.isHourMode != widget.isHourMode) {
      _animateTo(newAngle);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// The geometric angle (radians) for the current selected value.
  double _targetAngle() {
    if (widget.isHourMode) {
      final h = widget.hour12 % 12; // 12 -> 0
      return (h * 30.0 - 90.0) * math.pi / 180.0;
    } else {
      return (widget.minute * 6.0 - 90.0) * math.pi / 180.0;
    }
  }

  /// Animate from [_currentAngle] to [target] taking the shortest arc.
  void _animateTo(double target) {
    final from = _currentAngle;
    // Normalise delta to [-π, π] so we always rotate the short way.
    var delta = target - from;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    final to = from + delta;

    _angleAnim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _currentAngle = target;
    _ctrl
      ..reset()
      ..forward();
  }

  void _handleTouch(Offset local) {
    final c = widget.dialSize / 2;
    final dx = local.dx - c;
    final dy = local.dy - c;
    var clockDeg = (math.atan2(dy, dx) * 180.0 / math.pi + 90.0) % 360.0;
    if (clockDeg < 0) clockDeg += 360.0;

    if (widget.isHourMode) {
      var h = (clockDeg / 30.0).round();
      if (h == 0) h = 12;
      widget.onHourSelected(h);
    } else {
      final m = (clockDeg / 6.0).round() % 60;
      widget.onMinuteSelected(m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.dialSize;
    final center = size / 2;
    // Number ring radius ≈ 38% of dial diameter
    final radius = size * 0.38;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final angle = _ctrl.isAnimating ? _angleAnim.value : _currentAngle;
        final tx = center + radius * math.cos(angle);
        final ty = center + radius * math.sin(angle);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _handleTouch(d.localPosition),
          onPanUpdate: (d) => _handleTouch(d.localPosition),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _surface,
              border: Border.all(color: _border, width: 1.0),
              boxShadow: const [
                BoxShadow(color: Color(0x07142B45), blurRadius: 10.0, offset: Offset(0, 3)),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Dashed outer ring ──
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashedRingPainter(size: size),
                  ),
                ),

                // ── Minute tick marks ──
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MinuteTickPainter(size: size),
                  ),
                ),

                // ── Clock hand ──
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ClockHandPainter(
                      cx: center,
                      cy: center,
                      ex: tx,
                      ey: ty,
                    ),
                  ),
                ),

                // ── Selection highlight circle ──
                Positioned(
                  left: tx - 15.0,
                  top: ty - 15.0,
                  child: Container(
                    width: 30.0,
                    height: 30.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _navy,
                      border: Border.all(color: const Color(0x80FFC928), width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33142B45), blurRadius: 6.0, offset: Offset(0, 2)),
                      ],
                    ),
                    alignment: Alignment.center,
                    // Show non-5-multiple minute value inside the circle
                    child: !widget.isHourMode && (widget.minute % 5 != 0)
                        ? Text(
                            widget.minute.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),

                // ── 12 Dial Numbers ──
                ...List.generate(12, (i) {
                  final a = (i * 30.0 - 90.0) * math.pi / 180.0;
                  final nx = center + radius * math.cos(a);
                  final ny = center + radius * math.sin(a);

                  final String lbl;
                  final bool isSelected;
                  final bool isCardinal;

                  if (widget.isHourMode) {
                    final h = i == 0 ? 12 : i;
                    lbl = h.toString();
                    isSelected = widget.hour12 == h;
                    isCardinal = h == 12 || h == 3 || h == 6 || h == 9;
                  } else {
                    final m = i * 5;
                    lbl = m.toString().padLeft(2, '0');
                    isSelected = widget.minute == m;
                    isCardinal = m == 0 || m == 15 || m == 30 || m == 45;
                  }

                  final Color textColor = isSelected
                      ? Colors.white
                      : (isCardinal ? _navy : _slate);

                  final double fontSize = size < 220 ? 12.0 : 13.5;

                  return Positioned(
                    left: nx - 15.0,
                    top: ny - 15.0,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 30.0,
                        height: 30.0,
                        child: Center(
                          child: Text(
                            lbl,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: fontSize,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : (isCardinal ? FontWeight.w700 : FontWeight.w500),
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // ── Centre pivot ──
                Positioned(
                  left: center - 7.0,
                  top: center - 7.0,
                  child: Container(
                    width: 14.0,
                    height: 14.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _navy,
                      boxShadow: [
                        BoxShadow(
                            color: Color(0x26142B45), blurRadius: 3.0, offset: Offset(0, 1)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _yellow,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────

class _ClockHandPainter extends CustomPainter {
  const _ClockHandPainter({
    required this.cx,
    required this.cy,
    required this.ex,
    required this.ey,
  });

  final double cx, cy, ex, ey;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _navy
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy), Offset(ex, ey), paint);
  }

  @override
  bool shouldRepaint(covariant _ClockHandPainter old) =>
      old.ex != ex || old.ey != ey;
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.size});
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = const Color(0x55C4CDD6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final c = Offset(size / 2, size / 2);
    // Ring sits 10px inside the edge
    final r = size / 2 - 10.0;
    const dashes = 48;
    const sweep = (2 * math.pi) / dashes;
    for (int i = 0; i < dashes; i++) {
      if (i.isEven) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          i * sweep,
          sweep * 0.65,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => old.size != size;
}

class _MinuteTickPainter extends CustomPainter {
  const _MinuteTickPainter({required this.size});
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final c = Offset(size / 2, size / 2);
    final outerR = size / 2 - 4.0;

    final majorPaint = Paint()
      ..color = const Color(0x55C4CDD6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final minorPaint = Paint()
      ..color = const Color(0x33C4CDD6)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final a = (i * 6.0 - 90.0) * math.pi / 180.0;
      final isMajor = i % 5 == 0;
      final tickLen = isMajor ? 6.0 : 3.5;
      final innerR = outerR - tickLen;

      canvas.drawLine(
        Offset(c.dx + innerR * math.cos(a), c.dy + innerR * math.sin(a)),
        Offset(c.dx + outerR * math.cos(a), c.dy + outerR * math.sin(a)),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MinuteTickPainter old) => old.size != size;
}
