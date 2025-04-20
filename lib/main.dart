import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/destination_provider.dart';
import 'providers/itinerary_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => DestinationProvider(),
        ),
        ChangeNotifierProxyProvider<DestinationProvider, ItineraryProvider>(
          create: (context) => ItineraryProvider(context.read<DestinationProvider>()),
          update: (context, destinationProvider, previousItineraryProvider) => 
              previousItineraryProvider ?? ItineraryProvider(destinationProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Planejamento de Viagem',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
