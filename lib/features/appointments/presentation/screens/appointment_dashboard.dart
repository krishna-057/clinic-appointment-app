import 'package:flutter/material.dart';

import '../widgets/appointment_form.dart';
import '../widgets/appointment_list.dart';

class AppointmentDashboard extends StatelessWidget {
  const AppointmentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinic Appointments'),
            Text(
              'Staff booking desk',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;

            if (isWide) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        SizedBox(
                          width: 430,
                          child: SingleChildScrollView(
                            child: AppointmentForm(),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(child: AppointmentList()),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(14),
              children: [
                const AppointmentForm(),
                const SizedBox(height: 14),
                SizedBox(
                  height: constraints.maxHeight.clamp(520, 760),
                  child: const AppointmentList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
