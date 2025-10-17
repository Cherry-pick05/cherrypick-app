import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';
import '../widgets/add_trip_dialog.dart';

class TripSelectorDialog extends StatelessWidget {
  const TripSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '여행 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...tripProvider.trips.map((trip) => _TripItem(
                  trip: trip,
                  isSelected: tripProvider.currentTripId == trip.id,
                  onTap: () {
                    tripProvider.setCurrentTrip(trip.id);
                    Navigator.of(context).pop();
                  },
                  onDelete: tripProvider.trips.length > 1
                    ? () => tripProvider.deleteTrip(trip.id)
                    : null,
                )),
                const SizedBox(height: 8),
                _AddTripButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (context) => const AddTripDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TripItem extends StatelessWidget {
  final Trip trip;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _TripItem({
    required this.trip,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
            : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          trip.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(trip.destination),
        trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
            )
          : null,
      ),
    );
  }
}

class _AddTripButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTripButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          '새 여행 추가',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
