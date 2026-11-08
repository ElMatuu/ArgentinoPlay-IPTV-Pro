import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import 'supabase_bootstrap.dart';

/// Optional cloud account screen. The local IPTV player remains usable
/// regardless of whether the user signs in.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  late final SupabaseAuthService? _auth;
  bool _creatingAccount = false;
  bool _obscurePassword = true;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _auth = SupabaseBootstrap.isConfigured ? SupabaseAuthService() : null;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final auth = _auth;
    if (auth == null) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (_creatingAccount) {
        final response = await auth.signUp(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
        );
        if (!mounted) return;
        setState(() {
          _message = response.session == null
              ? 'Cuenta creada. Revisá tu correo para confirmar la dirección antes de iniciar sesión.'
              : 'Tu cuenta está lista.';
          _messageIsError = false;
          if (response.session != null) _password.clear();
        });
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
        if (!mounted) return;
        setState(() {
          _message = 'Sesión iniciada correctamente.';
          _messageIsError = false;
          _password.clear();
        });
      }
    } on AuthInputException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _messageIsError = true;
        });
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _messageIsError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'No se pudo completar la operación. Revisá la conexión e intentá nuevamente.';
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final auth = _auth;
    if (auth == null || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await auth.signOut();
      if (mounted) {
        setState(() {
          _message = 'Sesión cerrada. Tus listas locales siguen disponibles.';
          _messageIsError = false;
        });
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth?.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.account_circle_outlined, size: 64),
            const SizedBox(height: 12),
            Text(
              'Cuenta ArgentinoPlay',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'La cuenta permite preparar la sincronización en la nube. La reproducción y tus listas locales no dependen de iniciar sesión.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_auth == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'La conexión con la nube todavía no está configurada en esta compilación. Podés seguir usando el reproductor localmente.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 36),
                      const SizedBox(height: 12),
                      Text(user.email ?? 'Cuenta autenticada'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _busy ? null : _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('Iniciar sesión'),
                              icon: Icon(Icons.login),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Crear cuenta'),
                              icon: Icon(Icons.person_add_alt),
                            ),
                          ],
                          selected: {_creatingAccount},
                          onSelectionChanged: _busy
                              ? null
                              : (selection) => setState(() {
                                    _creatingAccount = selection.first;
                                    _message = null;
                                  }),
                        ),
                        const SizedBox(height: 20),
                        if (_creatingAccount) ...[
                          TextFormField(
                            controller: _displayName,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 80,
                            decoration: const InputDecoration(
                              labelText: 'Nombre (opcional)',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return 'Ingresá un correo válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          autofillHints: _creatingAccount
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (_creatingAccount && password.length < 8) {
                              return 'Usá al menos 8 caracteres.';
                            }
                            if (password.isEmpty) {
                              return 'Ingresá tu contraseña.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _creatingAccount
                                      ? 'Crear cuenta'
                                      : 'Iniciar sesión',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _messageIsError
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
