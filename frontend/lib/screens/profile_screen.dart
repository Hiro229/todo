import 'package:flutter/material.dart';
import '../services/user_auth_service.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  User? _currentUser;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await UserAuthService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _emailController.text = user.email;
          _usernameController.text = user.username;
          _fullNameController.text = user.fullName ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userUpdate = UserUpdate(
        email: _emailController.text.trim() != _currentUser?.email ? _emailController.text.trim() : null,
        username: _usernameController.text.trim() != _currentUser?.username ? _usernameController.text.trim() : null,
        fullName: _fullNameController.text.trim() != (_currentUser?.fullName ?? '') ? _fullNameController.text.trim() : null,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );

      final result = await UserAuthService.updateProfile(userUpdate);

      if (result.success && result.user != null) {
        setState(() {
          _currentUser = result.user;
          _isEditing = false;
          _successMessage = 'Profile updated successfully';
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Profile update failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await UserAuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _errorMessage = null;
      _successMessage = null;
      if (!_isEditing) {
        // Cancel editing - restore original values
        _emailController.text = _currentUser?.email ?? '';
        _usernameController.text = _currentUser?.username ?? '';
        _fullNameController.text = _currentUser?.fullName ?? '';
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value != null && value.isNotEmpty && value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_passwordController.text.isNotEmpty) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != _passwordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                _currentUser!.username.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentUser!.username,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentUser!.fullName != null && _currentUser!.fullName!.isNotEmpty)
                              Text(
                                _currentUser!.fullName!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _currentUser!.isVerified ? Icons.verified : Icons.verified_outlined,
                                  size: 16,
                                  color: _currentUser!.isVerified ? Colors.blue : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentUser!.isVerified ? 'Verified' : 'Unverified',
                                  style: TextStyle(
                                    color: _currentUser!.isVerified ? Colors.blue : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Form Fields
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Information',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: !_isEditing,
                                fillColor: !_isEditing ? Colors.grey.shade100 : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Username Field
                            TextFormField(
                              controller: _usernameController,
                              enabled: _isEditing,
                              validator: _validateUsername,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: !_isEditing,
                                fillColor: !_isEditing ? Colors.grey.shade100 : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Full Name Field
                            TextFormField(
                              controller: _fullNameController,
                              enabled: _isEditing,
                              decoration: InputDecoration(
                                labelText: 'Full Name (Optional)',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: !_isEditing,
                                fillColor: !_isEditing ? Colors.grey.shade100 : null,
                              ),
                            ),

                            // Password Fields (Only when editing)
                            if (_isEditing) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Change Password (Optional)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                validator: _validateConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm New Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Account Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Member since', _formatDate(_currentUser!.createdAt)),
                            if (_currentUser!.lastLogin != null)
                              _buildInfoRow('Last login', _formatDate(_currentUser!.lastLogin!)),
                          ],
                        ),
                      ),
                    ),

                    // Success/Error Messages
                    if (_successMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(color: Colors.green.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _toggleEditMode,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Environment Info (Debug only)
                    if (AppConfig.isDebug) ...[
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Environment: ${AppConfig.environment.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'API: ${AppConfig.apiBaseUrl}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}