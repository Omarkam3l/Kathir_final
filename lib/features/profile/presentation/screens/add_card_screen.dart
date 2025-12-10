import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kathir_final/features/authentication/presentation/blocs/auth_provider.dart';

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
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Card'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          // card preview
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color.fromARGB(255, 157, 237, 239), Color.fromARGB(255, 97, 218, 255)]), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Align(alignment: Alignment.topRight, child: Icon(Icons.credit_card, color: Colors.white)),
              Text(_number.text.isEmpty ? 'XXXX XXXX XXXX XXXX' : _number.text, style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_name.text.isEmpty ? 'Full Name' : _name.text, style: const TextStyle(color: Colors.white)), Text(_expiry.text.isEmpty ? 'MM/YY' : _expiry.text, style: const TextStyle(color: Colors.white))])
            ]),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(controller: _number, decoration: const InputDecoration(labelText: 'Card Number'), keyboardType: TextInputType.number, validator: (v) => v == null || v.replaceAll(' ', '').length < 12 ? 'Enter card number' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => v == null || v.isEmpty ? 'Enter name' : null),
              const SizedBox(height: 8),
              Row(children: [Expanded(child: TextFormField(controller: _expiry, decoration: const InputDecoration(labelText: 'Expiry'), validator: (v) => v == null || v.isEmpty ? 'Enter expiry' : null)), const SizedBox(width: 12), Expanded(child: TextFormField(controller: _cvv, decoration: const InputDecoration(labelText: 'CVV'), obscureText: true, validator: (v) => v == null || v.length < 3 ? 'Enter CVV' : null))]),
              const SizedBox(height: 16),
              ElevatedButton(
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
                      ? const CircularProgressIndicator()
                      : const Text('Add Card'))
            ]),
          )
        ]),
      ),
    );
  }
}
