import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:game_sentry/src/features/auth/presentation/notifiers/pin_notifier.dart';
import 'package:game_sentry/src/features/parents/presentation/screens/parent_dashboard_screen.dart';
import 'package:appwrite/models.dart' as appwrite_models;

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  final List<TextEditingController> _pinControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (index) => FocusNode());
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Add listeners to move to next field when 1 character is entered
    for (int i = 0; i < 6; i++) {
      final int index = i;
      _pinControllers[index].addListener(() {
        if (_pinControllers[index].text.length == 1 && index < 5) {
          _pinFocusNodes[index + 1].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < 6; i++) {
      _pinControllers[i].dispose();
      _pinFocusNodes[i].dispose();
    }
    super.dispose();
  }

  Future<void> _submitPin() async {
    final enteredPin = _pinControllers.map((c) => c.text).join();
    
    if (enteredPin.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a 6-digit PIN';
      });
      return;
    }

    // Clear any previous errors
    ref.read(pinNotifierProvider.notifier).clearError();

    // Use the PinNotifier to handle verification
    final isValid = await ref.read(pinNotifierProvider.notifier).verifyPin(enteredPin);
    
    if (isValid) {
      // Convert string to integer
      final pin = int.tryParse(enteredPin) ?? -1;
      
      // Get the parent ID by PIN
      final parentId = await ref.read(pinNotifierProvider.notifier).getParentIdByPin(pin);
      
      if (parentId != null) {
        // Create a mock user for the authenticated parent
        final mockUser = appwrite_models.User(
          $id: parentId,
          name: 'Parent',
          email: 'parent@game_sentry.com',
          prefs: appwrite_models.Preferences(data: {}),
          registration: DateTime.now().toIso8601String(),
          status: true,
          passwordUpdate: DateTime.now().toIso8601String(),
          phone: '',
          emailVerification: true,
          phoneVerification: false,
          $createdAt: DateTime.now().toIso8601String(),
          $updatedAt: DateTime.now().toIso8601String(),
          labels: [],
          mfa: false,
          targets: [],
          accessedAt: DateTime.now().toIso8601String(),
        );

        // Update auth state to simulate login
        ref.read(authNotifierProvider.notifier).updateUser(mockUser);

        // Navigate to parent dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ParentDashboardScreen(),
            ),
          );
        }
      } else {
        // This shouldn't happen if verification passed, but as a fallback
        setState(() {
          _errorMessage = 'Authentication error. Please try again.';
        });
        for (int i = 0; i < _pinControllers.length; i++) {
          _pinControllers[i].clear();
        }
        _pinFocusNodes[0].requestFocus(); // Focus back on first field
      }
    } else {
      // On error, clear the PIN fields for security
      for (int i = 0; i < _pinControllers.length; i++) {
        _pinControllers[i].clear();
      }
      _pinFocusNodes[0].requestFocus(); // Focus back on first field
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinNotifierProvider);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 32),
              const Text(
                'Game Sentry',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter Parent PIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              
              // PIN input fields
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50], // Light grey background for contrast
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Enter the 6-digit PIN generated on your mobile device',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    
                    // 6 PIN input boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _pinControllers[index],
                            focusNode: _pinFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            obscureText: false, // Changed to false so PIN numbers are visible
                            enabled: pinState.status != PinStatus.verifying,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(1),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: Colors.grey, width: 2),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: Colors.black87, // Ensure the text is clearly visible
                            ),
                            onSubmitted: (value) {
                              if (index < 5) {
                                _pinFocusNodes[index + 1].requestFocus();
                              } else {
                                // Last field submitted, try to submit the whole PIN
                                _submitPin();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (pinState.status == PinStatus.error && pinState.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          pinState.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: pinState.status == PinStatus.verifying ? null : _submitPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: pinState.status == PinStatus.verifying 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: () {
                        // Add instructions on how to get the PIN
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('How to Get Your PIN'),
                            content: const Text(
                              '1. Open the Game Sentry app on your mobile device\n'
                              '2. Navigate to the main screen when logged in\n'
                              '3. Tap the "Generate 6-Digit PIN" button\n'
                              '4. Enter the 6-digit PIN on this screen\n\n'
                              'The PIN is valid for 5 minutes and can be used once.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('How to get PIN?'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}