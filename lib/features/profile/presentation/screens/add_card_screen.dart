import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/features/authentication/presentation/blocs/auth_provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddCardScreen extends StatefulWidget {
  static const routeName = '/add-card';
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F1EB);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addNewCard), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          // card preview
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ]),
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Align(alignment: Alignment.topRight, child: Icon(Icons.credit_card, color: Colors.white)),
              Text(_number.text.isEmpty ? l10n.cardNumberHint : _number.text, style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_name.text.isEmpty ? l10n.fullNameLabel : _name.text, style: const TextStyle(color: Colors.white)), Text(_expiry.text.isEmpty ? l10n.expiryDateHint : _expiry.text, style: const TextStyle(color: Colors.white))])
            ]),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                controller: _number,
                decoration: InputDecoration(
                  labelText: l10n.cardNumberLabel,
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.replaceAll(' ', '').length < 12 ? l10n.enterCardNumberError : null
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.fullNameLabel,
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v == null || v.isEmpty ? l10n.enterNameError : null
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiry,
                    decoration: InputDecoration(
                      labelText: l10n.expiryDateLabel,
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.isEmpty ? l10n.enterExpiryError : null
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvv,
                    decoration: InputDecoration(
                      labelText: l10n.cvvLabel,
                      filled: true,
                      fillColor: inputFillColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 3 ? l10n.enterCvvError : null
                  )
                )
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading
                        ? null
                        : () async {
                          final navigator = Navigator.of(context);
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          await auth.addCard({
                            'number': _number.text.trim(),
                            'name': _name.text.trim(),
                            'expiry': _expiry.text.trim()
                          });
                          if (!mounted) return;
                          setState(() => _loading = false);
                          if (!mounted) return;
                          navigator.pop();
                        },
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.addCardAction))
            ),
            ]),
          )
        ]),
      ),
    );
  }
}
