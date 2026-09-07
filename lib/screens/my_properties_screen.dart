import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';

class MyPropertiesScreen extends StatelessWidget {
  const MyPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final user = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(t.t('my_properties'))),
      body: StreamBuilder<List<Property>>(
        stream: firestoreService.myProperties(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${snapshot.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final properties = snapshot.data!;
          if (properties.isEmpty) {
            return Center(child: Text(t.t('my_properties')));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              return PropertyCard(property: properties[index], canSeePrivate: true);
            },
          );
        },
      ),
    );
  }
}
