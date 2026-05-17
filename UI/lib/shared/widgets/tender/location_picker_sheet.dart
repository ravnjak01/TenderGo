import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';

class LocationPickerSheet extends StatelessWidget {
  final List<LocationDto>? locations;

  const LocationPickerSheet({super.key, this.locations});

  static Future<LocationDto?> show(BuildContext context, {List<LocationDto>? locations}) {
    return showModalBottomSheet<LocationDto?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LocationPickerSheet(locations: locations),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          if (locations == null)
            const Expanded(
              child: Center(child: Text('No locations available')),
            )
          else if (locations!.isEmpty)
            const Expanded(
              child: Center(child: Text('No locations found')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: locations!.length,
                itemBuilder: (context, index) {
                  final loc = locations![index];
                  return ListTile(
                    title: Text(loc.name),
                    subtitle: Text(loc.country + (loc.region != null ? ' • ${loc.region}' : '')),
                    onTap: () {
                      Navigator.of(context).pop(loc);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

