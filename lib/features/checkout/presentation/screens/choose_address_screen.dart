import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChooseAddressScreen extends StatefulWidget {
  static const routeName = '/choose-address';
  const ChooseAddressScreen({super.key});

  @override
  State<ChooseAddressScreen> createState() => _ChooseAddressScreenState();
}

class _ChooseAddressScreenState extends State<ChooseAddressScreen> {
  int _selectedIndex = 0;
  List<AddressModel> _addresses = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _addresses = [
      AddressModel(
        label: l10n.addressHomeLabel,
        type: l10n.addressHomeType,
        phone: '(503) 338-5200',
        address: '15612 Fisher Island Dr Miami Beach, Florida(FL), 33109',
      ),
      AddressModel(
        label: l10n.addressOfficeLabel,
        type: l10n.addressOfficeType,
        phone: '(503) 338-5200',
        address: '15612 Fisher Island Dr Miami Beach, Florida(FL), 33109',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Row(
                children: [
                  _diamondButton(
                    context,
                    icon: Icons.arrow_back_ios_new,
                    onTap: () {
                      final router = GoRouter.of(context);
                      if (router.canPop()) {
                        router.pop();
                      } else {
                        router.go('/home');
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.chooseAddressTitle,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                children: [
                  ...List.generate(
                    _addresses.length,
                    (index) => _AddressCard(
                      address: _addresses[index],
                      isSelected: _selectedIndex == index,
                      onTap: () => setState(() => _selectedIndex = index),
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to add new address
                    },
                    icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                    label: Text(
                      l10n.addNewAddress,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(_addresses[_selectedIndex]),
                  child: Text(
                    l10n.doneAction,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diamondButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Transform.rotate(
      angle: 0.78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.78,
            child: Icon(
              icon,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  final AddressModel address;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.type,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Radio<int>(
              value: isSelected ? 1 : 0,
              groupValue: isSelected ? 1 : 0,
              onChanged: (_) => onTap(),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class AddressModel {
  const AddressModel({
    required this.label,
    required this.type,
    required this.phone,
    required this.address,
  });

  final String label;
  final String type;
  final String phone;
  final String address;
}

